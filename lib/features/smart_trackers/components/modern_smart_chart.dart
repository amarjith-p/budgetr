// lib/features/smart_trackers/components/modern_smart_chart.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/currency_text.dart';

class ModernSmartChart extends StatefulWidget {
  final List<MapEntry<String, double>> data;
  final bool isLineChart;
  final String yAxisPrefix;

  const ModernSmartChart({
    Key? key,
    required this.data,
    this.isLineChart = false,
    this.yAxisPrefix = '',
  }) : super(key: key);

  @override
  State<ModernSmartChart> createState() => _ModernSmartChartState();
}

class _ModernSmartChartState extends State<ModernSmartChart> {
  double? _touchX;

  Widget _buildYAxisLabel(double amount, String prefix, ThemeData theme) {
    if (amount == 0) {
      return SizedBox(
        height: 14,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '0',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final absVal = amount.abs();
    final sign = amount < -0.01
        ? '-$prefix '
        : (amount > 0.01 ? '$prefix ' : '');

    return SizedBox(
      height: 14,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: CurrencyText(
          amount: absVal,
          sign: sign,
          amountStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          symbolStyle: TextStyle(
            fontSize: 8,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.data.isEmpty) {
      return Center(
        child: Text(
          'No data available.',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    double maxAmount = widget.data.map((e) => e.value).reduce(max);
    double minAmount = widget.data.map((e) => e.value).reduce(min);

    // Force Bar Charts to anchor at 0 for visual realism
    if (!widget.isLineChart && minAmount > 0) minAmount = 0;
    if (!widget.isLineChart && maxAmount < 0) maxAmount = 0;

    if (maxAmount == minAmount) {
      maxAmount += 100;
      minAmount -= 100;
    }

    final double range = maxAmount - minAmount;

    // Add exact headroom limits
    maxAmount += range * 0.15;
    minAmount -= range * 0.05;

    final double newRange = maxAmount - minAmount;

    // Fixed constraints to prevent traditional stretching
    const double chartMaxHeight = 180.0;
    const double stepX = 64.0;
    final double requiredWidth = widget.data.length * stepX;

    final Color chartColor = widget.isLineChart
        ? Colors.lightBlue.shade400
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 0, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FIXED LEFT Y-AXIS ---
          Container(
            width: 56,
            padding: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0.8),
                  width: 1.5,
                ),
              ),
            ),
            height: chartMaxHeight + 24,
            child: Column(
              children: [
                SizedBox(
                  height:
                      chartMaxHeight +
                      14, // Exact spacing for center text alignment
                  child: Stack(
                    children: [
                      // Hardcoded proportional layout mathematically bound to the painter
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildYAxisLabel(
                          maxAmount,
                          widget.yAxisPrefix,
                          theme,
                        ),
                      ),
                      Positioned(
                        top: chartMaxHeight * 0.25,
                        left: 0,
                        right: 0,
                        child: _buildYAxisLabel(
                          minAmount + (newRange * 0.75),
                          widget.yAxisPrefix,
                          theme,
                        ),
                      ),
                      Positioned(
                        top: chartMaxHeight * 0.50,
                        left: 0,
                        right: 0,
                        child: _buildYAxisLabel(
                          minAmount + (newRange * 0.50),
                          widget.yAxisPrefix,
                          theme,
                        ),
                      ),
                      Positioned(
                        top: chartMaxHeight * 0.75,
                        left: 0,
                        right: 0,
                        child: _buildYAxisLabel(
                          minAmount + (newRange * 0.25),
                          widget.yAxisPrefix,
                          theme,
                        ),
                      ),
                      Positioned(
                        top: chartMaxHeight,
                        left: 0,
                        right: 0,
                        child: _buildYAxisLabel(
                          minAmount,
                          widget.yAxisPrefix,
                          theme,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // --- HORIZONTALLY SCROLLABLE DATA LAYER ---
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double canvasWidth = max(
                  constraints.maxWidth,
                  requiredWidth,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    // Exactly 7px padding to shift y=0 to perfectly center the top text label
                    padding: const EdgeInsets.only(top: 7.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: (details) {
                        HapticFeedback.selectionClick();
                        setState(() => _touchX = details.localPosition.dx);
                      },
                      onLongPressMoveUpdate: (details) =>
                          setState(() => _touchX = details.localPosition.dx),
                      onLongPressEnd: (_) => setState(() => _touchX = null),
                      onLongPressCancel: () => setState(() => _touchX = null),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, animValue, child) {
                          return CustomPaint(
                            size: Size(canvasWidth, chartMaxHeight + 24),
                            painter: _SmartChartPainter(
                              data: widget.data,
                              minY: minAmount,
                              maxY: maxAmount,
                              progress: animValue,
                              stepX: stepX,
                              lineColor: chartColor,
                              gradientColors: [
                                chartColor.withOpacity(isDark ? 0.3 : 0.2),
                                chartColor.withOpacity(0.0),
                              ],
                              textColor: theme.colorScheme.onSurfaceVariant,
                              theme: theme,
                              yAxisPrefix: widget.yAxisPrefix,
                              touchX: _touchX,
                              isLineChart: widget.isLineChart,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double minY;
  final double maxY;
  final double progress;
  final double stepX;
  final Color lineColor;
  final List<Color> gradientColors;
  final Color textColor;
  final ThemeData theme;
  final String yAxisPrefix;
  final double? touchX;
  final bool isLineChart;

  _SmartChartPainter({
    required this.data,
    required this.minY,
    required this.maxY,
    required this.progress,
    required this.stepX,
    required this.lineColor,
    required this.gradientColors,
    required this.textColor,
    required this.theme,
    required this.yAxisPrefix,
    required this.touchX,
    required this.isLineChart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double chartHeight = size.height - 24;
    final double range = maxY - minY;

    // --- 1. MATHEMATICALLY SYNCED GRID LINES ---
    final Paint hGridPaint = Paint()
      ..color = theme.dividerColor.withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // By drawing them directly inside the CustomPainter,
    // they are absolutely guaranteed to sync perfectly with the data.
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), hGridPaint);
    canvas.drawLine(
      Offset(0, chartHeight * 0.25),
      Offset(size.width, chartHeight * 0.25),
      hGridPaint,
    );
    canvas.drawLine(
      Offset(0, chartHeight * 0.50),
      Offset(size.width, chartHeight * 0.50),
      hGridPaint,
    );
    canvas.drawLine(
      Offset(0, chartHeight * 0.75),
      Offset(size.width, chartHeight * 0.75),
      hGridPaint,
    );
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      hGridPaint,
    );

    // --- 2. CALCULATE BASELINE (ZERO AXIS) ---
    double zeroY = chartHeight;
    if (minY <= 0 && maxY >= 0) {
      zeroY = chartHeight - ((0 - minY) / range) * chartHeight;
    } else if (maxY < 0) {
      zeroY = 0;
    }

    final Paint axisPaint = Paint()
      ..color = theme.dividerColor.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Paint vGridPaint = Paint()
      ..color = theme.dividerColor.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Solid X-Axis Baseline
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), axisPaint);

    // --- 3. PLOT POINTS AND X-AXIS LABELS ---
    List<Offset> points = [];
    final TextPainter xLabelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < data.length; i++) {
      final double x = (i * stepX) + (stepX / 2);

      // Faded Vertical Line guiding the eye to each value
      canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), vGridPaint);

      final double animatedValue = minY + ((data[i].value - minY) * progress);
      final double y =
          chartHeight - ((animatedValue - minY) / range) * chartHeight;
      points.add(Offset(x, y));

      String label = data[i].key;
      if (label.length > 5) label = '${label.substring(0, 4)}..';

      xLabelPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: textColor.withOpacity(0.8),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      );
      xLabelPainter.layout(maxWidth: stepX - 4);
      xLabelPainter.paint(
        canvas,
        Offset(x - (xLabelPainter.width / 2), chartHeight + 8),
      );
    }

    // --- 4. RENDER DATA ARCHITECTURE ---
    if (isLineChart) {
      if (points.length == 1) {
        canvas.drawCircle(points.first, 4, Paint()..color = lineColor);
      } else {
        final Path path = Path();
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

        // Fills exactly to the Baseline (Zero-Line), not the floor
        final Path fillPath = Path.from(path);
        fillPath.lineTo(points.last.dx, zeroY);
        fillPath.lineTo(points.first.dx, zeroY);
        fillPath.close();

        final Paint fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

        canvas.drawPath(fillPath, fillPaint);
      }
    } else {
      // Bars are tightly constrained (never bulky)
      final double barWidth = 16.0;

      final Paint barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [lineColor.withOpacity(0.8), lineColor],
        ).createShader(Rect.fromLTWH(0, 0, 0, chartHeight));

      for (var p in points) {
        // Bars anchor correctly whether income or expense
        double top = min(p.dy, zeroY);
        double bottom = max(p.dy, zeroY);

        if ((bottom - top) > 0.5) {
          final rect = RRect.fromRectAndCorners(
            Rect.fromLTRB(
              p.dx - (barWidth / 2),
              top,
              p.dx + (barWidth / 2),
              bottom,
            ),
            topLeft: Radius.circular(p.dy < zeroY ? 4 : 0),
            topRight: Radius.circular(p.dy < zeroY ? 4 : 0),
            bottomLeft: Radius.circular(p.dy > zeroY ? 4 : 0),
            bottomRight: Radius.circular(p.dy > zeroY ? 4 : 0),
          );
          canvas.drawRRect(rect, barPaint);
        }
      }
    }

    // --- 5. INTERACTIVE TOUCH ENGINE ---
    if (touchX != null && points.isNotEmpty) {
      int closestIndex = ((touchX!) / stepX).floor().clamp(0, data.length - 1);
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

      final rawVal = data[closestIndex].value;
      final signStr = rawVal < 0
          ? '-$yAxisPrefix '
          : (rawVal > 0 ? '$yAxisPrefix ' : '');
      final dateStr = data[closestIndex].key;

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
          text: dateStr.toUpperCase(),
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

      if (ttX < 0) ttX = 0;
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
  bool shouldRepaint(covariant _SmartChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.touchX != touchX ||
        oldDelegate.progress != progress ||
        oldDelegate.isLineChart != isLineChart;
  }
}
