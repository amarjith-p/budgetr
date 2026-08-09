import 'dart:math';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../accounts/providers/account_provider.dart';
import '../../transactions/providers/transaction_provider.dart';

// --- POM IMPORTS ---
import 'analytics_account_selection_sheet.dart';
import 'analytics_timeframe_selector.dart';
import 'analytics_account_selector_pill.dart';

class BalanceTrendWidget extends ConsumerStatefulWidget {
  const BalanceTrendWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<BalanceTrendWidget> createState() => _BalanceTrendWidgetState();
}

class _BalanceTrendWidgetState extends ConsumerState<BalanceTrendWidget> {
  String _accountFilterId = 'ALL';

  // MATCH THE NEW DEFAULT
  TrendTimeframe _timeframe = TrendTimeframe.currentMonth;

  DateTime? _customStart;
  DateTime? _customEnd;

  double? _touchX;

  String _formatShortDate(DateTime d) {
    return '${d.day} ${DateTimeConstants.shortMonths[d.month - 1]}';
  }

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

    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: FuturisticLoader(size: 80, label: "LOADING..")),
      ),
      error: (e, st) =>
          SizedBox(height: 220, child: Center(child: Text('Error: $e'))),
      data: (rawAccounts) {
        return transactionsAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(
              child: FuturisticLoader(size: 80, label: "LOADING.."),
            ),
          ),
          error: (e, st) =>
              SizedBox(height: 220, child: Center(child: Text('Error: $e'))),
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

            double currentTotalBalance = targetAccounts.fold(
              0.0,
              (sum, acc) => sum + acc.balance,
            );
            double totalImpact = 0.0;

            for (var txData in transactions) {
              final t = txData.transaction;
              bool fromTarget = targetIds.contains(t.accountId);
              bool toTarget = targetIds.contains(t.toAccountId);

              if (t.type == 'Income' && fromTarget) {
                totalImpact += t.amount;
              } else if (t.type == 'Expense' && fromTarget) {
                totalImpact -= t.amount;
              } else if (t.type == 'Transfer') {
                if (fromTarget && !toTarget) totalImpact -= t.amount;
                if (!fromTarget && toTarget) totalImpact += t.amount;
              }
            }

            double runningBal = currentTotalBalance - totalImpact;

            Map<DateTime, List<dynamic>> txByDate = {};
            for (var txData in transactions) {
              final t = txData.transaction;
              DateTime pureDate = DateTime(
                t.date.year,
                t.date.month,
                t.date.day,
              );
              txByDate.putIfAbsent(pureDate, () => []).add(txData);
            }

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
                  if (transactions.isEmpty) {
                    start = DateTime(
                      now.year,
                      now.month,
                      now.day,
                    ).subtract(const Duration(days: 7));
                  } else {
                    final oldestTx = transactions.last.transaction.date;
                    start = DateTime(
                      oldestTx.year,
                      oldestTx.month,
                      oldestTx.day,
                    );
                  }
                  break;
              }
            }

            DateTime absoluteStart = transactions.isEmpty
                ? DateTime(now.year, now.month, now.day)
                : DateTime(
                    transactions.last.transaction.date.year,
                    transactions.last.transaction.date.month,
                    transactions.last.transaction.date.day,
                  );

            if (start.isBefore(absoluteStart) &&
                _timeframe != TrendTimeframe.custom) {
              absoluteStart = start;
            } else if (_timeframe == TrendTimeframe.custom) {
              absoluteStart = start;
            }

            Map<DateTime, double> plotData = {};
            DateTime pointer = absoluteStart;

            double highestBal = runningBal;
            double lowestBal = runningBal;

            while (!pointer.isAfter(end)) {
              if (txByDate.containsKey(pointer)) {
                for (var txData in txByDate[pointer]!) {
                  final t = txData.transaction;
                  bool fromTarget = targetIds.contains(t.accountId);
                  bool toTarget = targetIds.contains(t.toAccountId);

                  if (t.type == 'Income' && fromTarget) {
                    runningBal += t.amount;
                  } else if (t.type == 'Expense' && fromTarget) {
                    runningBal -= t.amount;
                  } else if (t.type == 'Transfer') {
                    if (fromTarget && !toTarget) runningBal -= t.amount;
                    if (!fromTarget && toTarget) runningBal += t.amount;
                  }
                }
              }

              if (!pointer.isBefore(start)) {
                plotData[pointer] = runningBal;
                if (runningBal > highestBal) highestBal = runningBal;
                if (runningBal < lowestBal) lowestBal = runningBal;
              }
              pointer = pointer.add(const Duration(days: 1));
            }

            final points = plotData.values.toList();
            final pointDates = plotData.keys.toList();

            if (highestBal == lowestBal) {
              highestBal += 100;
              lowestBal -= 100;
            }

            bool isLiabilityView =
                _accountFilterId == 'CREDIT' ||
                (targetAccounts.isNotEmpty &&
                    targetAccounts.every((a) => a.type == 'Credit Cards'));
            Color trendColor = isLiabilityView
                ? Colors.redAccent.shade400
                : Colors.lightBlue.shade400;

            String dropdownLabel = 'All Accounts';
            if (_accountFilterId == 'ASSETS')
              dropdownLabel = 'Assets Only';
            else if (_accountFilterId == 'CREDIT')
              dropdownLabel = 'Liabilities Only';
            else if (_accountFilterId != 'ALL') {
              dropdownLabel =
                  rawAccounts
                      .where((a) => a.id == _accountFilterId)
                      .firstOrNull
                      ?.name ??
                  'Unknown';
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
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
                              Icons.insights_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'BALANCE TREND',
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
                          (newId) =>
                              setState(() => _accountFilterId = newId ?? 'ALL'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: CurrencyText(
                      amount: currentTotalBalance.abs(),
                      sign: currentTotalBalance < 0 || isLiabilityView
                          ? '-₹ '
                          : '₹ ',
                      amountStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                      symbolStyle: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPressStart: (details) {
                      HapticFeedback.selectionClick();
                      setState(() => _touchX = details.localPosition.dx);
                    },
                    onLongPressMoveUpdate: (details) =>
                        setState(() => _touchX = details.localPosition.dx),
                    onLongPressEnd: (_) => setState(() => _touchX = null),
                    onLongPressCancel: () => setState(() => _touchX = null),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _BoxyGridChartPainter(
                          data: points,
                          dates: pointDates,
                          minY: lowestBal,
                          maxY: highestBal,
                          lineColor: trendColor,
                          gradientColors: [
                            trendColor.withOpacity(isDark ? 0.3 : 0.2),
                            trendColor.withOpacity(0.0),
                          ],
                          textColor: theme.colorScheme.onSurfaceVariant,
                          gridColor: theme.dividerColor,
                          startDateText: _formatShortDate(start),
                          endDateText: _formatShortDate(end),
                          touchX: _touchX,
                          isLiabilityView:
                              isLiabilityView, // <-- Passed into painter
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

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
      },
    );
  }
}

