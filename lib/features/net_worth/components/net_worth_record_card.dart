import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/net_worth_record_provider.dart';

class NetWorthRecordCard extends ConsumerWidget {
  final NetWorthRecord record;

  const NetWorthRecordCard({super.key, required this.record});

  // ... inside NetWorthRecordCard ...

  Widget _buildDetailRow(
    String label,
    double amount,
    Color color,
    ThemeData theme, {
    bool isLiability = false,
  }) {
    if (amount == 0) return const SizedBox.shrink();

    final displaySign = isLiability ? '-₹ ' : (amount < 0 ? '-₹ ' : '₹ ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: CurrencyText(
                amount: amount.abs(),
                sign: displaySign,
                amountStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.2,
                ),
                symbolStyle: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final double totalAssets =
        record.assetAccountBalance +
        record.assetSavings +
        record.assetMutualFunds +
        record.assetStocks +
        record.assetBonds +
        record.assetFixedDeposits +
        record.assetRecurringDeposits +
        record.assetP2PLending +
        record.assetOtherInvestments +
        record.assetLentDebts +
        record.assetExtraOthers;
    final double totalLiabilities =
        record.liabilityCreditCards +
        record.liabilityLoans +
        record.liabilityBorrowedDebts +
        record.liabilityExtraOthers;

    final double netWorth = totalAssets + totalLiabilities;
    final isPositive = netWorth >= 0;
    final netColor = isPositive ? Colors.green : theme.colorScheme.error;
    final netSign = isPositive ? '₹ ' : '-₹ ';

    final String formattedDate = DateFormat(
      'MMM yyyy',
    ).format(record.recordedAt);
    final String exactDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(record.recordedAt);

    final bool hasCashflow =
        record.cashflowTotalIncome != 0 || record.cashflowTotalExpense != 0;

    return BoxySlidableCard(
      // ... existing swipe actions ...
      key: ValueKey(record.id),
      onDelete: () {
        HapticFeedback.heavyImpact();
        ConfirmationBottomSheet.show(
          context,
          title: 'Delete Snapshot?',
          description:
              'Are you sure you want to permanently delete this net worth reconciliation record?',
          confirmText: 'DELETE',
          isDestructive: true,
          onConfirm: () => ref
              .read(netWorthRecordActionProvider.notifier)
              .deleteRecord(record.id),
        );
      },
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // ... existing tile header ...
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: netColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.spacingXs),
              border: Border.all(color: netColor.withOpacity(0.2)),
            ),
            child: Icon(Icons.analytics_rounded, color: netColor, size: 22),
          ),
          title: Text(
            '$formattedDate Snapshot',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              exactDate,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CurrencyText(
                amount: netWorth.abs(),
                sign: netSign,
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
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    size: 10,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${(totalAssets / 1000).toStringAsFixed(1)}k',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 10,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${(totalLiabilities.abs() / 1000).toStringAsFixed(1)}k',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                    if (record.notes != null && record.notes!.isNotEmpty) ...[
                      Text(
                        '"${record.notes}"',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Text(
                      'ASSETS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Cash & Others',
                      record.assetAccountBalance,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'Savings Account',
                      record.assetSavings,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'Mutual Funds',
                      record.assetMutualFunds,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'Stocks',
                      record.assetStocks,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'Bonds',
                      record.assetBonds,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'Fixed Deposits',
                      record.assetFixedDeposits,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'RDs',
                      record.assetRecurringDeposits,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'P2P Lending',
                      record.assetP2PLending,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'Lent Debt',
                      record.assetLentDebts,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'Other',
                      record.assetOtherInvestments,
                      Colors.green,
                      theme,
                    ),
                    _buildDetailRow(
                      'Extra',
                      record.assetExtraOthers,
                      Colors.green,
                      theme,
                    ),

                    const SizedBox(height: 4),
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'LIABILITIES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Credit Cards',
                      record.liabilityCreditCards,
                      theme.colorScheme.error,
                      theme,
                      isLiability: true,
                    ),
                    _buildDetailRow(
                      'Loans',
                      record.liabilityLoans,
                      theme.colorScheme.error,
                      theme,
                      isLiability: true,
                    ),
                    _buildDetailRow(
                      'Borrowed',
                      record.liabilityBorrowedDebts,
                      theme.colorScheme.error,
                      theme,
                      isLiability: true,
                    ),
                    _buildDetailRow(
                      'Extra',
                      record.liabilityExtraOthers,
                      theme.colorScheme.error,
                      theme,
                      isLiability: true,
                    ),

                    if (hasCashflow) ...[
                      const SizedBox(height: 4),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'MONTHLY CASHFLOW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Total Income',
                        record.cashflowTotalIncome,
                        Colors.blueAccent,
                        theme,
                      ),
                      _buildDetailRow(
                        'Total Expense',
                        record.cashflowTotalExpense,
                        theme.colorScheme.error,
                        theme,
                        isLiability: true,
                      ),
                      _buildDetailRow(
                        'Budgeted Income',
                        record.cashflowBudgetedIncome,
                        Colors.blueAccent,
                        theme,
                      ),
                      _buildDetailRow(
                        'Budgeted Expense',
                        record.cashflowBudgetedExpense,
                        theme.colorScheme.error,
                        theme,
                        isLiability: true,
                      ),
                      _buildDetailRow(
                        'Non-Calc Income',
                        record.cashflowNonCalcIncome,
                        theme.colorScheme.onSurface,
                        theme,
                      ),
                      _buildDetailRow(
                        'Non-Calc Expense',
                        record.cashflowNonCalcExpense,
                        theme.colorScheme.onSurface,
                        theme,
                      ),
                      _buildDetailRow(
                        'Out of Bucket',
                        record.cashflowOutOfBucket,
                        theme.colorScheme.error,
                        theme,
                        isLiability: true,
                      ),

                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Net Cashflow',
                        record.cashflowNetTotal,
                        record.cashflowNetTotal >= 0
                            ? Colors.green
                            : theme.colorScheme.error,
                        theme,
                      ),
                      _buildDetailRow(
                        'Net Budgeted',
                        record.cashflowNetBudgeted,
                        record.cashflowNetBudgeted >= 0
                            ? Colors.green
                            : theme.colorScheme.error,
                        theme,
                      ),
                    ],

                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Historical balances are locked to this timestamp.',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
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
// ...