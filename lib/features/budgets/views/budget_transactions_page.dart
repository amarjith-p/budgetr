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
import '../../transactions/services/transaction_service.dart';

import '../components/budget_metrics_grid.dart';
import '../components/smart_budget_chart.dart';
import '../components/transaction_classify_sheet.dart';
import '../models/transaction_classification.dart';
import '../models/smart_projection_result.dart';
import '../providers/projection_settings_provider.dart';
import '../services/smart_projection_engine.dart';
import '../services/transaction_classification_store.dart';

class BudgetTransactionsPage extends ConsumerStatefulWidget {
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
  ConsumerState<BudgetTransactionsPage> createState() =>
      _BudgetTransactionsPageState();
}

class _BudgetTransactionsPageState
    extends ConsumerState<BudgetTransactionsPage> {
  // Smart projection state
  Map<String, TransactionClassification> _classifications = {};
  bool _classificationsLoaded = false;
  bool _sheetOpen = false;

  // Bucket-scoped store key includes bucket id to separate from monthly store
  int get _month => widget.month;
  int get _year => widget.year;
  // We reuse the same month/year store but bucket transactions are a subset —
  // the engine only receives bucket transactions so projections are isolated.

  @override
  void initState() {
    super.initState();
    _loadClassifications();
  }

  Future<void> _loadClassifications() async {
    final stored = await TransactionClassificationStore.load(_month, _year);
    if (mounted) {
      setState(() {
        _classifications = stored;
        _classificationsLoaded = true;
      });
    }
  }

  Future<void> _openClassifySheet(
    BuildContext context,
    List<TransactionWithDetails> bucketExpenses, {
    bool forceEdit = false,
    Set<String> newTxIds = const {},
  }) async {
    if (_sheetOpen) return;
    final projMode = ref.read(projectionSettingsProvider);
    if (projMode != ProjectionMode.smart) return;

    final txList = bucketExpenses.map((d) => d.transaction).toList();
    if (txList.isEmpty) return;

    final hasExisting = _classifications.isNotEmpty;
    _sheetOpen = true;

    final result = await TransactionClassifySheet.show(
      context,
      transactions: txList,
      month: _month,
      year: _year,
      existingClassifications: _classifications,
      isEditMode: forceEdit || hasExisting,
      newTxIds: newTxIds,
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
    final monthString = '${DateTimeConstants.fullMonths[_month - 1]} $_year';
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: widget.bucket.name.toUpperCase(),
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
          // 1. FILTER TO THIS BUCKET
          final bucketTransactions = transactions.where((data) {
            final tx = data.transaction;
            return tx.type == 'Expense' &&
                tx.date.month == _month &&
                tx.date.year == _year &&
                tx.bucketId == widget.bucket.id;
          }).toList();

          bucketTransactions.sort(
            (a, b) => b.transaction.date.compareTo(a.transaction.date),
          );

          // 2. BASE PROJECTION MATH (LINEAR)
          final now = DateTime.now();
          final isCurrentMonth = now.month == _month && now.year == _year;
          final isPastMonth =
              _year < now.year || (_year == now.year && _month < now.month);
          final daysInMonth = DateTime(_year, _month + 1, 0).day;

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

          final remainingBudget = widget.allocatedAmount - totalSpend;
          final dailyAvg = daysElapsed > 0 ? totalSpend / daysElapsed : 0.0;
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

          // 3. SMART PROJECTION
          SmartProjectionResult? smartResult;
          if (projMode == ProjectionMode.smart &&
              _classificationsLoaded &&
              isCurrentMonth &&
              daysElapsed > 0) {
            final txRecords = bucketTransactions
                .map((d) => d.transaction)
                .toList();
            smartResult = SmartProjectionEngine.compute(
              transactions: txRecords,
              classifications: _classifications,
              allocatedBudget: widget.allocatedAmount,
              daysInMonth: daysInMonth,
              daysElapsed: daysElapsed,
            );
          }

          // Active values (smart or linear)
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

          final isOverBudget = activeProjection > widget.allocatedAmount;

          // 4. DETECT UNCLASSIFIED TRANSACTIONS
          // Transactions present in this bucket but absent from the stored
          // classifications map — these are NEW transactions added after the
          // user last ran the classify sheet.
          final unclassifiedTxIds =
              projMode == ProjectionMode.smart &&
                  _classificationsLoaded &&
                  isCurrentMonth
              ? bucketTransactions
                    .map((d) => d.transaction.id)
                    .where((id) => !_classifications.containsKey(id))
                    .toList()
              : <String>[];

          // 4a. TRIGGER CLASSIFY SHEET on first open (no classifications at all)
          if (projMode == ProjectionMode.smart &&
              _classificationsLoaded &&
              isCurrentMonth &&
              !_sheetOpen &&
              _classifications.isEmpty &&
              bucketTransactions.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openClassifySheet(context, bucketTransactions);
            });
          }

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
                      // --- PROJECTION MODE BADGE (carries unclassified warning inline) ---
                      _BucketProjectionBadge(
                        mode: projMode,
                        smartResult: smartResult,
                        theme: theme,
                        isDark: isDark,
                        bucketName: widget.bucket.name,
                        unclassifiedCount: unclassifiedTxIds.length,
                        onReclassify: isCurrentMonth
                            ? () => _openClassifySheet(
                                context,
                                bucketTransactions,
                                forceEdit: true,
                                newTxIds: unclassifiedTxIds.toSet(),
                              )
                            : null,
                      ),

                      const SizedBox(height: DesignTokens.spacingMd),

                      // --- SMART INSIGHT BANNER ---
                      // Suppressed when unclassified items exist (projections unreliable)
                      if (projMode == ProjectionMode.smart &&
                          smartResult != null &&
                          unclassifiedTxIds.isEmpty)
                        _BucketInsightBanner(result: smartResult, theme: theme),

                      if (projMode == ProjectionMode.smart &&
                          smartResult != null &&
                          unclassifiedTxIds.isEmpty)
                        const SizedBox(height: DesignTokens.spacingMd),

                      // --- METRICS GRID ---
                      BudgetMetricsGrid(
                        totalSpend: totalSpend,
                        remainingBudget: remainingBudget,
                        allocatedAmount: widget.allocatedAmount,
                        projectedSpend: activeProjection,
                        dailyAvg: activeDailyAvg,
                        recDaily: activeRecDaily,
                      ),

                      const SizedBox(height: DesignTokens.spacingLg),

                      // --- CHART ---
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
                              allocatedAmount: widget.allocatedAmount,
                              projectedSpend: activeProjection,
                              daysInMonth: daysInMonth,
                              daysElapsed: daysElapsed,
                              isCurrentMonth: isCurrentMonth,
                              theme: theme,
                              month: _month,
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

// ---------------------------------------------------------------------------
// Bucket-level projection mode badge (includes bucket context in label)
// ---------------------------------------------------------------------------
class _BucketProjectionBadge extends StatelessWidget {
  final ProjectionMode mode;
  final SmartProjectionResult? smartResult;
  final ThemeData theme;
  final bool isDark;
  final String bucketName;
  final int unclassifiedCount;
  final VoidCallback? onReclassify;

  const _BucketProjectionBadge({
    required this.mode,
    required this.smartResult,
    required this.theme,
    required this.isDark,
    required this.bucketName,
    this.unclassifiedCount = 0,
    this.onReclassify,
  });

  @override
  Widget build(BuildContext context) {
    final isLinear = mode == ProjectionMode.linear;
    final hasUnclassified = unclassifiedCount > 0 && !isLinear;

    final baseColor = isLinear
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    final color = hasUnclassified ? const Color(0xFFF5A623) : baseColor;

    return GestureDetector(
      onTap: hasUnclassified ? onReclassify : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLinear
                      ? Icons.show_chart_rounded
                      : (hasUnclassified
                            ? Icons.warning_amber_rounded
                            : Icons.psychology_rounded),
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLinear
                        ? 'Linear Projection - $bucketName bucket'
                        : (hasUnclassified
                              ? '$unclassifiedCount Auto-Classified, Needs Review'
                              : 'Smart Projection - Variable Only Extrapolated'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                if (!isLinear && onReclassify != null && !hasUnclassified)
                  GestureDetector(
                    onTap: onReclassify,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'EDIT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (hasUnclassified) ...[
              const SizedBox(height: 6),
              Text(
                'Confirm the auto-classification first to see accurate insights',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact bucket-level Smart Insight Banner
// ---------------------------------------------------------------------------
class _BucketInsightBanner extends StatelessWidget {
  final SmartProjectionResult result;
  final ThemeData theme;

  const _BucketInsightBanner({required this.result, required this.theme});

  @override
  Widget build(BuildContext context) {
    final score = result.healthScore;
    final isDark = theme.brightness == Brightness.dark;

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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Health Score ring
          SizedBox(
            width: 44,
            height: 44,
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
                    fontSize: 12,
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
                    Icon(scoreIcon, size: 12, color: scoreColor),
                    const SizedBox(width: 4),
                    Text(
                      'BUCKET HEALTH',
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                if (result.fixedTotal > 0 || result.oneoffTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      children: [
                        if (result.fixedTotal > 0)
                          _Chip(
                            '🔁 ₹${result.fixedTotal.toStringAsFixed(2)}',
                            const Color(0xFF5B6EF5),
                          ),
                        if (result.oneoffTotal > 0)
                          _Chip(
                            '⚡ ₹${result.oneoffTotal.toStringAsFixed(2)}',
                            const Color(0xFFF5A623),
                          ),
                        if (result.variableTotal > 0)
                          _Chip(
                            '🌊 ₹${result.variableTotal.toStringAsFixed(2)}',
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
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;

  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
