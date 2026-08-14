import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/currency_text.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../notifications/providers/in_app_notification_provider.dart';
import '../providers/automation_provider.dart';

class ManualRuleConfirmationSheet extends ConsumerStatefulWidget {
  final String ruleId;
  final String expectedDateStr;
  final String notificationId;

  const ManualRuleConfirmationSheet({
    Key? key,
    required this.ruleId,
    required this.expectedDateStr,
    required this.notificationId,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String ruleId,
    required String expectedDateStr,
    required String notificationId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => ManualRuleConfirmationSheet(
        ruleId: ruleId,
        expectedDateStr: expectedDateStr,
        notificationId: notificationId,
      ),
    );
  }

  @override
  ConsumerState<ManualRuleConfirmationSheet> createState() =>
      _ManualRuleConfirmationSheetState();
}

class _ManualRuleConfirmationSheetState
    extends ConsumerState<ManualRuleConfirmationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  Future<void> _executeRule(double finalAmount, dynamic rule) async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.selectionClick();

    // 1. Log the Transaction
    final success = await ref
        .read(transactionActionProvider.notifier)
        .saveTransaction(
          type: rule.transactionType,
          amount: finalAmount,
          date: DateTime.parse(widget.expectedDateStr),
          accountId: rule.accountId,
          toAccountId: rule.toAccountId,
          categoryId: rule.categoryId,
          categoryName: rule.categoryName,
          categoryIcon: rule.categoryIcon,
          subCategory: rule.subCategory,
          bucketId: rule.bucketId,
          bucketName: rule.bucketName,
          notes: 'Manually confirmed from ${rule.name}',
        );

    if (success && mounted) {
      // 2. Mark Notification as Read
      await ref
          .read(inAppNotificationActionProvider.notifier)
          .markAsRead(widget.notificationId);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final ruleAsync = ref.watch(singleRecurringRuleProvider(widget.ruleId));

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + DesignTokens.spacingLg,
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: DesignTokens.spacingSm,
      ),
      child: ruleAsync.when(
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Center(child: Text('Rule not found or deleted.')),
        data: (rule) {
          final isVariable = rule.amount == null;

          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(
                      bottom: DesignTokens.spacingLg,
                    ),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Confirm Execution',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule.name,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                if (isVariable) ...[
                  ModernBoxyInput(
                    controller: _amountCtrl,
                    labelText: 'Enter Variable Amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null || double.parse(v) <= 0)
                        return 'Invalid amount';
                      return null;
                    },
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'FIXED AMOUNT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CurrencyText(
                          amount: rule.amount!,
                          amountStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ModernBoxyButton(
                        onPressed: () => Navigator.pop(context),
                        label: 'Cancel',
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      flex: 2,
                      child: ModernBoxyButton(
                        onPressed: () {
                          double finalAmount = isVariable
                              ? double.parse(_amountCtrl.text)
                              : rule.amount!;
                          _executeRule(finalAmount, rule);
                        },
                        label: 'CONFIRM & LOG',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
