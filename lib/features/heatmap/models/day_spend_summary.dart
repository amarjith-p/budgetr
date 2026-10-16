// lib/features/heatmap/models/day_spend_summary.dart
import 'package:flutter/material.dart';
import '../../budgets/models/smart_projection_result.dart';
import '../../budgets/providers/projection_settings_provider.dart';

enum HeatmapColorLevel { green, orange, red, noData, future }

class DaySpendSummary {
  final DateTime date;
  final double totalSpend;
  final double dailyTarget;
  final HeatmapColorLevel level;
  final double variableSpend;
  final double fixedSpend;
  final double oneoffSpend;

  const DaySpendSummary({
    required this.date,
    required this.totalSpend,
    required this.dailyTarget,
    required this.level,
    this.variableSpend = 0.0,
    this.fixedSpend = 0.0,
    this.oneoffSpend = 0.0,
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
  final double projectedTotal;
  final List<HeatmapAdvice> advices;
  final SmartProjectionResult? smartResult;
  final int unclassifiedCount;
  final ProjectionMode projectionMode;

  const HeatmapData({
    required this.days,
    required this.includedBudget,
    required this.projectedTotal,
    required this.advices,
    this.smartResult,
    this.unclassifiedCount = 0,
    this.projectionMode = ProjectionMode.linear,
  });
}

