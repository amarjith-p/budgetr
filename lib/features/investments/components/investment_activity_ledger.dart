import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/investment_provider.dart';
import 'investment_action_bottom_sheet.dart';

class _EnrichedLog {
  final InvestmentLog log;
  final double delta;
  final double balanceAfter;
  _EnrichedLog(this.log, this.delta, this.balanceAfter);
}

class InvestmentActivityLedger extends ConsumerWidget {
  final Investment investment;

  const InvestmentActivityLedger({Key? key, required this.investment})
    : super(key: key);

  void _confirmDelete(BuildContext context, WidgetRef ref, String logId) {
    HapticFeedback.heavyImpact();
    ConfirmationBottomSheet.show(
      context,
      title: 'Delete Transaction?',
      description:
          'Are you sure? Your investment balance will be mathematically recalculated.',
      confirmText: 'DELETE',
      isDestructive: true,
      onConfirm: () => ref
          .read(investmentActionProvider.notifier)
          .deleteInvestmentActivity(logId, investment.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(investmentLogsStreamProvider(investment.id));
    final bool isClosed = investment.isClosed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVITY LEDGER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isClosed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'READ ONLY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
        logsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (allLogs) {
            final logs = allLogs
                .where((l) => l.type != 'Dividend' && l.type != 'Interest')
                .toList();
            if (logs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No activity logged yet.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            double netInvestmentsInLogs = 0.0;
            for (final log in logs) {
              if (log.type == 'Deposit') netInvestmentsInLogs += log.amount;
              if (log.type == 'Withdrawal') netInvestmentsInLogs -= log.amount;
            }

            double startBal = investment.initialAmount - netInvestmentsInLogs;
            if (startBal < 0) startBal = 0.0;

            final sortedLogs = List<InvestmentLog>.from(logs)
              ..sort((a, b) => a.date.compareTo(b.date));

            double runningBalance = startBal;
            final enrichedLogs = <_EnrichedLog>[];

            for (final log in sortedLogs) {
              double delta = 0.0;
              if (log.type == 'Deposit') {
                delta = log.amount;
                runningBalance += delta;
              } else if (log.type == 'Withdrawal') {
                delta = -log.amount;
                runningBalance += delta;
              } else if (log.type == 'Update') {
                delta = log.amount - runningBalance;
                runningBalance = log.amount;
              }
              enrichedLogs.insert(0, _EnrichedLog(log, delta, runningBalance));
            }

            return Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor, width: 1.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: enrichedLogs.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final enriched = entry.value;
                  final isLast = index == enrichedLogs.length - 1;

                  final log = enriched.log;
                  final delta = enriched.delta;
                  final balance = enriched.balanceAfter;

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

                  Widget logRow = Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: mainColor.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(icon, color: mainColor, size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 55,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.type == 'Update'
                                    ? 'Value Updated'
                                    : log.type,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMM yyyy').format(log.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 45,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 11,
                                      color: deltaColor,
                                    ),
                                    const SizedBox(width: 4),
                                    CurrencyText(
                                      amount: balance.abs(),
                                      sign: balance < 0 ? '-₹ ' : '₹ ',
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
                      ],
                    ),
                  );

                  return Column(
                    children: [
                      isClosed
                          ? logRow
                          : Slidable(
                              key: ValueKey(log.id),
                              startActionPane: ActionPane(
                                motion: const StretchMotion(),
                                extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) {
                                      HapticFeedback.lightImpact();
                                      InvestmentActionBottomSheet.show(
                                        context,
                                        investment: investment,
                                        isUpdateMode: log.type == 'Update',
                                        existingLog: log,
                                      );
                                    },
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                  ),
                                ],
                              ),
                              endActionPane: ActionPane(
                                motion: const StretchMotion(),
                                extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) =>
                                        _confirmDelete(context, ref, log.id),
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_outline_rounded,
                                    label: 'Delete',
                                  ),
                                ],
                              ),
                              child: logRow,
                            ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: theme.dividerColor,
                          indent: 64,
                        ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
