import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/components/currency_text.dart'; // <-- ADDED IMPORT

class SmartBudgetChart extends StatefulWidget {
  final List<double> cumulativeData;
  final double allocatedAmount;
  final double projectedSpend;
  final int daysInMonth;
  final int daysElapsed;
  final bool isCurrentMonth;
  final ThemeData theme;
  final int month;

  const SmartBudgetChart({
    Key? key,
    required this.cumulativeData,
    required this.allocatedAmount,
    required this.projectedSpend,
    required this.daysInMonth,
    required this.daysElapsed,
    required this.isCurrentMonth,
    required this.theme,
    required this.month,
  }) : super(key: key);

  @override
  State<SmartBudgetChart> createState() => _SmartBudgetChartState();
}

class _SmartBudgetChartState extends State<SmartBudgetChart> {
  double? _touchX;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) =>
          setState(() => _touchX = details.localPosition.dx),
      onPanUpdate: (details) =>
          setState(() => _touchX = details.localPosition.dx),
      onPanEnd: (_) => setState(() => _touchX = null),
      onPanCancel: () => setState(() => _touchX = null),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CustomPaint(
          painter: SmartBudgetChartPainter(
            cumulativeData: widget.cumulativeData,
            allocatedAmount: widget.allocatedAmount,
            projectedSpend: widget.projectedSpend,
            daysInMonth: widget.daysInMonth,
            daysElapsed: widget.daysElapsed,
            isCurrentMonth: widget.isCurrentMonth,
            theme: widget.theme,
            month: widget.month,
            touchX: _touchX,
          ),
        ),
      ),
    );
  }
}

class SmartBudgetChartPainter extends CustomPainter {
  final List<double> cumulativeData;
  final double allocatedAmount;
  final double projectedSpend;
  final int daysInMonth;
  final int daysElapsed;
  final bool isCurrentMonth;
  final ThemeData theme;
  final int month;
  final double? touchX;

  SmartBudgetChartPainter({
    required this.cumulativeData,
    required this.allocatedAmount,
    required this.projectedSpend,
    required this.daysInMonth,
    required this.daysElapsed,
    required this.isCurrentMonth,
    required this.theme,
    required this.month,
    this.touchX,
  });

