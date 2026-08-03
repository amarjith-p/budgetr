// features/custom_budgets/providers/custom_budget_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../models/custom_budget_details.dart';
import '../services/custom_budget_service.dart';

final customBudgetServiceProvider = Provider<CustomBudgetService>((ref) {
  return CustomBudgetService(ref.watch(databaseProvider));
});

final activeCustomBudgetsProvider = StreamProvider.autoDispose<List<CustomBudgetWithDetails>>((ref) {
  return ref.watch(customBudgetServiceProvider).watchBudgets(false);
});

final settledCustomBudgetsProvider = StreamProvider.autoDispose<List<CustomBudgetWithDetails>>((ref) {
  return ref.watch(customBudgetServiceProvider).watchBudgets(true);
});

class CustomBudgetActionNotifier extends AsyncNotifier<void> {
  late CustomBudgetService _service;

  @override
  FutureOr<void> build() {
    _service = ref.watch(customBudgetServiceProvider);
  }

  Future<bool> saveBudget({
    String? existingId,
    required String name,
    required double amountLimit,
    required String timeFrame,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? subCategory,
    int? bucketId,
    String? accountId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.saveCustomBudget(
          existingId: existingId,
          name: name,
          amountLimit: amountLimit,
          timeFrame: timeFrame,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          subCategory: subCategory,
          bucketId: bucketId,
          accountId: accountId,
        ));
    return !state.hasError;
  }

  Future<void> settleBudget(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.settleBudget(id));
  }

  Future<void> deleteBudget(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteBudget(id));
  }
}

final customBudgetActionProvider = AsyncNotifierProvider<CustomBudgetActionNotifier, void>(
  () => CustomBudgetActionNotifier(),
);