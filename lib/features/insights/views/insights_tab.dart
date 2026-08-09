// features/insights/views/insights_tab.dart
import 'package:budgetr/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/design_tokens.dart';
import '../providers/insight_filter_provider.dart';
import '../providers/insight_summary_provider.dart';
import '../providers/insight_view_provider.dart';
import '../providers/insight_category_provider.dart';
import '../providers/insight_bucket_provider.dart';
import '../models/insight_category_model.dart';
import '../models/insight_bucket_model.dart';
import '../models/insight_summary_model.dart';
import '../services/insight_export_service.dart'; // <-- Ensure this is imported

import '../components/insight_filter_bar.dart';
import '../components/interactive_summary_card.dart';
import '../components/insight_account_selection_sheet.dart';
import '../components/insight_timeframe_selection_sheet.dart';
import '../components/insight_category_card.dart';
import '../components/insight_bucket_card.dart';
import '../components/insight_donut_chart.dart';
import '../components/insight_cash_flow_chart.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../accounts/providers/account_provider.dart';
import '../../transactions/services/transaction_service.dart';

class InsightsTab extends ConsumerStatefulWidget {
  const InsightsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends ConsumerState<InsightsTab> {
  bool _isExporting = false;
  String _exportMessage = "";

  // --- EXPORT SUCCESS SHEET ---
  void _showExportSuccessSheet(
    InsightExportResult result,
    Color themeColor,
    String format,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: themeColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "$format Export Successful",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "File Saved to:",
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.publicPath,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: themeColor.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(Icons.ios_share_rounded, color: themeColor),
                    label: Text(
                      "Share",
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Share.shareXFiles([
                        XFile(result.safeCachePath),
                      ], text: "Budgetr Comprehensive $format Export");
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.file_open_rounded),
                    label: const Text(
                      "Open File",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final String mimeType = format == "PDF"
                          ? "application/pdf"
                          : "text/csv";
                      final openResult = await OpenFile.open(
                        result.safeCachePath,
                        type: mimeType,
                      );
                      if (openResult.type != ResultType.done && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Cannot open directly. Please use the 'Share' button.",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Dismiss",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- EXPORT OPTIONS MENU ---
  // inside features/insights/views/insights_tab.dart

  // --- EXPORT OPTIONS MENU ---
  void _showExportOptions(
    InsightFilterState filter,
    InsightSummaryModel summary,
    List<TransactionWithDetails> allTransactions,
    List<BudgetBucket> activeBuckets, // <-- NEW
    String accountDisplayName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Export Financial Report",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Generates a comprehensive report with charts, summaries, and full ledgers.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildExportOption(
                    icon: Icons.picture_as_pdf_rounded,
                    label: "Save PDF",
                    color: const Color(0xFFE71D36),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() {
                        _isExporting = true;
                        _exportMessage = "GENERATING PRO REPORT...";
                      });
                      try {
                        final result = await InsightExportService().exportToPdf(
                          filter: filter,
                          summary: summary,
                          accountName: accountDisplayName,
                          allTransactions: allTransactions,
                          activeBuckets: activeBuckets, // <-- PASSED
                        );
                        if (mounted) {
                          setState(() => _isExporting = false);
                          _showExportSuccessSheet(
                            result,
                            const Color(0xFFE71D36),
                            "PDF",
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isExporting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Export failed: $e")),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExportOption(
                    icon: Icons.table_chart_rounded,
                    label: "Save CSV",
                    color: const Color(0xFF2EC4B6),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() {
                        _isExporting = true;
                        _exportMessage = "EXTRACTING DATA TO SPREADSHEET...";
                      });
                      try {
                        final result = await InsightExportService().exportToCsv(
                          filter: filter,
                          summary: summary,
                          accountName: accountDisplayName,
                          allTransactions: allTransactions,
                          activeBuckets: activeBuckets, // <-- PASSED
                        );
                        if (mounted) {
                          setState(() => _isExporting = false);
                          _showExportSuccessSheet(
                            result,
                            const Color(0xFF2EC4B6),
                            "CSV",
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isExporting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Export failed: $e")),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(insightFilterProvider);
    final summary = ref.watch(insightSummaryProvider);
    final isExpense = ref.watch(insightViewIsExpenseProvider);
    final isBucketView = ref.watch(insightViewIsBucketProvider);
    final categoryBreakdown = ref.watch(insightCategoryBreakdownProvider);
    final bucketBreakdown = ref.watch(insightBucketBreakdownProvider);
    final accounts = ref.watch(accountsStreamProvider).asData?.value ?? [];
    final allTransactions =
        ref.watch(allTransactionsProvider).asData?.value ?? [];
    final activeBuckets = ref.watch(bucketsStreamProvider).asData?.value ?? [];

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

    return Stack(
      children: [
        ListView(
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
                      Future.delayed(
                        const Duration(milliseconds: 150),
                        () async {
                          if (!context.mounted) return;
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            ref
                                .read(insightFilterProvider.notifier)
                                .state = filterState.copyWith(
                              timeFrame: selectedTimeframe,
                              customRange: picked,
                            );
                          }
                        },
                      );
                    } else {
                      ref.read(insightFilterProvider.notifier).state =
                          filterState.copyWith(timeFrame: selectedTimeframe);
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

            // --- UPDATED: Header Row with Export Button passing ALL data ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showExportOptions(
                        filterState,
                        summary,
                        allTransactions,
                        activeBuckets, // <-- PASS THEM HERE
                        accountDisplayName,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.ios_share_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
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
                            ref
                                    .read(insightViewIsBucketProvider.notifier)
                                    .state =
                                false;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: !isBucketView
                                  ? theme.colorScheme.primaryContainer
                                        .withOpacity(0.3)
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
                            ref
                                    .read(insightViewIsBucketProvider.notifier)
                                    .state =
                                true;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isBucketView
                                  ? theme.colorScheme.primaryContainer
                                        .withOpacity(0.3)
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
                totalAmount: isExpense
                    ? summary.totalExpense
                    : summary.totalIncome,
                data: chartData,
              ),
            ],

            InsightCashFlowChart(
              allTransactions: allTransactions,
              filterState: filterState,
            ),
          ],
        ),

        // --- FULL SCREEN LOADING OVERLAY ---
        if (_isExporting)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.cyanAccent),
                      const SizedBox(height: 32),
                      Text(
                        _exportMessage,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
