import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/database/app_database.dart';
import '../../../core/constants/date_time_constants.dart';
import '../providers/net_worth_provider.dart';

enum NetWorthCardFace { front, breakdown, chart }

class NetWorthSummaryCard extends StatefulWidget {
  final NetWorthMetrics metrics;
  final List<NetWorthRecord> records;

  const NetWorthSummaryCard({
    super.key,
    required this.metrics,
    required this.records,
  });

  @override
  State<NetWorthSummaryCard> createState() => _NetWorthSummaryCardState();
}

class _NetWorthSummaryCardState extends State<NetWorthSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  NetWorthCardFace _currentFace = NetWorthCardFace.front;
  NetWorthCardFace _backFaceTarget = NetWorthCardFace.breakdown;
  double? _touchX;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip(NetWorthCardFace target) {
    HapticFeedback.lightImpact();
    if (_currentFace == NetWorthCardFace.front) {
      setState(() {
        _backFaceTarget = target;
        _currentFace = target;
      });
      _controller.forward();
    } else {
      setState(() => _currentFace = NetWorthCardFace.front);
      _controller.reverse();
    }
  }

  String _formatShortDate(DateTime d) {
    return '${d.day} ${DateTimeConstants.shortMonths[d.month - 1]}';
  }

  // --- BASE STAT BUILDER ---
  Widget _buildGridStat(
    String label,
    double amount,
    Color color,
    ThemeData theme,
  ) {
    final String displaySign = amount < 0 ? '-₹ ' : '₹ ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: CurrencyText(
            amount: amount.abs(),
            sign: displaySign,
            amountStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            symbolStyle: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
          ),
        ),
      ],
    );
  }

  // --- SMART ADAPTIVE ROW MANAGER ---
  Widget _buildAdaptiveRow(List<Widget> items, ThemeData theme) {
    if (items.isEmpty) return const SizedBox.shrink();

    List<Widget> rowChildren = [];
    for (int i = 0; i < items.length; i++) {
      rowChildren.add(Expanded(child: items[i]));
      if (i < items.length - 1) {
        rowChildren.add(
          VerticalDivider(width: 24, thickness: 1, color: theme.dividerColor),
        );
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rowChildren,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isPositive = widget.metrics.netWorth >= 0;
    final netWorthColor = isPositive ? Colors.green : theme.colorScheme.error;
    final netWorthSign = isPositive ? '₹ ' : '-₹ ';

    final double receivables = widget.metrics.netDebts > 0
        ? widget.metrics.netDebts
        : 0.0;
    final double payables = widget.metrics.netDebts < 0
        ? widget.metrics.netDebts
        : 0.0;

    final double totalAssets =
        widget.metrics.totalAssets +
        widget.metrics.totalInvestments +
        receivables;
    final double totalLiabilities =
        widget.metrics.totalCreditCards + widget.metrics.totalLoans + payables;

    final double totalVolume = totalAssets + totalLiabilities.abs();
    final double assetRatio = totalVolume > 0
        ? (totalAssets / totalVolume).clamp(0.0, 1.0)
        : 0.5;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final isFrontVisible = angle <= pi / 2;

        return Material(
          color: Colors.transparent,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontVisible
                ? _buildFrontFace(
                    theme,
                    isDark,
                    netWorthColor,
                    netWorthSign,
                    assetRatio,
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _backFaceTarget == NetWorthCardFace.breakdown
                        ? _buildBackFace(theme, isDark, receivables, payables)
                        : _buildChartFace(theme, isDark),
                  ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // FRONT FACE
  // ===========================================================================
  Widget _buildFrontFace(
    ThemeData theme,
    bool isDark,
    Color netWorthColor,
    String netWorthSign,
    double assetRatio,
  ) {
    final isPositive = widget.metrics.netWorth >= 0;

    double? lastNetWorth;
    if (widget.records.isNotEmpty) {
      final r = widget.records.first; // First item is the newest snapshot
      final double historicalAssets =
          r.assetAccountBalance +
          r.assetSavings +
          r.assetMutualFunds +
          r.assetStocks +
          r.assetBonds +
          r.assetFixedDeposits +
          r.assetRecurringDeposits +
          r.assetP2PLending +
          r.assetOtherInvestments +
          r.assetLentDebts +
          r.assetExtraOthers;
      final double historicalLiabilities =
          r.liabilityCreditCards +
          r.liabilityLoans +
          r.liabilityBorrowedDebts +
          r.liabilityExtraOthers;
      lastNetWorth = historicalAssets + historicalLiabilities;
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE NET WORTH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: netWorthColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPositive ? 'POSITIVE' : 'NEGATIVE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: netWorthColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurrencyText(
              amount: widget.metrics.netWorth.abs(),
              sign: netWorthSign,
              amountStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: netWorthColor,
                letterSpacing: -0.5,
              ),
              symbolStyle: TextStyle(
                fontSize: 14,
                color: netWorthColor.withOpacity(0.7),
              ),
            ),
          ),

          if (lastNetWorth != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 10,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Last Snapshot: ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
                CurrencyText(
                  amount: lastNetWorth.abs(),
                  sign: lastNetWorth < 0 ? '-₹ ' : '₹ ',
                  amountStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 8,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 4,
              width: double.infinity,
              color: theme.colorScheme.error.withOpacity(0.8),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: assetRatio,
                child: Container(color: Colors.green),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(assetRatio * 100).toStringAsFixed(1)}% Assets',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                ),
              ),
              Text(
                '${((1 - assetRatio) * 100).toStringAsFixed(1)}% Liabilities',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const Spacer(),

          // --- SPLIT BOTTOM ACTION ROW ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _toggleFlip(NetWorthCardFace.chart),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'VIEW TREND',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.6,
                        ),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleFlip(NetWorthCardFace.breakdown),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      'BREAKDOWN',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.6,
                        ),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.grid_view_rounded,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BACK FACE: GRID BREAKDOWN
  // ===========================================================================
  Widget _buildBackFace(
    ThemeData theme,
    bool isDark,
    double receivables,
    double payables,
  ) {
    List<Widget> activeAssetItems = [];
    if (widget.metrics.totalAssets != 0)
      activeAssetItems.add(
        _buildGridStat(
          'ACCOUNTS',
          widget.metrics.totalAssets,
          Colors.green,
          theme,
        ),
      );
    if (widget.metrics.totalInvestments != 0)
      activeAssetItems.add(
        _buildGridStat(
          'INVESTMENTS',
          widget.metrics.totalInvestments,
          Colors.green,
          theme,
        ),
      );
    if (receivables > 0)
      activeAssetItems.add(
        _buildGridStat('P2P DEBT', receivables, Colors.green, theme),
      );
    if (activeAssetItems.isEmpty)
      activeAssetItems.add(_buildGridStat('ASSETS', 0.0, Colors.green, theme));

    List<Widget> activeLiabilityItems = [];
    if (widget.metrics.totalCreditCards != 0)
      activeLiabilityItems.add(
        _buildGridStat(
          'CREDIT CARDS',
          widget.metrics.totalCreditCards,
          theme.colorScheme.error,
          theme,
        ),
      );
    if (widget.metrics.totalLoans != 0)
      activeLiabilityItems.add(
        _buildGridStat(
          'ACTIVE LOANS',
          widget.metrics.totalLoans,
          theme.colorScheme.error,
          theme,
        ),
      );
    if (payables < 0)
      activeLiabilityItems.add(
        _buildGridStat('P2P DEBT', payables, theme.colorScheme.error, theme),
      );
    if (activeLiabilityItems.isEmpty)
      activeLiabilityItems.add(
        _buildGridStat('LIABILITIES', 0.0, theme.colorScheme.error, theme),
      );

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DETAILED BREAKDOWN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: () => _toggleFlip(NetWorthCardFace.front),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.flip_to_front_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  size: 16,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          Expanded(child: _buildAdaptiveRow(activeAssetItems, theme)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          Expanded(child: _buildAdaptiveRow(activeLiabilityItems, theme)),
        ],
      ),
    );
  }

  // ===========================================================================
  // BACK FACE: SMART TREND CHART
  // ===========================================================================
  Widget _buildChartFace(ThemeData theme, bool isDark) {
    if (widget.records.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor, width: 1.0),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_graph_rounded,
                size: 32,
                color: theme.dividerColor,
              ),
              const SizedBox(height: 8),
              Text(
                'NO TREND DATA YET',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _toggleFlip(NetWorthCardFace.front),
                child: Text(
                  'GO BACK',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Prepare data chronologically
    final List<double> values = [];
    final List<DateTime> dates = [];

    for (var r in widget.records.reversed) {
      double assets =
          r.assetAccountBalance +
          r.assetSavings +
          r.assetMutualFunds +
          r.assetStocks +
          r.assetBonds +
          r.assetFixedDeposits +
          r.assetRecurringDeposits +
          r.assetP2PLending +
          r.assetOtherInvestments +
          r.assetLentDebts +
          r.assetExtraOthers;
      double liabilities =
          r.liabilityCreditCards +
          r.liabilityLoans +
          r.liabilityBorrowedDebts +
          r.liabilityExtraOthers;
      values.add(assets + liabilities);
      dates.add(r.recordedAt);
    }

    double minY = values.reduce(min);
    double maxY = values.reduce(max);
    if (minY == maxY) {
      minY -= 1000;
      maxY += 1000;
    }

    final Color trendColor = values.last >= 0
        ? Colors.green
        : theme.colorScheme.error;

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NET WORTH TREND',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: () => _toggleFlip(NetWorthCardFace.front),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.flip_to_front_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
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
              child: CustomPaint(
                painter: _NetWorthChartPainter(
                  data: values,
                  dates: dates,
                  minY: minY,
                  maxY: maxY,
                  lineColor: trendColor,
                  gradientColors: [
                    trendColor.withOpacity(isDark ? 0.3 : 0.2),
                    trendColor.withOpacity(0.0),
                  ],
                  textColor: theme.colorScheme.onSurfaceVariant,
                  gridColor: theme.dividerColor,
                  startDateText: _formatShortDate(dates.first),
                  endDateText: _formatShortDate(dates.last),
                  touchX: _touchX,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CHART PAINTER (Adapted from BalanceTrendWidget)[cite: 14]
// ===========================================================================
class _NetWorthChartPainter extends CustomPainter {
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

  _NetWorthChartPainter({
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
  bool shouldRepaint(covariant _NetWorthChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.touchX != touchX;
  }
}
