// features/custom_budgets/views/custom_budget_transactions_page.dart

import 'dart:math';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/components/transaction_card.dart';
import '../../budgets/components/budget_metrics_grid.dart';
import '../../budgets/components/smart_budget_chart.dart';
import '../models/custom_budget_details.dart';

class CustomBudgetTransactionsPage extends ConsumerWidget {
  final CustomBudgetWithDetails data;

  const CustomBudgetTransactionsPage({Key? key, required this.data})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final budget = data.budget;
    final isSettled = budget.isSettled;

    String dateSubtitle = '';
    if (budget.timeFrame == 'Custom') {
      dateSubtitle =
          '${budget.startDate.day} ${DateTimeConstants.shortMonths[budget.startDate.month - 1]} - ${budget.endDate.day} ${DateTimeConstants.shortMonths[budget.endDate.month - 1]}';
    } else {
      dateSubtitle =
          '${budget.timeFrame.toUpperCase()} • ${budget.startDate.day} ${DateTimeConstants.shortMonths[budget.startDate.month - 1]}';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: budget.name.toUpperCase(),
        subtitle: isSettled ? 'SETTLED TARGET' : dateSubtitle,
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
          final matchedTransactions = transactions.where((txData) {
            final tx = txData.transaction;
            if (tx.type != 'Expense') return false;

            // Check dates (Respects frozen endDate if settled)
            if (tx.date.isBefore(budget.startDate) ||
                tx.date.isAfter(budget.endDate))
              return false;

            // Optional Filters
            if (budget.categoryId != null && tx.categoryId != budget.categoryId)
              return false;
            if (budget.subCategory != null &&
                tx.subCategory != budget.subCategory)
              return false;
            if (budget.bucketId != null && tx.bucketId != budget.bucketId)
              return false;
            if (budget.accountId != null && tx.accountId != budget.accountId)
              return false;

            return true;
          }).toList();

          matchedTransactions.sort(
            (a, b) => b.transaction.date.compareTo(a.transaction.date),
          );

          // 2. MATHEMATICAL PROJECTION ENGINE
          final now = DateTime.now();
          final duration =
              budget.endDate.difference(budget.startDate).inDays + 1;

          int elapsed = 0;
          if (isSettled) {
            elapsed = duration;
          } else {
            elapsed = now.isAfter(budget.endDate)
                ? duration
                : (now.isBefore(budget.startDate)
                      ? 0
                      : now.difference(budget.startDate).inDays + 1);
          }

          final remainingDays = duration - elapsed;

          double totalSpend = 0.0;
          Map<int, double> dailySpendMap = {};

          for (var txData in matchedTransactions) {
            final tx = txData.transaction;
            totalSpend += tx.amount;

            int dayIndex = tx.date.difference(budget.startDate).inDays + 1;
            if (dayIndex > 0 && dayIndex <= duration) {
              dailySpendMap[dayIndex] =
                  (dailySpendMap[dayIndex] ?? 0.0) + tx.amount;
            }
          }

          // If settled, force the totalSpend to match the frozen DB value
          // (in case historical transactions were deleted but the snapshot was locked).
          if (isSettled && budget.settledAmount != null) {
            totalSpend = budget.settledAmount!;
          }

          final remainingBudget = budget.amountLimit - totalSpend;
          final dailyAvg = elapsed > 0 ? totalSpend / elapsed : 0.0;
          final projectedSpend = isSettled ? totalSpend : (dailyAvg * duration);
          final recDaily = remainingDays > 0
              ? max(0.0, remainingBudget / remainingDays)
              : 0.0;

          List<double> cumulativeData = [];
          double runningTotal = 0.0;
          for (int i = 1; i <= elapsed; i++) {
            runningTotal += (dailySpendMap[i] ?? 0.0);
            cumulativeData.add(runningTotal);
          }

          final isOverBudget = projectedSpend > budget.amountLimit;

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
                        allocatedAmount: budget.amountLimit,
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
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOverBudget && !isSettled
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
                                  if (isOverBudget && !isSettled)
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
                              allocatedAmount: budget.amountLimit,
                              projectedSpend: projectedSpend,
                              daysInMonth: duration,
                              daysElapsed: elapsed,
                              isCurrentMonth: !isSettled,
                              theme: theme,
                              month: budget.startDate.month,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction History',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (isSettled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LOCKED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (matchedTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      isSettled
                          ? 'No transactions were logged.'
                          : 'No transactions logged yet.',
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
                      final txData = matchedTransactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.spacingSm,
                        ),
                        child: TransactionCard(
                          data: txData,
                          currentAccountId: txData.transaction.accountId,
                          isGlobalView: true,
                        ),
                      );
                    }, childCount: matchedTransactions.length),
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
