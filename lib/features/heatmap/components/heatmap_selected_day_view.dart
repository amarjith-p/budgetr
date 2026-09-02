// lib/features/heatmap/components/heatmap_selected_day_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/components/currency_text.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../transactions/components/transaction_card.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/views/transaction_form_page.dart';
import '../providers/heatmap_selected_date_provider.dart';
import '../providers/heatmap_daily_spend_provider.dart';

class HeatmapSelectedDayView extends ConsumerWidget {
  const HeatmapSelectedDayView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(heatmapSelectedDateProvider);
    if (selectedDate == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final allTxs = ref.watch(allTransactionsProvider).asData?.value ?? [];

    final days = ref.read(heatmapDailySpendProvider);
    final summary = days
        .where(
          (d) =>
              d.date.year == selectedDate.year &&
              d.date.month == selectedDate.month &&
              d.date.day == selectedDate.day,
        )
        .firstOrNull;

    final dateTxs = allTxs.where((txData) {
      final d = txData.transaction.date;
      return d.year == selectedDate.year &&
          d.month == selectedDate.month &&
          d.day == selectedDate.day;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignTokens.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedDate.day} ${DateTimeConstants.fullMonths[selectedDate.month - 1]} ${selectedDate.year}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (summary != null)
                    Row(
                      children: [
                        // --- FIX: Removed sign: '' so the default Rupee symbol displays ---
                        CurrencyText(
                          amount: summary.totalSpend,
                          amountStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          ' / ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // --- FIX: Native CurrencyText wrapper for the target ---
                        CurrencyText(
                          amount: summary.dailyTarget,
                          amountStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          symbolStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' Target',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: theme.colorScheme.primary,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TransactionFormPage(initialDate: selectedDate),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          if (dateTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No transactions on this date.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dateTxs.length,
              itemBuilder: (context, index) {
                final txData = dateTxs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TransactionCard(
                    data: txData,
                    currentAccountId: txData.transaction.accountId,
                    isGlobalView: true,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
