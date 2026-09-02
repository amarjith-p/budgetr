// lib/features/heatmap/models/day_spend_summary.dart

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
