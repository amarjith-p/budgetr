import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';

class InterestPayableBottomSheet extends StatefulWidget {
  final double currentAmount;
  final bool isCustom;
  
  const InterestPayableBottomSheet({Key? key, required this.currentAmount, required this.isCustom}) : super(key: key);

  static Future<double?> show(BuildContext context, double currentAmount, bool isCustom) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => InterestPayableBottomSheet(currentAmount: currentAmount, isCustom: isCustom),
    );
  }

  @override
  State<InterestPayableBottomSheet> createState() => _InterestPayableBottomSheetState();
}

class _InterestPayableBottomSheetState extends State<InterestPayableBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.currentAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount != null && amount >= 0) {
      Navigator.pop(context, amount);
    }
  }

  void _resetToAuto() {
    Navigator.pop(context, -1.0); // -1.0 acts as the sentinel reset signal
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + DesignTokens.spacingLg,
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: DesignTokens.spacingSm,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Interest Payable',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  if (widget.isCustom)
                    TextButton(
                      onPressed: _resetToAuto,
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      child: const Text('RESET TO AUTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Override the auto-calculated EMI amount or reset back to formula calculation.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: DesignTokens.spacingLg),
              
              ModernBoxyInput(
                controller: _amountCtrl,
                labelText: 'Total Interest Amount (₹)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                onFieldSubmitted: (_) => _apply(),
              ),
              
              const SizedBox(height: DesignTokens.spacingLg),
              
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
                      onPressed: _apply,
                      label: 'Save Amount',
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