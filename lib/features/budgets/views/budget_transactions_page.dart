import 'dart:math';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/components/transaction_card.dart';

// --- IMPORT OUR NEW COMPONENTS ---
import '../components/budget_metrics_grid.dart';
import '../components/smart_budget_chart.dart';

class BudgetTransactionsPage extends ConsumerWidget {
  final BudgetBucket bucket;
  final int month;
  final int year;
  final double allocatedAmount;

  const BudgetTransactionsPage({
    Key? key,
    required this.bucket,
    required this.month,
    required this.year,
    required this.allocatedAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final theme = Theme.of(context);
    final monthString = '${DateTimeConstants.fullMonths[month - 1]} $year';
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: bucket.name.toUpperCase(),
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
          // 1. FILTER TRANSACTIONS
          final bucketTransactions = transactions.where((data) {
            final tx = data.transaction;
            return tx.type == 'Expense' &&
                tx.date.month == month &&
                tx.date.year == year &&
                tx.bucketId == bucket.id;
          }).toList();
          bucketTransactions.sort(
            (a, b) => b.transaction.date.compareTo(a.transaction.date),
          );

          // 2. MATHEMATICAL PROJECTION ENGINE
          final now = DateTime.now();
          final isCurrentMonth = now.month == month && now.year == year;
          final isPastMonth =
              year < now.year || (year == now.year && month < now.month);
          final daysInMonth = DateTime(year, month + 1, 0).day;

          final daysElapsed = isCurrentMonth
              ? now.day
              : (isPastMonth ? daysInMonth : 0);
          final remainingDays = daysInMonth - daysElapsed;

          double totalSpend = 0.0;
          Map<int, double> dailySpendMap = {};

          for (var data in bucketTransactions) {
            final tx = data.transaction;
            totalSpend += tx.amount;
            dailySpendMap[tx.date.day] =
                (dailySpendMap[tx.date.day] ?? 0.0) + tx.amount;
          }

          final remainingBudget = allocatedAmount - totalSpend;
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

          final isOverBudget = projectedSpend > allocatedAmount;

          // 3. RENDER UI
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- POM COMPONENT 1: METRICS GRID ---
                      BudgetMetricsGrid(
                        totalSpend: totalSpend,
                        remainingBudget: remainingBudget,
                        allocatedAmount: allocatedAmount,
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
                              allocatedAmount: allocatedAmount,
                              projectedSpend: projectedSpend,
                              daysInMonth: daysInMonth,
                              daysElapsed: daysElapsed,
                              isCurrentMonth: isCurrentMonth,
                              theme: theme,
                              month: month, // Passed in for the date tooltips
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

              if (bucketTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No transactions logged in this bucket.',
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
                      final data = bucketTransactions[index];
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
                    }, childCount: bucketTransactions.length),
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
