// lib/features/automation/components/manual_rule_confirmation_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/currency_text.dart';
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
      isDismissible: false,
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

  bool _isLoading = false;

  Future<void> _executeRule(double finalAmount, dynamic rule) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.selectionClick();

    final success = await ref
        .read(automationActionProvider.notifier)
        .executeManualRule(
          rule: rule,
          finalAmount: finalAmount,
          executionDate: DateTime.parse(widget.expectedDateStr),
          notificationId: widget.notificationId,
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _isLoading = false);
        final errorState = ref.read(automationActionProvider);

        // --- NEW: Display the error message in a SnackBar ---
        if (errorState.hasError) {
          final errMsg = errorState.error.toString().replaceAll(
            'Exception: ',
            '',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errMsg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          // Pop the sheet so the user isn't stuck on a stale transaction
          if (errMsg.contains('already been executed')) {
            Navigator.pop(context);
          }
        }
      }
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
        error: (e, st) =>
            const Center(child: Text('Rule not found or deleted.')),
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
                    enabled: !_isLoading,
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
                        onPressed: _isLoading
                            ? () {}
                            : () => Navigator.pop(context),
                        label: 'Cancel',
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      flex: 2,
                      child: ModernBoxyButton(
                        onPressed: _isLoading
                            ? () {}
                            : () {
                                double finalAmount = isVariable
                                    ? double.parse(_amountCtrl.text)
                                    : rule.amount!;
                                _executeRule(finalAmount, rule);
                              },
                        label: _isLoading ? 'PROCESSING...' : 'CONFIRM & LOG',
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
