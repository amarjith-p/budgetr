// lib/features/transactions/components/records_smart_summary_card.dart
import 'package:flutter/material.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/theme/transaction_colors.dart';
import '../providers/transaction_filter_provider.dart';

class RecordsSmartSummaryCard extends StatelessWidget {
  final List<RecordItem> searchedRecords;

  const RecordsSmartSummaryCard({Key? key, required this.searchedRecords})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double totalIn = 0.0;
    double totalOut = 0.0;
    int countIn = 0;
    int countOut = 0;

    for (var record in searchedRecords) {
      final tx = record.data.transaction;
      final perspective = record.perspectiveAccountId;

      bool isMoneyLeaving = tx.type == 'Expense';
      if (tx.type == 'Transfer') {
        if (tx.toAccountId == 'EXTERNAL_IN') {
          isMoneyLeaving = false;
        } else if (tx.toAccountId == 'EXTERNAL_OUT') {
          isMoneyLeaving = true;
        } else {
          isMoneyLeaving = perspective == tx.accountId;
        }
      } else if (tx.type == 'Income') {
        isMoneyLeaving = false;
      }

      if (isMoneyLeaving) {
        totalOut += tx.amount;
        countOut++;
      } else {
        totalIn += tx.amount;
        countIn++;
      }
    }

    final netFlow = totalIn - totalOut;
    final netSign = netFlow < -0.01 ? '-  ' : (netFlow > 0.01 ? '+  ' : '  ');
    final netColor = netFlow < -0.01
        ? TransactionColors.expense(theme)
        : (netFlow > 0.01
              ? TransactionColors.income(theme)
              : theme.colorScheme.onSurface);

    final labelStyle = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: theme.colorScheme.onSurfaceVariant,
    );

    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      letterSpacing: -0.5,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
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
          Text(
            'FILTERED NET CASH FLOW',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurrencyText(
              amount: netFlow.abs(),
              sign: netSign,
              amountStyle: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: netColor,
                letterSpacing: -0.5,
              ),
              symbolStyle: TextStyle(
                fontSize: 14,
                color: netColor.withOpacity(0.7),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 12,
                            color: TransactionColors.income(theme),
                          ),
                          const SizedBox(width: 4),
                          Text('MONEY IN', style: labelStyle),
                        ],
                      ),
                      const SizedBox(height: 6),
                      CurrencyText(
                        amount: totalIn,
                        sign: '',
                        amountStyle: valueStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$countIn Record${countIn == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 12,
                            color: TransactionColors.expense(theme),
                          ),
                          const SizedBox(width: 4),
                          Text('MONEY OUT', style: labelStyle),
                        ],
                      ),
                      const SizedBox(height: 6),
                      CurrencyText(
                        amount: totalOut,
                        sign: '',
                        amountStyle: valueStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$countOut Record${countOut == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
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
}
