// lib/features/heatmap/providers/heatmap_month_provider.dart
import 'package:flutter_riverpod/legacy.dart';

final heatmapSelectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
