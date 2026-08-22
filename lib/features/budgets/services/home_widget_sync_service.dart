import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class HomeWidgetSyncService {
  static const String androidWidgetName = 'BudgetWidgetProvider';

  static Future<void> syncBudget(AppDatabase db) async {
    try {
      final now = DateTime.now();

      // 1. Fetch current month's budget
      final budget =
          await (db.select(db.monthlyBudgets)..where(
                (t) => t.month.equals(now.month) & t.year.equals(now.year),
              ))
              .getSingleOrNull();

      double totalBudget = 0.0;
      List<Map<String, dynamic>> bucketsData = [];

      if (budget != null) {
        totalBudget =
            budget.salaryIncome + budget.extraIncome - budget.deductions;

        // Parse individual buckets
        if (budget.bucketsSnapshot != null) {
          try {
            final List<dynamic> decoded = jsonDecode(budget.bucketsSnapshot!);
            for (var b in decoded) {
              bucketsData.add({
                'id': b['id'],
                'name': b['name'] ?? 'Unnamed Bucket',
                'allocated': totalBudget * ((b['percentage'] as num) / 100.0),
                'spent': 0.0,
              });
            }
          } catch (_) {}
        }
      }

      // 2. Fetch expenses for the month
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

      final txs =
          await (db.select(db.transactions)
                ..where(
                  (t) =>
                      t.date.isBiggerOrEqualValue(startOfMonth) &
                      t.date.isSmallerThanValue(startOfNextMonth),
                )
                ..where((t) => t.type.equals('Expense')))
              .get();

      double totalSpentInBuckets = 0.0;

      for (var tx in txs) {
        bool isLoanFee =
            tx.subCategory == 'Loan Interest' ||
            tx.subCategory == 'Tax on Interest' ||
            tx.subCategory == 'Bank Charges on Loan';

        if (!isLoanFee) {
          // EXCLUDE "Out of Bucket" spends (null or -1)
          if (tx.bucketId != null && tx.bucketId != -1) {
            totalSpentInBuckets += tx.amount;

            // Allocate to specific bucket
            for (var b in bucketsData) {
              if (b['id'] == tx.bucketId) {
                b['spent'] += tx.amount;
                break;
              }
            }
          }
        }
      }

      double remaining = totalBudget - totalSpentInBuckets;
      double progress = totalBudget > 0
          ? (totalSpentInBuckets / totalBudget).clamp(0.0, 1.0)
          : 0.0;

      // 3. Prepare JSON for Android Buckets
      // Removed .take(3) to include ALL buckets.
      List<Map<String, dynamic>> finalBucketsJson = bucketsData.map((b) {
        double allocated = (b['allocated'] as num?)?.toDouble() ?? 0.0;
        double spent = (b['spent'] as num?)?.toDouble() ?? 0.0;
        int bucketProgress = allocated > 0
            ? ((spent / allocated) * 100).clamp(0, 100).toInt()
            : 0;

        return {
          'name': b['name'].toString(),
          'spent': '₹${spent.toStringAsFixed(2)}',
          'allocated': '₹${allocated.toStringAsFixed(2)}',
          'progress': bucketProgress,
        };
      }).toList();

      // 4. Save to Native Widget SharedPreferences
      final monthName = DateFormat('MMMM yyyy').format(now);

      await HomeWidget.saveWidgetData<String>(
        'budget_month',
        monthName.toUpperCase(),
      );
      await HomeWidget.saveWidgetData<String>(
        'budget_total',
        totalBudget.toStringAsFixed(2),
      );
      await HomeWidget.saveWidgetData<String>(
        'budget_spent',
        '₹${totalSpentInBuckets.toStringAsFixed(2)}',
      );
      await HomeWidget.saveWidgetData<String>(
        'budget_remaining',
        '₹${remaining.toStringAsFixed(2)} left',
      );
      await HomeWidget.saveWidgetData<int>(
        'budget_progress_int',
        (progress * 100).toInt(),
      );
      await HomeWidget.saveWidgetData<String>(
        'buckets_json',
        jsonEncode(finalBucketsJson),
      );

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );

      debugPrint("WIDGET SYNC SUCCESSFUL (ALL BUCKETS INCLUDED)");
    } catch (e) {
      debugPrint("WIDGET SYNC ERROR: $e");
    }
  }
}
