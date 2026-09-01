// lib/features/smart_trackers/models/summary_card_model.dart
import 'dart:convert';

class ConditionalFormatRule {
  final String operator; // '>', '<', '>=', '<=', '=='
  final double value;
  final String colorHex;

  ConditionalFormatRule({
    required this.operator,
    required this.value,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
    'operator': operator,
    'value': value,
    'colorHex': colorHex,
  };

  factory ConditionalFormatRule.fromJson(Map<String, dynamic> json) =>
      ConditionalFormatRule(
        operator: json['operator'] ?? '>',
        value: (json['value'] as num).toDouble(),
        colorHex: json['colorHex'] ?? '#FFFFFF',
      );
}

class SmartSummaryMetric {
  final String id;
  final String label;
  final String formula;
  final String formatAs; // 'currency', 'percentage', 'number', 'text'
  final String? colorHex;
  final String? currencySymbol;
  final List<ConditionalFormatRule>? conditionalColors;

  SmartSummaryMetric({
    required this.id,
    required this.label,
    required this.formula,
    required this.formatAs,
    this.colorHex,
    this.currencySymbol,
    this.conditionalColors,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'formula': formula,
    'formatAs': formatAs,
    'colorHex': colorHex,
    'currencySymbol': currencySymbol,
    'conditionalColors': conditionalColors?.map((r) => r.toJson()).toList(),
  };

  factory SmartSummaryMetric.fromJson(Map<String, dynamic> json) =>
      SmartSummaryMetric(
        id: json['id'],
        label: json['label'],
        formula: json['formula'],
        formatAs: json['formatAs'] ?? 'text',
        colorHex: json['colorHex'],
        currencySymbol: json['currencySymbol'],
        conditionalColors: (json['conditionalColors'] as List<dynamic>?)
            ?.map((e) => ConditionalFormatRule.fromJson(e))
            .toList(),
      );
}

class SmartSummaryCardConfig {
  final String title;
  final List<SmartSummaryMetric> mainMetrics; // <-- UPDATED TO LIST
  final List<SmartSummaryMetric> subMetrics;

  SmartSummaryCardConfig({
    required this.title,
    required this.mainMetrics,
    required this.subMetrics,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'mainMetrics': mainMetrics.map((m) => m.toJson()).toList(),
    'subMetrics': subMetrics.map((m) => m.toJson()).toList(),
  };

  factory SmartSummaryCardConfig.fromJson(Map<String, dynamic> json) {
    // Graceful backward compatibility handling for existing single 'mainMetric'
    List<SmartSummaryMetric> parsedMains = [];
    if (json['mainMetrics'] != null) {
      parsedMains = (json['mainMetrics'] as List<dynamic>)
          .map((e) => SmartSummaryMetric.fromJson(e))
          .toList();
    } else if (json['mainMetric'] != null) {
      parsedMains = [SmartSummaryMetric.fromJson(json['mainMetric'])];
    }

    return SmartSummaryCardConfig(
      title: json['title'] ?? 'TRACKER SUMMARY',
      mainMetrics: parsedMains,
      subMetrics:
          (json['subMetrics'] as List<dynamic>?)
              ?.map((e) => SmartSummaryMetric.fromJson(e))
              .toList() ??
          [],
    );
  }

  static SmartSummaryCardConfig parse(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return SmartSummaryCardConfig(
        title: 'TRACKER SUMMARY',
        mainMetrics: [],
        subMetrics: [],
      );
    }
    return SmartSummaryCardConfig.fromJson(jsonDecode(jsonString));
  }
}
