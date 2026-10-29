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

  // ─── AMFI Direct Scheme Lookup ───────────────────────────────────

  /// Looks up a specific Indian Mutual Fund scheme directly by its AMFI Scheme Code.
  /// (e.g. '122639' for Parag Parikh Flexi Cap Direct Growth)
  Future<MarketSearchResult?> lookupMutualFundByCode(String code) async {
    final cleanCode = code.trim();
    if (!RegExp(r'^\d{4,8}$').hasMatch(cleanCode)) return null;

    try {
      final uri = Uri.parse('https://api.mfapi.in/mf/$cleanCode/latest');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final status = data['status']?.toString().toUpperCase();
        if (status == 'SUCCESS') {
          final meta = data['meta'] as Map<String, dynamic>?;
          final name =
              meta?['scheme_name']?.toString() ?? 'Scheme $cleanCode';
          return MarketSearchResult(
            symbol: cleanCode,
            name: name,
            type: 'mutual_fund',
            exchange: 'AMFI',
            currency: 'INR',
          );
        }
      }
    } catch (e) {
      debugPrint('[MarketDataService] lookupMutualFundByCode error: $e');
    }
    return null;
  }

  // ─── Stock / ETF Direct Ticker Lookup ────────────────────────────

  /// Looks up a stock or ETF directly by its exact ticker symbol.
  /// (e.g. 'RELIANCE.NS', 'TCS.NS', 'NIFTYBEES.NS', 'GOLDBEES.NS', 'AAPL')
  /// If the ticker has no exchange suffix, automatically checks NSE (.NS) and BSE (.BO).
  Future<MarketSearchResult?> lookupStockByTicker(String ticker) async {
    final clean = ticker.trim().toUpperCase();
    if (clean.isEmpty) return null;

    // 1. Try with the ticker as-is
    final quote = await getStockQuote(clean);
    if (quote != null) {
      return MarketSearchResult(
        symbol: clean,
        name: quote.name ?? clean,
        type: 'stock',
        exchange: clean.contains('.NS')
            ? 'NSE'
            : (clean.contains('.BO') ? 'BSE' : 'STOCK'),
        currency: quote.currency,
      );
    }

    // 2. If it has no exchange suffix, try Indian NSE (.NS) first, then BSE (.BO)
    if (!clean.contains('.')) {
      final nseQuote = await getStockQuote('$clean.NS');
      if (nseQuote != null) {
        return MarketSearchResult(
          symbol: '$clean.NS',
          name: nseQuote.name ?? clean,
          type: 'stock',
          exchange: 'NSE',
          currency: nseQuote.currency,
        );
      }

      final bseQuote = await getStockQuote('$clean.BO');
      if (bseQuote != null) {
        return MarketSearchResult(
          symbol: '$clean.BO',
          name: bseQuote.name ?? clean,
          type: 'stock',
          exchange: 'BSE',
          currency: bseQuote.currency,
        );
      }
    }
    return null;
  }

  // ─── Mutual Fund Search (fuzzy, multi-keyword + code aware) ─────

  /// Searches Indian Mutual Funds via MFAPI.in.
  ///
  /// Features:
  /// - If the query is or contains a 5-7 digit AMFI scheme code, it resolves
  ///   the exact scheme directly and places it at the top of results.
  /// - If query is text, uses smart multi-keyword broad search + client-side filter
  ///   so word-order and space variations match correctly.
  Future<List<MarketSearchResult>> searchMutualFunds(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      // 1. Check if the query is or contains an AMFI Scheme Code
      final codeMatch = RegExp(r'\b\d{5,7}\b').firstMatch(cleanQuery);
      MarketSearchResult? directResult;
      if (codeMatch != null) {
        final code = codeMatch.group(0)!;
        directResult = await lookupMutualFundByCode(code);
        // If the query was purely the scheme code, return direct match immediately
        if (cleanQuery == code ||
            cleanQuery.replaceAll(RegExp(r'\D'), '') == cleanQuery) {
          if (directResult != null) return [directResult];
        }
      }

      // Normalise: collapse multiple spaces, lowercase for comparison
      final normalised = cleanQuery.replaceAll(RegExp(r'\s+'), ' ');
      final words = normalised
          .toLowerCase()
          .split(' ')
          .where((w) => w.length >= 2 && !RegExp(r'^\d+$').hasMatch(w))
          .toList();

      List<MarketSearchResult> results = [];

      // --- Strategy 1: full-string search ---
      results = await _searchMfApi(normalised);

      // --- Strategy 2: keyword-based search + client-side filter ---
      if (results.length < 3 && words.length >= 2) {
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

        if (filtered.isNotEmpty) {
          results = filtered;
        } else {
          // Relaxed: rank results by how many query words they match
          final scored = broadResults.map((r) {
            final nameLower = r.name.toLowerCase();
            final matchCount =
                words.where((w) => nameLower.contains(w)).length;
            return (result: r, score: matchCount);
          }).where((e) => e.score >= (words.length * 0.5).ceil()).toList()
            ..sort((a, b) => b.score.compareTo(a.score));

          if (scored.isNotEmpty) {
            results = scored.take(20).map((e) => e.result).toList();
          } else if (broadResults.isNotEmpty) {
            results = broadResults.take(20).toList();
          }
        }
      }

      // If we found an exact direct AMFI scheme match, prepend it at index 0
      if (directResult != null) {
        results.removeWhere((r) => r.symbol == directResult!.symbol);
        results.insert(0, directResult);
      }

      return results;
    } catch (e) {
      debugPrint('[MarketDataService] searchMutualFunds error: $e');
    }
    return [];
  }

  /// Raw MFAPI search call — returns up to 35 results
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
          return data.take(35).map((item) {
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

  // ─── Stock & ETF Search ──────────────────────────────────────────

  /// Searches Stocks & ETFs via free Yahoo Finance search endpoint
  Future<List<MarketSearchResult>> searchStocks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      // 1. Direct ticker check if query looks like a ticker symbol (e.g. NIFTYBEES, TCS.NS)
      final upper = cleanQuery.toUpperCase();
      MarketSearchResult? directMatch;
      if (!upper.contains(' ') && upper.length <= 15) {
        directMatch = await lookupStockByTicker(upper);
      }

      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=${Uri.encodeComponent(cleanQuery)}&quotesCount=15&newsCount=0',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);

      List<MarketSearchResult> results = [];

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final quotes = data['quotes'] as List<dynamic>? ?? [];

        results = quotes.where((q) {
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

      if (directMatch != null) {
        results.removeWhere((r) => r.symbol == directMatch!.symbol);
        results.insert(0, directMatch);
      }

      return results;
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

          final status = data['status']?.toString().toUpperCase();
          if (status != null && status != 'SUCCESS') {
            debugPrint(
              '[MarketDataService] MFAPI returned status: $status for $schemeCode',
            );
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

            if (price <= 0) {
              debugPrint(
                '[MarketDataService] NAV was zero/negative for $schemeCode',
              );
              continue;
            }

            DateTime date = DateTime.now();
            if (dateStr.isNotEmpty) {
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

            return MarketPriceQuote(
              symbol: schemeCode,
              name: name,
              price: price,
              date: date,
              currency: 'INR',
            );
          }
        }
      } catch (e) {
        debugPrint(
          '[MarketDataService] getMutualFundQuote attempt $attempt error for $schemeCode: $e',
        );
      }

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
                continue;
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
