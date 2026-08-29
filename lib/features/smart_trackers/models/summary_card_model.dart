import 'dart:convert';

class SmartSummaryMetric {
  final String id;
  final String label;
  final String formula;
  final String formatAs; // 'currency', 'percentage', 'number', 'text'
  final String? colorHex;
  final String? currencySymbol; // <-- NEW

  SmartSummaryMetric({
    required this.id,
    required this.label,
    required this.formula,
    required this.formatAs,
    this.colorHex,
    this.currencySymbol, // <-- NEW
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'formula': formula,
    'formatAs': formatAs,
    'colorHex': colorHex,
    'currencySymbol': currencySymbol, // <-- NEW
  };

  factory SmartSummaryMetric.fromJson(Map<String, dynamic> json) =>
      SmartSummaryMetric(
        id: json['id'],
        label: json['label'],
        formula: json['formula'],
        formatAs: json['formatAs'] ?? 'text',
        colorHex: json['colorHex'],
        currencySymbol: json['currencySymbol'], // <-- NEW
      );
}

class SmartSummaryCardConfig {
  final String title;
  final SmartSummaryMetric? mainMetric;
  final List<SmartSummaryMetric> subMetrics;

  SmartSummaryCardConfig({
    required this.title,
    this.mainMetric,
    required this.subMetrics,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'mainMetric': mainMetric?.toJson(),
    'subMetrics': subMetrics.map((m) => m.toJson()).toList(),
  };

  factory SmartSummaryCardConfig.fromJson(Map<String, dynamic> json) =>
      SmartSummaryCardConfig(
        title: json['title'] ?? 'TRACKER SUMMARY',
        mainMetric: json['mainMetric'] != null
            ? SmartSummaryMetric.fromJson(json['mainMetric'])
            : null,
        subMetrics:
            (json['subMetrics'] as List<dynamic>?)
                ?.map((e) => SmartSummaryMetric.fromJson(e))
                .toList() ??
            [],
      );

  static SmartSummaryCardConfig parse(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return SmartSummaryCardConfig(title: 'TRACKER SUMMARY', subMetrics: []);
    }
    return SmartSummaryCardConfig.fromJson(jsonDecode(jsonString));
  }
}
