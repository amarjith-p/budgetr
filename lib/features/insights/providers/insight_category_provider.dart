// features/insights/providers/insight_category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/services/transaction_service.dart';
import '../models/insight_category_model.dart';
import '../models/insight_subcategory_model.dart';
import 'insight_filter_provider.dart';
import 'insight_view_provider.dart';

final insightCategoryBreakdownProvider =
    Provider.autoDispose<List<InsightCategoryModel>>((ref) {
      final filter = ref.watch(insightFilterProvider);
      final isExpense = ref.watch(insightViewIsExpenseProvider);
      final allTxs = ref.watch(allTransactionsProvider).asData?.value ?? [];

      final now = DateTime.now();
      DateTime currentStart = DateTime(2000), currentEnd = DateTime(2100);
      DateTime prevStart = DateTime(1900), prevEnd = DateTime(1999);

      switch (filter.timeFrame) {
        case 'Today':
          currentStart = DateTime(now.year, now.month, now.day);
          currentEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          prevStart = currentStart.subtract(const Duration(days: 1));
          prevEnd = currentEnd.subtract(const Duration(days: 1));
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
          prevStart = currentStart.subtract(const Duration(days: 7));
          prevEnd = currentEnd.subtract(const Duration(days: 7));
          break;
        case 'This Month':
          currentStart = DateTime(now.year, now.month, 1);
          currentEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          prevStart = DateTime(now.year, now.month - 1, 1);
          prevEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case 'Last Month':
          currentStart = DateTime(now.year, now.month - 1, 1);
          currentEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
          prevStart = DateTime(now.year, now.month - 2, 1);
          prevEnd = DateTime(now.year, now.month - 1, 0, 23, 59, 59);
          break;
        case 'This Year':
          currentStart = DateTime(now.year, 1, 1);
          currentEnd = DateTime(now.year, 12, 31, 23, 59, 59);
          prevStart = DateTime(now.year - 1, 1, 1);
          prevEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
          break;
        case 'Last Year':
          currentStart = DateTime(now.year - 1, 1, 1);
          currentEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
          prevStart = DateTime(now.year - 2, 1, 1);
          prevEnd = DateTime(now.year - 2, 12, 31, 23, 59, 59);
          break;
        case 'Custom Range':
          if (filter.customRange != null) {
            currentStart = filter.customRange!.start;
            currentEnd = filter.customRange!.end.add(
              const Duration(hours: 23, minutes: 59, seconds: 59),
            );
            final durationDays =
                filter.customRange!.end
                    .difference(filter.customRange!.start)
                    .inDays +
                1;
            prevStart = currentStart.subtract(Duration(days: durationDays));
            prevEnd = currentEnd.subtract(Duration(days: durationDays));
          }
          break;
        case 'All Time':
        default:
          break;
      }

      List<TransactionWithDetails> currentTxs = [];
      List<TransactionWithDetails> prevTxs = [];
      double grandTotal = 0.0;

      final targetType = isExpense ? 'Expense' : 'Income';

      for (var t in allTxs) {
        final tx = t.transaction;
        final accType = t.account.type;

        if (filter.accountId != null) {
          if (filter.accountId == 'ASSETS') {
            if (accType == 'Credit Cards' || accType == 'Loan') continue;
          } else if (filter.accountId == 'CREDIT') {
            if (accType != 'Credit Cards' && accType != 'Loan') continue;
          } else if (tx.accountId != filter.accountId)
            continue;
        }

        if (tx.type == 'Transfer' || tx.type != targetType) continue;

        if (!tx.date.isBefore(currentStart) && !tx.date.isAfter(currentEnd)) {
          currentTxs.add(t);
          grandTotal += tx.amount;
        } else if (!tx.date.isBefore(prevStart) && !tx.date.isAfter(prevEnd)) {
          prevTxs.add(t);
        }
      }

      final Map<String, double> prevCatTotals = {};
      final Map<String, double> prevSubTotals = {};

      for (var t in prevTxs) {
        // --- FIX: USE SNAPSHOT CATEGORY NAME ---
        final cat =
            t.transaction.categoryName ?? t.category?.name ?? 'Uncategorized';
        final sub = t.transaction.subCategory ?? 'Uncategorized';

        prevCatTotals[cat] = (prevCatTotals[cat] ?? 0.0) + t.transaction.amount;
        prevSubTotals['$cat|$sub'] =
            (prevSubTotals['$cat|$sub'] ?? 0.0) + t.transaction.amount;
      }

      final groupedByCat = groupBy(
        currentTxs,
        // --- FIX: USE SNAPSHOT CATEGORY NAME ---
        (t) =>
            t.transaction.categoryName ?? t.category?.name ?? 'Uncategorized',
      );

      List<InsightCategoryModel> result = [];

      groupedByCat.forEach((catName, catTxs) {
        double catTotal = 0.0;
        for (var t in catTxs) catTotal += t.transaction.amount;

        // --- FIX: USE SNAPSHOT CATEGORY ICON ---
        final match = catTxs.firstWhereOrNull(
          (t) =>
              t.transaction.categoryIcon != null ||
              t.category?.iconCode != null,
        );
        int? iconCode =
            match?.transaction.categoryIcon ?? match?.category?.iconCode;

        final groupedBySub = groupBy(
          catTxs,
          (t) => t.transaction.subCategory ?? 'Uncategorized',
        );

        List<InsightSubcategoryModel> subcategories = [];

        groupedBySub.forEach((subName, subTxs) {
          double subTotal = 0.0;
          for (var t in subTxs) subTotal += t.transaction.amount;

          subcategories.add(
            InsightSubcategoryModel(
              name: subName,
              totalAmount: subTotal,
              previousAmount: prevSubTotals['$catName|$subName'] ?? 0.0,
              percentage: grandTotal > 0 ? (subTotal / grandTotal) : 0.0,
              transactions: subTxs
                ..sort(
                  (a, b) => b.transaction.date.compareTo(a.transaction.date),
                ),
            ),
          );
        });

        subcategories.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        result.add(
          InsightCategoryModel(
            name: catName,
            iconCode: iconCode,
            totalAmount: catTotal,
            previousAmount: prevCatTotals[catName] ?? 0.0,
            percentage: grandTotal > 0 ? (catTotal / grandTotal) : 0.0,
            subcategories: subcategories,
            transactions: catTxs
              ..sort(
                (a, b) => b.transaction.date.compareTo(a.transaction.date),
              ),
          ),
        );
      });

      result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return result;
    });
