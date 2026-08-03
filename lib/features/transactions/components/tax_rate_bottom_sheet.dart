import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';

class TaxRateBottomSheet extends StatefulWidget {
  const TaxRateBottomSheet({Key? key}) : super(key: key);

  static Future<double?> show(BuildContext context) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => const TaxRateBottomSheet(),
    );
  }

  @override
  State<TaxRateBottomSheet> createState() => _TaxRateBottomSheetState();
}

class _TaxRateBottomSheetState extends State<TaxRateBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _taxCtrl;

  @override
  void initState() {
    super.initState();
    _taxCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _taxCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    final rate = double.tryParse(_taxCtrl.text);
    if (rate != null && rate >= 0) {
      Navigator.pop(context, rate);
    }
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
              // --- APP STANDARD DRAG HANDLE ---
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              
              // --- APP STANDARD TYPOGRAPHY ---
              Text(
                'Calculate Tax',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              
              ModernBoxyInput(
                controller: _taxCtrl,
                labelText: 'Tax Rate (%)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffixIcon: const Icon(Icons.percent_rounded, size: 18),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                onFieldSubmitted: (_) => _apply(),
              ),
              
              const SizedBox(height: DesignTokens.spacingLg),
              
              // --- APP STANDARD TWIN ACTION BUTTONS ---
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
                      label: 'Apply Tax',
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