class _BoxyGridChartPainter extends CustomPainter {
  final List<double> data;
  final List<DateTime> dates;
  final double minY;
  final double maxY;
  final Color lineColor;
  final List<Color> gradientColors;
  final Color textColor;
  final Color gridColor;
  final String startDateText;
  final String endDateText;
  final double? touchX;
  final bool isLiabilityView;

  _BoxyGridChartPainter({
    required this.data,
    required this.dates,
    required this.minY,
    required this.maxY,
    required this.lineColor,
    required this.gradientColors,
    required this.textColor,
    required this.gridColor,
    required this.startDateText,
    required this.endDateText,
    required this.touchX,
    required this.isLiabilityView,
  });

  // --- REPLICATES CurrencyText STYLING FOR AXIS LABELS ---
  TextPainter _getAxisLabelPainter(double value, TextStyle baseStyle) {
    final absVal = value.abs();
    final sign = (value < 0 || isLiabilityView) ? '-₹ ' : '₹ ';
    String amountStr;
    String suffix = '';

    // Enforce 2 decimal digits across the board
    if (absVal >= 1000000) {
      amountStr = (absVal / 1000000).toStringAsFixed(2);
      suffix = 'M';
    } else if (absVal >= 1000) {
      amountStr = (absVal / 1000).toStringAsFixed(2);
      suffix = 'K';
    } else {
      amountStr = absVal.toStringAsFixed(2);
    }

    return TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: sign,
            style: baseStyle.copyWith(fontSize: baseStyle.fontSize! - 1),
          ),
          TextSpan(text: '$amountStr$suffix', style: baseStyle),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final textStyle = TextStyle(
      color: textColor.withOpacity(0.6),
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );

    final maxLabel = _getAxisLabelPainter(maxY, textStyle);
    final midLabel = _getAxisLabelPainter((maxY + minY) / 2, textStyle);
    final minLabel = _getAxisLabelPainter(minY, textStyle);

