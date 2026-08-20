// features/analytics/components/spending_widget.dart
import 'dart:math';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../accounts/providers/account_provider.dart';
import '../../transactions/providers/transaction_provider.dart';

import 'analytics_account_selection_sheet.dart';
import 'analytics_timeframe_selector.dart';
import 'analytics_account_selector_pill.dart';

class ChartSegment {
  final String name;
  final double amount;
  final Color color;
  double startAngle = 0;
  double sweepAngle = 0;

  ChartSegment(this.name, this.amount, this.color);
}

class SpendingWidget extends ConsumerStatefulWidget {
  const SpendingWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<SpendingWidget> createState() => _SpendingWidgetState();
}

class _SpendingWidgetState extends ConsumerState<SpendingWidget> {
  String _accountFilterId = 'ALL';
  TrendTimeframe _timeframe = TrendTimeframe.currentMonth;

  DateTime? _customStart;
  DateTime? _customEnd;

  bool _hideOutOfBucket = false;
  int _viewMode = 0; // 0 = Category, 1 = Bucket
  int? _selectedSliceIndex;

  final List<Color> _palette = [
    Colors.blueAccent.shade400,
    Colors.pinkAccent.shade400,
    Colors.orangeAccent.shade400,
    Colors.tealAccent.shade400,
    Colors.purpleAccent.shade400,
    Colors.amberAccent.shade400,
    Colors.indigoAccent.shade400,
    Colors.redAccent.shade400,
    Colors.cyanAccent.shade400,
    Colors.greenAccent.shade400,
  ];

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
        _selectedSliceIndex = null;
      });
    }
  }

  void _handleFilterChange(VoidCallback action) {
    setState(() {
      action();
      _selectedSliceIndex = null;
    });
  }

  Widget _buildModeToggle(
    String label,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    bool isSelected = _viewMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _handleFilterChange(() => _viewMode = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: FuturisticLoader(size: 80, label: "LOADING..")),
      ),
      error: (e, st) =>
          SizedBox(height: 250, child: Center(child: Text('Error: $e'))),
      data: (rawAccounts) {
        return transactionsAsync.when(
          loading: () => const SizedBox(
            height: 250,
            child: Center(
              child: FuturisticLoader(size: 80, label: "LOADING.."),
            ),
          ),
          error: (e, st) =>
              SizedBox(height: 250, child: Center(child: Text('Error: $e'))),
          data: (transactions) {
            final targetAccounts = rawAccounts.where((a) {
              if (a.type == 'Loan') return false;
              if (_accountFilterId == 'ASSETS' && a.type == 'Credit Cards')
                return false;
              if (_accountFilterId == 'CREDIT' && a.type != 'Credit Cards')
                return false;
              if (_accountFilterId != 'ALL' &&
                  _accountFilterId != 'ASSETS' &&
                  _accountFilterId != 'CREDIT') {
                return a.id == _accountFilterId;
              }
              return true;
            }).toList();

            final targetIds = targetAccounts.map((a) => a.id).toSet();

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

            Map<String, double> aggregatedData = {};
            double totalSpends = 0.0;

            for (var txData in transactions) {
              final t = txData.transaction;
              final date = t.date;

              if (t.id.startsWith('LOAN_TX_')) continue;
              if (date.isBefore(start) || date.isAfter(end)) continue;
              if (t.type != 'Expense') continue;

              bool fromTarget = targetIds.contains(t.accountId);
              bool isOutOfBucket = t.bucketId == null || t.bucketId == -1;

              if (fromTarget) {
                if (_hideOutOfBucket && isOutOfBucket) continue;

                String keyName = '';
                if (_viewMode == 0) {
                  // --- FIX: USE SNAPSHOT NAME ---
                  keyName =
                      t.categoryName ??
                      txData.category?.name ??
                      'Uncategorized';
                } else {
                  // --- FIX: USE SNAPSHOT BUCKET ---
                  keyName =
                      t.bucketName ?? txData.bucket?.name ?? 'Out of Bucket';
                }

                aggregatedData[keyName] =
                    (aggregatedData[keyName] ?? 0) + t.amount;
                totalSpends += t.amount;
              }
            }

            var sortedEntries = aggregatedData.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            List<ChartSegment> segments = [];
            double startAngle = 0;
            int colorIdx = 0;

            for (var entry in sortedEntries) {
              var seg = ChartSegment(
                entry.key,
                entry.value,
                _palette[colorIdx % _palette.length],
              );
              seg.startAngle = startAngle;
              seg.sweepAngle = totalSpends > 0
                  ? (entry.value / totalSpends) * 2 * pi
                  : 0;
              startAngle += seg.sweepAngle;
              segments.add(seg);
              colorIdx++;
            }

            String dropdownLabel = 'All Accounts';
            if (_accountFilterId == 'ASSETS')
              dropdownLabel = 'Assets Only';
            else if (_accountFilterId == 'CREDIT')
              dropdownLabel = 'Credit Cards Only';
            else if (_accountFilterId != 'ALL') {
              dropdownLabel =
                  rawAccounts
                      .where((a) => a.id == _accountFilterId)
                      .firstOrNull
                      ?.name ??
                  'Unknown';
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              Icons.pie_chart_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SPENDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      AnalyticsAccountSelectorPill(
                        label: dropdownLabel,
                        onTap: () => AnalyticsAccountSelectionSheet.show(
                          context,
                          rawAccounts,
                          _accountFilterId,
                          (newId) => _handleFilterChange(
                            () => _accountFilterId = newId ?? 'ALL',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- VIEW MODE TOGGLE ---
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(isDark ? 0.3 : 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildModeToggle('BY CATEGORY', 0, theme, isDark),
                        _buildModeToggle('BY BUCKET', 1, theme, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- MODERN CENTERED DONUT CHART ---
                  Center(
                    child: SizedBox(
                      height: 160,
                      width: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTapUp: (details) {
                              if (segments.isEmpty) return;

                              Offset center = const Offset(80, 80);
                              double dx = details.localPosition.dx - center.dx;
                              double dy = details.localPosition.dy - center.dy;

                              double distance = sqrt(dx * dx + dy * dy);

                              if (distance < 40 || distance > 90) {
                                setState(() => _selectedSliceIndex = null);
                                return;
                              }

                              double tapAngle = atan2(dy, dx) + pi / 2;
                              if (tapAngle < 0) tapAngle += 2 * pi;
                              if (tapAngle > 2 * pi) tapAngle -= 2 * pi;

                              int? hitIndex;
                              for (int i = 0; i < segments.length; i++) {
                                if (tapAngle >= segments[i].startAngle &&
                                    tapAngle <=
                                        (segments[i].startAngle +
                                            segments[i].sweepAngle)) {
                                  hitIndex = i;
                                  break;
                                }
                              }

                              setState(() {
                                if (_selectedSliceIndex == hitIndex) {
                                  _selectedSliceIndex = null;
                                } else if (hitIndex != null) {
                                  _selectedSliceIndex = hitIndex;
                                  HapticFeedback.selectionClick();
                                }
                              });
                            },
                            child: CustomPaint(
                              size: const Size(160, 160),
                              painter: _DonutPainter(
                                segments: segments,
                                selectedIndex: _selectedSliceIndex,
                                emptyColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 105,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _selectedSliceIndex == null
                                  ? Column(
                                      key: const ValueKey('Total'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'TOTAL SPEND',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: CurrencyText(
                                            amount: totalSpends,
                                            sign: '₹ ',
                                            amountStyle: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  theme.colorScheme.onSurface,
                                              letterSpacing: -0.5,
                                            ),
                                            symbolStyle: TextStyle(
                                              fontSize: 11,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      key: ValueKey(
                                        segments[_selectedSliceIndex!].name,
                                      ),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          segments[_selectedSliceIndex!].name
                                              .toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color:
                                                segments[_selectedSliceIndex!]
                                                    .color,
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: CurrencyText(
                                            amount:
                                                segments[_selectedSliceIndex!]
                                                    .amount,
                                            sign: '₹ ',
                                            amountStyle: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  theme.colorScheme.onSurface,
                                              letterSpacing: -0.5,
                                            ),
                                            symbolStyle: TextStyle(
                                              fontSize: 11,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                segments[_selectedSliceIndex!]
                                                    .color
                                                    .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${((segments[_selectedSliceIndex!].amount / totalSpends) * 100).toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  segments[_selectedSliceIndex!]
                                                      .color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (segments.isNotEmpty)
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: segments.length,
                        itemBuilder: (context, index) {
                          final seg = segments[index];
                          final isSelected = _selectedSliceIndex == index;
                          final isAnySelected = _selectedSliceIndex != null;
                          final opacity = isAnySelected && !isSelected
                              ? 0.3
                              : 1.0;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(
                                () => _selectedSliceIndex = isSelected
                                    ? null
                                    : index,
                              );
                            },
                            child: AnimatedOpacity(
                              opacity: opacity,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? seg.color.withOpacity(0.1)
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(isDark ? 0.15 : 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? seg.color.withOpacity(0.5)
                                        : Colors.transparent,
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: seg.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        seg.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? seg.color
                                              : theme.colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    CurrencyText(
                                      amount: seg.amount,
                                      sign: '₹ ',
                                      amountStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                      symbolStyle: TextStyle(
                                        fontSize: 9,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No spending found for this period.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // --- OUT OF BUCKET TOGGLE ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(isDark ? 0.3 : 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.donut_small_rounded,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Budgeted Expenses Only',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: _hideOutOfBucket,
                            activeColor: theme.colorScheme.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              _handleFilterChange(() => _hideOutOfBucket = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  AnalyticsTimeframeSelector(
                    selectedTimeframe: _timeframe,
                    onSelected: (type) =>
                        _handleFilterChange(() => _timeframe = type),
                    onCustomTapped: _pickCustomDateRange,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final int? selectedIndex;
  final Color emptyColor;

  _DonutPainter({
    required this.segments,
    required this.selectedIndex,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Padding to ensure pop-out doesn't clip
    final radius = maxRadius - 10;

    final baseStrokeWidth = radius * 0.25;
    final innerRadius = radius - (baseStrokeWidth / 2);

    if (segments.isEmpty) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStrokeWidth
        ..color = emptyColor
        ..strokeCap = StrokeCap.butt;

      canvas.drawCircle(center, innerRadius, paint);
      return;
    }

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final isSelected = selectedIndex == i;
      final isAnySelected = selectedIndex != null;

      final strokeWidth = isSelected ? baseStrokeWidth * 1.4 : baseStrokeWidth;
      final color = isAnySelected && !isSelected
          ? seg.color.withOpacity(0.2)
          : seg.color;

      Offset arcCenter = center;
      if (isSelected) {
        final midAngle = seg.startAngle + (seg.sweepAngle / 2) - pi / 2;
        arcCenter = Offset(
          center.dx + cos(midAngle) * 6,
          center.dy + sin(midAngle) * 6,
        );
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: arcCenter, radius: innerRadius),
        seg.startAngle - pi / 2,
        seg.sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
