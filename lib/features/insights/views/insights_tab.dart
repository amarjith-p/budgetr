// features/insights/views/insights_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/insight_filter_provider.dart';
import '../providers/insight_summary_provider.dart';
import '../providers/insight_view_provider.dart';
import '../providers/insight_category_provider.dart';
import '../providers/insight_bucket_provider.dart';
import '../models/insight_category_model.dart';
import '../models/insight_bucket_model.dart';
import '../components/insight_filter_bar.dart';
import '../components/interactive_summary_card.dart';
import '../components/insight_account_selection_sheet.dart';
import '../components/insight_timeframe_selection_sheet.dart';
import '../components/insight_category_card.dart';
import '../components/insight_bucket_card.dart';
import '../components/insight_donut_chart.dart';
import '../components/insight_cash_flow_chart.dart'; // <-- IMPORT CHART
import '../../transactions/providers/transaction_provider.dart';
import '../../accounts/providers/account_provider.dart';

class InsightsTab extends ConsumerWidget {
  const InsightsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filterState = ref.watch(insightFilterProvider);
    final summary = ref.watch(insightSummaryProvider);
    final isExpense = ref.watch(insightViewIsExpenseProvider);
    final isBucketView = ref.watch(insightViewIsBucketProvider);

    final categoryBreakdown = ref.watch(insightCategoryBreakdownProvider);
    final bucketBreakdown = ref.watch(insightBucketBreakdownProvider);
    final accounts = ref.watch(accountsStreamProvider).asData?.value ?? [];

    final allTransactions =
        ref.watch(allTransactionsProvider).asData?.value ?? [];

    String accountDisplayName = 'All Accounts';
    if (filterState.accountId == 'ASSETS') {
      accountDisplayName = 'Assets Only';
    } else if (filterState.accountId == 'CREDIT') {
      accountDisplayName = 'Liabilities Only';
    } else if (filterState.accountId != null) {
      final acc = accounts
          .where((a) => a.id == filterState.accountId)
          .firstOrNull;
      if (acc != null) accountDisplayName = acc.name;
    }

    final List<dynamic> activeBreakdown = (isExpense && isBucketView)
        ? bucketBreakdown
        : categoryBreakdown;
    final List<ChartDataItem> chartData = [];
    double othersTotal = 0;

    for (int i = 0; i < activeBreakdown.length; i++) {
      final item = activeBreakdown[i];
      String name = '';
      double amount = 0.0;

      if (item is InsightBucketModel) {
        name = item.name;
        amount = item.totalAmount;
      } else if (item is InsightCategoryModel) {
        name = item.name;
        amount = item.totalAmount;
      }

      if (i < 10) {
        chartData.add(
          ChartDataItem(
            label: name,
            amount: amount,
            color:
                InsightDonutChart.palette[i % InsightDonutChart.palette.length],
          ),
        );
      } else {
        othersTotal += amount;
      }
    }

    if (othersTotal > 0) {
      chartData.add(
        ChartDataItem(
          label: 'Others',
          amount: othersTotal,
          color: Colors.grey.shade600,
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: DesignTokens.spacingLg,
        bottom: 120,
      ),
      children: [
        InsightFilterBar(
          filterState: filterState,
          accountDisplayName: accountDisplayName,
          onAccountTap: () {
            InsightAccountSelectionSheet.show(
              context,
              accounts,
              filterState.accountId,
              (selectedId) {
                ref.read(insightFilterProvider.notifier).state = filterState
                    .copyWith(
                      accountId: selectedId,
                      clearAccount: selectedId == null,
                    );
              },
            );
          },
          onTimeframeTap: () {
            InsightTimeframeSelectionSheet.show(
              context,
              filterState.timeFrame,
              (selectedTimeframe) {
                if (selectedTimeframe == 'Custom Range') {
                  Future.delayed(const Duration(milliseconds: 150), () async {
                    if (!context.mounted) return;
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      ref
                          .read(insightFilterProvider.notifier)
                          .state = filterState.copyWith(
                        timeFrame: selectedTimeframe,
                        customRange: picked,
                      );
                    }
                  });
                } else {
                  ref.read(insightFilterProvider.notifier).state = filterState
                      .copyWith(timeFrame: selectedTimeframe);
                }
              },
            );
          },
          onResetTap: () {
            ref.read(insightFilterProvider.notifier).state =
                InsightFilterState();
          },
        ),

        const SizedBox(height: DesignTokens.spacingLg),

        InteractiveSummaryCard(
          summary: summary,
          isExpenseActive: isExpense,
          onIncomeTap: () {
            ref.read(insightViewIsExpenseProvider.notifier).state = false;
          },
          onExpenseTap: () {
            ref.read(insightViewIsExpenseProvider.notifier).state = true;
          },
        ),

        const SizedBox(height: DesignTokens.spacingXl),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isExpense ? 'EXPENSE BREAKDOWN' : 'INCOME SOURCES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isExpense)
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(insightViewIsBucketProvider.notifier).state =
                            false;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: !isBucketView
                              ? theme.colorScheme.primaryContainer.withOpacity(
                                  isDark ? 0.3 : 0.5,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Category",
                          style: TextStyle(
                            color: !isBucketView
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: !isBucketView
                                ? FontWeight.w900
                                : FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(insightViewIsBucketProvider.notifier).state =
                            true;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isBucketView
                              ? theme.colorScheme.primaryContainer.withOpacity(
                                  isDark ? 0.3 : 0.5,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Bucket",
                          style: TextStyle(
                            color: isBucketView
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isBucketView
                                ? FontWeight.w900
                                : FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingMd),

        if (isExpense && isBucketView) ...[
          if (bucketBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text(
                  'No bucket records found.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ...bucketBreakdown
                .map(
                  (bucket) => InsightBucketCard(
                    bucket: bucket,
                    activeTimeframe: filterState.timeFrame,
                  ),
                )
                .toList(),
        ] else ...[
          if (categoryBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text(
                  'No category records found.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ...categoryBreakdown
                .map(
                  (cat) => InsightCategoryCard(
                    category: cat,
                    isExpense: isExpense,
                    activeTimeframe: filterState.timeFrame,
                  ),
                )
                .toList(),
        ],

        if (chartData.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spacingXl),
          Text(
            isExpense ? 'TOP 10 EXPENSES' : 'TOP 10 INCOME SOURCES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          InsightDonutChart(
            isExpense: isExpense,
            totalAmount: isExpense ? summary.totalExpense : summary.totalIncome,
            data: chartData,
          ),
        ],

        // --- PLACED THE CASH FLOW CHART AT THE BOTTOM ---
        InsightCashFlowChart(
          allTransactions: allTransactions,
          filterState: filterState,
        ),
      ],
    );
  }
}
