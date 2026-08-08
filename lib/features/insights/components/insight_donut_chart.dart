// features/insights/components/insight_donut_chart.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/currency_text.dart';

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
  int? _selectedIndex; // <-- NEW: Tracks the interactive selection

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      _selectedIndex = null; // Reset selection on data change
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- NEW: Handle Taps on Legend or Chart ---
  void _handleSelection(int? index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null; // Toggle off if tapped again
      } else {
        _selectedIndex = index;
      }
    });
  }

  // --- NEW: Calculate which slice was tapped based on angle and radius ---
  void _onChartTapDown(TapDownDetails details, double chartSize) {
    if (widget.totalAmount <= 0) return;

    final center = Offset(chartSize / 2, chartSize / 2);
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final strokeWidth = 14.0;
    final radius = chartSize / 2 - (strokeWidth / 2);

    // Ensure tap is actually ON the donut ring, not the empty center
    if (distance < radius - strokeWidth || distance > radius + strokeWidth) {
      if (_selectedIndex != null) _handleSelection(null);
      return;
    }

    // Calculate tap angle (adjusted for the -pi/2 starting point at the top)
    double angle = math.atan2(dy, dx);
    angle += math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    double currentAngle = 0;
    for (int i = 0; i < widget.data.length; i++) {
      final sweepAngle =
          (widget.data[i].amount / widget.totalAmount) * 2 * math.pi;
      if (angle >= currentAngle && angle < currentAngle + sweepAngle) {
        _handleSelection(i);
        return;
      }
      currentAngle += sweepAngle;
    }

    if (_selectedIndex != null) _handleSelection(null);
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

    // Dynamic Center Text Data
    String centerTitle = 'TOTAL';
    double centerAmount = widget.totalAmount;
    Color centerColor = primaryColor;
    String? centerSubtitle;

    if (_selectedIndex != null) {
      final selectedItem = widget.data[_selectedIndex!];
      centerTitle = selectedItem.label.toUpperCase();
      centerAmount = selectedItem.amount;
      centerColor = selectedItem.color;
      final percent = (selectedItem.amount / widget.totalAmount) * 100;
      centerSubtitle = '${percent.toStringAsFixed(1)}%';
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- INTERACTIVE DONUT CHART VISUAL ---
          GestureDetector(
            onTapDown: (details) => _onChartTapDown(details, 120.0),
            child: SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dynamic Inner Glow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: centerColor.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Dynamic Center Text
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerTitle,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CurrencyText(
                            amount: centerAmount,
                            sign: widget.isExpense ? '-₹ ' : '+₹ ',
                            amountStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: centerColor,
                              letterSpacing: -0.5,
                            ),
                            symbolStyle: TextStyle(
                              fontSize: 10,
                              color: centerColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                        if (centerSubtitle != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            centerSubtitle,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: centerColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Animated Custom Painter
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(120, 120),
                        painter: _DonutChartPainter(
                          items: widget.data,
                          totalAmount: widget.totalAmount,
                          progress: _animation.value,
                          strokeWidth: 14.0,
                          selectedIndex:
                              _selectedIndex, // Pass selection state to painter
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // --- INTERACTIVE BOXY LEGEND ---
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.data.length, (index) {
                final item = widget.data[index];
                final percentage = (item.amount / widget.totalAmount) * 100;

                // Determine opacity based on selection state
                final isSelected = _selectedIndex == index;
                final isDimmed = _selectedIndex != null && !isSelected;

                return GestureDetector(
                  onTap: () => _handleSelection(index),
                  behavior: HitTestBehavior
                      .opaque, // Ensures the entire row is tappable
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isDimmed ? 0.3 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          // Boxy Square Indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isSelected
                                ? 12
                                : 10, // Pops out slightly if selected
                            height: isSelected ? 12 : 10,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: item.color.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: isSelected
                                    ? item.color
                                    : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                              color: isSelected
                                  ? item.color
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
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
  final int? selectedIndex;

  _DonutChartPainter({
    required this.items,
    required this.totalAmount,
    required this.progress,
    required this.strokeWidth,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2; // Start from top
    final double gap = items.length > 1 ? 0.04 : 0.0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final sweepAngle = (item.amount / totalAmount) * 2 * math.pi * progress;

      if (sweepAngle > 0) {
        final isSelected = selectedIndex == i;
        final isDimmed = selectedIndex != null && !isSelected;

        final paint = Paint()
          ..color = isDimmed ? item.color.withOpacity(0.15) : item.color
          ..style = PaintingStyle.stroke
          // Selected slice pops out slightly thicker
          ..strokeWidth = isSelected ? strokeWidth + 4.0 : strokeWidth
          ..strokeCap = StrokeCap.round;

        final drawAngle = sweepAngle > gap ? sweepAngle - gap : sweepAngle;

        canvas.drawArc(rect, startAngle, drawAngle, false, paint);
        startAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
