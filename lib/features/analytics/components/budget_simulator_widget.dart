import 'dart:convert';
import 'dart:math';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/providers/transaction_provider.dart';

import '../../budgets/components/budget_metrics_grid.dart';
import '../../budgets/components/smart_budget_chart.dart';

// --- LOCAL PROVIDER: Fetches the specific month's budget snapshot ---
final _simulatorBudgetProvider = StreamProvider.family
    .autoDispose<MonthlyBudget?, DateTime>((ref, date) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.monthlyBudgets)..where(
            (t) => t.month.equals(date.month) & t.year.equals(date.year),
          ))
          .watchSingleOrNull();
    });

class BudgetSimulatorWidget extends ConsumerStatefulWidget {
  const BudgetSimulatorWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<BudgetSimulatorWidget> createState() =>
      _BudgetSimulatorWidgetState();
}

class _BudgetSimulatorWidgetState extends ConsumerState<BudgetSimulatorWidget> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<int> _selectedBucketIds = {};

  // --- MODERN MONTH/YEAR PICKER DIALOG ---
  Future<void> _pickMonthYear() async {
    HapticFeedback.selectionClick();
    DateTime tempDate = _selectedMonth;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Dialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setDialogState(
                              () => tempDate = DateTime(
                                tempDate.year - 1,
                                tempDate.month,
                              ),
                            );
                          },
                        ),
                        Text(
                          '${tempDate.year}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setDialogState(
                              () => tempDate = DateTime(
                                tempDate.year + 1,
                                tempDate.month,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(12, (index) {
                        final m = index + 1;
                        final isSelected =
                            tempDate.year == _selectedMonth.year &&
                            m == _selectedMonth.month;

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx, DateTime(tempDate.year, m));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(isDark ? 0.3 : 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                DateTimeConstants.shortMonths[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
        _selectedBucketIds.clear();
      });
    }
  }

  // --- NEW: RESET PILL ---
  Widget _buildResetPill(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedBucketIds.clear());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restart_alt_rounded,
              size: 14,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Reset',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODERN BOXY BUCKET PILL ---
  Widget _buildBucketPill(dynamic b, ThemeData theme, bool isDark) {
    final id = b['id'] as int;
    final name = b['name'] as String;
    final pct = b['percentage'] as double;
    final isSelected = _selectedBucketIds.contains(id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isSelected) {
            _selectedBucketIds.remove(id);
          } else {
            _selectedBucketIds.add(id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withOpacity(
                  isDark ? 0.3 : 0.5,
                ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (pct > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withOpacity(0.8)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final budgetAsync = ref.watch(_simulatorBudgetProvider(_selectedMonth));
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER & MONTH SELECTOR ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.memory_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BUDGET SIMULATOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _pickMonthYear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateTimeConstants.shortMonths[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- HORIZONTALLY SCROLLABLE BUCKET PILLS ---
          budgetAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: FuturisticLoader(size: 80, label: "LOADING.."),
              ),
            ),
            error: (_, __) => const Text('Error loading budget data.'),
            data: (budget) {
              if (budget == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No budget allocated for this month.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              List<dynamic> availableBuckets = [];
              if (budget.bucketsSnapshot != null) {
                try {
                  availableBuckets = jsonDecode(budget.bucketsSnapshot!);
                } catch (_) {}
              }

              // --- INJECT "OUT OF BUCKET" OPTION ---
              availableBuckets.add({
                'id': -1,
                'name': 'Out of Bucket',
                'percentage': 0.0,
              });

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // --- DYNAMIC RESET PILL ---
                    if (_selectedBucketIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildResetPill(theme),
                      ),
                    ...availableBuckets
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildBucketPill(b, theme, isDark),
                          ),
                        )
                        .toList(),
                  ],
                ),
              );
            },
          ),

          // --- ENGINE CALCULATIONS & RENDER (EXPANDS ON SELECTION) ---
          if (_selectedBucketIds.isNotEmpty) ...[
            const SizedBox(height: 24),

            budgetAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: FuturisticLoader(size: 80, label: "LOADING.."),
                ),
              ),
              error: (e, st) => SizedBox(
                height: 200,
                child: Center(child: Text('Error: $e')),
              ),
              data: (budget) {
                if (budget == null) return const SizedBox.shrink();

                // 1. Calculate Combined Allocation Limits
                List<dynamic> allBuckets = jsonDecode(
                  budget.bucketsSnapshot ?? '[]',
                );
                double combinedPercentage = 0;
                for (var b in allBuckets) {
                  if (_selectedBucketIds.contains(b['id'])) {
                    combinedPercentage += b['percentage'];
                  }
                }

                final effectiveIncome =
                    budget.salaryIncome +
                    budget.extraIncome -
                    budget.deductions;
                final allocatedAmount =
                    (effectiveIncome * combinedPercentage) / 100;

                return transactionsAsync.when(
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(
                      child: FuturisticLoader(size: 80, label: "LOADING.."),
                    ),
                  ),
                  error: (e, st) => SizedBox(
                    height: 200,
                    child: Center(child: Text('Error: $e')),
                  ),
                  data: (transactions) {
                    // 2. Filter Transactions for Selected Cluster
                    final matchedTransactions = transactions.where((txData) {
                      final tx = txData.transaction;
                      if (tx.type != 'Expense') return false;
                      if (tx.id.startsWith('LOAN_TX_')) return false;

                      if (tx.date.year != _selectedMonth.year ||
                          tx.date.month != _selectedMonth.month)
                        return false;

                      // Check if transaction belongs to selected buckets (including Out of Bucket logic)
                      final isOutOfBucket =
                          tx.bucketId == null || tx.bucketId == -1;
                      bool belongsToSelection = false;
                      if (isOutOfBucket && _selectedBucketIds.contains(-1)) {
                        belongsToSelection = true;
                      } else if (tx.bucketId != null &&
                          _selectedBucketIds.contains(tx.bucketId)) {
                        belongsToSelection = true;
                      }

                      if (!belongsToSelection) return false;

                      return true;
                    }).toList();
                    matchedTransactions.sort(
                      (a, b) =>
                          a.transaction.date.compareTo(b.transaction.date),
                    );

                    // 3. Time & Mathematical Projection Engine
                    final now = DateTime.now();
                    final isCurrentMonth =
                        now.year == _selectedMonth.year &&
                        now.month == _selectedMonth.month;
                    final daysInMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      0,
                    ).day;

                    int daysElapsed = 0;
                    if (budget.isClosed) {
                      daysElapsed = daysInMonth;
                    } else if (isCurrentMonth) {
                      daysElapsed = now.day;
                    } else if (now.isAfter(
                      DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month,
                        daysInMonth,
                        23,
                        59,
                        59,
                      ),
                    )) {
                      daysElapsed = daysInMonth;
                    }

                    final remainingDays = daysInMonth - daysElapsed;
                    double totalSpend = 0.0;
                    Map<int, double> dailySpendMap = {};

                    for (var txData in matchedTransactions) {
                      final tx = txData.transaction;
                      totalSpend += tx.amount;
                      dailySpendMap[tx.date.day] =
                          (dailySpendMap[tx.date.day] ?? 0.0) + tx.amount;
                    }

                    final remainingBudget = allocatedAmount - totalSpend;
                    final dailyAvg = daysElapsed > 0
                        ? totalSpend / daysElapsed
                        : 0.0;
                    final projectedSpend = budget.isClosed
                        ? totalSpend
                        : (dailyAvg * daysInMonth);
                    final recDaily = remainingDays > 0
                        ? max(0.0, remainingBudget / remainingDays)
                        : 0.0;

                    List<double> cumulativeData = [];
                    double runningTotal = 0.0;
                    for (int i = 1; i <= daysElapsed; i++) {
                      runningTotal += (dailySpendMap[i] ?? 0.0);
                      cumulativeData.add(runningTotal);
                    }

                    return Column(
                      children: [
                        // --- REUSE BUDGET METRICS GRID ---
                        BudgetMetricsGrid(
                          totalSpend: totalSpend,
                          remainingBudget: remainingBudget,
                          allocatedAmount: allocatedAmount,
                          projectedSpend: projectedSpend,
                          dailyAvg: dailyAvg,
                          recDaily: recDaily,
                        ),

                        const SizedBox(height: 24),

                        // --- REUSE SMART BUDGET CHART ---
                        Container(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(isDark ? 0.3 : 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: SmartBudgetChart(
                            cumulativeData: cumulativeData,
                            allocatedAmount: allocatedAmount,
                            projectedSpend: projectedSpend,
                            daysInMonth: daysInMonth,
                            daysElapsed: daysElapsed,
                            isCurrentMonth: isCurrentMonth && !budget.isClosed,
                            theme: theme,
                            month: _selectedMonth.month,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