  String _formatK(double val) {
    if (val.abs() >= 1000000000)
      return '${(val / 1000000000).toStringAsFixed(1)}B';
    if (val.abs() >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val.abs() >= 1000) return '${(val / 1000).toStringAsFixed(1)}k';
    return val.toStringAsFixed(0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (allocatedAmount <= 0) return;

    final double maxY = max(allocatedAmount, projectedSpend) * 1.15;
    if (maxY <= 0) return;

    final isDark = theme.brightness == Brightness.dark;

    final gridPaint = Paint()
      ..color = theme.dividerColor.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final textStyle = TextStyle(
      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    final maxLabel = TextPainter(
      text: TextSpan(text: _formatK(maxY), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final double paddingLeft = maxLabel.width + 12.0;

    const double paddingBottom = 24.0;
    const double paddingTop = 20.0;
    const double paddingRight = 16.0;

    final double usableWidth = size.width - paddingLeft - paddingRight;
    final double usableHeight = size.height - paddingTop - paddingBottom;

    double getX(int day) =>
        paddingLeft + (((day - 1) / (daysInMonth - 1)) * usableWidth);
    double getY(double amount) =>
        paddingTop + usableHeight - ((amount / maxY) * usableHeight);

    // 1. Draw Y-Axis (Horizontal Dotted Grids)
    int ySteps = 4;
    for (int i = 0; i <= ySteps; i++) {
      double val = (maxY / ySteps) * i;
      double y = getY(val);

      _drawDashedLine(
        canvas,
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
        dashWidth: 2,
        dashSpace: 4,
      );

      final tp = TextPainter(
        text: TextSpan(text: _formatK(val), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 8, y - tp.height / 2));
    }

    // 2. Draw X-Axis (Vertical Ticks)
    List<int> xDays = [1, 10, 20, daysInMonth];
    for (int day in xDays) {
      double x = getX(day);
      canvas.drawLine(
        Offset(x, size.height - paddingBottom),
        Offset(x, size.height - paddingBottom + 4),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(text: 'D$day', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, size.height - paddingBottom + 8),
      );
    }

    // 3. Draw Budget Limit Line (Dashed)
    final limitY = getY(allocatedAmount);
    final limitPaint = Paint()
      ..color = theme.colorScheme.error.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(paddingLeft, limitY),
      Offset(size.width - paddingRight, limitY),
      limitPaint,
    );

    final limitLabel = TextPainter(
      text: TextSpan(
        text: 'LIMIT',
        style: TextStyle(
          color: theme.colorScheme.error,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    limitLabel.paint(
      canvas,
      Offset(size.width - paddingRight - limitLabel.width, limitY - 14),
    );

    // 4. Draw Projected Line & Warning Label
    double? breakX;
    int? breakDay;

    if (isCurrentMonth && daysElapsed > 0 && cumulativeData.isNotEmpty) {
      final currentX = getX(daysElapsed);
      final currentY = getY(cumulativeData.last);
      final projX = getX(daysInMonth);
      final projY = getY(projectedSpend);

      final isOverBudget = projectedSpend > allocatedAmount;
      final projColor = isOverBudget
          ? theme.colorScheme.error
          : theme.colorScheme.primary.withOpacity(0.5);

      final projPaint = Paint()
        ..color = projColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      _drawDashedLine(
        canvas,
        Offset(currentX, currentY),
        Offset(projX, projY),
        projPaint,
      );

      // Warning Intersection
      if (isOverBudget && cumulativeData.last < allocatedAmount) {
        final dailyAvg = cumulativeData.last / daysElapsed;
        if (dailyAvg > 0) {
          breakDay = (allocatedAmount / dailyAvg).round();
          breakX = getX(breakDay);

          final warningPaint = Paint()
            ..color = theme.colorScheme.error.withOpacity(0.4)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          _drawDashedLine(
            canvas,
            Offset(breakX, paddingTop),
            Offset(breakX, size.height - paddingBottom),
            warningPaint,
            dashWidth: 4,
            dashSpace: 4,
          );

          canvas.drawCircle(
            Offset(breakX, limitY),
            4.0,
            Paint()..color = theme.colorScheme.error,
          );
          canvas.drawCircle(
            Offset(breakX, limitY),
            8.0,
            Paint()..color = theme.colorScheme.error.withOpacity(0.3),
          );
        }
      }
    }

    // 5. Draw Actual Spending Line & Gradient
    if (cumulativeData.isNotEmpty) {
      final actualPath = Path();
      actualPath.moveTo(getX(1), getY(cumulativeData[0]));

      for (int i = 0; i < cumulativeData.length; i++) {
        actualPath.lineTo(getX(i + 1), getY(cumulativeData[i]));
      }

      final fillPath = Path.from(actualPath);
      fillPath.lineTo(getX(cumulativeData.length), size.height - paddingBottom);
      fillPath.lineTo(getX(1), size.height - paddingBottom);
      fillPath.close();

      final gradient = ui.Gradient.linear(
        Offset(0, paddingTop),
        Offset(0, size.height - paddingBottom),
        [
          theme.colorScheme.primary.withOpacity(isDark ? 0.4 : 0.2),
          theme.colorScheme.primary.withOpacity(0.0),
        ],
      );

      canvas.drawPath(fillPath, Paint()..shader = gradient);

      final linePaint = Paint()
        ..color = theme.colorScheme.primary
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(actualPath, linePaint);

      final lastX = getX(cumulativeData.length);
      final lastY = getY(cumulativeData.last);
      canvas.drawCircle(
        Offset(lastX, lastY),
        5.0,
        Paint()..color = theme.colorScheme.surface,
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        3.5,
        Paint()..color = theme.colorScheme.primary,
      );
    }

    // 6. Draw Interactive Tooltip
    if (touchX != null &&
        touchX! >= paddingLeft &&
        touchX! <= size.width - paddingRight &&
        cumulativeData.isNotEmpty) {
      double ratio = (touchX! - paddingLeft) / usableWidth;
      int day = (ratio * (daysInMonth - 1)).round() + 1;
      day = day.clamp(1, daysElapsed);

      double x = getX(day);
      double y = getY(cumulativeData[day - 1]);

      canvas.drawLine(
        Offset(x, paddingTop),
        Offset(x, size.height - paddingBottom),
        Paint()
          ..color = theme.colorScheme.primary.withOpacity(0.5)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = theme.colorScheme.surface,
      );
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = theme.colorScheme.primary,
      );

      final monthName = DateTimeConstants.shortMonths[month - 1];

      // --- FIX: Formatted Currency with Global Formatter ---
      final formattedAmount = CurrencyFormatter.format(cumulativeData[day - 1]);
      String tooltipText = '$monthName $day\n₹ $formattedAmount';

      final tp = TextPainter(
        text: TextSpan(
          text: tooltipText,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      double boxWidth = tp.width + 16;
      double boxHeight = tp.height + 10;
      double boxX = x - boxWidth / 2;
      double boxY = y - boxHeight - 12;

      if (boxX < paddingLeft) boxX = paddingLeft;
      if (boxX + boxWidth > size.width - paddingRight)
        boxX = size.width - paddingRight - boxWidth;
      if (boxY < paddingTop) boxY = y + 12;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()..color = theme.colorScheme.primary);
      tp.paint(canvas, Offset(boxX + 8, boxY + 5));
    }

    // 7. Draw Break Day Label
    if (breakX != null && breakDay != null) {
      final warnText = TextPainter(
        text: TextSpan(
          text: 'BREAKS DAY $breakDay',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double textX = breakX + 6;
      if (textX + warnText.width + 8 > size.width)
        textX = breakX - warnText.width - 12;

      double textY = limitY - warnText.height - 10;
      if (textY < paddingTop) textY = limitY + 10;

      final textRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          textX - 4,
          textY - 2,
          warnText.width + 8,
          warnText.height + 4,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        textRect,
        Paint()..color = theme.colorScheme.surface.withOpacity(0.9),
      );

      warnText.paint(canvas, Offset(textX, textY));
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    int dashWidth = 5,
    int dashSpace = 4,
  }) {
    double startX = p1.dx;
    double startY = p1.dy;

    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final magnitude = sqrt(dx * dx + dy * dy);
    final direction = Offset(dx / magnitude, dy / magnitude);

    double distance = 0;
    while (distance < magnitude) {
      final endX = startX + direction.dx * dashWidth;
      final endY = startY + direction.dy * dashWidth;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      distance += dashWidth + dashSpace;
      startX = p1.dx + direction.dx * distance;
      startY = p1.dy + direction.dy * distance;
    }
  }

  @override
  bool shouldRepaint(covariant SmartBudgetChartPainter oldDelegate) {
    return oldDelegate.touchX != touchX ||
        oldDelegate.cumulativeData != cumulativeData ||
        oldDelegate.allocatedAmount != allocatedAmount ||
        oldDelegate.projectedSpend != projectedSpend;
  }
}
