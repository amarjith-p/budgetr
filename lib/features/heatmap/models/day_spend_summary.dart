// lib/features/heatmap/models/day_spend_summary.dart
import 'package:flutter/material.dart';

enum HeatmapColorLevel { green, orange, red, noData, future }

class DaySpendSummary {
  final DateTime date;
  final double totalSpend;
  final double dailyTarget;
  final HeatmapColorLevel level;

  const DaySpendSummary({
    required this.date,
    required this.totalSpend,
    required this.dailyTarget,
    required this.level,
  });
}

class HeatmapAdvice {
  final String text;
  final Color color;
  final IconData icon;

  const HeatmapAdvice({
    required this.text,
    required this.color,
    required this.icon,
  });
}

class HeatmapData {
  final List<DaySpendSummary> days;
  final double includedBudget;
  // --- FIX: Now holds multiple pieces of advice ---
  final List<HeatmapAdvice> advices;

  const HeatmapData({
    required this.days,
    required this.includedBudget,
    required this.advices,
  });
}
