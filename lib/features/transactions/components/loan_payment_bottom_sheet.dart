import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../providers/transaction_provider.dart';

class LoanPaymentBottomSheet extends ConsumerStatefulWidget {
  final String accountId;

  const LoanPaymentBottomSheet({Key? key, required this.accountId}) : super(key: key);

  static void show(BuildContext context, String accountId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => LoanPaymentBottomSheet(accountId: accountId),
    );
  }

  @override
  ConsumerState<LoanPaymentBottomSheet> createState() => _LoanPaymentBottomSheetState();
}

class _LoanPaymentBottomSheetState extends ConsumerState<LoanPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _principalCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _principalCtrl.dispose();
    _interestCtrl.dispose();
    _taxCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final principal = double.tryParse(_principalCtrl.text) ?? 0.0;
    final interest = double.tryParse(_interestCtrl.text) ?? 0.0;
    final tax = double.tryParse(_taxCtrl.text) ?? 0.0;

    if (principal <= 0 && interest <= 0 && tax <= 0) return;

    HapticFeedback.lightImpact();

    final success = await ref.read(transactionActionProvider.notifier).logLoanPayment(
      accountId: widget.accountId,
      principal: principal,
      interest: interest,
      tax: tax,
      date: _selectedDate,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final actionState = ref.watch(transactionActionProvider);

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
              // Drag Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              
              Text(
                'Log Loan Payment',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              
              // 1. Paying Principal
              ModernBoxyInput(
                controller: _principalCtrl,
                labelText: 'Paying Principal (₹)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v) == null ? 'Invalid number' : null;
                },
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              
              // 2. Paying Interest
              ModernBoxyInput(
                controller: _interestCtrl,
                labelText: 'Paying Interest (₹)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v) == null ? 'Invalid number' : null;
                },
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              
              // 3. Paying Tax
              ModernBoxyInput(
                controller: _taxCtrl,
                labelText: 'Paying Tax (₹)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v) == null ? 'Invalid number' : null;
                },
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              
              // Date Selector
              InkWell(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: ModernBoxyInput(
                    controller: TextEditingController(text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                    labelText: 'Payment Date',
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              
              // Optional Notes
              ModernBoxyInput(
                controller: _notesCtrl,
                labelText: 'Notes (Optional)',
                keyboardType: TextInputType.text,
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
                      onPressed: _submit,
                      label: 'Log Payment',
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