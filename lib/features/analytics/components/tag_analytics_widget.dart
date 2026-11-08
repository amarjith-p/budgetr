// lib/features/analytics/components/tag_analytics_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/futuristic_loader.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../transactions/components/tag_input_sheet.dart';
import '../../transactions/services/transaction_service.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/views/transaction_form_page.dart';
import 'analytics_timeframe_selector.dart';

class TagAnalyticsWidget extends ConsumerStatefulWidget {
  const TagAnalyticsWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<TagAnalyticsWidget> createState() => _TagAnalyticsWidgetState();
}

class _TagData {
  final String tag;
  double income;
  double expense;
  double transfer;
  int count;
  final List<TransactionWithDetails> txs;

  _TagData({
    required this.tag,
    this.income = 0.0,
    this.expense = 0.0,
    this.transfer = 0.0,
    this.count = 0,
    List<TransactionWithDetails>? txs,
  }) : txs = txs ?? [];

  double get net => income - expense;
  double get totalVolume => income + expense + transfer;
}

class _TagDonutSegment {
  final String label;
  final double amount;
  final Color color;
  final double startAngle;
  final double sweepAngle;

  _TagDonutSegment({
    required this.label,
    required this.amount,
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
  });
}

class _TagAnalyticsWidgetState extends ConsumerState<TagAnalyticsWidget> {
  String? _selectedTag;
  String? _selectedTypeFilter;
  TrendTimeframe _timeframe = TrendTimeframe.currentMonth;
  int _txCurrentPage = 0;

  DateTime? _customStart;
  DateTime? _customEnd;

