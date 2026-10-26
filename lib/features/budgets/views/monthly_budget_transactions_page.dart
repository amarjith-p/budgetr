import 'dart:convert';
import 'dart:math';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/currency_text.dart';
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
import '../providers/budget_provider.dart';
import '../providers/projection_settings_provider.dart';
import '../services/smart_projection_engine.dart';
import '../services/transaction_classification_store.dart';
import '../services/transaction_auto_classifier.dart';
import '../components/projection_mode_badge.dart';

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
  bool _showOutOfBucket = false;
  Set<int>? _selectedBucketIds; // null means all available buckets selected

  // Smart projection state
  Map<String, TransactionClassification> _classifications = {};
  bool _classificationsLoaded = false;
  bool _sheetOpen = false; // Guard to prevent double-open

  @override
  void initState() {
    super.initState();
    _loadClassifications();
    TransactionClassificationStore.changeNotifier
        .addListener(_loadClassifications);
  }

  @override
  void dispose() {
    TransactionClassificationStore.changeNotifier
        .removeListener(_loadClassifications);
    super.dispose();
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
    Set<String> newTxIds = const {},
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
    final budgetAsync = ref.watch(
      monthlyBudgetForMonthProvider(DateTime(widget.year, widget.month)),
    );
    final dbBucketsAsync = ref.watch(bucketsStreamProvider);
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
          final budget = budgetAsync.asData?.value;
          final dbBuckets = dbBucketsAsync.asData?.value ?? [];

          // 1. GET ALL MONTH EXPENSES
          final allMonthExpenses = transactions.where((data) {
            final tx = data.transaction;
            return tx.type == 'Expense' &&
                tx.date.month == widget.month &&
                tx.date.year == widget.year;
          }).toList();

          // 2. DISCOVER ALL AVAILABLE BUCKETS FOR THIS MONTH
          final availableBuckets = <BudgetBucket>[];
          final seenBucketIds = <int>{};

          if (budget?.bucketsSnapshot != null) {
            try {
              final List<dynamic> decoded = jsonDecode(budget!.bucketsSnapshot!);
              for (var b in decoded) {
                final id = b['id'] as int;
                if (seenBucketIds.add(id)) {
                  availableBuckets.add(BudgetBucket(
                    id: id,
                    name: b['name'] as String,
                    percentage: (b['percentage'] as num).toDouble(),
                    createdAt: DateTime.now(),
                  ));
                }
              }
            } catch (_) {}
          }

          for (var b in dbBuckets) {
            if (seenBucketIds.add(b.id)) {
              availableBuckets.add(b);
            }
          }

          for (var data in allMonthExpenses) {
            if (data.bucket != null && seenBucketIds.add(data.bucket!.id)) {
              availableBuckets.add(data.bucket!);
            }
          }

          // 3. COMPUTE ACTIVE BUCKET SELECTION & COMBINATION
          final activeSelectedBucketIds = _selectedBucketIds ??
              availableBuckets.map((b) => b.id).toSet();

          final bool isCustomCombo = availableBuckets.isNotEmpty &&
              activeSelectedBucketIds.length < availableBuckets.length;

          final double selectedPercentage = availableBuckets
              .where((b) => activeSelectedBucketIds.contains(b.id))
              .fold(0.0, (sum, b) => sum + b.percentage);

          // Scaled allocation for custom bucket combo:
          final double selectedAllocated = isCustomCombo
              ? (widget.effectiveIncome * (selectedPercentage / 100.0))
              : widget.effectiveIncome;

          // 4. ISOLATE OUT OF BUCKET TOTAL
          double outOfBucketTotal = 0.0;
          for (var data in allMonthExpenses) {
            if (data.transaction.bucketId == null ||
                data.transaction.bucketId == -1) {
              outOfBucketTotal += data.transaction.amount;
            }
          }

          // 5. APPLY TOGGLE & BUCKET FILTER
          final displayExpenses = allMonthExpenses.where((data) {
            final bId = data.transaction.bucketId;
            final isOutOfBucket = bId == null || bId == -1;
            if (isOutOfBucket) {
              return _showOutOfBucket;
            }
            return activeSelectedBucketIds.contains(bId);
          }).toList();

          displayExpenses.sort(
            (a, b) => b.transaction.date.compareTo(a.transaction.date),
          );

          // 6. BASE PROJECTION MATH (LINEAR)
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

          final remainingBudget = selectedAllocated - totalSpend;
          final dailyAvg = daysElapsed > 0 ? totalSpend / daysElapsed : 0.0;

          // LINEAR projection
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

          // 7. SMART PROJECTION (computed when classifications are loaded)
          SmartProjectionResult? smartResult;
          final List<String> unclassifiedTxIds = [];

          if (projMode == ProjectionMode.smart &&
              _classificationsLoaded &&
              isCurrentMonth &&
              daysElapsed > 0) {
            final txRecords = displayExpenses
                .map((d) => d.transaction)
                .toList();

            final activeClassifications = <String, TransactionClassification>{};
            final dailyBudget = daysInMonth > 0
                ? selectedAllocated / daysInMonth
                : 500.0;

            for (final tx in txRecords) {
              if (_classifications.containsKey(tx.id)) {
                activeClassifications[tx.id] = _classifications[tx.id]!;
              } else {
                final guess = TransactionAutoClassifier.classify(
                  tx,
                  dailyBudget: dailyBudget,
                );
                activeClassifications[tx.id] = guess.classification;
                unclassifiedTxIds.add(tx.id);
              }
            }

            smartResult = SmartProjectionEngine.compute(
              transactions: txRecords,
              classifications: activeClassifications,
              allocatedBudget: selectedAllocated,
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

          final isOverBudget = activeProjection > selectedAllocated;

          // 8. TRIGGER CLASSIFY SHEET on first open (only if no classifications yet)
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

          // 9. RENDER UI
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
                      ProjectionModeBadge(
                        mode: projMode,
                        smartResult: smartResult,
                        theme: theme,
                        isDark: isDark,
                        unclassifiedCount: unclassifiedTxIds.length,
                        onReclassify: isCurrentMonth
                            ? () => _openClassifySheet(
                                context,
                                allMonthExpenses,
                                forceEdit: true,
                                newTxIds: unclassifiedTxIds.toSet(),
                              )
                            : null,
                      ),

                      const SizedBox(height: DesignTokens.spacingMd),

                      // --- BUCKET SELECTOR / CUSTOM COMBO SECTION ---
                      if (availableBuckets.isNotEmpty) ...[
                        _buildBucketSelector(
                          context: context,
                          theme: theme,
                          isDark: isDark,
                          availableBuckets: availableBuckets,
                          activeSelectedBucketIds: activeSelectedBucketIds,
                          isCustomCombo: isCustomCombo,
                          selectedPercentage: selectedPercentage,
                          selectedAllocated: selectedAllocated,
                          allMonthExpenses: allMonthExpenses,
                        ),
                        const SizedBox(height: DesignTokens.spacingMd),
                      ],

                      // --- OUT OF BUCKET TOGGLE CARD ---
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
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.blur_circular_rounded,
                                      color: theme.colorScheme.error,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Out of Bucket',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: !_showOutOfBucket
                                                ? theme.colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.5)
                                                : null,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          _showOutOfBucket
                                              ? '₹${CurrencyFormatter.format(outOfBucketTotal)} Total · Included'
                                              : '₹${CurrencyFormatter.format(outOfBucketTotal)} Total · Excluded',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: _showOutOfBucket
                                                ? theme.colorScheme.error
                                                : theme.colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.5),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _showOutOfBucket,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) =>
                                  setState(() => _showOutOfBucket = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: DesignTokens.spacingMd),

                      // --- SMART INSIGHT BANNER (only in smart mode) ---
                      if (projMode == ProjectionMode.smart &&
                          smartResult != null &&
                          unclassifiedTxIds.isEmpty)
                        _SmartInsightBanner(result: smartResult, theme: theme),

                      if (projMode == ProjectionMode.smart &&
                          smartResult != null &&
                          unclassifiedTxIds.isEmpty)
                        const SizedBox(height: DesignTokens.spacingMd),

                      // --- METRICS GRID ---
                      BudgetMetricsGrid(
                        totalSpend: totalSpend,
                        remainingBudget: remainingBudget,
                        allocatedAmount: selectedAllocated,
                        projectedSpend: activeProjection,
                        dailyAvg: activeDailyAvg,
                        recDaily: activeRecDaily,
                        remainingWithoutOutOfBucket:
                            (_showOutOfBucket && outOfBucketTotal > 0)
                                ? (remainingBudget + outOfBucketTotal)
                                : null,
                      ),

                      const SizedBox(height: DesignTokens.spacingLg),

                      // --- SMART CHART CONTAINER ---
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 18, 0, 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOverBudget && isCurrentMonth
                                ? theme.colorScheme.error.withValues(alpha: 0.5)
                                : theme.dividerColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
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
                                        if (isCustomCombo)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'CUSTOM COMBO',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color:
                                                    theme.colorScheme.primary,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isOverBudget && isCurrentMonth)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.warning_rounded,
                                            color: theme.colorScheme.error,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'OVER BUDGET',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              color: theme.colorScheme.error,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            SmartBudgetChart(
                              cumulativeData: cumulativeData,
                              allocatedAmount: selectedAllocated,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isCustomCombo
                                    ? 'Transaction History (Custom)'
                                    : 'Transaction History',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${displayExpenses.length} ${displayExpenses.length == 1 ? 'txn' : 'txns'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
                      isCustomCombo
                          ? 'No transactions in selected buckets.'
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
                      final data = displayExpenses[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 2.0,
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

  Widget _buildBucketSelector({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required List<BudgetBucket> availableBuckets,
    required Set<int> activeSelectedBucketIds,
    required bool isCustomCombo,
    required double selectedPercentage,
    required double selectedAllocated,
    required List<dynamic> allMonthExpenses,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCustomCombo
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isCustomCombo
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.donut_small_rounded,
                        color: theme.colorScheme.primary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'BUCKETS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isCustomCombo
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.dividerColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCustomCombo
                            ? '${activeSelectedBucketIds.length}/${availableBuckets.length} ACTIVE'
                            : 'ALL ACTIVE',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: isCustomCombo
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCustomCombo)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedBucketIds = null);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'RESET ALL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Subtitle Explanation Row
          Row(
            children: [
              Icon(
                isCustomCombo
                    ? Icons.info_outline_rounded
                    : Icons.touch_app_rounded,
                size: 11,
                color: isCustomCombo
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isCustomCombo
                        ? '${selectedPercentage.toStringAsFixed(0)}% budget ceiling (₹${CurrencyFormatter.format(selectedAllocated)}) · Excluded buckets hidden'
                        : 'Tap to avoid buckets (e.g. investments) · Long-press to isolate',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isCustomCombo
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Horizontal Sleek Bucket Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: availableBuckets.map((bucket) {
                final isSelected = activeSelectedBucketIds.contains(bucket.id);
                final bucketSpend = allMonthExpenses
                    .where((d) => d.transaction.bucketId == bucket.id)
                    .fold(0.0, (sum, d) => sum + d.transaction.amount);

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          final current =
                              Set<int>.from(activeSelectedBucketIds);
                          if (current.contains(bucket.id)) {
                            if (current.length <= 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'At least one bucket must remain selected.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            current.remove(bucket.id);
                          } else {
                            current.add(bucket.id);
                          }

                          if (current.length == availableBuckets.length) {
                            _selectedBucketIds = null;
                          } else {
                            _selectedBucketIds = current;
                          }
                        });
                      },
                      onLongPress: () {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          _selectedBucketIds = {bucket.id};
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Viewing only "${bucket.name}" bucket.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 142,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                                  .withValues(alpha: isDark ? 0.12 : 0.08)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: isDark ? 0.25 : 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.6)
                                : theme.dividerColor.withValues(alpha: 0.3),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor
                                        .withValues(alpha: 0.3),
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check_rounded
                                    : Icons.remove_rounded,
                                size: 13,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    bucket.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: isSelected
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                      decoration: isSelected
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isSelected
                                        ? '${bucket.percentage.toStringAsFixed(0)}% · ₹${CurrencyFormatter.format(bucketSpend)}'
                                        : '${bucket.percentage.toStringAsFixed(0)}% · Avoided',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? theme.colorScheme.onSurfaceVariant
                                          : theme.colorScheme.error
                                              .withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
        color: scoreColor.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withValues(alpha: 0.25)),
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
                  backgroundColor: scoreColor.withValues(alpha: 0.15),
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
        color: color.withValues(alpha: 0.12),
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
