// lib/features/investments/components/investment_passive_income_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../providers/investment_provider.dart';
import 'passive_income_list_bottom_sheet.dart';

class InvestmentPassiveIncomeCard extends ConsumerWidget {
  final Investment investment;

  const InvestmentPassiveIncomeCard({Key? key, required this.investment})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logsAsync = ref.watch(investmentLogsStreamProvider(investment.id));
    final logs = logsAsync.asData?.value ?? [];

    // Filter and calculate total passive income
    final passiveLogs = logs
        .where((l) => l.type == 'Dividend' || l.type == 'Interest')
        .toList();
    final double totalIncome = passiveLogs.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        PassiveIncomeListBottomSheet.show(context, investment);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.redeem_rounded,
                color: Colors.amber,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PASSIVE INCOME',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CurrencyText(
                    amount: totalIncome,
                    sign: '₹ ',
                    amountStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
