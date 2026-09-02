// lib/features/heatmap/providers/heatmap_daily_spend_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../budgets/providers/budget_provider.dart';

import '../models/day_spend_summary.dart';
import 'heatmap_month_provider.dart';
import 'heatmap_bucket_selection_provider.dart';

final heatmapBudgetProvider = StreamProvider.family
    .autoDispose<MonthlyBudget?, DateTime>((ref, date) {
      final service = ref.watch(budgetServiceProvider);
      return service.watchBudgetForMonth(date.month, date.year);
    });

final heatmapDailySpendProvider = Provider.autoDispose<List<DaySpendSummary>>((
  ref,
) {
  final month = ref.watch(heatmapSelectedMonthProvider);
  final budgetAsync = ref.watch(heatmapBudgetProvider(month));
  final txsAsync = ref.watch(allTransactionsProvider);
  final bucketsAsync = ref.watch(bucketsStreamProvider);
  final selectedBucketsState = ref.watch(heatmapSelectedBucketsProvider);

  if (selectedBucketsState == null ||
      !txsAsync.hasValue ||
      !bucketsAsync.hasValue) {
    return [];
  }

  final allBuckets = bucketsAsync.value ?? [];
  final txs = txsAsync.value ?? [];
  final budget = budgetAsync.value;

  Set<int> selectedBuckets = selectedBucketsState;
  if (selectedBuckets.isEmpty && allBuckets.isNotEmpty) {
    selectedBuckets = allBuckets.map((b) => b.id).toSet();
  }

  if (selectedBuckets.isEmpty) {
    return [];
  }

  // --- CALCULATE HISTORICAL MEDIAN FALLBACK (Trailing 60 Days) ---
  final now = DateTime.now();
  final sixtyDaysAgo = now.subtract(const Duration(days: 60));
  Map<DateTime, double> trailingSpend = {};

  for (var txData in txs) {
    final t = txData.transaction;
    if (t.type != 'Expense') continue;
    if (t.bucketId == null || t.bucketId == -1) continue; // Must be bucketed
    if (!selectedBuckets.contains(t.bucketId)) continue;
    if (t.date.isBefore(sixtyDaysAgo)) continue;

    final d = DateTime(t.date.year, t.date.month, t.date.day);
    trailingSpend[d] = (trailingSpend[d] ?? 0) + t.amount;
  }

  double median = 500.0;
  if (trailingSpend.isNotEmpty) {
    final values = trailingSpend.values.toList()..sort();
    median = values[values.length ~/ 2];
  }

  // --- CALCULATE INCLUDED BUDGET FOR SELECTED BUCKETS ---
  double includedBudget = 0.0;
  if (budget != null && budget.bucketsSnapshot != null) {
    try {
      final snapshot = jsonDecode(budget.bucketsSnapshot!) as List<dynamic>;
      final effectiveIncome =
          (budget.salaryIncome + budget.extraIncome) - budget.deductions;
      for (var b in snapshot) {
        if (selectedBuckets.contains(b['id'])) {
          final percentage = (b['percentage'] as num).toDouble();
          includedBudget += effectiveIncome * (percentage / 100);
        }
      }
    } catch (_) {}
  }

  // --- BUILD PACING AGGREGATES ---
  final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  List<DaySpendSummary> result = [];
  double spentSoFar = 0.0;

  for (int d = 1; d <= daysInMonth; d++) {
    final currentDate = DateTime(month.year, month.month, d);
    final isFuture = currentDate.isAfter(
      DateTime(now.year, now.month, now.day),
    );

    // Daily Target Strategy
    double dailyTarget = median;
    if (includedBudget > 0) {
      double remaining = includedBudget - spentSoFar;
      int daysLeft = daysInMonth - d + 1;
      dailyTarget = remaining / daysLeft;

      // Blend first 2 days
      if (d == 1) dailyTarget = (dailyTarget * 0.2) + (median * 0.8);
      if (d == 2) dailyTarget = (dailyTarget * 0.5) + (median * 0.5);
    }
    if (dailyTarget <= 0) dailyTarget = median > 0 ? median : 100.0;

    // Calculate Today's Spend
    double todaySpend = 0.0;
    for (var txData in txs) {
      final t = txData.transaction;
      if (t.type == 'Expense' &&
          t.bucketId != null &&
          t.bucketId != -1 &&
          selectedBuckets.contains(t.bucketId) &&
          t.date.year == currentDate.year &&
          t.date.month == currentDate.month &&
          t.date.day == currentDate.day) {
        todaySpend += t.amount;
      }
    }

    // Determine Level
    HeatmapColorLevel level;
    if (isFuture) {
      level = HeatmapColorLevel.future;
    } else if (todaySpend == 0.0) {
      level = HeatmapColorLevel.noData;
    } else if (todaySpend <= dailyTarget) {
      level = HeatmapColorLevel.green;
    } else if (todaySpend <= 1.5 * dailyTarget) {
      level = HeatmapColorLevel.orange;
    } else {
      level = HeatmapColorLevel.red;
    }

    result.add(
      DaySpendSummary(
        date: currentDate,
        totalSpend: todaySpend,
        dailyTarget: dailyTarget,
        level: level,
      ),
    );

    spentSoFar += todaySpend;
  }

  return result;
});
