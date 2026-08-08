// features/insights/providers/insight_summary_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../models/insight_summary_model.dart';
import 'insight_filter_provider.dart';

final insightSummaryProvider = Provider<InsightSummaryModel>((ref) {
  final filter = ref.watch(insightFilterProvider);
  final allTxs = ref.watch(allTransactionsProvider).asData?.value ?? [];

  final now = DateTime.now();
  DateTime currentStart = DateTime(2000);
  DateTime currentEnd = DateTime(2100);

  // --- NEW: Robust Date Boundary Setup ---
  switch (filter.timeFrame) {
    case 'Today':
      currentStart = DateTime(now.year, now.month, now.day);
      currentEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case 'This Week':
      currentStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      currentEnd = currentStart.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      break;
    case 'This Month':
      currentStart = DateTime(now.year, now.month, 1);
      currentEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
    case 'Last Month':
      currentStart = DateTime(now.year, now.month - 1, 1);
      currentEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
      break;
    case 'This Year':
      currentStart = DateTime(now.year, 1, 1);
      currentEnd = DateTime(now.year, 12, 31, 23, 59, 59);
      break;
    case 'Last Year':
      currentStart = DateTime(now.year - 1, 1, 1);
      currentEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
      break;
    case 'Custom Range':
      if (filter.customRange != null) {
        currentStart = filter.customRange!.start;
        currentEnd = filter.customRange!.end.add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        );
      }
      break;
    case 'All Time':
    default:
      break;
  }

  double inc = 0.0;
  double exp = 0.0;

  for (var t in allTxs) {
    final tx = t.transaction;
    final accType = t.account.type;

    if (filter.accountId != null) {
      if (filter.accountId == 'ASSETS') {
        if (accType == 'Credit Cards' || accType == 'Loan') continue;
      } else if (filter.accountId == 'CREDIT') {
        if (accType != 'Credit Cards' && accType != 'Loan') continue;
      } else if (tx.accountId != filter.accountId) {
        continue;
      }
    }

    // Check if within bounds
    if (tx.date.isBefore(currentStart) || tx.date.isAfter(currentEnd)) continue;

    if (tx.type == 'Transfer') continue;
    if (tx.type == 'Income' && t.category?.name.toLowerCase() == 'repayment')
      continue;

    if (tx.type == 'Income') {
      inc += tx.amount;
    } else if (tx.type == 'Expense') {
      exp += tx.amount;
    }
  }

  return InsightSummaryModel(totalIncome: inc, totalExpense: exp);
});
