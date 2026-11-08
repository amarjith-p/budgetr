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
  TrendTimeframe _timeframe = TrendTimeframe.currentMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  String? _selectedTag; // null means auto-select first or 'ALL'
  String? _selectedTypeFilter; // 'Expense', 'Income', 'Transfer', or null for all

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
              start = DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(days: 6));
              break;
            case TrendTimeframe.month:
              start = DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(days: 29));
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
              start = DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(days: 364));
              break;
            case TrendTimeframe.allTime:
            default:
              start = DateTime(2000);
              break;
          }
        }

        // --- 2. EXTRACT AND AGGREGATE TAGS ---
        final Map<String, _TagData> tagMap = {};

        for (var txData in transactions) {
          final t = txData.transaction;
          if (t.id.endsWith('_SOURCETRANSFER')) continue;
          if (t.date.isBefore(start) || t.date.isAfter(end)) continue;

          final tagList = parseTagString(t.tags);
          if (tagList.isEmpty) continue;

          for (var tag in tagList) {
            final entry = tagMap.putIfAbsent(tag, () => _TagData(tag: tag));
            entry.count++;
            entry.txs.add(txData);

            if (t.type == 'Income') {
              entry.income += t.amount;
            } else if (t.type == 'Expense') {
              entry.expense += t.amount;
            } else if (t.type == 'Transfer') {
              entry.transfer += t.amount;
            }
          }
        }

        final sortedTags = tagMap.values.toList()
          ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

        // Auto-select first tag if not selected or invalid
        String? activeTag = _selectedTag;
        if (activeTag != null && !tagMap.containsKey(activeTag)) {
          activeTag = null;
        }
        if (activeTag == null && sortedTags.isNotEmpty) {
          activeTag = sortedTags.first.tag;
        }

        final _TagData? currentTagData =
            activeTag != null ? tagMap[activeTag] : null;

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(isDark ? 0.3 : 0.6),
                      borderRadius: BorderRadius.circular(12),
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
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.4),
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
                // --- TAG SELECTOR CHIPS ---
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: sortedTags.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final item = sortedTags[index];
                      final isSelected = item.tag == activeTag;
                      final tagColor =
                          TagColorHelper.getColor(item.tag, theme.brightness);

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedTag = item.tag;
                            _selectedTypeFilter = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tagColor.withOpacity(0.18)
                                : theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(isDark ? 0.2 : 0.4),
                            borderRadius: BorderRadius.circular(16),
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
                                      ? (isDark ? Colors.white : Colors.black87)
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
                      );
                    },
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

                  // --- MINI TRANSACTION PREVIEW ---
                  _buildRecentTransactionsPreview(
                      currentTagData, theme, isDark),
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
      _TagData data, ThemeData theme, bool isDark) {
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
        segments.add(_TagDonutSegment(
          label: label,
          amount: amount,
          color: color,
          startAngle: currentAngle + gap / 2,
          sweepAngle: max(0.01, sweep),
        ));
        currentAngle += (amount / total) * 2 * pi;
      }

      addSegment('Expense', exp, theme.colorScheme.error);
      addSegment('Income', inc, Colors.green);
      addSegment('Transfer', trf, TransactionColors.transfer(theme));
    }

    final double net = data.net;
    final Color netColor =
        net > 0 ? Colors.green : (net < 0 ? theme.colorScheme.error : theme.colorScheme.onSurface);
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
                emptyColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                      'Gross: ₹${data.totalVolume.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
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

  // --- 3-PILL TYPE SELECTOR ROW ---
  Widget _buildTypePillsRow(_TagData data, ThemeData theme) {
    int expCount =
        data.txs.where((d) => d.transaction.type == 'Expense').length;
    int incCount =
        data.txs.where((d) => d.transaction.type == 'Income').length;
    int trfCount =
        data.txs.where((d) => d.transaction.type == 'Transfer').length;

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
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTypeFilter = isSelected ? null : typeKey;
          });
        },
        borderRadius: BorderRadius.circular(6),
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

  // --- RECENT TAG TRANSACTIONS PREVIEW ---
  Widget _buildRecentTransactionsPreview(
      _TagData data, ThemeData theme, bool isDark) {
    List<TransactionWithDetails> displayList = data.txs;
    if (_selectedTypeFilter != null) {
      displayList = displayList
          .where((d) => d.transaction.type == _selectedTypeFilter)
          .toList();
    }

    // Sort newest first
    displayList.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
    final previewItems = displayList.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTypeFilter != null
                  ? '${_selectedTypeFilter!.toUpperCase()} TRANSACTIONS'
                  : 'RECENT TRANSACTIONS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (displayList.isNotEmpty)
              Text(
                'Showing ${previewItems.length} of ${displayList.length}',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (previewItems.isEmpty)
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
        else
          ...previewItems.map((txData) {
            final t = txData.transaction;
            final isExpense = t.type == 'Expense';
            final isIncome = t.type == 'Income';
            final Color amtColor = isIncome
                ? Colors.green
                : (isExpense
                    ? theme.colorScheme.error
                    : TransactionColors.transfer(theme));
            final String sign = isIncome ? '+₹ ' : (isExpense ? '-₹ ' : '₹ ');

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(isDark ? 0.2 : 0.35),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : (isExpense
                            ? Icons.arrow_upward_rounded
                            : Icons.swap_horiz_rounded),
                    size: 12,
                    color: amtColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.notes != null && t.notes!.trim().isNotEmpty
                              ? t.notes!
                              : (t.categoryName ?? t.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${t.date.day} ${DateTimeConstants.shortMonths[t.date.month - 1]} • ${txData.account?.name ?? "Account"}',
                          style: TextStyle(
                            fontSize: 7.5,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CurrencyText(
                    amount: t.amount,
                    sign: sign,
                    amountStyle: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: amtColor,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 8,
                      color: amtColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
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

