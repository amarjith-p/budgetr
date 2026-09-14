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
    return const HeatmapData(
      days: [],
      includedBudget: 0.0,
      projectedTotal: 0.0,
      advices: [],
    );
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
    return const HeatmapData(
      days: [],
      includedBudget: 0.0,
      projectedTotal: 0.0,
      advices: [],
    );
  }

  final now = DateTime.now();
  final isCurrentMonth = month.year == now.year && month.month == now.month;
  final isPastMonth =
      month.year < now.year ||
      (month.year == now.year && month.month < now.month);

  final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;

  // --- BULLETPROOF TIME CALCULATION (Down to the minute/second) ---
  double exactDaysElapsed = 1.0;
  double exactDaysLeft = 0.0;

  if (isCurrentMonth) {
    // Current day fraction: e.g. 12:00 PM = 0.5 days.
    double todayFraction =
        (now.hour / 24.0) + (now.minute / 1440.0) + (now.second / 86400.0);
    exactDaysElapsed = (now.day - 1) + todayFraction;
    if (exactDaysElapsed <= 0.001)
      exactDaysElapsed = 0.001; // Avoid division by zero at exact midnight
    exactDaysLeft = daysInMonth.toDouble() - exactDaysElapsed;
  } else if (isPastMonth) {
    exactDaysElapsed = daysInMonth.toDouble();
    exactDaysLeft = 0.0;
  } else {
    exactDaysElapsed = 0.001;
    exactDaysLeft = daysInMonth.toDouble();
  }

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

  // --- 2. CALCULATE HISTORICAL TRENDS & MONTH TOTAL ---
  final sixtyDaysAgo = now.subtract(const Duration(days: 60));
  double trailingTotalSpend = 0.0;
  double weekendSpend = 0.0;
  double weekdaySpend = 0.0;
  int weekendDaysCount = 0;
  int weekdayDaysCount = 0;

  for (int i = 0; i < 60; i++) {
    final d = now.subtract(Duration(days: i));
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)
      weekendDaysCount++;
    else
      weekdayDaysCount++;
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

  double currentBurnRate = isPastMonth
      ? (monthTotal / daysInMonth)
      : (monthTotal / exactDaysElapsed);
  double projectedTotal = currentBurnRate * daysInMonth.toDouble();

  // --- 3. BULLETPROOF UPCOMING FIXED COSTS ---
  // Loops through occurrences exactly to catch weekly/daily multiple triggers
  double upcomingBills = 0.0;
  if (isCurrentMonth) {
    final endOfMonth = DateTime(now.year, now.month, daysInMonth, 23, 59, 59);
    for (var rule in rules) {
      if (rule.isActive &&
          rule.amount != null &&
          rule.transactionType == 'Expense') {
        if (rule.bucketId == null ||
            rule.bucketId == -1 ||
            selectedBuckets.contains(rule.bucketId)) {
          DateTime pointer = rule.nextExecutionDate;
          int simulatedExecs = rule.currentExecutionCount;

          while (pointer.isBefore(endOfMonth) ||
              pointer.isAtSameMomentAs(endOfMonth)) {
            if (pointer.isAfter(now)) {
              upcomingBills += rule.amount!;
            }
            simulatedExecs++;
            if (rule.maxExecutions != null &&
                simulatedExecs >= rule.maxExecutions!)
              break;
            if (rule.endDate != null && pointer.isAfter(rule.endDate!)) break;

            pointer = ScheduleHelper.calculateNextDate(
              pointer,
              rule.repetitionSchedule,
              rule.repetitionInterval,
              rule.advancedSchedule,
            );
          }
        }
      }
    }
  }

  // --- 4. BUILD PACING AGGREGATES FOR GRID ---
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
  // --- 5. AI MULTI-ADVICE ENGINE (MINUTE-PERFECT SCENARIOS) ---
  // =========================================================
  List<HeatmapAdvice> activeAdvices = [];

  if (includedBudget > 0 && isCurrentMonth) {
    double trueRemainingBudget = (includedBudget - monthTotal) - upcomingBills;

    // SCENARIO 0: Budget Blown (Critical Stop)
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
      // SCENARIO 1: Zero-Day Prediction (Exact Minute Runway)
      if (currentBurnRate > 0) {
        double daysRunway = (includedBudget - monthTotal) / currentBurnRate;
        if (daysRunway < exactDaysLeft) {
          int minutesRunway = (daysRunway * 1440).toInt();
          DateTime zeroDate = now.add(Duration(minutes: minutesRunway));
          String formattedDate = DateFormat('MMM do, h:mm a').format(zeroDate);

          double neededPace = (includedBudget - monthTotal) / exactDaysLeft;

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
          trueRemainingBudget < (currentBurnRate * exactDaysLeft)) {
        activeAdvices.add(
          HeatmapAdvice(
            text:
                "Auto-bills will claim ${CurrencyFormatter.format(upcomingBills)} soon. Your true safe balance to spend is actually only ${CurrencyFormatter.format(trueRemainingBudget)}.",
            color: Colors.orangeAccent.shade700,
            icon: Icons.receipt_long_rounded,
          ),
        );
      }

      // SCENARIO 3: Dynamic Bucket Bleed Detection
      double expectedExhaustion = exactDaysElapsed / daysInMonth;
      bucketSpends.forEach((id, spent) {
        double limit = bucketLimits[id] ?? 0.0;
        if (limit > 0) {
          double exhaustion = spent / limit;
          // If they used 30% more than the expected pace AND it's over half empty
          if (exhaustion > expectedExhaustion * 1.3 && exhaustion > 0.5) {
            activeAdvices.add(
              HeatmapAdvice(
                text:
                    "Bucket Bleed: Your '${bucketNames[id]}' bucket is pacing dangerously fast (${(exhaustion * 100).toInt()}% exhausted).",
                color: Colors.orangeAccent.shade700,
                icon: Icons.water_drop_outlined,
              ),
            );
          }
        }
      });

      // SCENARIO 4: Historical Anomaly Alert
      if (exactDaysElapsed > 5 && currentBurnRate > historicalDailyBurn * 1.3) {
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
      if (exactDaysLeft <= 5.0) {
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

      // SCENARIO 6: Fractional Weekend vs. Weekday Behavioral Pacing
      double avgWeekend = weekendDaysCount > 0
          ? (weekendSpend / weekendDaysCount)
          : 0;
      double avgWeekday = weekdayDaysCount > 0
          ? (weekdaySpend / weekdayDaysCount)
          : 0;

      if (avgWeekend > (avgWeekday * 1.5) && trueRemainingBudget > 0) {
        // Exact fraction calculations
        double exactWeekendsLeft = 0.0;
        double exactWeekdaysLeft = 0.0;
        double todayRemainingFraction =
            1.0 - (now.hour / 24.0) - (now.minute / 1440.0);

        if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday)
          exactWeekendsLeft += todayRemainingFraction;
        else
          exactWeekdaysLeft += todayRemainingFraction;

        for (int d = now.day + 1; d <= daysInMonth; d++) {
          final temp = DateTime(now.year, now.month, d);
          if (temp.weekday == DateTime.saturday ||
              temp.weekday == DateTime.sunday)
            exactWeekendsLeft += 1.0;
          else
            exactWeekdaysLeft += 1.0;
        }

        double weight = exactWeekdaysLeft + (1.5 * exactWeekendsLeft);
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
        double recDaily = trueRemainingBudget / exactDaysLeft;
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
    projectedTotal: projectedTotal,
    advices: activeAdvices,
  );
});
