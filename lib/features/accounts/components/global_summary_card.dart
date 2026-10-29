// features/accounts/components/global_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';

class GlobalSummaryCard extends StatefulWidget {
  // Without Hidden accounts
  final double assets;
  final double liabilities;
  final double loans;

  // Hidden accounts
  final double hiddenAssets;
  final double hiddenLiabilities;
  final double hiddenLoans;

  // Full global total (With Hidden)
  final double totalAssets;
  final double totalLiabilities;
  final double totalLoans;

  final bool hasHidden;
  final int hiddenCount;

  const GlobalSummaryCard({
    super.key,
    required this.assets,
    required this.liabilities,
    required this.loans,
    this.hiddenAssets = 0.0,
    this.hiddenLiabilities = 0.0,
    this.hiddenLoans = 0.0,
    this.totalAssets = 0.0,
    this.totalLiabilities = 0.0,
    this.totalLoans = 0.0,
    this.hasHidden = false,
    this.hiddenCount = 0,
  });

  @override
  State<GlobalSummaryCard> createState() => _GlobalSummaryCardState();
}

class _GlobalSummaryCardState extends State<GlobalSummaryCard> {
  bool _includeAssets = true;
  bool _includeLiabilities = true;
  bool _includeLoans = true;
  bool _isExpanded = false;

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- LIABILITIES AND LOANS ARE PASSED AS NEGATIVE, SO WE ADD THEM ---
    double activeNetBalance = 0.0;
    if (_includeAssets) activeNetBalance += widget.assets;
    if (_includeLiabilities) activeNetBalance += widget.liabilities;
    if (_includeLoans) activeNetBalance += widget.loans;

    final bool showReset =
        !_includeAssets || !_includeLiabilities || !_includeLoans;

