// lib/features/investments/components/investment_summary_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/utils/xirr_calculator.dart';
import '../../../core/utils/drawdown_calculator.dart';
import '../providers/investment_provider.dart';
import 'investment_details_bottom_sheet.dart';
import 'investment_performance_chart.dart';
import 'investment_projection_card.dart';

enum CardFace { front, chart, projection }

class InvestmentSummaryCard extends ConsumerStatefulWidget {
  final Investment investment;

  const InvestmentSummaryCard({Key? key, required this.investment})
    : super(key: key);

  @override
  ConsumerState<InvestmentSummaryCard> createState() =>
      _InvestmentSummaryCardState();
}

class _InvestmentSummaryCardState extends ConsumerState<InvestmentSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _animation;

  CardFace _currentFace = CardFace.front;
  CardFace _backFaceTarget = CardFace.chart;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip(CardFace target) {
    HapticFeedback.lightImpact();
    if (_currentFace == CardFace.front) {
      // Flipping from Front to Back
      setState(() {
        _backFaceTarget = target;
        _currentFace = target;
      });
      _flipController.forward();
    } else {
      // Flipping from Back to Front
      setState(() => _currentFace = CardFace.front);
      _flipController.reverse();
    }
  }

  void _openDetails(BuildContext context) {
    HapticFeedback.lightImpact();
    InvestmentDetailsBottomSheet.show(context, widget.investment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logsAsync = ref.watch(
      investmentLogsStreamProvider(widget.investment.id),
    );
    final logs = logsAsync.asData?.value ?? [];

    double netInvestmentsInLogs = 0.0;
    for (final log in logs) {
      if (log.type == 'Deposit') netInvestmentsInLogs += log.amount;
      if (log.type == 'Withdrawal') netInvestmentsInLogs -= log.amount;
    }
    double startBal = widget.investment.initialAmount - netInvestmentsInLogs;
    if (startBal < 0) startBal = 0.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final isFront = angle <= pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isFront
              ? _buildFront(context, startBal, logs, theme, isDark)
              : Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _backFaceTarget == CardFace.chart
                      ? _buildChartBack(startBal, logs, theme, isDark)
                      : InvestmentProjectionCard(
                          investment: widget.investment,
                          logs: logs,
                          onFlip: () => _toggleFlip(CardFace.front),
                        ),
                ),
        );
      },
    );
  }

  // --- THE FRONT OF THE CARD ---
  Widget _buildFront(
    BuildContext context,
    double startBal,
    List<InvestmentLog> logs,
    ThemeData theme,
    bool isDark,
  ) {
    List<CashFlow> cfs = [];
    cfs.add(CashFlow(-startBal, widget.investment.startDate));
    for (final log in logs) {
      if (log.type == 'Deposit') cfs.add(CashFlow(-log.amount, log.date));
      if (log.type == 'Withdrawal') cfs.add(CashFlow(log.amount, log.date));
    }
    cfs.add(CashFlow(widget.investment.currentValue, DateTime.now()));

    double xirr = XirrCalculator.calculate(cfs) * 100;
    if (xirr.isNaN || xirr.isInfinite) xirr = 0.0;
    if (xirr > 999) xirr = 999.0;
    if (xirr < -999) xirr = -999.0;

    double maxDrawdown = DrawdownCalculator.calculate(startBal, logs);

    final double invested = widget.investment.initialAmount < 0
        ? 0.0
        : widget.investment.initialAmount;
    final double current = widget.investment.currentValue;
    final double gainLoss = current - invested;
    final double absReturnPct = invested > 0
        ? (gainLoss / invested) * 100
        : 0.0;
    final bool isPositive = gainLoss >= 0;

    String faviconUrl = '';
    if (widget.investment.providerUrl != null &&
        widget.investment.providerUrl!.isNotEmpty) {
      String cleanUrl = widget.investment.providerUrl!
          .replaceAll('http://', '')
          .replaceAll('https://', '')
          .split('/')
          .first;
      faviconUrl = 'https://www.google.com/s2/favicons?domain=$cleanUrl&sz=128';
    }

    final Color returnColor = isPositive
        ? Colors.green
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FIX 1: Wrap pill in Expanded + Align to strictly prevent long text overflows[cite: 14] ---
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (faviconUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Image.network(
                              faviconUrl,
                              width: 12,
                              height: 12,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.business_rounded,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Added Flexible + Ellipsis so super long provider names just truncate cleanly
                        Flexible(
                          child: Text(
                            widget.investment.provider.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // --- SMART ICONS: AI, CHART, DETAILS ---
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _toggleFlip(CardFace.projection),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _toggleFlip(CardFace.chart),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.show_chart_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _openDetails(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.open_in_new_rounded,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.4,
                        ),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CURRENT VALUE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CurrencyText(
                    amount: current.abs(),
                    sign: current < 0 ? '-₹ ' : '₹ ',
                    amountStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1.0,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: returnColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 10,
                      color: returnColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${absReturnPct.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: returnColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- FIX 2: Added FittedBox to all sub-headers to prevent flex overflow[cite: 14] ---
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'INVESTED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: CurrencyText(
                          amount: invested.abs(),
                          sign: invested < 0 ? '-₹ ' : '₹ ',
                          amountStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          symbolStyle: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 16,
                  thickness: 1,
                  color: theme.dividerColor,
                ),

                Expanded(
                  flex: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isPositive ? 'TOTAL GAIN' : 'TOTAL LOSS',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: CurrencyText(
                          amount: gainLoss.abs(),
                          sign: isPositive ? '+₹ ' : '-₹ ',
                          amountStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: returnColor,
                            letterSpacing: -0.5,
                          ),
                          symbolStyle: TextStyle(
                            fontSize: 10,
                            color: returnColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 16,
                  thickness: 1,
                  color: theme.dividerColor,
                ),

                Expanded(
                  flex: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'XIRR',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.insights_rounded,
                              size: 8,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${xirr > 0 ? '+' : ''}${xirr.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: xirr >= 0
                                ? Colors.green
                                : theme.colorScheme.error,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 16,
                  thickness: 1,
                  color: theme.dividerColor,
                ),

                Expanded(
                  flex: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MAX DD',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.show_chart_rounded,
                              size: 8,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          maxDrawdown == 0.0
                              ? '0.0%'
                              : '${maxDrawdown.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: maxDrawdown < 0
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
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
  }

  // Wraps the Chart Component to maintain sizing consistency
  Widget _buildChartBack(
    double startBal,
    List<InvestmentLog> logs,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InvestmentPerformanceChart(
        investment: widget.investment,
        logs: logs,
        startBal: startBal,
        onFlip: () => _toggleFlip(CardFace.front),
      ),
    );
  }
}
