import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/currency_text.dart';
import '../providers/automation_provider.dart';
import 'automation_rule_form_page.dart';

class AutomationDashboardPage extends ConsumerWidget {
  const AutomationDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rulesAsync = ref.watch(allRecurringRulesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Automation',
        subtitle: 'RECURRING RULES',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AutomationRuleFormPage()),
          );
        },
        icon: Icons.add_rounded,
        label: 'Create',
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const PremiumEmptyState(
              title: 'No Automation Rules',
              subtitle:
                  'Set up recurring transactions to automate your logging and approvals.',
              icon: Icons.published_with_changes_rounded,
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(DesignTokens.spacingLg),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              final txColor = TransactionColors.getTypeColor(
                rule.transactionType,
                theme,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
                child: BoxySlidableCard(
                  key: ValueKey(rule.id),
                  onEdit: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AutomationRuleFormPage(existingRule: rule),
                      ),
                    );
                  },
                  onDelete: () {
                    HapticFeedback.mediumImpact();
                    ConfirmationBottomSheet.show(
                      context,
                      title: 'Delete Rule?',
                      description:
                          'Are you sure you want to stop automating "${rule.name}"?',
                      confirmText: 'DELETE',
                      isDestructive: true,
                      onConfirm: () {
                        ref
                            .read(automationActionProvider.notifier)
                            .deleteRule(rule.id);
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: txColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.autorenew_rounded,
                            color: txColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      rule.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (rule.amount != null)
                                    CurrencyText(
                                      amount: rule.amount!,
                                      amountStyle: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: txColor,
                                      ),
                                    )
                                  else
                                    Text(
                                      'VARIABLE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    size: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Next: ${DateFormat('dd MMM yyyy, HH:mm').format(rule.nextExecutionDate)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Every ${rule.repetitionInterval} ${rule.repetitionSchedule}(s)',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rule.isAutomatic
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orangeAccent.withOpacity(
                                              0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      rule.isAutomatic ? 'AUTO' : 'MANUAL',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: rule.isAutomatic
                                            ? Colors.green
                                            : Colors.orangeAccent.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
