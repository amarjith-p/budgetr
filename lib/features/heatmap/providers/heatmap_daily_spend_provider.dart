// lib/features/heatmap/providers/heatmap_daily_spend_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../budgets/providers/budget_provider.dart';
import '../../automation/providers/automation_provider.dart';
import '../models/day_spend_summary.dart';
import 'heatmap_month_provider.dart';
import 'heatmap_bucket_selection_provider.dart';

final heatmapBudgetProvider = StreamProvider.family
    .autoDispose<MonthlyBudget?, DateTime>((ref, date) {
      final service = ref.watch(budgetServiceProvider);
      return service.watchBudgetForMonth(date.month, date.year);
    });

final heatmapDailySpendProvider = Provider.autoDispose<HeatmapData>((ref) {
  final month = ref.watch(heatmapSelectedMonthProvider);
  final budgetAsync = ref.watch(heatmapBudgetProvider(month));
  final txsAsync = ref.watch(allTransactionsProvider);
  final bucketsAsync = ref.watch(bucketsStreamProvider);
  final selectedBucketsState = ref.watch(heatmapSelectedBucketsProvider);
  final rulesAsync = ref.watch(allRecurringRulesProvider);

  if (selectedBucketsState == null ||
      !txsAsync.hasValue ||
      !bucketsAsync.hasValue) {
    return const HeatmapData(days: [], includedBudget: 0.0, advices: []);
  }

  final allBuckets = bucketsAsync.value ?? [];
  final txs = txsAsync.value ?? [];
  final rules = rulesAsync.asData?.value ?? [];
  final budget = budgetAsync.value;

  Set<int> selectedBuckets = selectedBucketsState;
  if (selectedBuckets.isEmpty && allBuckets.isNotEmpty) {
    selectedBuckets = allBuckets.map((b) => b.id).toSet();
  }

  if (selectedBuckets.isEmpty) {
    return const HeatmapData(days: [], includedBudget: 0.0, advices: []);
  }

  final now = DateTime.now();
  final isCurrentMonth = month.year == now.year && month.month == now.month;
  final isPastMonth =
      month.year < now.year ||
      (month.year == now.year && month.month < now.month);

  final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  int daysElapsed = isCurrentMonth ? now.day : (isPastMonth ? daysInMonth : 1);
  int daysLeft = isCurrentMonth
      ? (daysInMonth - now.day + 1)
      : (isPastMonth ? 0 : daysInMonth);

  // --- 1. CALCULATE BUCKET-LEVEL METRICS & OVERALL BUDGET ---
  double includedBudget = 0.0;
  Map<int, double> bucketLimits = {};
  Map<int, String> bucketNames = {};
  Map<int, double> bucketSpends = {};

  if (budget != null && budget.bucketsSnapshot != null) {
    try {
      final snapshot = jsonDecode(budget.bucketsSnapshot!) as List<dynamic>;
      final effectiveIncome =
          (budget.salaryIncome + budget.extraIncome) - budget.deductions;

      for (var b in snapshot) {
        int bId = b['id'] as int;
        if (selectedBuckets.contains(bId)) {
          final percentage = (b['percentage'] as num).toDouble();
          double limit = effectiveIncome * (percentage / 100);
          includedBudget += limit;
          bucketLimits[bId] = limit;
          bucketNames[bId] = b['name'] as String;
          bucketSpends[bId] = 0.0;
        }
      }
    } catch (_) {}
  }

  // --- 2. CALCULATE HISTORICAL TRENDS (Trailing 60 Days) ---
  final sixtyDaysAgo = now.subtract(const Duration(days: 60));
  double trailingTotalSpend = 0.0;
  double weekendSpend = 0.0;
  double weekdaySpend = 0.0;
  int weekendDaysCount = 0;
  int weekdayDaysCount = 0;

  for (int i = 0; i < 60; i++) {
    final d = now.subtract(Duration(days: i));
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      weekendDaysCount++;
    } else {
      weekdayDaysCount++;
    }
  }

  double monthTotal = 0.0;
  for (var txData in txs) {
    final t = txData.transaction;
    if (t.type != 'Expense') continue;
    if (t.bucketId == null ||
        t.bucketId == -1 ||
        !selectedBuckets.contains(t.bucketId))
      continue;

    if (t.date.year == month.year && t.date.month == month.month) {
      monthTotal += t.amount;
      bucketSpends[t.bucketId!] = (bucketSpends[t.bucketId!] ?? 0.0) + t.amount;
    }

    if (t.date.isAfter(sixtyDaysAgo)) {
      trailingTotalSpend += t.amount;
      if (t.date.weekday == DateTime.saturday ||
          t.date.weekday == DateTime.sunday) {
        weekendSpend += t.amount;
      } else {
        weekdaySpend += t.amount;
      }
    }
  }

  double historicalDailyBurn = trailingTotalSpend / 60.0;
  if (historicalDailyBurn <= 0) historicalDailyBurn = 500.0;

  // --- 3. CALCULATE UPCOMING FIXED COSTS ---
  double upcomingBills = 0.0;
  if (isCurrentMonth) {
    for (var rule in rules) {
      if (rule.isActive &&
          rule.amount != null &&
          rule.transactionType == 'Expense') {
        if (rule.nextExecutionDate.year == now.year &&
            rule.nextExecutionDate.month == now.month &&
            rule.nextExecutionDate.isAfter(now)) {
          if (rule.bucketId == null ||
              rule.bucketId == -1 ||
              selectedBuckets.contains(rule.bucketId)) {
            upcomingBills += rule.amount!;
          }
        }
      }
    }
  }

  // --- 4. BUILD PACING AGGREGATES ---
  List<DaySpendSummary> result = [];
  double spentSoFar = 0.0;

  for (int d = 1; d <= daysInMonth; d++) {
    final currentDate = DateTime(month.year, month.month, d);
    final isFuture = currentDate.isAfter(
      DateTime(now.year, now.month, now.day),
    );

    double dailyTarget = historicalDailyBurn;
    if (includedBudget > 0) {
      double remaining = includedBudget - spentSoFar;
      int left = daysInMonth - d + 1;
      dailyTarget = remaining / left;
      if (d == 1)
        dailyTarget = (dailyTarget * 0.2) + (historicalDailyBurn * 0.8);
      if (d == 2)
        dailyTarget = (dailyTarget * 0.5) + (historicalDailyBurn * 0.5);
    }
    if (dailyTarget <= 0) dailyTarget = historicalDailyBurn;

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

  // =========================================================
  // --- 5. AI MULTI-ADVICE ENGINE (ALL SCENARIOS DECOUPLED) ---
  // =========================================================
  List<HeatmapAdvice> activeAdvices = [];

  if (includedBudget > 0 && isCurrentMonth) {
    double currentBurnRate = monthTotal / daysElapsed;
    double trueRemainingBudget = (includedBudget - monthTotal) - upcomingBills;
    double projectedTotal = currentBurnRate * daysInMonth;

    // 0. Budget Blown (Critical Stop)
    if (monthTotal >= includedBudget) {
      activeAdvices.add(
        HeatmapAdvice(
          text:
              "Budget Exceeded! 🛑 Halt all non-essential spends immediately to minimize the deficit.",
          color: Colors.red.shade700,
          icon: Icons.warning_amber_rounded,
        ),
      );
    } else {
      // SCENARIO 1: Zero-Day Prediction (Runway)
      if (currentBurnRate > 0) {
        int daysRunway = ((includedBudget - monthTotal) / currentBurnRate)
            .floor();
        if (daysRunway < daysLeft) {
          DateTime zeroDate = now.add(Duration(days: daysRunway));
          String formattedDate = DateFormat('MMM do').format(zeroDate);
          double neededPace = (includedBudget - monthTotal) / daysLeft;

          activeAdvices.add(
            HeatmapAdvice(
              text:
                  "Zero-Day Warning: At your pace, you hit zero on $formattedDate. Drop your daily average to ${CurrencyFormatter.format(neededPace)} to survive.",
              color: Colors.red.shade700,
              icon: Icons.flight_land_rounded,
            ),
          );
        }
      }

      // SCENARIO 2: Upcoming Fixed Cost Shock
      if (upcomingBills > 0 &&
          trueRemainingBudget < (currentBurnRate * daysLeft)) {
        activeAdvices.add(
          HeatmapAdvice(
            text:
                "Auto-bills will claim ${CurrencyFormatter.format(upcomingBills)} soon. Your true safe balance to spend is actually only ${CurrencyFormatter.format(trueRemainingBudget)}.",
            color: Colors.orangeAccent.shade700,
            icon: Icons.receipt_long_rounded,
          ),
        );
      }

      // SCENARIO 3: Bucket Bleed Detection
      if ((daysElapsed / daysInMonth) < 0.8) {
        bucketSpends.forEach((id, spent) {
          double limit = bucketLimits[id] ?? 0.0;
          if (limit > 0) {
            double exhaustion = spent / limit;
            if (exhaustion > 0.85) {
              activeAdvices.add(
                HeatmapAdvice(
                  text:
                      "Bucket Bleed: Your '${bucketNames[id]}' bucket is ${(exhaustion * 100).toInt()}% exhausted with $daysLeft days still left.",
                  color: Colors.orangeAccent.shade700,
                  icon: Icons.water_drop_outlined,
                ),
              );
            }
          }
        });
      }

      // SCENARIO 4: Historical Anomaly Alert
      if (daysElapsed > 5 && currentBurnRate > historicalDailyBurn * 1.3) {
        activeAdvices.add(
          HeatmapAdvice(
            text:
                "Anomaly: You're spending 30%+ faster than your 60-day historical average. Tighten the belt unless planned.",
            color: Colors.orangeAccent.shade700,
            icon: Icons.insights_rounded,
          ),
        );
      }

      // SCENARIO 5: End-of-Month Surplus Sweeping
      if (daysLeft <= 5) {
        double surplus = includedBudget - projectedTotal;
        if (surplus > (includedBudget * 0.05)) {
          activeAdvices.add(
            HeatmapAdvice(
              text:
                  "Wealth Builder: You are projected to end with a ${CurrencyFormatter.format(surplus)} surplus. Consider investing or sweeping it to savings.",
              color: Colors.green.shade700,
              icon: Icons.savings_outlined,
            ),
          );
        }
      }

      // SCENARIO 6: Weekend vs. Weekday Behavioral Pacing
      double avgWeekend = weekendDaysCount > 0
          ? (weekendSpend / weekendDaysCount)
          : 0;
      double avgWeekday = weekdayDaysCount > 0
          ? (weekdaySpend / weekdayDaysCount)
          : 0;

      if (avgWeekend > (avgWeekday * 1.5) && trueRemainingBudget > 0) {
        int weekendsLeft = 0;
        int weekdaysLeft = 0;
        for (int i = 0; i < daysLeft; i++) {
          final d = now.add(Duration(days: i));
          if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
            weekendsLeft++;
          } else {
            weekdaysLeft++;
          }
        }
        double weight = weekdaysLeft + (1.5 * weekendsLeft);
        double weekdayTarget = weight > 0 ? trueRemainingBudget / weight : 0;

        activeAdvices.add(
          HeatmapAdvice(
            text:
                "Weekend Adjustment: To afford your usual weekend spikes, keep weekday spends strictly under ${CurrencyFormatter.format(weekdayTarget)}/day.",
            color: Colors.blue.shade600,
            icon: Icons.balance_rounded,
          ),
        );
      }

      // Default: Standard Pacing Baseline
      if (trueRemainingBudget > 0) {
        double recDaily = trueRemainingBudget / daysLeft;
        activeAdvices.add(
          HeatmapAdvice(
            text:
                "💡 Monthly Pacing: Keep daily spends under ${CurrencyFormatter.format(recDaily)} for the rest of the month to stay within budget.",
            color: Colors.green.shade700,
            icon: Icons.trending_up_rounded,
          ),
        );
      }
    }
  } else if (isPastMonth && includedBudget > 0) {
    if (monthTotal <= includedBudget) {
      activeAdvices.add(
        HeatmapAdvice(
          text:
              "Great job! You survived this month with ${CurrencyFormatter.format(includedBudget - monthTotal)} to spare.",
          color: Colors.green.shade700,
          icon: Icons.check_circle_outline_rounded,
        ),
      );
    } else {
      activeAdvices.add(
        HeatmapAdvice(
          text:
              "You exceeded your budget by ${CurrencyFormatter.format(monthTotal - includedBudget)} this month.",
          color: Colors.red.shade700,
          icon: Icons.warning_amber_rounded,
        ),
      );
    }
  }

  if (activeAdvices.isEmpty) {
    activeAdvices.add(
      const HeatmapAdvice(
        text: "Assign categories to budget buckets to unlock AI pacing advice.",
        color: Colors.grey,
        icon: Icons.hourglass_top_rounded,
      ),
    );
  }

  return HeatmapData(
    days: result,
    includedBudget: includedBudget,
    advices: activeAdvices,
  );
});
