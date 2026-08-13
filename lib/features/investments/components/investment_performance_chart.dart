// lib/features/investments/components/investment_performance_chart.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/constants/date_time_constants.dart';

class InvestmentPerformanceChart extends StatefulWidget {
  final Investment investment;
  final List<InvestmentLog> logs;
  final double startBal;
  final VoidCallback onFlip;

  const InvestmentPerformanceChart({
    Key? key,
    required this.investment,
    required this.logs,
    required this.startBal,
    required this.onFlip,
  }) : super(key: key);

  @override
  State<InvestmentPerformanceChart> createState() =>
      _InvestmentPerformanceChartState();
}

class _InvestmentPerformanceChartState
    extends State<InvestmentPerformanceChart> {
  double? _touchX;

  String _formatShortDate(DateTime d) {
    return '${d.day} ${DateTimeConstants.shortMonths[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Group logs by Date to process multiple transactions on the same day
    Map<DateTime, List<InvestmentLog>> txByDate = {};
    for (var log in widget.logs) {
      DateTime pureDate = DateTime(log.date.year, log.date.month, log.date.day);
      txByDate.putIfAbsent(pureDate, () => []).add(log);
    }

    // 2. Set Timeline Bounds
    DateTime start = DateTime(
      widget.investment.startDate.year,
      widget.investment.startDate.month,
      widget.investment.startDate.day,
    );
    DateTime now = DateTime.now();
    DateTime end = DateTime(now.year, now.month, now.day);
    if (start.isAfter(end)) start = end;

    // --- FIX: EXTRACT LIVE DAYS ONLY ---
    // Only map dates where an actual transaction occurred
    Set<DateTime> liveDatesSet = txByDate.keys.toSet();
    liveDatesSet.add(start);
    liveDatesSet.add(end);

    List<DateTime> liveDates = liveDatesSet.toList()..sort();

    // 3. Interpolate Balances strictly on Live Days
    Map<DateTime, double> plotData = {};
    double runningBal = widget.startBal;
    double highestBal = runningBal;
    double lowestBal = runningBal;

    for (var date in liveDates) {
      if (txByDate.containsKey(date)) {
        final dayLogs = txByDate[date]!
          ..sort((a, b) => a.date.compareTo(b.date));
        for (var log in dayLogs) {
          if (log.type == 'Deposit') runningBal += log.amount;
          if (log.type == 'Withdrawal') runningBal -= log.amount;
          if (log.type == 'Update') runningBal = log.amount;
        }
      }
      plotData[date] = runningBal;
      if (runningBal > highestBal) highestBal = runningBal;
      if (runningBal < lowestBal) lowestBal = runningBal;
    }

    final points = plotData.values.toList();
    final pointDates = plotData.keys.toList();

    if (highestBal == lowestBal) {
      highestBal += 100;
      lowestBal -= 100;
    }

    final Color trendColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PERFORMANCE HISTORY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: theme.colorScheme.primary,
              ),
            ),
            GestureDetector(
              onTap: widget.onFlip,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.flip_to_front_rounded,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // --- CUSTOM PAINTER IMPLEMENTATION ---
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
            height: 140, // Strict height to match the front of the Summary Card
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- EXACT PAINTER FROM BALANCE TREND WIDGET ---
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
  });

  TextPainter _getAxisLabelPainter(double value, TextStyle baseStyle) {
    final absVal = value.abs();
    final sign = value < 0 ? '-₹ ' : '₹ ';
    String amountStr;
    String suffix = '';

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
      final signStr = rawVal < 0 ? '-₹ ' : '₹ ';

      final dateStr =
          '${dates[closestIndex].day} ${DateTimeConstants.shortMonths[dates[closestIndex].month - 1]}';

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
        oldDelegate.touchX != touchX;
  }
}
