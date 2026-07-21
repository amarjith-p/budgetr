import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
// Remove legacy import if no longer needed
import '../models/bucket_draft_model.dart';
import '../../../core/database/database_provider.dart';
import '../services/budget_bucket_service.dart';

class BucketDraftNotifier extends StateNotifier<List<BucketDraft>> {
  final BudgetBucketService _service;
  StreamSubscription? _dbSubscription;

  // Update constructor to require the service
  BucketDraftNotifier(this._service) : super([]) {
    // 2. Start listening to the database immediately upon initialization
    _listenToDatabase();
  }
  void _listenToDatabase() {
    _dbSubscription = _service.watchBuckets().listen((bucketsFromDb) {
      // Instantly overwrite the UI state whenever the DB changes
      state = bucketsFromDb; 
    });
  }
  @override
  void dispose() {
    // 3. Clean up the listener to prevent memory leaks when the screen is closed
    _dbSubscription?.cancel();
    super.dispose();
  }

  void addBucket() {
    state = [...state, BucketDraft()];
  }

  void updateName(String id, String name) {
    state = state.map((b) => b.id == id ? b.copyWith(name: name) : b).toList();
  }

  void updatePercentage(String id, double percentage) {
    state = state.map((b) => b.id == id ? b.copyWith(percentage: percentage) : b).toList();
  }

  void removeBucket(String id) {
    state = state.where((b) => b.id != id).toList();
  }
  void scrubEmptyBuckets() {
    state = state.where((b) => b.name.trim().isNotEmpty || b.percentage > 0).toList();
  }
  double get totalPercentage => state.fold(0, (sum, b) => sum + b.percentage);

  bool get isValid {
    // Only validate buckets that contain at least some data
    final activeBuckets = state.where((b) => b.name.trim().isNotEmpty || b.percentage > 0).toList();
    final activeTotal = activeBuckets.fold(0.0, (sum, b) => sum + b.percentage);

    return activeTotal == 100.0 &&
           activeBuckets.isNotEmpty &&
           activeBuckets.every((b) => b.name.trim().isNotEmpty && b.percentage > 0);
  }

  Future<bool> saveBuckets() async {
    scrubEmptyBuckets();
    if (!isValid) return false;
    
    try {
      await _service.replaceAllBuckets(state);
      return true; // Database transaction succeeded
    } catch (e) {
      return false; // Database transaction failed
    }
  }
}

final bucketDraftProvider = StateNotifierProvider.autoDispose<BucketDraftNotifier, List<BucketDraft>>((ref) {
  final db = ref.watch(databaseProvider);
  final service = BudgetBucketService(db);
  return BucketDraftNotifier(service);
});