// lib/features/investments/models/market_data_models.dart

class MarketSearchResult {
  final String symbol; // Scheme Code (e.g. '101206') or Stock Ticker (e.g. 'RELIANCE.NS')
  final String name; // Scheme name or Stock name
  final String type; // 'mutual_fund' or 'stock'
  final String? exchange; // 'NSE', 'BSE', 'AMFI', etc.
  final String currency;

  const MarketSearchResult({
    required this.symbol,
    required this.name,
    required this.type,
    this.exchange,
    this.currency = 'INR',
  });

  bool get isMutualFund => type == 'mutual_fund';
  bool get isStock => type == 'stock';

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'type': type,
    'exchange': exchange,
    'currency': currency,
  };

  factory MarketSearchResult.fromJson(Map<String, dynamic> json) {
    return MarketSearchResult(
      symbol: json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'stock',
      exchange: json['exchange']?.toString(),
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}

class MarketPriceQuote {
  final String symbol;
  final double price;
  final double? previousClose;
  final double? changePercent;
  final DateTime date;
  final String currency;
  final String? name;

  const MarketPriceQuote({
    required this.symbol,
    required this.price,
    this.previousClose,
    this.changePercent,
    required this.date,
    this.currency = 'INR',
    this.name,
  });

  double? get changeAmount {
    if (previousClose != null && previousClose! > 0) {
      return price - previousClose!;
    }
    return null;
  }
}

