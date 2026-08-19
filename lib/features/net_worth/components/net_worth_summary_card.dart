import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/database/app_database.dart';
import '../providers/net_worth_provider.dart';

class NetWorthSummaryCard extends StatefulWidget {
  final NetWorthMetrics metrics;
  final NetWorthRecord? latestRecord;

  const NetWorthSummaryCard({
    super.key,
    required this.metrics,
    this.latestRecord,
  });

  @override
  State<NetWorthSummaryCard> createState() => _NetWorthSummaryCardState();
}

class _NetWorthSummaryCardState extends State<NetWorthSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

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

  void _toggleCard() {
    HapticFeedback.lightImpact();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  // --- BASE STAT BUILDER (No expanded wrapper yet) ---
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
  // Distributes the items evenly. 3 items = 33% each. 2 items = 50% each.
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
          child: InkWell(
            onTap: _toggleCard,
            borderRadius: BorderRadius.circular(16.0),
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
                      child: _buildBackFace(
                        theme,
                        isDark,
                        receivables,
                        payables,
                      ),
                    ),
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
    if (widget.latestRecord != null) {
      final r = widget.latestRecord!;
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
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TAP FOR BREAKDOWN',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(
                Icons.flip_to_back_rounded,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BACK FACE: Adaptive Smart Grid
  // ===========================================================================
  Widget _buildBackFace(
    ThemeData theme,
    bool isDark,
    double receivables,
    double payables,
  ) {
    // Dynamically compile active asset items
    List<Widget> activeAssetItems = [];
    if (widget.metrics.totalAssets != 0) {
      activeAssetItems.add(
        _buildGridStat(
          'ACCOUNTS',
          widget.metrics.totalAssets,
          Colors.green,
          theme,
        ),
      );
    }
    if (widget.metrics.totalInvestments != 0) {
      activeAssetItems.add(
        _buildGridStat(
          'INVESTMENTS',
          widget.metrics.totalInvestments,
          Colors.green,
          theme,
        ),
      );
    }
    if (receivables > 0) {
      activeAssetItems.add(
        _buildGridStat('P2P DEBT', receivables, Colors.green, theme),
      );
    }
    // Fallback if completely empty
    if (activeAssetItems.isEmpty) {
      activeAssetItems.add(_buildGridStat('ASSETS', 0.0, Colors.green, theme));
    }

    // Dynamically compile active liability items
    List<Widget> activeLiabilityItems = [];
    if (widget.metrics.totalCreditCards != 0) {
      activeLiabilityItems.add(
        _buildGridStat(
          'CREDIT CARDS',
          widget.metrics.totalCreditCards,
          theme.colorScheme.error,
          theme,
        ),
      );
    }
    if (widget.metrics.totalLoans != 0) {
      activeLiabilityItems.add(
        _buildGridStat(
          'ACTIVE LOANS',
          widget.metrics.totalLoans,
          theme.colorScheme.error,
          theme,
        ),
      );
    }
    if (payables < 0) {
      activeLiabilityItems.add(
        _buildGridStat('P2P DEBT', payables, theme.colorScheme.error, theme),
      );
    }
    // Fallback if completely empty
    if (activeLiabilityItems.isEmpty) {
      activeLiabilityItems.add(
        _buildGridStat('LIABILITIES', 0.0, theme.colorScheme.error, theme),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.flip_to_front_rounded,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                size: 14,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),

          // --- ADAPTIVE ASSETS ROW ---
          Expanded(child: _buildAdaptiveRow(activeAssetItems, theme)),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),

          // --- ADAPTIVE LIABILITIES ROW ---
          Expanded(child: _buildAdaptiveRow(activeLiabilityItems, theme)),
        ],
      ),
    );
  }
}