    final leftPadding =
        [maxLabel.width, midLabel.width, minLabel.width].reduce(max) + 8.0;
    const bottomPadding = 16.0;

    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(leftPadding, 0), Offset(size.width, 0), gridPaint);
    maxLabel.paint(
      canvas,
      Offset(leftPadding - maxLabel.width - 4, -maxLabel.height / 2),
    );

    canvas.drawLine(
      Offset(leftPadding, chartHeight / 2),
      Offset(size.width, chartHeight / 2),
      gridPaint,
    );
    midLabel.paint(
      canvas,
      Offset(
        leftPadding - midLabel.width - 4,
        (chartHeight / 2) - (midLabel.height / 2),
      ),
    );

    canvas.drawLine(
      Offset(leftPadding, chartHeight),
      Offset(size.width, chartHeight),
      gridPaint,
    );
    minLabel.paint(
      canvas,
      Offset(
        leftPadding - minLabel.width - 4,
        chartHeight - (minLabel.height / 2),
      ),
    );

    final startLabel = TextPainter(
      text: TextSpan(text: startDateText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final endLabel = TextPainter(
      text: TextSpan(text: endDateText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    startLabel.paint(
      canvas,
      Offset(leftPadding, size.height - startLabel.height),
    );
    endLabel.paint(
      canvas,
      Offset(size.width - endLabel.width, size.height - endLabel.height),
    );

    if (data.length == 1) {
      final y = chartHeight - ((data[0] - minY) / (maxY - minY)) * chartHeight;
      canvas.drawCircle(
        Offset(leftPadding + (chartWidth / 2), y),
        3,
        Paint()..color = lineColor,
      );
      return;
    }

    final double stepX = chartWidth / (data.length - 1);
    final Path path = Path();

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + (i * stepX);
      final y = chartHeight - ((data[i] - minY) / (maxY - minY)) * chartHeight;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final Path fillPath = Path.from(path);
    fillPath.lineTo(leftPadding + chartWidth, chartHeight);
    fillPath.lineTo(leftPadding, chartHeight);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    if (touchX != null) {
      int closestIndex = ((touchX! - leftPadding) / stepX).round().clamp(
        0,
        data.length - 1,
      );
      final p = points[closestIndex];

      final vLinePaint = Paint()
        ..color = textColor.withOpacity(0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      double dashY = 0;
      while (dashY < chartHeight) {
        canvas.drawLine(
          Offset(p.dx, dashY),
          Offset(p.dx, dashY + 4),
          vLinePaint,
        );
        dashY += 8;
      }

      canvas.drawCircle(p, 8.0, Paint()..color = lineColor.withOpacity(0.3));
      canvas.drawCircle(p, 4.0, Paint()..color = lineColor);
      canvas.drawCircle(p, 2.0, Paint()..color = Colors.white);

      final rawVal = data[closestIndex];
      final signStr = (rawVal < 0 || isLiabilityView) ? '-₹ ' : '₹ ';

      final dateStr =
          '${dates[closestIndex].day} ${DateTimeConstants.shortMonths[dates[closestIndex].month - 1]}';

      // --- REPLICATES CurrencyText IN TOOLTIP ---
      final valuePainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: signStr,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
            TextSpan(
              // Using CurrencyFormatter to safely format exactly to 2 decimals with commas
              text: CurrencyFormatter.format(rawVal.abs()),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final datePainter = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final ttWidth = max(valuePainter.width, datePainter.width) + 16;
      final ttHeight = valuePainter.height + datePainter.height + 12;

      double ttX = p.dx - (ttWidth / 2);
      double ttY = p.dy - ttHeight - 12;

      if (ttX < leftPadding) ttX = leftPadding;
      if (ttX + ttWidth > size.width) ttX = size.width - ttWidth;
      if (ttY < 0) ttY = p.dy + 12;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(ttX, ttY, ttWidth, ttHeight),
        const Radius.circular(6),
      );

      canvas.drawShadow(Path()..addRRect(rect), Colors.black, 4, false);
      canvas.drawRRect(rect, Paint()..color = Colors.grey.shade900);

      // Centers text inside the tooltip
      final valXOffset = (ttWidth - valuePainter.width) / 2;
      final dateXOffset = (ttWidth - datePainter.width) / 2;

      valuePainter.paint(canvas, Offset(ttX + valXOffset, ttY + 6));
      datePainter.paint(
        canvas,
        Offset(ttX + dateXOffset, ttY + 6 + valuePainter.height + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoxyGridChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.touchX != touchX ||
        oldDelegate.isLiabilityView != isLiabilityView;
  }
}
