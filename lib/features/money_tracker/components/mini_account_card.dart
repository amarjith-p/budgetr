import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../../accounts/providers/loan_math_provider.dart';
import '../../accounts/providers/credit_math_provider.dart';

class MiniAccountCard extends ConsumerWidget {
  final Account account;
  final VoidCallback onTap;

  const MiniAccountCard({Key? key, required this.account, required this.onTap})
    : super(key: key);

  String _formatSubtext(double val) {
    if (val < 0) return '-₹ ${CurrencyFormatter.format(val.abs())}';
    if (val > 0) return '+₹ ${CurrencyFormatter.format(val.abs())}';
    return '₹ 0.00';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isCreditCard = account.type == 'Credit Cards';
    final isLoan = account.type == 'Loan';

    final isDebtCard = isCreditCard || isLoan;

    final bgColor = isDebtCard
        ? theme.colorScheme.primary.withOpacity(0.85)
        : theme.colorScheme.surface.withOpacity(isDark ? 0.5 : 0.8);

    final fgColor = isDebtCard
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    double rawBalance = account.balance;
    double unbilled = 0.0;
    double billed = 0.0;

    if (isLoan) {
      rawBalance = ref.watch(loanTotalOutstandingProvider(account));
    } else if (isCreditCard) {
      final metrics = ref.watch(creditCardMetricsProvider(account));
      rawBalance = metrics.totalOutstanding;
      unbilled = metrics.unbilled;
      billed = metrics.billed;
    }

    String signText = '₹ ';

    // --- FIX: RESTORED THE RUPEE SYMBOL TO THE MAIN BALANCE SIGNS ---
    if (isLoan) {
      signText = rawBalance > 0 ? '-₹ ' : (rawBalance < 0 ? '+₹ ' : '₹ ');
    } else if (isCreditCard) {
      signText = rawBalance < 0 ? '-₹ ' : (rawBalance > 0 ? '+₹ ' : '₹ ');
    } else {
      signText = rawBalance < 0 ? '-₹ ' : '₹ ';
    }

    IconData cardIcon = Icons.account_balance_wallet_rounded;
    if (isCreditCard) cardIcon = Icons.credit_card_rounded;
    if (isLoan) cardIcon = Icons.account_balance_rounded;

    return Container(
      width: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDebtCard
                        ? theme.colorScheme.onPrimary.withOpacity(0.2)
                        : theme.dividerColor.withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: fgColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              account.providerName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: fgColor.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          cardIcon,
                          size: 14,
                          color: fgColor.withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  account.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: fgColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),

                              if (isCreditCard &&
                                  (unbilled != 0 || billed != 0))
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'U: ${_formatSubtext(unbilled)} | B: ${_formatSubtext(billed)}',
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                        color: fgColor.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          flex: 5,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: CurrencyText(
                              amount: rawBalance.abs(),
                              sign: signText,
                              amountStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: fgColor,
                                letterSpacing: -0.5,
                              ),
                              symbolStyle: TextStyle(
                                fontSize: 9,
                                color: fgColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
