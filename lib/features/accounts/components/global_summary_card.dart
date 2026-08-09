// features/accounts/components/global_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';

class GlobalSummaryCard extends StatefulWidget {
  final double assets;
  final double liabilities;
  final double loans;

  const GlobalSummaryCard({
    Key? key,
    required this.assets,
    required this.liabilities,
    required this.loans,
  }) : super(key: key);

  @override
  State<GlobalSummaryCard> createState() => _GlobalSummaryCardState();
}

class _GlobalSummaryCardState extends State<GlobalSummaryCard> {
  bool _includeAssets = true;
  bool _includeLiabilities = true;
  bool _includeLoans = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- FIXED: LIABILITIES AND LOANS ARE PASSED AS NEGATIVE, SO WE ADD THEM ---
    double activeNetBalance = 0.0;
    if (_includeAssets) activeNetBalance += widget.assets;
    if (_includeLiabilities) activeNetBalance += widget.liabilities;
    if (_includeLoans) activeNetBalance += widget.loans;

    // Show the reset button only if something is unchecked
    final bool showReset =
        !_includeAssets || !_includeLiabilities || !_includeLoans;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        DesignTokens.spacingLg,
        DesignTokens.spacingLg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                  'NET BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // --- NEW: RESET BUTTON ---
                if (showReset)
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 10,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'RESET',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: activeNetBalance < 0
                        ? theme.colorScheme.error
                        : (activeNetBalance > 0
                              ? Colors.green
                              : theme.colorScheme.onSurface),
                    letterSpacing: -0.5,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 12,
                    color:
                        (activeNetBalance < 0
                                ? theme.colorScheme.error
                                : (activeNetBalance > 0
                                      ? Colors.green
                                      : theme.colorScheme.onSurface))
                            .withOpacity(0.7),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(height: 1),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  _buildInteractiveMiniStat(
                    'ASSETS',
                    widget.assets,
                    Colors.green,
                    theme,
                    _includeAssets,
                    () => setState(() {
                      HapticFeedback.selectionClick();
                      _includeAssets = !_includeAssets;
                    }),
                  ),
                  VerticalDivider(
                    width: 16,
                    thickness: 1,
                    color: theme.dividerColor,
                  ),
                  _buildInteractiveMiniStat(
                    'LIABILITIES',
                    widget.liabilities,
                    theme.colorScheme.error,
                    theme,
                    _includeLiabilities,
                    () => setState(() {
                      HapticFeedback.selectionClick();
                      _includeLiabilities = !_includeLiabilities;
                    }),
                  ),
                  VerticalDivider(
                    width: 16,
                    thickness: 1,
                    color: theme.dividerColor,
                  ),
                  _buildInteractiveMiniStat(
                    'LOANS',
                    widget.loans,
                    Colors.orangeAccent.shade700,
                    theme,
                    _includeLoans,
                    () => setState(() {
                      HapticFeedback.selectionClick();
                      _includeLoans = !_includeLoans;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMiniStat(
    String label,
    double amount,
    Color color,
    ThemeData theme,
    bool isIncluded,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isIncluded ? 1.0 : 0.35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncluded
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
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
                  // --- FIXED: RUPEE SYMBOL & PROPER NEGATIVE SIGNS ---
                  sign: amount < 0 ? '- ₹ ' : (amount > 0 ? '+ ₹ ' : '₹ '),
                  amountStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 9,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
