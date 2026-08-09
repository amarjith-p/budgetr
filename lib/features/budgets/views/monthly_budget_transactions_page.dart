import 'dart:math';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/components/transaction_card.dart';
import '../components/budget_metrics_grid.dart';
import '../components/smart_budget_chart.dart';

class MonthlyBudgetTransactionsPage extends ConsumerStatefulWidget {
  final int month;
  final int year;
  final double effectiveIncome;

  const MonthlyBudgetTransactionsPage({
    Key? key,
    required this.month,
    required this.year,
    required this.effectiveIncome,
  }) : super(key: key);

  @override
  ConsumerState<MonthlyBudgetTransactionsPage> createState() =>
      _MonthlyBudgetTransactionsPageState();
}

class _MonthlyBudgetTransactionsPageState
    extends ConsumerState<MonthlyBudgetTransactionsPage> {
  bool _showOutOfBucket = true;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final theme = Theme.of(context);
    final monthString =
        '${DateTimeConstants.fullMonths[widget.month - 1]} ${widget.year}';
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: 'MONTH OVERVIEW',
        subtitle: monthString.toUpperCase(),
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(
          child: FuturisticLoader(size: 80, label: "LOADING TRANSACTIONS.."),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          // 1. GET ALL MONTH EXPENSES
          final allMonthExpenses = transactions.where((data) {
            final tx = data.transaction;
            return tx.type == 'Expense' &&
                tx.date.month == widget.month &&
                tx.date.year == widget.year;
          }).toList();

          // 2. ISOLATE OUT OF BUCKET TOTAL
          double outOfBucketTotal = 0.0;
          for (var data in allMonthExpenses) {
            if (data.transaction.bucketId == null ||
                data.transaction.bucketId == -1) {
              outOfBucketTotal += data.transaction.amount;
            }
          }

          // 3. APPLY TOGGLE FILTER
          final displayExpenses = _showOutOfBucket
              ? allMonthExpenses
              : allMonthExpenses
                    .where(
                      (data) =>
                          data.transaction.bucketId != null &&
                          data.transaction.bucketId != -1,
                    )
                    .toList();

          displayExpenses.sort(
            (a, b) => b.transaction.date.compareTo(a.transaction.date),
          );

          // 4. MATHEMATICAL PROJECTION ENGINE
          final now = DateTime.now();
          final isCurrentMonth =
              now.month == widget.month && now.year == widget.year;
          final isPastMonth =
              widget.year < now.year ||
              (widget.year == now.year && widget.month < now.month);
          final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;

          final daysElapsed = isCurrentMonth
              ? now.day
              : (isPastMonth ? daysInMonth : 0);
          final remainingDays = daysInMonth - daysElapsed;

          double totalSpend = 0.0;
          Map<int, double> dailySpendMap = {};

          for (var data in displayExpenses) {
            final tx = data.transaction;
            totalSpend += tx.amount;
            dailySpendMap[tx.date.day] =
                (dailySpendMap[tx.date.day] ?? 0.0) + tx.amount;
          }

          final remainingBudget = widget.effectiveIncome - totalSpend;
          final dailyAvg = daysElapsed > 0 ? totalSpend / daysElapsed : 0.0;
          final projectedSpend = isCurrentMonth
              ? (dailyAvg * daysInMonth)
              : totalSpend;
          final recDaily = remainingDays > 0
              ? max(0.0, remainingBudget / remainingDays)
              : 0.0;

          List<double> cumulativeData = [];
          double runningTotal = 0.0;
          for (int i = 1; i <= daysElapsed; i++) {
            runningTotal += (dailySpendMap[i] ?? 0.0);
            cumulativeData.add(runningTotal);
          }

          final isOverBudget = projectedSpend > widget.effectiveIncome;

          // 5. RENDER UI
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- OUT OF BUCKET TOGGLE CARD ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.blur_circular_rounded,
                                    color: theme.colorScheme.error,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Out of Bucket',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '₹${outOfBucketTotal.toStringAsFixed(0)} Total',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: _showOutOfBucket,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) =>
                                  setState(() => _showOutOfBucket = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: DesignTokens.spacingLg),

                      // --- POM COMPONENT 1: METRICS GRID ---
                      BudgetMetricsGrid(
                        totalSpend: totalSpend,
                        remainingBudget: remainingBudget,
                        allocatedAmount: widget.effectiveIncome,
                        projectedSpend: projectedSpend,
                        dailyAvg: dailyAvg,
                        recDaily: recDaily,
                      ),

                      const SizedBox(height: DesignTokens.spacingLg),

                      // --- POM COMPONENT 2: SMART CHART CONTAINER ---
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOverBudget && isCurrentMonth
                                ? theme.colorScheme.error.withOpacity(0.5)
                                : theme.dividerColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SPENDING TREND',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isOverBudget && isCurrentMonth)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning_rounded,
                                          color: theme.colorScheme.error,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'OVER BUDGET',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            SmartBudgetChart(
                              cumulativeData: cumulativeData,
                              allocatedAmount: widget.effectiveIncome,
                              projectedSpend: projectedSpend,
                              daysInMonth: daysInMonth,
                              daysElapsed: daysElapsed,
                              isCurrentMonth: isCurrentMonth,
                              theme: theme,
                              month: widget.month,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        'Transaction History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (displayExpenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No transactions logged yet.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingLg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final data = displayExpenses[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.spacingSm,
                        ),
                        child: TransactionCard(
                          data: data,
                          currentAccountId: data.transaction.accountId,
                          isGlobalView: true,
                        ),
                      );
                    }, childCount: displayExpenses.length),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}
