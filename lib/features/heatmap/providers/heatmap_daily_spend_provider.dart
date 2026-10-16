// lib/features/heatmap/providers/heatmap_daily_spend_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../budgets/providers/budget_provider.dart';
import '../../budgets/providers/projection_settings_provider.dart';
import '../../budgets/services/smart_projection_engine.dart';
import '../../budgets/services/transaction_classification_store.dart';
import '../../budgets/services/transaction_auto_classifier.dart';
import '../../budgets/models/transaction_classification.dart';
import '../../budgets/models/smart_projection_result.dart';
import '../../automation/providers/automation_provider.dart';
import '../models/day_spend_summary.dart';
import 'heatmap_month_provider.dart';
import 'heatmap_bucket_selection_provider.dart';

/// Async provider that loads transaction classifications for the heatmap month.
/// Automatically invalidates whenever classifications are saved or modified.
final heatmapClassificationsProvider = FutureProvider.family
    .autoDispose<Map<String, TransactionClassification>, ({int month, int year})>((ref, arg) async {
  final sub = TransactionClassificationStore.changeNotifier;
  void listener() => ref.invalidateSelf();
  sub.addListener(listener);
  ref.onDispose(() => sub.removeListener(listener));

  return TransactionClassificationStore.load(arg.month, arg.year);
});

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
  final projMode = ref.watch(projectionSettingsProvider);
  final classificationsAsync = ref.watch(
    heatmapClassificationsProvider((month: month.month, year: month.year)),
  );
  final storedClassifications = classificationsAsync.asData?.value ?? {};

  if (selectedBucketsState == null ||
      !txsAsync.hasValue ||
      !bucketsAsync.hasValue) {
    return HeatmapData(
      days: const [],
      includedBudget: 0.0,
      projectedTotal: 0.0,
      advices: const [],
      projectionMode: projMode,
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
    return HeatmapData(
      days: const [],
      includedBudget: 0.0,
      projectedTotal: 0.0,
      advices: const [],
      projectionMode: projMode,
    );
  }

  final now = DateTime.now();
  final isCurrentMonth = month.year == now.year && month.month == now.month;
  final isPastMonth =
      month.year < now.year ||
      (month.year == now.year && month.month < now.month);

  final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;

  // --- BULLETPROOF TIME CALCULATION ---
  double exactDaysElapsed = 1.0;
  double exactDaysLeft = 0.0;

  if (isCurrentMonth) {
    double todayFraction =
        (now.hour / 24.0) + (now.minute / 1440.0) + (now.second / 86400.0);
    exactDaysElapsed = (now.day - 1) + todayFraction;
    if (exactDaysElapsed <= 0.001) exactDaysElapsed = 0.001;
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

  // --- 2. CALCULATE HISTORICAL TRENDS & MONTH EXPENSES ---
  final sixtyDaysAgo = now.subtract(const Duration(days: 60));
  double trailingTotalSpend = 0.0;
  double weekendSpend = 0.0;
  double weekdaySpend = 0.0;
  int weekendDaysCount = 0;
  int weekdayDaysCount = 0;

  DateTime? oldestTxDate;

  for (int i = 0; i < 60; i++) {
    final d = now.subtract(Duration(days: i));
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      weekendDaysCount++;
    } else {
      weekdayDaysCount++;
    }
  }

  final bool isAllBucketsSelected = selectedBuckets.length == allBuckets.length;

  List<TransactionRecord> monthExpenses = [];
  double monthTotal = 0.0;

  for (var txData in txs) {
    final t = txData.transaction;
    if (t.type != 'Expense') continue;

    if (oldestTxDate == null || t.date.isBefore(oldestTxDate)) {
      oldestTxDate = t.date;
    }

    final inBucket = t.bucketId != null &&
        t.bucketId != -1 &&
        selectedBuckets.contains(t.bucketId);
    final includeInMonth = inBucket ||
        (projMode == ProjectionMode.smart && isAllBucketsSelected);

    if (t.date.year == month.year &&
        t.date.month == month.month &&
        includeInMonth) {
      monthExpenses.add(t);
      monthTotal += t.amount;
      final bId = t.bucketId;
      if (bId != null && bucketSpends.containsKey(bId)) {
        bucketSpends[bId] = (bucketSpends[bId] ?? 0.0) + t.amount;
      }
    }

    if (t.date.isAfter(sixtyDaysAgo) && inBucket) {
      trailingTotalSpend += t.amount;
      if (t.date.weekday == DateTime.saturday ||
          t.date.weekday == DateTime.sunday) {
        weekendSpend += t.amount;
      } else {
        weekdaySpend += t.amount;
      }
    }
  }

  double historicalDays = 60.0;
  if (oldestTxDate != null) {
    double activeDays = now.difference(oldestTxDate).inHours / 24.0;
    if (activeDays > 0 && activeDays < 60.0) {
      historicalDays = activeDays;
    }
  }
  if (historicalDays < 1.0) historicalDays = 1.0;

  double historicalDailyBurn = trailingTotalSpend / historicalDays;
  if (historicalDailyBurn <= 0) historicalDailyBurn = 500.0;

  double currentBurnRate = isPastMonth
      ? (monthTotal / daysInMonth)
      : (monthTotal / exactDaysElapsed);
  double linearProjectedTotal = currentBurnRate * daysInMonth.toDouble();

  // --- CLASSIFICATION RESOLUTION (Stored + Heuristic Fallback) ---
  final activeClassifications = <String, TransactionClassification>{};
  int unclassifiedCount = 0;

  for (final tx in monthExpenses) {
    if (storedClassifications.containsKey(tx.id)) {
      activeClassifications[tx.id] = storedClassifications[tx.id]!;
    } else {
      final guess = TransactionAutoClassifier.classify(
        tx,
        dailyBudget: historicalDailyBurn,
      );
      activeClassifications[tx.id] = guess.classification;
      unclassifiedCount++;
    }
  }

  // --- SMART PROJECTION CALCULATION ---
  final int intDaysElapsed = isPastMonth
      ? daysInMonth
      : (isCurrentMonth ? now.day : 0);

  SmartProjectionResult? smartResult;
  if (projMode == ProjectionMode.smart &&
      isCurrentMonth &&
      intDaysElapsed > 0 &&
      monthExpenses.isNotEmpty) {
    smartResult = SmartProjectionEngine.compute(
      transactions: monthExpenses,
      classifications: activeClassifications,
      allocatedBudget: includedBudget,
      daysInMonth: daysInMonth,
      daysElapsed: intDaysElapsed,
    );
  }

  final double projectedTotal =
      (projMode == ProjectionMode.smart && smartResult != null)
          ? smartResult.smartProjection
          : linearProjectedTotal;

  final double? smartDailyTarget =
      (projMode == ProjectionMode.smart && smartResult != null)
          ? smartResult.adjustedDailyTarget
          : null;

  // --- UPCOMING FIXED COSTS FROM AUTOMATION RULES ---
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
                simulatedExecs >= rule.maxExecutions!) {
              break;
            }
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

    double todayTotalSpend = 0.0;
    double todayVariableSpend = 0.0;
    double todayFixedSpend = 0.0;
    double todayOneoffSpend = 0.0;

    for (var tx in monthExpenses) {
      if (tx.date.year == currentDate.year &&
          tx.date.month == currentDate.month &&
          tx.date.day == currentDate.day) {
        todayTotalSpend += tx.amount;
        if (projMode == ProjectionMode.smart) {
          final clf = activeClassifications[tx.id] ??
              TransactionClassification.variable;
          switch (clf) {
            case TransactionClassification.fixed:
              todayFixedSpend += tx.amount;
              break;
            case TransactionClassification.oneoff:
              todayOneoffSpend += tx.amount;
              break;
            case TransactionClassification.variable:
              todayVariableSpend += tx.amount;
              break;
          }
        }
      }
    }

    double dailyTarget;
    HeatmapColorLevel level;

    if (projMode == ProjectionMode.smart && smartDailyTarget != null) {
      dailyTarget = smartDailyTarget + todayFixedSpend + todayOneoffSpend;
      if (dailyTarget <= 0) dailyTarget = historicalDailyBurn;

      if (isFuture) {
        level = HeatmapColorLevel.future;
      } else if (todayTotalSpend == 0.0) {
        level = HeatmapColorLevel.noData;
      } else if (todayVariableSpend <= smartDailyTarget) {
        level = HeatmapColorLevel.green;
      } else if (todayVariableSpend <= 1.5 * smartDailyTarget) {
        level = HeatmapColorLevel.orange;
      } else {
        level = HeatmapColorLevel.red;
      }
    } else {
      dailyTarget = historicalDailyBurn;
      if (includedBudget > 0) {
        double remaining = includedBudget - spentSoFar;
        int left = daysInMonth - d + 1;
        dailyTarget = remaining / left;
        if (d == 1) {
          dailyTarget = (dailyTarget * 0.2) + (historicalDailyBurn * 0.8);
        }
        if (d == 2) {
          dailyTarget = (dailyTarget * 0.5) + (historicalDailyBurn * 0.5);
        }
      }
      if (dailyTarget <= 0) dailyTarget = historicalDailyBurn;

      if (isFuture) {
        level = HeatmapColorLevel.future;
      } else if (todayTotalSpend == 0.0) {
        level = HeatmapColorLevel.noData;
      } else if (todayTotalSpend <= dailyTarget) {
        level = HeatmapColorLevel.green;
      } else if (todayTotalSpend <= 1.5 * dailyTarget) {
        level = HeatmapColorLevel.orange;
      } else {
        level = HeatmapColorLevel.red;
      }
    }

    result.add(
      DaySpendSummary(
        date: currentDate,
        totalSpend: todayTotalSpend,
        dailyTarget: dailyTarget,
        level: level,
        variableSpend: todayVariableSpend,
        fixedSpend: todayFixedSpend,
        oneoffSpend: todayOneoffSpend,
      ),
    );
    spentSoFar += todayTotalSpend;
  }

  // --- 5. AI MULTI-ADVICE ENGINE (PROJECTION-MODE AWARE) ---
  List<HeatmapAdvice> activeAdvices = [];
  final bool isSmart = projMode == ProjectionMode.smart && smartResult != null;

  if (includedBudget > 0 && isCurrentMonth) {
    final double trueRemainingBudget =
        includedBudget - monthTotal - upcomingBills;

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
      // PRIMARY SMART INSIGHT: Health Score & Insight from Smart Engine
      if (isSmart && unclassifiedCount == 0) {
        final score = smartResult.healthScore;
        final Color scoreColor = score >= 75
            ? const Color(0xFF00BFA5)
            : (score >= 50 ? const Color(0xFFF5A623) : Colors.red.shade700);

        activeAdvices.add(
          HeatmapAdvice(
            text: "Health Score $score/100: ${smartResult.insightMessage}",
            color: scoreColor,
            icon: Icons.psychology_rounded,
          ),
        );
      }

      // SCENARIO 1: Zero-Day Prediction (Exact Minute Runway)
      if (isSmart) {
        if (smartResult.smartProjection > includedBudget &&
            smartResult.variableDailyAvg > 0) {
          final double controllableRemaining = includedBudget -
              smartResult.fixedTotal -
              smartResult.oneoffTotal -
              smartResult.variableTotal;

          if (controllableRemaining > 0) {
            final double daysRunway =
                controllableRemaining / smartResult.variableDailyAvg;
            if (daysRunway < exactDaysLeft) {
              final int minutesRunway = (daysRunway * 1440).toInt();
              final DateTime zeroDate =
                  now.add(Duration(minutes: minutesRunway));
              final String formattedDate =
                  DateFormat('MMM dd, h:mm a').format(zeroDate);
              final double neededPace = smartResult.adjustedDailyTarget;

              activeAdvices.add(
                HeatmapAdvice(
                  text:
                      "Zero-Day Warning: At your variable pace, you hit zero on $formattedDate. Drop your daily variable spend to ${CurrencyFormatter.format(neededPace)} to stay in budget.",
                  color: Colors.red.shade700,
                  icon: Icons.flight_land_rounded,
                ),
              );
            }
          }
        }
      } else {
        if (currentBurnRate > 0) {
          final double daysRunway =
              (includedBudget - monthTotal) / currentBurnRate;
          if (daysRunway < exactDaysLeft) {
            final int minutesRunway = (daysRunway * 1440).toInt();
            final DateTime zeroDate =
                now.add(Duration(minutes: minutesRunway));
            final String formattedDate =
                DateFormat('MMM dd, h:mm a').format(zeroDate);
            final double neededPace =
                (includedBudget - monthTotal) / exactDaysLeft;

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
      }

      // SCENARIO 2: Upcoming Fixed Cost Shock
      final double burnPace =
          isSmart ? smartResult.variableDailyAvg : currentBurnRate;
      if (upcomingBills > 0 &&
          trueRemainingBudget < (burnPace * exactDaysLeft)) {
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
      final double expectedExhaustion = exactDaysElapsed / daysInMonth;
      bucketSpends.forEach((id, spent) {
        final double limit = bucketLimits[id] ?? 0.0;
        if (limit > 0) {
          final double exhaustion = spent / limit;
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

      // SCENARIO 4: Dynamic Historical Anomaly Alert
      final double comparisonBurn =
          isSmart ? smartResult.variableDailyAvg : currentBurnRate;
      if (exactDaysElapsed > 5 && comparisonBurn > historicalDailyBurn * 1.3) {
        final int excessPercentage =
            (((comparisonBurn / historicalDailyBurn) - 1.0) * 100).toInt();

        activeAdvices.add(
          HeatmapAdvice(
            text:
                "Anomaly: You're spending ${isSmart ? 'variable funds ' : ''}$excessPercentage% faster than your historical average. Tighten the belt unless planned.",
            color: Colors.orangeAccent.shade700,
            icon: Icons.insights_rounded,
          ),
        );
      }

      // SCENARIO 5: End-of-Month Surplus Sweeping
      if (exactDaysLeft <= 5.0) {
        final double surplus = includedBudget - projectedTotal;
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
      double avgWeekend =
          weekendDaysCount > 0 ? (weekendSpend / weekendDaysCount) : 0;
      double avgWeekday =
          weekdayDaysCount > 0 ? (weekdaySpend / weekdayDaysCount) : 0;

      if (avgWeekend > (avgWeekday * 1.5) && trueRemainingBudget > 0) {
        double exactWeekendsLeft = 0.0;
        double exactWeekdaysLeft = 0.0;
        double todayRemainingFraction =
            1.0 - (now.hour / 24.0) - (now.minute / 1440.0);

        if (now.weekday == DateTime.saturday ||
            now.weekday == DateTime.sunday) {
          exactWeekendsLeft += todayRemainingFraction;
        } else {
          exactWeekdaysLeft += todayRemainingFraction;
        }

        for (int d = now.day + 1; d <= daysInMonth; d++) {
          final temp = DateTime(now.year, now.month, d);
          if (temp.weekday == DateTime.saturday ||
              temp.weekday == DateTime.sunday) {
            exactWeekendsLeft += 1.0;
          } else {
            exactWeekdaysLeft += 1.0;
          }
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

      // SCENARIO 7: Monthly Pacing
      if (trueRemainingBudget > 0) {
        final double recDaily = isSmart
            ? (smartDailyTarget ?? (trueRemainingBudget / exactDaysLeft))
            : trueRemainingBudget / exactDaysLeft;

        activeAdvices.add(
          HeatmapAdvice(
            text:
                "💡 Monthly Pacing: Keep daily ${isSmart ? 'variable ' : ''}spends under ${CurrencyFormatter.format(recDaily)} for the rest of the month to stay within budget.",
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
    smartResult: smartResult,
    unclassifiedCount: unclassifiedCount,
    projectionMode: projMode,
  );
});