  Future<void> _pickCustomDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeframe = TrendTimeframe.custom;
        _customStart = picked.start;
        _customEnd = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: FuturisticLoader(size: 80, label: "LOADING..")),
      ),
      error: (e, st) =>
          SizedBox(height: 180, child: Center(child: Text('Error: $e'))),
      data: (transactions) {
        // --- 1. DETERMINE DATE BOUNDARIES ---
        DateTime now = DateTime.now();
        DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        DateTime start;

        if (_timeframe == TrendTimeframe.custom &&
            _customStart != null &&
            _customEnd != null) {
          start = DateTime(
            _customStart!.year,
            _customStart!.month,
            _customStart!.day,
          );
          end = _customEnd!;
        } else {
          switch (_timeframe) {
            case TrendTimeframe.week:
              start = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(const Duration(days: 6));
              break;
            case TrendTimeframe.month:
              start = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(const Duration(days: 29));
              break;
            case TrendTimeframe.currentMonth:
              start = DateTime(now.year, now.month, 1);
              break;
            case TrendTimeframe.lastMonth:
              int targetYear = now.month == 1 ? now.year - 1 : now.year;
              int targetMonth = now.month == 1 ? 12 : now.month - 1;
              start = DateTime(targetYear, targetMonth, 1);
              end = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);
              break;
            case TrendTimeframe.year:
              start = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(const Duration(days: 364));
              break;
            case TrendTimeframe.allTime:
            default:
              start = DateTime(2000);
              break;
          }
        }

        // --- 2. AGGREGATE BY TAG ---
        final Map<String, _TagData> tagMap = {};

        for (var txData in transactions) {
          final t = txData.transaction;
          if (t.id.startsWith('LOAN_TX_')) continue;
          if (t.date.isBefore(start) || t.date.isAfter(end)) continue;

          if (t.tags == null || t.tags!.trim().isEmpty) continue;

          final tagList = t.tags!
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty);

          for (final tag in tagList) {
            final data = tagMap.putIfAbsent(tag, () => _TagData(tag: tag));

            data.count++;
            data.txs.add(txData);

            if (t.type == 'Expense') {
              data.expense += t.amount;
            } else if (t.type == 'Income') {
              data.income += t.amount;
            } else if (t.type == 'Transfer') {
              data.transfer += t.amount;
            }
          }
        }

        final sortedTags = tagMap.values.toList()
          ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

        final String? activeTag =
            _selectedTag != null && sortedTags.any((t) => t.tag == _selectedTag)
            ? _selectedTag
            : (sortedTags.isNotEmpty ? sortedTags.first.tag : null);

        final _TagData? currentTagData = activeTag != null
            ? tagMap[activeTag]
            : null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.5),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
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
                          Icons.tag_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TAG INSIGHTS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(isDark ? 0.3 : 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${sortedTags.length} ${sortedTags.length == 1 ? "Tag" : "Tags"}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- EMPTY STATE ---
              if (sortedTags.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 28,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NO TAGGED TRANSACTIONS',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add #tags to transactions to track their combined flow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // --- TAG SELECTOR CHIPS (Single line horizontal scroll) ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: sortedTags.map((item) {
                      final isSelected = item.tag == activeTag;
                      final tagColor = TagColorHelper.getColor(
                        item.tag,
                        theme.brightness,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedTag = item.tag;
                              _selectedTypeFilter = null;
                              _txCurrentPage = 0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? tagColor.withOpacity(0.18)
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(isDark ? 0.2 : 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? tagColor
                                    : theme.dividerColor.withOpacity(0.3),
                                width: isSelected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: tagColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '#${item.tag}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    color: isSelected
                                        ? (isDark
                                              ? Colors.white
                                              : Colors.black87)
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.count}',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: tagColor.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // --- INTERACTIVE MULTI-TYPE DONUT & NET IMPACT ---
                if (currentTagData != null) ...[
                  _buildDonutWithNetSection(currentTagData, theme, isDark),
                  const SizedBox(height: 14),

                  // --- 3-PILL TYPE BREAKDOWN SELECTOR ---
                  _buildTypePillsRow(currentTagData, theme),
                  const SizedBox(height: 12),

                  // --- MINI TRANSACTION PREVIEW (PAGINATED 3 PER PAGE) ---
                  _buildRecentTransactionsPreview(
                    currentTagData,
                    theme,
                    isDark,
                  ),
                ],
              ],

              const SizedBox(height: 10),

              // --- TIMEFRAME SELECTOR ---
              AnalyticsTimeframeSelector(
                selectedTimeframe: _timeframe,
                onSelected: (type) => setState(() => _timeframe = type),
                onCustomTapped: _pickCustomDateRange,
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DONUT AND NET IMPACT VISUALIZATION ---
  Widget _buildDonutWithNetSection(
    _TagData data,
    ThemeData theme,
    bool isDark,
  ) {
    final double exp = data.expense;
    final double inc = data.income;
    final double trf = data.transfer;
    final double total = data.totalVolume;

    final List<_TagDonutSegment> segments = [];

    if (total > 0) {
      double currentAngle = -pi / 2;
      const double gap = 0.05;

      void addSegment(String label, double amount, Color color) {
        if (amount <= 0) return;
        final double sweep = (amount / total) * 2 * pi - gap;
        segments.add(
          _TagDonutSegment(
            label: label,
            amount: amount,
            color: color,
            startAngle: currentAngle + gap / 2,
            sweepAngle: max(0.01, sweep),
          ),
        );
        currentAngle += (amount / total) * 2 * pi;
      }

      addSegment('Expense', exp, theme.colorScheme.error);
      addSegment('Income', inc, Colors.green);
      addSegment('Transfer', trf, TransactionColors.transfer(theme));
    }

    final double net = data.net;
    final Color netColor = net > 0
        ? Colors.green
        : (net < 0 ? theme.colorScheme.error : theme.colorScheme.onSurface);
    final String netSign = net > 0 ? '+₹ ' : (net < 0 ? '-₹ ' : '₹ ');

    return Center(
      child: SizedBox(
        height: 140,
        width: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(140, 140),
              painter: _TagDonutPainter(
                segments: segments,
                emptyColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NET IMPACT',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CurrencyText(
                      amount: net.abs(),
                      sign: netSign,
                      amountStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: netColor,
                      ),
                      symbolStyle: TextStyle(
                        fontSize: 10,
                        color: netColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Gross: ₹${data.totalVolume.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3-PILL TYPE BREAKDOWN SELECTOR ---
  Widget _buildTypePillsRow(_TagData data, ThemeData theme) {
    int expCount = 0;
    int incCount = 0;
    int trfCount = 0;

    for (var d in data.txs) {
      if (d.transaction.type == 'Expense') expCount++;
      if (d.transaction.type == 'Income') incCount++;
      if (d.transaction.type == 'Transfer') trfCount++;
    }

    return Row(
      children: [
        _buildTypePill(
          label: 'EXPENSE',
          amount: data.expense,
          count: expCount,
          color: theme.colorScheme.error,
          sign: '-₹ ',
          typeKey: 'Expense',
          theme: theme,
        ),
        const SizedBox(width: 6),
        _buildTypePill(
          label: 'INCOME',
          amount: data.income,
          count: incCount,
          color: Colors.green,
          sign: '+₹ ',
          typeKey: 'Income',
          theme: theme,
        ),
        const SizedBox(width: 6),
        _buildTypePill(
          label: 'TRANSFER',
          amount: data.transfer,
          count: trfCount,
          color: TransactionColors.transfer(theme),
          sign: '₹ ',
          typeKey: 'Transfer',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildTypePill({
    required String label,
    required double amount,
    required int count,
    required Color color,
    required String sign,
    required String typeKey,
    required ThemeData theme,
  }) {
    final bool isSelected = _selectedTypeFilter == typeKey;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTypeFilter = isSelected ? null : typeKey;
            _txCurrentPage = 0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : theme.dividerColor.withOpacity(0.25),
              width: isSelected ? 1.2 : 0.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: color,
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CurrencyText(
                  amount: amount,
                  sign: amount == 0 ? '₹ ' : sign,
                  amountStyle: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 8,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- RECENT TAG TRANSACTIONS PREVIEW (PAGINATED 3 PER PAGE) ---
  Widget _buildRecentTransactionsPreview(
    _TagData data,
    ThemeData theme,
    bool isDark,
  ) {
    List<TransactionWithDetails> displayList = data.txs;
    if (_selectedTypeFilter != null) {
      displayList = displayList
          .where((d) => d.transaction.type == _selectedTypeFilter)
          .toList();
    }

    // Sort newest first
    displayList.sort(
      (a, b) => b.transaction.date.compareTo(a.transaction.date),
    );
    final int pageCount = (displayList.length / 3).ceil();
    final bool hasMultiplePages = pageCount > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTypeFilter != null
                  ? '${_selectedTypeFilter!.toUpperCase()} TRANSACTIONS'
                  : 'TAG TRANSACTIONS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (displayList.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasMultiplePages) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: _txCurrentPage > 0
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _txCurrentPage--);
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 14,
                          color: _txCurrentPage > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.3,
                                ),
                        ),
                      ),
                    ),
                    Text(
                      '${_txCurrentPage + 1}/$pageCount (${displayList.length})',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: _txCurrentPage < pageCount - 1
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _txCurrentPage++);
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: _txCurrentPage < pageCount - 1
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.3,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    Text(
                      '${displayList.length} total',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => _showAllTransactionsSheet(
                      context,
                      data,
                      displayList,
                      theme,
                      isDark,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.open_in_new_rounded,
                        size: 11,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (displayList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(
              'No ${_selectedTypeFilter ?? ""} transactions for this tag',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          )
        else if (!hasMultiplePages)
          Column(
            children: displayList
                .map((txData) => _buildTransactionCard(txData, theme, isDark))
                .toList(),
          )
        else
          Builder(
            builder: (context) {
              final pageItems = displayList
                  .skip(_txCurrentPage * 3)
                  .take(3)
                  .toList();
              return Column(
                children: pageItems
                    .map(
                      (txData) => _buildTransactionCard(txData, theme, isDark),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  // --- INDIVIDUAL TRANSACTION CARD WITH CATEGORY & BUDGET BUCKET ---
  Widget _buildTransactionCard(
    TransactionWithDetails txData,
    ThemeData theme,
    bool isDark,
  ) {
    final t = txData.transaction;
    final isExpense = t.type == 'Expense';
    final isIncome = t.type == 'Income';
    final isTransfer = t.type == 'Transfer';

    final Color amtColor = isIncome
        ? Colors.green
        : (isExpense
              ? theme.colorScheme.error
              : TransactionColors.transfer(theme));

    final String sign = isIncome ? '+₹ ' : (isExpense ? '-₹ ' : '₹ ');
    final bool hasNotes = t.notes != null && t.notes!.trim().isNotEmpty;
    final String categoryName =
        (t.categoryName != null && t.categoryName!.trim().isNotEmpty)
        ? t.categoryName!.trim()
        : (txData.category?.name ??
              (isTransfer ? 'Transfer' : 'Uncategorized'));

    final String? subCat =
        (t.subCategory != null &&
            t.subCategory!.trim().isNotEmpty &&
            t.subCategory!.trim() != categoryName)
        ? t.subCategory!.trim()
        : null;

    final String? rawBucket =
        (t.bucketName != null && t.bucketName!.trim().isNotEmpty)
        ? t.bucketName!.trim()
        : txData.bucket?.name;

    final String? bucketName = (rawBucket != null && rawBucket.isNotEmpty)
        ? rawBucket
        : (isExpense && (t.bucketId == null || t.bucketId == -1)
              ? 'Out of Bucket'
              : null);

    String accountDisplay = txData.account.name;
    if (isTransfer) {
      if (t.toAccountId == 'EXTERNAL_IN') {
        accountDisplay = 'External → ${txData.account.name}';
      } else if (t.toAccountId == 'EXTERNAL_OUT') {
        accountDisplay = '${txData.account.name} → External';
      } else if (txData.toAccount != null) {
        accountDisplay = '${txData.account.name} → ${txData.toAccount!.name}';
      }
    }

    final String dateStr =
        '${t.date.day} ${DateTimeConstants.shortMonths[t.date.month - 1]}';

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          isDark ? 0.2 : 0.35,
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.12),
          width: 0.6,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () {},
          onLongPress: () {
            HapticFeedback.heavyImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TransactionFormPage(existingTransaction: txData),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Direction / Type Icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: amtColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : (isExpense
                              ? Icons.arrow_upward_rounded
                              : Icons.swap_horiz_rounded),
                    size: 12,
                    color: amtColor,
                  ),
                ),
                const SizedBox(width: 8),

                // Transaction Details (Category as Main Header, Subcategory, Bucket, Notes, Date & Account)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category is ALWAYS the Main Header
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      // Badges: Subcategory & Budget Bucket
                      if (subCat != null || bucketName != null) ...[
                        const SizedBox(height: 1.5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Subcategory pill
                            if (subCat != null)
                              _buildCardBadge(
                                icon: Icons.subdirectory_arrow_right_rounded,
                                text: subCat,
                                textColor: theme.colorScheme.onSurfaceVariant,
                                bgColor: theme
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.7),
                              ),

                            // Budget Bucket pill
                            if (bucketName != null)
                              _buildCardBadge(
                                icon: Icons.folder_outlined,
                                text: bucketName,
                                textColor: bucketName == 'Out of Bucket'
                                    ? theme.colorScheme.error.withOpacity(0.85)
                                    : theme.colorScheme.primary,
                                bgColor: bucketName == 'Out of Bucket'
                                    ? theme.colorScheme.error.withOpacity(0.08)
                                    : theme.colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                              ),
                          ],
                        ),
                      ],

                      // Notes with lesser priority (subtle italic)
                      if (hasNotes) ...[
                        const SizedBox(height: 1),
                        Text(
                          '"${t.notes!.trim()}"',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 1),

                      // Date & Account details
                      Text(
                        '$dateStr • $accountDisplay',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.65,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Formatted Amount
                CurrencyText(
                  amount: t.amount,
                  sign: sign,
                  amountStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: amtColor,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 7.5,
                    color: amtColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- REUSABLE MICRO BADGE FOR CATEGORY / BUCKET ---
  Widget _buildCardBadge({
    required IconData icon,
    required String text,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 7, color: textColor),
          const SizedBox(width: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 6.8,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL BOTTOM SHEET: ALL TAG TRANSACTIONS (MODERN PROFESSIONAL DESIGN) ---
  void _showAllTransactionsSheet(
    BuildContext context,
    _TagData data,
    List<TransactionWithDetails> displayList,
    ThemeData theme,
    bool isDark,
  ) {
    HapticFeedback.lightImpact();
    final tagColor = TagColorHelper.getColor(data.tag, theme.brightness);

    final allTxs = List<TransactionWithDetails>.from(data.txs)
      ..sort((a, b) => b.transaction.date.compareTo(a.transaction.date));

    final expenses = allTxs
        .where((t) => t.transaction.type == 'Expense')
        .toList();
    final incomes = allTxs
        .where((t) => t.transaction.type == 'Income')
        .toList();
    final transfers = allTxs
        .where((t) => t.transaction.type == 'Transfer')
        .toList();

    String activeFilter = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DesignTokens.radiusLg),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ─── DRAG HANDLE ───
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // ─── HEADER BAR ───
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DesignTokens.spacingMd,
                          2,
                          8,
                          8,
                        ),
                        child: Row(
                          children: [
                            // Tag Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(
                                  isDark ? 0.16 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: tagColor.withOpacity(0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tag_rounded,
                                    size: 14,
                                    color: tagColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    data.tag,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${allTxs.length} Transactions',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            // Net volume pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (data.net >= 0
                                            ? Colors.green
                                            : theme.colorScheme.error)
                                        .withOpacity(isDark ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      (data.net >= 0
                                              ? Colors.green
                                              : theme.colorScheme.error)
                                          .withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Net: ',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${data.net > 0 ? "+₹" : (data.net < 0 ? "-₹" : "₹")}${data.net.abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: data.net >= 0
                                          ? Colors.green
                                          : theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.15),
                      ),

                      // ─── UNIFIED SMART OVERVIEW METRICS CARD ───
                      Container(
                        margin: const EdgeInsets.fromLTRB(
                          DesignTokens.spacingMd,
                          10,
                          DesignTokens.spacingMd,
                          8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusSm,
                          ),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(
                              isDark ? 0.12 : 0.25,
                            ),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildSheetOverviewColumn(
                              label: 'EXPENSES',
                              amount: data.expense,
                              count: expenses.length,
                              color: theme.colorScheme.error,
                              sign: '-₹ ',
                              icon: Icons.arrow_upward_rounded,
                              theme: theme,
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: theme.dividerColor.withOpacity(0.2),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            _buildSheetOverviewColumn(
                              label: 'INCOME',
                              amount: data.income,
                              count: incomes.length,
                              color: Colors.green,
                              sign: '+₹ ',
                              icon: Icons.arrow_downward_rounded,
                              theme: theme,
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: theme.dividerColor.withOpacity(0.2),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            _buildSheetOverviewColumn(
                              label: 'TRANSFERS',
                              amount: data.transfer,
                              count: transfers.length,
                              color: TransactionColors.transfer(theme),
                              sign: '₹ ',
                              icon: Icons.swap_horiz_rounded,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),

                      // ─── FILTER TABS ───
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingMd,
                          vertical: 4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(isDark ? 0.3 : 0.5),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSm,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildSheetTab(
                                label: 'All',
                                count: allTxs.length,
                                isActive: activeFilter == 'All',
                                theme: theme,
                                isDark: isDark,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setSheetState(() => activeFilter = 'All');
                                },
                              ),
                              _buildSheetTab(
                                label: 'Expenses',
                                count: expenses.length,
                                isActive: activeFilter == 'Expense',
                                theme: theme,
                                isDark: isDark,
                                color: theme.colorScheme.error,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setSheetState(() => activeFilter = 'Expense');
                                },
                              ),
                              _buildSheetTab(
                                label: 'Income',
                                count: incomes.length,
                                isActive: activeFilter == 'Income',
                                theme: theme,
                                isDark: isDark,
                                color: Colors.green,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setSheetState(() => activeFilter = 'Income');
                                },
                              ),
                              _buildSheetTab(
                                label: 'Transfers',
                                count: transfers.length,
                                isActive: activeFilter == 'Transfer',
                                theme: theme,
                                isDark: isDark,
                                color: TransactionColors.transfer(theme),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setSheetState(
                                    () => activeFilter = 'Transfer',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── SCROLLABLE SECTIONS LIST ───
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            DesignTokens.spacingMd,
                            4,
                            DesignTokens.spacingMd,
                            36,
                          ),
                          children: [
                            // ── EXPENSES SECTION ──
                            if (activeFilter == 'All' ||
                                activeFilter == 'Expense')
                              if (expenses.isNotEmpty) ...[
                                _buildSheetTypeSectionHeader(
                                  title: 'EXPENSES',
                                  count: expenses.length,
                                  total: data.expense,
                                  color: theme.colorScheme.error,
                                  sign: '-₹ ',
                                  icon: Icons.arrow_upward_rounded,
                                  theme: theme,
                                ),
                                ...expenses.map(
                                  (tx) => _buildSheetTransactionTile(
                                    tx,
                                    theme,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                            // ── INCOME SECTION ──
                            if (activeFilter == 'All' ||
                                activeFilter == 'Income')
                              if (incomes.isNotEmpty) ...[
                                _buildSheetTypeSectionHeader(
                                  title: 'INCOME',
                                  count: incomes.length,
                                  total: data.income,
                                  color: Colors.green,
                                  sign: '+₹ ',
                                  icon: Icons.arrow_downward_rounded,
                                  theme: theme,
                                ),
                                ...incomes.map(
                                  (tx) => _buildSheetTransactionTile(
                                    tx,
                                    theme,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                            // ── TRANSFERS SECTION ──
                            if (activeFilter == 'All' ||
                                activeFilter == 'Transfer')
                              if (transfers.isNotEmpty) ...[
                                _buildSheetTypeSectionHeader(
                                  title: 'TRANSFERS',
                                  count: transfers.length,
                                  total: data.transfer,
                                  color: TransactionColors.transfer(theme),
                                  sign: '₹ ',
                                  icon: Icons.swap_horiz_rounded,
                                  theme: theme,
                                ),
                                ...transfers.map(
                                  (tx) => _buildSheetTransactionTile(
                                    tx,
                                    theme,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                            // Empty filter state
                            if ((activeFilter == 'Expense' &&
                                    expenses.isEmpty) ||
                                (activeFilter == 'Income' && incomes.isEmpty) ||
                                (activeFilter == 'Transfer' &&
                                    transfers.isEmpty) ||
                                (allTxs.isEmpty))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 36,
                                        color: theme
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No ${activeFilter == "All" ? "" : activeFilter} transactions found',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Footer hint
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 14.0,
                                bottom: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 13,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Long-press any transaction to edit',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.5),
                                    ),
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
              },
            );
          },
        );
      },
    );
  }

  // ─── SMART OVERVIEW COLUMN ───
  Widget _buildSheetOverviewColumn({
    required String label,
    required double amount,
    required int count,
    required Color color,
    required String sign,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: color,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurrencyText(
              amount: amount,
              sign: sign,
              amountStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: color,
              ),
              symbolStyle: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEGMENTED TAB BUTTON ───
  Widget _buildSheetTab({
    required String label,
    required int count,
    required bool isActive,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? theme.colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive
                      ? activeColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withOpacity(0.15)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? activeColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TRANSACTION TYPE SECTION HEADER ───
  Widget _buildSheetTypeSectionHeader({
    required String title,
    required int count,
    required double total,
    required Color color,
    required String sign,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const Spacer(),
          CurrencyText(
            amount: total,
            sign: sign,
            amountStyle: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.3,
            ),
            symbolStyle: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROFESSIONAL TRANSACTION LIST TILE ───
  Widget _buildSheetTransactionTile(
    TransactionWithDetails txData,
    ThemeData theme,
    bool isDark,
  ) {
    final t = txData.transaction;
    final isExpense = t.type == 'Expense';
    final isIncome = t.type == 'Income';
    final isTransfer = t.type == 'Transfer';

    final Color typeColor = isIncome
        ? Colors.green
        : (isExpense
              ? theme.colorScheme.error
              : TransactionColors.transfer(theme));

    final String sign = isIncome ? '+₹ ' : (isExpense ? '-₹ ' : '₹ ');

    final String categoryName =
        (t.categoryName != null && t.categoryName!.trim().isNotEmpty)
        ? t.categoryName!.trim()
        : (txData.category?.name ??
              (isTransfer ? 'Transfer' : 'Uncategorized'));

    final String? subCat =
        (t.subCategory != null &&
            t.subCategory!.trim().isNotEmpty &&
            t.subCategory!.trim() != categoryName)
        ? t.subCategory!.trim()
        : null;

    final String? rawBucket =
        (t.bucketName != null && t.bucketName!.trim().isNotEmpty)
        ? t.bucketName!.trim()
        : txData.bucket?.name;

    final String? bucketName = (rawBucket != null && rawBucket.isNotEmpty)
        ? rawBucket
        : (isExpense && (t.bucketId == null || t.bucketId == -1)
              ? 'Out of Bucket'
              : null);

    String accountDisplay = txData.account.name;
    if (isTransfer) {
      if (t.toAccountId == 'EXTERNAL_IN') {
        accountDisplay = 'External → ${txData.account.name}';
      } else if (t.toAccountId == 'EXTERNAL_OUT') {
        accountDisplay = '${txData.account.name} → External';
      } else if (txData.toAccount != null) {
        accountDisplay = '${txData.account.name} → ${txData.toAccount!.name}';
      }
    }

    final String dateStr =
        '${t.date.day.toString().padLeft(2, '0')} ${DateTimeConstants.shortMonths[t.date.month - 1]}';
    final bool hasNotes = t.notes != null && t.notes!.trim().isNotEmpty;

    final IconData leadIcon = isIncome
        ? Icons.arrow_downward_rounded
        : (isExpense ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.12 : 0.22),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          onTap: () {},
          onLongPress: () {
            HapticFeedback.heavyImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TransactionFormPage(existingTransaction: txData),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Type icon container
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(DesignTokens.spacingXs),
                    border: Border.all(
                      color: typeColor.withOpacity(0.2),
                      width: 0.6,
                    ),
                  ),
                  child: Icon(leadIcon, size: 16, color: typeColor),
                ),
                const SizedBox(width: 10),

                // Details column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category title
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      // Badges row
                      if (subCat != null || bucketName != null) ...[
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (subCat != null)
                              _buildSheetBadge(
                                subCat,
                                theme.colorScheme.primary.withOpacity(
                                  isDark ? 0.14 : 0.08,
                                ),
                                theme.colorScheme.primary,
                                theme,
                              ),
                            if (bucketName != null)
                              _buildSheetBadge(
                                bucketName,
                                Colors.orange.withOpacity(isDark ? 0.14 : 0.08),
                                Colors.orange.shade700,
                                theme,
                              ),
                          ],
                        ),
                      ],

                      // Notes
                      if (hasNotes) ...[
                        const SizedBox(height: 2),
                        Text(
                          t.notes!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.65),
                          ),
                        ),
                      ],

                      const SizedBox(height: 3),

                      // Date & Account details
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          ),
                          Container(
                            width: 2.5,
                            height: 2.5,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              accountDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Amount
                CurrencyText(
                  amount: t.amount,
                  sign: sign,
                  amountStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: typeColor,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: typeColor.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── MINI BADGE HELPER ───
  Widget _buildSheetBadge(
    String text,
    Color bgColor,
    Color textColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

// --- DONUT PAINTER FOR TAG SEGMENTS ---
class _TagDonutPainter extends CustomPainter {
  final List<_TagDonutSegment> segments;
  final Color emptyColor;

  _TagDonutPainter({required this.segments, required this.emptyColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 14.0;

    if (segments.isEmpty) {
      final emptyPaint = Paint()
        ..color = emptyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }

    for (var seg in segments) {
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        seg.startAngle,
        seg.sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TagDonutPainter oldDelegate) => true;
}