    final double visibleNet = widget.assets + widget.liabilities + widget.loans;
    final double hiddenNet =
        widget.hiddenAssets + widget.hiddenLiabilities + widget.hiddenLoans;
    final double totalNet =
        widget.totalAssets + widget.totalLiabilities + widget.totalLoans;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        DesignTokens.spacingLg,
        DesignTokens.spacingLg,
        0,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isExpanded
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.dividerColor.withValues(alpha: 0.6),
            width: _isExpanded ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: _isExpanded ? 14 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Net Balance & Toggle
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                onTap: _toggleExpanded,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side: Title and optional Hidden badge wrapped flexibly
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 3,
                              children: [
                                Text(
                                  'NET BALANCE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (widget.hasHidden)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.orange.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.visibility_off_rounded,
                                          size: 9,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${widget.hiddenCount} HIDDEN',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.orange,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Right side: Reset (when filtering) and Breakdown Toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showReset) ...[
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _includeAssets = true;
                                      _includeLiabilities = true;
                                      _includeLoans = true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.replay_rounded,
                                          size: 10,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'RESET',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: theme.colorScheme.primary,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isExpanded ? 'LESS' : 'BREAKDOWN',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      _isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Net Balance Display
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: CurrencyText(
                            key: ValueKey(activeNetBalance),
                            amount: activeNetBalance.abs(),
                            sign: activeNetBalance < 0
                                ? '- ₹ '
                                : (activeNetBalance > 0 ? '+ ₹ ' : '₹ '),
                            amountStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: activeNetBalance < 0
                                  ? theme.colorScheme.error
                                  : (activeNetBalance > 0
                                      ? Colors.green
                                      : theme.colorScheme.onSurface),
                              letterSpacing: -0.5,
                            ),
                            symbolStyle: TextStyle(
                              fontSize: 13,
                              color: (activeNetBalance < 0
                                      ? theme.colorScheme.error
                                      : (activeNetBalance > 0
                                          ? Colors.green
                                          : theme.colorScheme.onSurface))
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),

                      if (widget.hasHidden) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Excludes hidden account balances • Tap card for full breakdown',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              child: Divider(height: 1),
            ),

            // Mini Category Filter Cards
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterCard(
                      label: 'ASSETS',
                      amount: widget.assets,
                      color: Colors.green,
                      isIncluded: _includeAssets,
                      theme: theme,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _includeAssets = !_includeAssets);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildFilterCard(
                      label: 'CREDIT CARDS',
                      amount: widget.liabilities,
                      color: theme.colorScheme.error,
                      isIncluded: _includeLiabilities,
                      theme: theme,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _includeLiabilities = !_includeLiabilities);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildFilterCard(
                      label: 'LOANS',
                      amount: widget.loans,
                      color: Colors.orangeAccent.shade700,
                      isIncluded: _includeLoans,
                      theme: theme,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _includeLoans = !_includeLoans);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // EXPANDED BREAKDOWN: MOBILE-OPTIMIZED & RESPONSIVE
            AnimatedCrossFade(
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),

                  // Splitwise Category List (Clean, vertical, perfectly responsive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPLITWISE BREAKDOWN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildResponsiveCategoryTile(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Assets',
                          color: Colors.green,
                          withoutHidden: widget.assets,
                          hidden: widget.hiddenAssets,
                          withHidden: widget.totalAssets,
                          theme: theme,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildResponsiveCategoryTile(
                          icon: Icons.credit_card_rounded,
                          title: 'Credit Cards',
                          color: theme.colorScheme.error,
                          withoutHidden: widget.liabilities,
                          hidden: widget.hiddenLiabilities,
                          withHidden: widget.totalLiabilities,
                          theme: theme,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildResponsiveCategoryTile(
                          icon: Icons.account_balance_rounded,
                          title: 'Loans',
                          color: Colors.orangeAccent.shade700,
                          withoutHidden: widget.loans,
                          hidden: widget.hiddenLoans,
                          withHidden: widget.totalLoans,
                          theme: theme,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildResponsiveCategoryTile(
                          icon: Icons.calculate_rounded,
                          title: 'Net Total',
                          color: theme.colorScheme.primary,
                          withoutHidden: visibleNet,
                          hidden: hiddenNet,
                          withHidden: totalNet,
                          isHighlight: true,
                          theme: theme,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard({
    required String label,
    required double amount,
    required Color color,
    required bool isIncluded,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isIncluded ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isIncluded
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isIncluded
                  ? theme.dividerColor.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isIncluded
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 9,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: theme.colorScheme.onSurfaceVariant,
                        decoration: isIncluded
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CurrencyText(
                  amount: amount.abs(),
                  sign: amount < 0 ? '- ₹ ' : (amount > 0 ? '+ ₹ ' : '₹ '),
                  amountStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveCategoryTile({
    required IconData icon,
    required String title,
    required Color color,
    required double withoutHidden,
    required double hidden,
    required double withHidden,
    required ThemeData theme,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.35)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.2 : 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.dividerColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Category & Active (Without Hidden) Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 12, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
                      color: isHighlight
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: CurrencyText(
                  amount: withoutHidden.abs(),
                  sign: withoutHidden < 0
                      ? '-₹ '
                      : (withoutHidden > 0 ? '+₹ ' : '₹ '),
                  amountStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isHighlight ? color : theme.colorScheme.onSurface,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Bottom Row: Hidden & Total with Hidden
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hidden: ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  CurrencyText(
                    amount: hidden.abs(),
                    sign: hidden < 0 ? '-₹ ' : (hidden > 0 ? '+₹ ' : '₹ '),
                    amountStyle: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: hidden != 0 ? Colors.orange.shade700 : Colors.grey,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 8,
                      color: hidden != 0 ? Colors.orange.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'With Hidden: ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  CurrencyText(
                    amount: withHidden.abs(),
                    sign: withHidden < 0
                        ? '-₹ '
                        : (withHidden > 0 ? '+₹ ' : '₹ '),
                    amountStyle: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
