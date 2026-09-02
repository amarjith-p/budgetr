// lib/features/heatmap/providers/heatmap_selected_date_provider.dart
import 'package:flutter_riverpod/legacy.dart';

final heatmapSelectedDateProvider = StateProvider<DateTime?>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
