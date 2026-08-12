// lib/features/investments/components/global_investment_summary_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/utils/xirr_calculator.dart';
import '../../../core/utils/drawdown_calculator.dart';
import '../providers/investment_provider.dart';
import 'investment_performance_chart.dart';
import 'investment_projection_card.dart';

enum CardFace { front, chart, projection }

class GlobalInvestmentSummaryCard extends ConsumerStatefulWidget {
  final List<Investment> investments;
  const GlobalInvestmentSummaryCard({Key? key, required this.investments})
    : super(key: key);

  @override
  ConsumerState<GlobalInvestmentSummaryCard> createState() =>
      _GlobalInvestmentSummaryCardState();
}

class _GlobalInvestmentSummaryCardState
    extends ConsumerState<GlobalInvestmentSummaryCard>
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
      setState(() {
        _backFaceTarget = target;
        _currentFace = target;
      });
      _flipController.forward();
    } else {
      setState(() => _currentFace = CardFace.front);
      _flipController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allLogsAsync = ref.watch(allInvestmentLogsStreamProvider);
    final allLogs = allLogsAsync.asData?.value ?? [];

    double totalCurrent = 0.0;
    double totalInvested = 0.0;

    // --- NEW: Profit/Loss Counters ---
    int profitableCount = 0;
    int lossCount = 0;

    DateTime earliestDate = DateTime.now();

    if (widget.investments.isNotEmpty) {
      earliestDate = widget.investments
          .map((e) => e.startDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    }

    double globalDay0Bal = 0.0;
    List<InvestmentLog> globalLogs = [];

    for (var inv in widget.investments) {
      totalCurrent += inv.currentValue;
      totalInvested += max(0.0, inv.initialAmount);

      // Tally Profitable vs Loss-making investments
      if (inv.currentValue >= inv.initialAmount) {
        profitableCount++;
      } else {
        lossCount++;
      }

      final invLogs = allLogs.where((l) => l.investmentId == inv.id).toList();
      double netLogs = 0.0;
      for (var l in invLogs) {
        if (l.type == 'Deposit') netLogs += l.amount;
        if (l.type == 'Withdrawal') netLogs -= l.amount;
      }
      double startBal = max(0.0, inv.initialAmount - netLogs);

      if (inv.startDate.difference(earliestDate).inDays == 0) {
        globalDay0Bal += startBal;
      } else {
        globalLogs.add(
          InvestmentLog(
            id: 'sync_${inv.id}',
            investmentId: 'GLOBAL',
            type: 'Deposit',
            amount: startBal,
            date: inv.startDate,
          ),
        );
      }
      globalLogs.addAll(invLogs);
    }

    final dummyGlobalInvestment = Investment(
      id: 'GLOBAL',
      name: 'Global Portfolio',
      type: 'ALL',
      provider: 'PORTFOLIO',
      initialAmount: totalInvested,
      currentValue: totalCurrent,
      startDate: earliestDate,
      specialTag: null,
      providerUrl: null,
      isClosed: false,
    );

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
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  // Pass the new counts into the front builder
                  child: _buildFront(
                    context,
                    globalDay0Bal,
                    globalLogs,
                    totalInvested,
                    totalCurrent,
                    earliestDate,
                    theme,
                    isDark,
                    profitableCount,
                    lossCount,
                  ),
                )
              : Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _backFaceTarget == CardFace.chart
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(
                                  isDark ? 0.15 : 0.2,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InvestmentPerformanceChart(
                            investment: dummyGlobalInvestment,
                            logs: globalLogs,
                            startBal: globalDay0Bal,
                            onFlip: () => _toggleFlip(CardFace.front),
                          ),
                        )
                      : InvestmentProjectionCard(
                          investment: dummyGlobalInvestment,
                          logs: globalLogs,
                          onFlip: () => _toggleFlip(CardFace.front),
                        ),
                ),
        );
      },
    );
  }

  Widget _buildFront(
    BuildContext context,
    double globalDay0Bal,
    List<InvestmentLog> globalLogs,
    double totalInvested,
    double totalCurrent,
    DateTime earliestDate,
    ThemeData theme,
    bool isDark,
    int profitableCount, // Received count
    int lossCount, // Received count
  ) {
    List<CashFlow> cfs = [CashFlow(-globalDay0Bal, earliestDate)];
    for (final log in globalLogs) {
      if (log.type == 'Deposit') cfs.add(CashFlow(-log.amount, log.date));
      if (log.type == 'Withdrawal') cfs.add(CashFlow(log.amount, log.date));
    }
    cfs.add(CashFlow(totalCurrent, DateTime.now()));

    double xirr = XirrCalculator.calculate(cfs) * 100;
    if (xirr.isNaN || xirr.isInfinite) xirr = 0.0;
    if (xirr > 999) xirr = 999.0;
    if (xirr < -999) xirr = -999.0;

    double maxDrawdown = DrawdownCalculator.calculate(
      globalDay0Bal,
      globalLogs,
    );

    final double gainLoss = totalCurrent - totalInvested;
    final double absReturnPct = totalInvested > 0
        ? (gainLoss / totalInvested) * 100
        : 0.0;
    final bool isPositive = gainLoss >= 0;
    final Color returnColor = isPositive
        ? Colors.green
        : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                      Icon(
                        Icons.language_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GLOBAL PORTFOLIO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // --- NEW: Minimal Profitable / Non-Profitable Pill ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(isDark ? 0.3 : 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 11,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$profitableCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.trending_down_rounded,
                        size: 11,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$lossCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'TOTAL ASSET VALUE',
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
                  amount: totalCurrent.abs(),
                  sign: totalCurrent < 0 ? '-₹ ' : '₹ ',
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
                    Text(
                      'INVESTED',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CurrencyText(
                        amount: totalInvested.abs(),
                        sign: totalInvested < 0 ? '-₹ ' : '₹ ',
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
                    Text(
                      isPositive ? 'TOTAL GAIN' : 'TOTAL LOSS',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurfaceVariant,
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
                    Row(
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
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ],
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
                    Row(
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
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ],
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
    );
  }
}
