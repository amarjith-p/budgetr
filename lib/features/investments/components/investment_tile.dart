// lib/features/investments/components/investment_tile.dart
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';

class InvestmentTile extends StatelessWidget {
  final Investment investment;
  final VoidCallback onTap;

  const InvestmentTile({
    Key? key,
    required this.investment,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- FIXED: Removed > 0 mask ---
    final double invested = investment.initialAmount;
    final double current = investment.currentValue;
    final double returnAmt = current - invested;
    final double returnPct = invested > 0 ? (returnAmt / invested) * 100 : 0.0;
    final bool isPositive = returnAmt >= 0;

    String faviconUrl = '';
    if (investment.providerUrl != null && investment.providerUrl!.isNotEmpty) {
      String cleanUrl = investment.providerUrl!
          .replaceAll('http://', '')
          .replaceAll('https://', '')
          .split('/')
          .first;
      faviconUrl = 'https://www.google.com/s2/favicons?domain=$cleanUrl&sz=128';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: faviconUrl.isNotEmpty
                      ? Image.network(
                          faviconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Icon(
                            Icons.trending_up_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.trending_up_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 8,
                        color: isPositive
                            ? Colors.green
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${returnPct.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: isPositive
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                investment.name,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CurrencyText(
                    amount: current.abs(),
                    sign: current < 0 ? '-₹ ' : '₹ ',
                    amountStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'INV: ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      CurrencyText(
                        amount: invested.abs(),
                        sign: invested < 0 ? '-₹ ' : '₹ ',
                        amountStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        symbolStyle: TextStyle(
                          fontSize: 8,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
