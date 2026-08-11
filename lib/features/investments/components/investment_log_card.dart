// lib/features/investments/components/investment_log_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/database/app_database.dart';
import '../providers/investment_provider.dart';
import 'investment_action_bottom_sheet.dart';

class InvestmentLogCard extends ConsumerWidget {
  final InvestmentLog log;
  final Investment investment;
  final double closingBalance;
  final double delta;

  const InvestmentLogCard({
    Key? key,
    required this.log,
    required this.investment,
    required this.closingBalance,
    required this.delta,
  }) : super(key: key);

  void _handleEdit(BuildContext context) {
    HapticFeedback.lightImpact();
    InvestmentActionBottomSheet.show(
      context,
      investment: investment,
      isUpdateMode: log.type == 'Update',
      existingLog: log,
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    ConfirmationBottomSheet.show(
      context,
      title: 'Delete Log?',
      description:
          'This will perfectly recalculate your balance timeline. Proceed?',
      confirmText: 'DELETE',
      isDestructive: true,
      onConfirm: () => ref
          .read(investmentActionProvider.notifier)
          .deleteInvestmentActivity(log.id, investment.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    IconData icon;
    Color mainColor;
    String mainSign = '';

    if (log.type == 'Deposit') {
      icon = Icons.south_west_rounded;
      mainColor = Colors.green;
      mainSign = '+₹ ';
    } else if (log.type == 'Withdrawal') {
      icon = Icons.north_east_rounded;
      mainColor = theme.colorScheme.error;
      mainSign = '-₹ ';
    } else {
      icon = Icons.sync_rounded;
      mainColor = theme.colorScheme.primary;
      mainSign = '₹ ';
    }

    final bool isPositiveDelta = delta >= 0;
    final Color deltaColor = isPositiveDelta
        ? Colors.green
        : theme.colorScheme.error;
    final String expandedDate =
        '${log.date.day.toString().padLeft(2, '0')} ${DateTimeConstants.fullMonths[log.date.month - 1]} ${log.date.year}, ${DateTimeConstants.shortDays[log.date.weekday - 1]}';

    return BoxySlidableCard(
      key: ValueKey(log.id),
      onEdit: () => _handleEdit(context),
      onDelete: () => _handleDelete(context, ref),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 6.0,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.spacingXs),
              border: Border.all(color: mainColor.withOpacity(0.2)),
            ),
            child: Icon(icon, color: mainColor, size: 22),
          ),
          title: Text(
            log.type == 'Update' ? 'Market Update' : log.type,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              '${log.date.day.toString().padLeft(2, '0')} ${DateTimeConstants.shortMonths[log.date.month - 1]}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.35,
            ), // Forces shrinking if too large
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Transaction Amount (Regular Color, Largest)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: CurrencyText(
                    amount: log.amount.abs(),
                    sign: mainSign,
                    amountStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // 2. Resulting Balance (Medium)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 10,
                        color: deltaColor,
                      ),
                      const SizedBox(width: 4),
                      CurrencyText(
                        amount: closingBalance.abs(),
                        sign: closingBalance < 0 ? '-₹ ' : '₹ ',
                        amountStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: deltaColor,
                        ),
                        symbolStyle: TextStyle(
                          fontSize: 10,
                          color: deltaColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // 3. Change Delta (Smallest)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveDelta
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 9,
                        color: deltaColor,
                      ),
                      const SizedBox(width: 4),
                      CurrencyText(
                        amount: delta.abs(),
                        sign: delta < 0 ? '-₹ ' : '+₹ ',
                        amountStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: deltaColor,
                        ),
                        symbolStyle: TextStyle(
                          fontSize: 8,
                          color: deltaColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            expandedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
