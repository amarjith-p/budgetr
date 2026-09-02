// lib/features/heatmap/providers/heatmap_bucket_selection_provider.dart
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeatmapBucketSelectionNotifier extends StateNotifier<Set<int>?> {
  HeatmapBucketSelectionNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('heatmap_buckets');
    if (saved != null) {
      state = saved.map((e) => int.parse(e)).toSet();
    } else {
      state = {};
    }
  }

  Future<void> updateSelection(Set<int> newSelection) async {
    state = newSelection;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'heatmap_buckets',
      newSelection.map((e) => e.toString()).toList(),
    );
  }
}

final heatmapSelectedBucketsProvider =
    StateNotifierProvider<HeatmapBucketSelectionNotifier, Set<int>?>(
      (ref) => HeatmapBucketSelectionNotifier(),
    );
