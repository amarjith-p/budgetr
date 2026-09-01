import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../providers/investment_provider.dart';

class InvestmentCloseBottomSheet extends ConsumerStatefulWidget {
  final Investment investment;

  const InvestmentCloseBottomSheet({Key? key, required this.investment})
    : super(key: key);

  static void show(BuildContext context, Investment investment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InvestmentCloseBottomSheet(investment: investment),
    );
  }

  @override
  ConsumerState<InvestmentCloseBottomSheet> createState() =>
      _InvestmentCloseBottomSheetState();
}

class _InvestmentCloseBottomSheetState
    extends ConsumerState<InvestmentCloseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _reasonCtrl;

  DateTime _closeDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.investment.currentValue.toStringAsFixed(2),
    );
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _closeDate,
      firstDate: widget.investment.startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(
        () => _closeDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _closeDate.hour,
          _closeDate.minute,
          _closeDate.second,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount < 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.selectionClick();
    final success = await ref
        .read(investmentActionProvider.notifier)
        .closeInvestment(
          investment: widget.investment,
          finalValue: amount,
          reason: _reasonCtrl.text.trim(),
          date: _closeDate,
        );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionState = ref.watch(investmentActionProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + DesignTokens.spacingLg,
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Close Investment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'This action is permanent.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ModernBoxyInput(
                controller: _amountCtrl,
                labelText: 'Final Current Value (₹) *',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ModernBoxyInput(
                controller: _reasonCtrl,
                labelText: 'Reason for closing *',
                hintText: 'e.g., Goal achieved, Reinvesting, Poor performance',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: ModernBoxyInput(
                    controller: TextEditingController(
                      text: DateFormat('dd MMM yyyy').format(_closeDate),
                    ),
                    labelText: 'Date of Closure',
                    suffixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ModernBoxyButton(
                      onPressed: () => Navigator.pop(context),
                      label: 'CANCEL',
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ModernBoxyButton(
                      onPressed: _submit,
                      label: 'CONFIRM CLOSURE',
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      isLoading: actionState.isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
