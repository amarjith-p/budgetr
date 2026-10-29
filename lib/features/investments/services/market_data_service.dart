// lib/features/investments/services/market_data_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/market_data_models.dart';

class MarketDataService {
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json',
  };

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 2;

  // ─── Mutual Fund Search (fuzzy, multi-keyword) ───────────────────

  /// Searches Indian Mutual Funds via the completely free MFAPI.in endpoint.
  ///
  /// Uses a smart multi-keyword strategy:
  /// 1. First tries the full query string as-is.
  /// 2. If few/no results, splits into individual words and searches the
  ///    longest keyword, then filters results client-side against all words.
  /// This makes the search forgiving of spaces and word order differences.
  Future<List<MarketSearchResult>> searchMutualFunds(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      // Normalise: collapse multiple spaces, lowercase for comparison
      final normalised = cleanQuery.replaceAll(RegExp(r'\s+'), ' ');
      final words = normalised
          .toLowerCase()
          .split(' ')
          .where((w) => w.length >= 2) // ignore single-char words
          .toList();

      // --- Strategy 1: full-string search ---
      List<MarketSearchResult> results = await _searchMfApi(normalised);

      // If we got decent results, return them
      if (results.length >= 3) return results;

      // --- Strategy 2: keyword-based search + client-side filter ---
      if (words.length >= 2) {
        // Search using the longest keyword (most specific)
        final sortedWords = List<String>.from(words)
          ..sort((a, b) => b.length.compareTo(a.length));
        final primaryKeyword = sortedWords.first;

        final broadResults = await _searchMfApi(primaryKeyword);

        // Client-side fuzzy filter: keep results whose name contains
        // ALL of the user's search words (case-insensitive)
        final filtered = broadResults.where((r) {
          final nameLower = r.name.toLowerCase();
          return words.every((w) => nameLower.contains(w));
        }).toList();

        // If strict all-words match gives results, use them
        if (filtered.isNotEmpty) return filtered;

        // Relaxed: rank results by how many query words they match
        final scored = broadResults.map((r) {
          final nameLower = r.name.toLowerCase();
          final matchCount = words.where((w) => nameLower.contains(w)).length;
          return (result: r, score: matchCount);
        }).where((e) => e.score >= (words.length * 0.5).ceil()).toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        if (scored.isNotEmpty) {
          return scored.take(15).map((e) => e.result).toList();
        }

        // If longest keyword gave nothing, try the first keyword as well
        if (broadResults.isEmpty && sortedWords.length > 1) {
          final fallbackResults = await _searchMfApi(words.first);
          final fallbackFiltered = fallbackResults.where((r) {
            final nameLower = r.name.toLowerCase();
            return words
                .where((w) => nameLower.contains(w))
                .length >= (words.length * 0.5).ceil();
          }).toList();
          if (fallbackFiltered.isNotEmpty) return fallbackFiltered;
          return fallbackResults;
        }

        // Return whatever broad results we got
        return broadResults;
      }

      return results;
    } catch (e) {
      debugPrint('[MarketDataService] searchMutualFunds error: $e');
    }
    return [];
  }

  /// Raw MFAPI search call — returns up to 30 results
  Future<List<MarketSearchResult>> _searchMfApi(String query) async {
    try {
      final uri = Uri.parse(
        'https://api.mfapi.in/mf/search?q=${Uri.encodeComponent(query)}',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.take(30).map((item) {
            final code = item['schemeCode']?.toString() ?? '';
            final name = item['schemeName']?.toString() ?? '';
            return MarketSearchResult(
              symbol: code,
              name: name,
              type: 'mutual_fund',
              exchange: 'AMFI',
              currency: 'INR',
            );
          }).toList();
        }
      } else {
        debugPrint(
          '[MarketDataService] MFAPI search returned ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[MarketDataService] _searchMfApi error: $e');
    }
    return [];
  }

  // ─── Stock Search ────────────────────────────────────────────────

  /// Searches Stocks & ETFs via free Yahoo Finance search endpoint
  Future<List<MarketSearchResult>> searchStocks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=${Uri.encodeComponent(cleanQuery)}&quotesCount=10&newsCount=0',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final quotes = data['quotes'] as List<dynamic>? ?? [];

        return quotes.where((q) {
          final quoteType = q['quoteType']?.toString().toUpperCase();
          return quoteType == 'EQUITY' ||
              quoteType == 'ETF' ||
              quoteType == 'MUTUALFUND';
        }).map((q) {
          final symbol = q['symbol']?.toString() ?? '';
          final name = q['longname']?.toString() ??
              q['shortname']?.toString() ??
              symbol;
          final exchange = q['exchDisp']?.toString() ??
              q['exchange']?.toString() ??
              '';
          return MarketSearchResult(
            symbol: symbol,
            name: name,
            type: 'stock',
            exchange: exchange,
            currency: 'INR',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[MarketDataService] searchStocks error: $e');
    }
    return [];
  }

  // ─── Mutual Fund Quote (with retry) ──────────────────────────────

  /// Fetches latest NAV for Indian Mutual Fund by AMFI scheme code.
  /// Automatically retries up to [_maxRetries] times on failure.
  Future<MarketPriceQuote?> getMutualFundQuote(String schemeCode) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse('https://api.mfapi.in/mf/$schemeCode/latest');
        final response = await http
            .get(uri, headers: _headers)
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);

          // Check for 'SUCCESS' status from MFAPI
          final status = data['status']?.toString().toUpperCase();
          if (status != null && status != 'SUCCESS') {
            debugPrint(
              '[MarketDataService] MFAPI returned status: $status for $schemeCode',
            );
            // Don't retry on explicit non-success status
            return null;
          }

          final meta = data['meta'] as Map<String, dynamic>?;
          final list = data['data'] as List<dynamic>?;

          if (list != null && list.isNotEmpty) {
            final first = list.first as Map<String, dynamic>;
            final navStr = first['nav']?.toString() ?? '0.0';
            final dateStr = first['date']?.toString() ?? '';
            final price = double.tryParse(navStr) ?? 0.0;
            final name = meta?['scheme_name']?.toString();

            // Sanity check: a NAV of 0 is almost certainly invalid
            if (price <= 0) {
              debugPrint(
                '[MarketDataService] NAV was zero/negative for $schemeCode',
              );
              continue; // retry
            }

            DateTime date = DateTime.now();
            if (dateStr.isNotEmpty) {
              // MFAPI returns DD-MM-YYYY
              final parts = dateStr.split('-');
              if (parts.length == 3) {
                final d = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                final y = int.tryParse(parts[2]);
                if (d != null && m != null && y != null) {
                  date = DateTime(y, m, d);
                }
              }
            }

            debugPrint(
              '[MarketDataService] Got NAV $price for scheme $schemeCode (attempt $attempt)',
            );

            return MarketPriceQuote(
              symbol: schemeCode,
              name: name,
              price: price,
              date: date,
              currency: 'INR',
            );
          } else {
            debugPrint(
              '[MarketDataService] Empty data array for scheme $schemeCode',
            );
          }
        } else {
          debugPrint(
            '[MarketDataService] MFAPI quote returned HTTP ${response.statusCode} for $schemeCode (attempt $attempt)',
          );
        }
      } catch (e) {
        debugPrint(
          '[MarketDataService] getMutualFundQuote attempt $attempt error for $schemeCode: $e',
        );
      }

      // Brief delay before retry to avoid hammering
      if (attempt < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    return null;
  }

  // ─── Stock Quote (with retry) ────────────────────────────────────

  /// Fetches live stock/ETF price from Yahoo Finance.
  /// Automatically retries up to [_maxRetries] times on failure.
  Future<MarketPriceQuote?> getStockQuote(String symbol) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/${Uri.encodeComponent(symbol)}?interval=1d',
        );
        final response = await http
            .get(uri, headers: _headers)
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final result =
              (data['chart']?['result'] as List<dynamic>?)?.firstOrNull
                  as Map<String, dynamic>?;

          if (result != null) {
            final meta = result['meta'] as Map<String, dynamic>?;
            if (meta != null) {
              final double price =
                  (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
              final double? prevClose =
                  (meta['chartPreviousClose'] as num?)?.toDouble();
              final double? changePercent =
                  (meta['regularMarketChangePercent'] as num?)?.toDouble();
              final String currency =
                  meta['currency']?.toString().toUpperCase() ?? 'INR';
              final String? name = meta['longName']?.toString() ??
                  meta['shortName']?.toString();

              if (price <= 0) {
                debugPrint(
                  '[MarketDataService] Stock price was zero for $symbol',
                );
                continue; // retry
              }

              return MarketPriceQuote(
                symbol: symbol,
                name: name,
                price: price,
                previousClose: prevClose,
                changePercent: changePercent,
                date: DateTime.now(),
                currency: currency,
              );
            }
          }
        } else {
          debugPrint(
            '[MarketDataService] Yahoo quote returned HTTP ${response.statusCode} for $symbol (attempt $attempt)',
          );
        }
      } catch (e) {
        debugPrint(
          '[MarketDataService] getStockQuote attempt $attempt error for $symbol: $e',
        );
      }

      if (attempt < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    return null;
  }

  // ─── Unified Quote ───────────────────────────────────────────────

  /// Unified quote fetcher based on asset type
  Future<MarketPriceQuote?> getQuote({
    required String symbol,
    required String assetType,
  }) async {
    if (assetType == 'mutual_fund') {
      return getMutualFundQuote(symbol);
    } else {
      return getStockQuote(symbol);
    }
  }
}
