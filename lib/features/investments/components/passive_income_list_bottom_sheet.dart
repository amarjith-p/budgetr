// lib/features/investments/components/passive_income_list_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/investment_provider.dart';
import 'passive_income_action_bottom_sheet.dart';

class PassiveIncomeListBottomSheet extends ConsumerWidget {
  final Investment investment;

  const PassiveIncomeListBottomSheet({Key? key, required this.investment})
    : super(key: key);

  static void show(BuildContext context, Investment investment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PassiveIncomeListBottomSheet(investment: investment),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String logId) {
    HapticFeedback.heavyImpact();
    ConfirmationBottomSheet.show(
      context,
      title: 'Delete Income Log?',
      description: 'This will permanently delete this passive income record.',
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
    final isClosed = investment.isClosed;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + DesignTokens.spacingLg,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.redeem_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passive Income',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Dividends & Interest Tracking',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!isClosed)
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            PassiveIncomeActionBottomSheet.show(
                              context,
                              investment: investment,
                              isUpdateMode: false,
                            );
                          },
                          icon: Icon(
                            Icons.add_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Add Income',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),

              Expanded(
                child: logsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (logs) {
                    final passiveLogs = logs
                        .where(
                          (l) => l.type == 'Dividend' || l.type == 'Interest',
                        )
                        .toList();
                    passiveLogs.sort(
                      (a, b) => b.date.compareTo(a.date),
                    ); // Newest first

                    if (passiveLogs.isEmpty) {
                      return Center(
                        child: Text(
                          'No passive income recorded yet.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: passiveLogs.length,
                      // --- REDUCED SPACING BETWEEN CARDS FROM 12 TO 6 ---
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final log = passiveLogs[index];
                        final isDividend = log.type == 'Dividend';
                        final icon = isDividend
                            ? Icons.pie_chart_rounded
                            : Icons.percent_rounded;
                        final color = isDividend ? Colors.indigo : Colors.teal;

                        final rowContent = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: color.withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.type,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${log.date.day.toString().padLeft(2, '0')}/${log.date.month.toString().padLeft(2, '0')}/${log.date.year}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CurrencyText(
                                amount: log.amount,
                                sign: '+₹ ',
                                amountStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                  letterSpacing: -0.5,
                                ),
                                symbolStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isClosed) return rowContent;

                        return BoxySlidableCard(
                          key: ValueKey(log.id),
                          onEdit: () {
                            HapticFeedback.lightImpact();
                            PassiveIncomeActionBottomSheet.show(
                              context,
                              investment: investment,
                              isUpdateMode: true,
                              existingLog: log,
                            );
                          },
                          onDelete: () => _confirmDelete(context, ref, log.id),
                          child: rowContent,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
