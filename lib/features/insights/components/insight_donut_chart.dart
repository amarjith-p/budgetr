// features/insights/components/insight_donut_chart.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/theme/design_tokens.dart';

class ChartDataItem {
  final String label;
  final double amount;
  final Color color;

  ChartDataItem({
    required this.label,
    required this.amount,
    required this.color,
  });
}

class InsightDonutChart extends StatefulWidget {
  final bool isExpense;
  final double totalAmount;
  final List<ChartDataItem> data;

  static const List<Color> palette = [
    Color(0xFF00B4D8), // Cyan
    Color(0xFF9D4EDD), // Purple
    Color(0xFFFF4D6D), // Pink
    Color(0xFFFF9F1C), // Orange
    Color(0xFF00E676), // Green
    Color(0xFFF15BB5), // Coral
    Color(0xFF3F37C9), // Indigo
    Color(0xFF2EC4B6), // Teal
    Color(0xFFFFBF69), // Yellow
    Color(0xFF48CAE4), // Light Blue
  ];

  const InsightDonutChart({
    Key? key,
    required this.isExpense,
    required this.totalAmount,
    required this.data,
  }) : super(key: key);

  @override
  State<InsightDonutChart> createState() => _InsightDonutChartState();
}

class _InsightDonutChartState extends State<InsightDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant InsightDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpense != widget.isExpense ||
        oldWidget.totalAmount != widget.totalAmount) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = widget.isExpense
        ? theme.colorScheme.error
        : Colors.green;

    if (widget.data.isEmpty || widget.totalAmount <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- THE DONUT CHART VISUAL ---
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner Glow/Shadow
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                // Center Text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CurrencyText(
                      amount: widget.totalAmount,
                      sign: widget.isExpense ? '-₹ ' : '+₹ ',
                      amountStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: -0.5,
                      ),
                      symbolStyle: TextStyle(
                        fontSize: 14,
                        color: primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                // Animated Custom Painter
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(220, 220),
                      painter: _DonutChartPainter(
                        items: widget.data,
                        totalAmount: widget.totalAmount,
                        progress: _animation.value,
                        strokeWidth: 22.0,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- THE LEGEND ---
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = widget.data[index];
              final percentage = (item.amount / widget.totalAmount) * 100;
              return Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CurrencyText(
                    amount: item.amount,
                    sign: '₹ ',
                    amountStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartDataItem> items;
  final double totalAmount;
  final double progress;
  final double strokeWidth;

  _DonutChartPainter({
    required this.items,
    required this.totalAmount,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2; // Start from top
    final double gap = items.length > 1
        ? 0.06
        : 0.0; // The modern pill-gap between arcs

    for (var item in items) {
      final sweepAngle = (item.amount / totalAmount) * 2 * math.pi * progress;

      if (sweepAngle > 0) {
        final paint = Paint()
          ..color = item.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        // Prevent negative drawing angles for very tiny slices
        final drawAngle = sweepAngle > gap ? sweepAngle - gap : sweepAngle;

        canvas.drawArc(rect, startAngle, drawAngle, false, paint);
        startAngle += sweepAngle; // Advance the pointer perfectly
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.totalAmount != totalAmount;
  }
}
