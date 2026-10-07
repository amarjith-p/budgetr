import 'dart:math';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/components/transaction_card.dart';
import '../components/budget_metrics_grid.dart';
import '../components/smart_budget_chart.dart';
import '../components/transaction_classify_sheet.dart';
import '../models/transaction_classification.dart';
import '../models/smart_projection_result.dart';
import '../providers/projection_settings_provider.dart';
import '../services/smart_projection_engine.dart';
import '../services/transaction_classification_store.dart';

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

  // Smart projection state
  Map<String, TransactionClassification> _classifications = {};
  bool _classificationsLoaded = false;
  bool _sheetOpen = false; // Guard to prevent double-open

  @override
  void initState() {
    super.initState();
    _loadClassifications();
  }

  Future<void> _loadClassifications() async {
    final stored = await TransactionClassificationStore.load(
      widget.month,
      widget.year,
    );
    if (mounted) {
      setState(() {
        _classifications = stored;
        _classificationsLoaded = true;
      });
    }
  }

  /// Opens the classify sheet for ALL transactions in the month.
  /// Uses edit mode if classifications already exist.
  Future<void> _openClassifySheet(
    BuildContext context,
    List<dynamic> allMonthExpenses, {
    bool forceEdit = false,
  }) async {
    if (_sheetOpen) return; // Prevent double-open
    final projMode = ref.read(projectionSettingsProvider);
    if (projMode != ProjectionMode.smart) return;

    final txList = allMonthExpenses
        .map((d) => (d.transaction as TransactionRecord))
        .toList();

    if (txList.isEmpty) return;

    final hasExisting = _classifications.isNotEmpty;
    _sheetOpen = true;

    final result = await TransactionClassifySheet.show(
      context,
      transactions: txList,
      month: widget.month,
      year: widget.year,
      existingClassifications: _classifications,
      isEditMode: forceEdit || hasExisting,
    );

    _sheetOpen = false;
    if (result != null && mounted) {
      setState(() => _classifications = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final projMode = ref.watch(projectionSettingsProvider);
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
          // In Smart mode: ALL transactions are included — classifications cover
          // out-of-bucket items too, so the toggle is irrelevant.
          final isSmartMode = projMode == ProjectionMode.smart;
          final displayExpenses = (isSmartMode || _showOutOfBucket)
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

          // 4. BASE PROJECTION MATH (LINEAR — unchanged)
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

          // LINEAR projection (always computed, shown when mode = linear)
          final linearProjectedSpend = isCurrentMonth
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

          // 5. SMART PROJECTION (computed when classifications are loaded)
          SmartProjectionResult? smartResult;
          if (projMode == ProjectionMode.smart &&
              _classificationsLoaded &&
              isCurrentMonth &&
              daysElapsed > 0) {
            final txRecords = allMonthExpenses
                .map((d) => d.transaction)
                .toList();
            smartResult = SmartProjectionEngine.compute(
              transactions: txRecords,
              classifications: _classifications,
              allocatedBudget: widget.effectiveIncome,
              daysInMonth: daysInMonth,
              daysElapsed: daysElapsed,
            );
          }

          // Decide which projection to display
          final activeProjection =
              (projMode == ProjectionMode.smart && smartResult != null)
              ? smartResult.smartProjection
              : linearProjectedSpend;

          final activeRecDaily =
              (projMode == ProjectionMode.smart && smartResult != null)
              ? smartResult.adjustedDailyTarget
              : recDaily;

          final activeDailyAvg =
              (projMode == ProjectionMode.smart && smartResult != null)
              ? smartResult.variableDailyAvg
              : dailyAvg;

          final isOverBudget = activeProjection > widget.effectiveIncome;

          // 6. TRIGGER CLASSIFY SHEET on first open (only if no classifications yet)
          if (projMode == ProjectionMode.smart &&
              _classificationsLoaded &&
              isCurrentMonth &&
              !_sheetOpen &&
              _classifications.isEmpty &&
              allMonthExpenses.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openClassifySheet(context, allMonthExpenses);
            });
          }

          // 7. RENDER UI
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- PROJECTION MODE BADGE ---
                      _ProjectionModeBadge(
                        mode: projMode,
                        smartResult: smartResult,
                        theme: theme,
                        isDark: isDark,
                        onReclassify: isCurrentMonth
                            ? () => _openClassifySheet(
                                context,
                                allMonthExpenses,
                                forceEdit: true,
                              )
                            : null,
                      ),

                      const SizedBox(height: DesignTokens.spacingMd),

                      // --- OUT OF BUCKET TOGGLE CARD (Linear mode only) ---
                      if (projMode == ProjectionMode.linear)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
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
                                      color: theme.colorScheme.error
                                          .withOpacity(0.1),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Out of Bucket',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '₹${outOfBucketTotal.toStringAsFixed(2)} Total',
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

                      // --- SMART MODE: out-of-bucket info note ---
                      if (projMode == ProjectionMode.smart &&
                          outOfBucketTotal > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(
                              isDark ? 0.08 : 0.05,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(
                                0.15,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '₹${outOfBucketTotal.toStringAsFixed(2)} out-of-bucket included - classify via the sheet above.',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: DesignTokens.spacingMd),

                      // --- SMART INSIGHT BANNER (only in smart mode) ---
                      if (projMode == ProjectionMode.smart &&
                          smartResult != null)
                        _SmartInsightBanner(result: smartResult, theme: theme),

                      if (projMode == ProjectionMode.smart &&
                          smartResult != null)
                        const SizedBox(height: DesignTokens.spacingMd),

                      // --- METRICS GRID ---
                      BudgetMetricsGrid(
                        totalSpend: totalSpend,
                        remainingBudget: remainingBudget,
                        allocatedAmount: widget.effectiveIncome,
                        projectedSpend: activeProjection,
                        dailyAvg: activeDailyAvg,
                        recDaily: activeRecDaily,
                      ),

                      const SizedBox(height: DesignTokens.spacingLg),

                      // --- SMART CHART CONTAINER ---
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
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
                              projectedSpend: activeProjection,
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

// ---------------------------------------------------------------------------
// Projection Mode Badge Widget
// ---------------------------------------------------------------------------
class _ProjectionModeBadge extends StatelessWidget {
  final ProjectionMode mode;
  final SmartProjectionResult? smartResult;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback? onReclassify;

  const _ProjectionModeBadge({
    required this.mode,
    required this.smartResult,
    required this.theme,
    required this.isDark,
    this.onReclassify,
  });

  @override
  Widget build(BuildContext context) {
    final isLinear = mode == ProjectionMode.linear;
    final color = isLinear
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isLinear ? Icons.show_chart_rounded : Icons.psychology_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLinear
                  ? 'Linear Projection - Simple Daily Average'
                  : 'Smart Projection - Variable Only Extrapolated',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          if (!isLinear && onReclassify != null)
            GestureDetector(
              onTap: onReclassify,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RE-CLASSIFY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Smart Insight Banner Widget
// ---------------------------------------------------------------------------
class _SmartInsightBanner extends StatelessWidget {
  final SmartProjectionResult result;
  final ThemeData theme;

  const _SmartInsightBanner({required this.result, required this.theme});

  @override
  Widget build(BuildContext context) {
    final score = result.healthScore;
    final Color scoreColor;
    final IconData scoreIcon;

    if (score >= 75) {
      scoreColor = const Color(0xFF00BFA5);
      scoreIcon = Icons.check_circle_outline_rounded;
    } else if (score >= 50) {
      scoreColor = const Color(0xFFF5A623);
      scoreIcon = Icons.info_outline_rounded;
    } else {
      scoreColor = theme.colorScheme.error;
      scoreIcon = Icons.warning_amber_rounded;
    }

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Health Score Ring
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 4,
                  backgroundColor: scoreColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: scoreColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(scoreIcon, size: 13, color: scoreColor),
                    const SizedBox(width: 4),
                    Text(
                      'BUDGET HEALTH SCORE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.insightMessage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                if (result.fixedTotal > 0 || result.oneoffTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (result.fixedTotal > 0)
                          _buildChip(
                            '🔁 Fixed ₹${_fmt(result.fixedTotal)}',
                            const Color(0xFF5B6EF5),
                          ),
                        if (result.oneoffTotal > 0)
                          _buildChip(
                            '⚡ One-off ₹${_fmt(result.oneoffTotal)}',
                            const Color(0xFFF5A623),
                          ),
                        if (result.variableTotal > 0)
                          _buildChip(
                            '🌊 Variable ₹${_fmt(result.variableTotal)}',
                            const Color(0xFF00BFA5),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static String _fmt(double val) {
    return val.toStringAsFixed(2);
  }
}
