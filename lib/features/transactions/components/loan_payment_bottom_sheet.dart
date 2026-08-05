import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/inline_calculator_pad.dart';
import '../../../core/utils/bodmas_calculator.dart';
import '../providers/transaction_provider.dart';

class LoanPaymentBottomSheet extends ConsumerStatefulWidget {
  final String accountId;
  const LoanPaymentBottomSheet({Key? key, required this.accountId})
    : super(key: key);

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
  ConsumerState<LoanPaymentBottomSheet> createState() =>
      _LoanPaymentBottomSheetState();
}

class _LoanPaymentBottomSheetState
    extends ConsumerState<LoanPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _principalCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _bankChargesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _principalFocus = FocusNode();
  final _interestFocus = FocusNode();
  final _taxFocus = FocusNode();
  final _bankChargesFocus = FocusNode();
  final _notesFocus = FocusNode();

  TextEditingController? _activeCalcController;
  DateTime _selectedDate = DateTime.now();
  bool _showBankCharges = false;

  @override
  void initState() {
    super.initState();
    _setupCalcListener(_principalCtrl, _principalFocus);
    _setupCalcListener(_interestCtrl, _interestFocus);
    _setupCalcListener(_taxCtrl, _taxFocus);
    _setupCalcListener(_bankChargesCtrl, _bankChargesFocus);

    _notesFocus.addListener(() {
      if (_notesFocus.hasFocus) {
        _closeCalculatorSafely(dropFocus: false);
      }
    });
  }

  void _setupCalcListener(TextEditingController ctrl, FocusNode node) {
    node.addListener(() {
      if (node.hasFocus && _activeCalcController != ctrl) {
        _openCalculatorFor(ctrl, node);
      }
    });
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _interestCtrl.dispose();
    _taxCtrl.dispose();
    _bankChargesCtrl.dispose();
    _notesCtrl.dispose();

    _principalFocus.dispose();
    _interestFocus.dispose();
    _taxFocus.dispose();
    _bankChargesFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _openCalculatorFor(
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    if (_activeCalcController != null && _activeCalcController != controller) {
      _closeCalculatorSafely(reopen: true);
    }
    setState(() => _activeCalcController = controller);
    if (!focusNode.hasFocus) focusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.context != null && mounted) {
        Scrollable.ensureVisible(
          focusNode.context!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  void _closeCalculatorSafely({bool reopen = false, bool dropFocus = true}) {
    if (_activeCalcController != null) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty
          ? ''
          : BodmasCalculator.evaluate(text);
      if (!reopen) {
        setState(() => _activeCalcController = null);
        if (dropFocus) {
          FocusScope.of(context).unfocus();
        }
      }
    }
  }

  void _handleCalcNext() {
    if (_activeCalcController == _principalCtrl) {
      _openCalculatorFor(_interestCtrl, _interestFocus);
    } else if (_activeCalcController == _interestCtrl) {
      _openCalculatorFor(_taxCtrl, _taxFocus);
    } else if (_activeCalcController == _taxCtrl) {
      if (_showBankCharges) {
        _openCalculatorFor(_bankChargesCtrl, _bankChargesFocus);
      } else {
        _closeCalculatorSafely(dropFocus: false);
        _notesFocus.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    } else if (_activeCalcController == _bankChargesCtrl) {
      _closeCalculatorSafely(dropFocus: false);
      _notesFocus.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  void _handleCalcPrev() {
    if (_activeCalcController == _bankChargesCtrl)
      _openCalculatorFor(_taxCtrl, _taxFocus);
    else if (_activeCalcController == _taxCtrl)
      _openCalculatorFor(_interestCtrl, _interestFocus);
    else if (_activeCalcController == _interestCtrl)
      _openCalculatorFor(_principalCtrl, _principalFocus);
  }

  Future<void> _pickDate() async {
    _closeCalculatorSafely();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        // Preserves the existing time component instead of resetting to 12 AM (00:00:00)
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
          _selectedDate.second,
        );
      });
    }
  }

  Future<void> _submit() async {
    _closeCalculatorSafely();
    if (!_formKey.currentState!.validate()) return;

    final principal =
        double.tryParse(BodmasCalculator.evaluate(_principalCtrl.text)) ?? 0.0;
    final interest =
        double.tryParse(BodmasCalculator.evaluate(_interestCtrl.text)) ?? 0.0;
    final tax =
        double.tryParse(BodmasCalculator.evaluate(_taxCtrl.text)) ?? 0.0;
    final bankCharges =
        double.tryParse(BodmasCalculator.evaluate(_bankChargesCtrl.text)) ??
        0.0;

    if (principal <= 0) return;

    HapticFeedback.lightImpact();
    final success = await ref
        .read(transactionActionProvider.notifier)
        .logLoanPayment(
          accountId: widget.accountId,
          principal: principal,
          interest: interest,
          tax: tax,
          bankCharges: bankCharges,
          date: _selectedDate,
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
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
    final showCalculator = _activeCalcController != null;

    final String formattedDate =
        "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: showCalculator
                    ? DesignTokens.spacingLg
                    : bottomInset + DesignTokens.spacingLg,
                left: DesignTokens.spacingLg,
                right: DesignTokens.spacingLg,
                top: DesignTokens.spacingSm,
              ),
              child: Form(
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
                      'Log Loan Payment',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingLg),

                    // --- MANDATORY PRINCIPAL FIELD ---
                    ModernBoxyInput(
                      controller: _principalCtrl,
                      focusNode: _principalFocus,
                      readOnly: true,
                      onTap: () =>
                          _openCalculatorFor(_principalCtrl, _principalFocus),
                      labelText: 'Paying Principal (₹)',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final parsed = double.tryParse(
                          BodmasCalculator.evaluate(v),
                        );
                        if (parsed == null || parsed <= 0)
                          return 'Must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    ModernBoxyInput(
                      controller: _interestCtrl,
                      focusNode: _interestFocus,
                      readOnly: true,
                      onTap: () =>
                          _openCalculatorFor(_interestCtrl, _interestFocus),
                      labelText: 'Paying Interest (₹)',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return double.tryParse(BodmasCalculator.evaluate(v)) ==
                                null
                            ? 'Invalid math'
                            : null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    ModernBoxyInput(
                      controller: _taxCtrl,
                      focusNode: _taxFocus,
                      readOnly: true,
                      onTap: () => _openCalculatorFor(_taxCtrl, _taxFocus),
                      labelText: 'Paying Tax (₹)',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return double.tryParse(BodmasCalculator.evaluate(v)) ==
                                null
                            ? 'Invalid math'
                            : null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    // --- MODERN ANIMATED BANK CHARGES TOGGLE ---
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _showBankCharges
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.spacingMd,
                        ),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showBankCharges = true);

                            Future.delayed(
                              const Duration(milliseconds: 350),
                              () {
                                if (mounted && _showBankCharges) {
                                  _openCalculatorFor(
                                    _bankChargesCtrl,
                                    _bankChargesFocus,
                                  );
                                }
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(
                                0.08,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ADD BANK / PROCESSING FEES',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.spacingMd,
                        ),
                        child: ModernBoxyInput(
                          controller: _bankChargesCtrl,
                          focusNode: _bankChargesFocus,
                          readOnly: true,
                          onTap: () => _openCalculatorFor(
                            _bankChargesCtrl,
                            _bankChargesFocus,
                          ),
                          labelText: 'Paying Bank Charges (₹)',
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            tooltip: 'Remove',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _bankChargesCtrl.clear();
                              if (_activeCalcController == _bankChargesCtrl)
                                _closeCalculatorSafely();
                              setState(() => _showBankCharges = false);
                            },
                          ),
                          validator: (v) {
                            if (!_showBankCharges) return null;
                            if (v == null || v.trim().isEmpty) return null;
                            return double.tryParse(
                                      BodmasCalculator.evaluate(v),
                                    ) ==
                                    null
                                ? 'Invalid math'
                                : null;
                          },
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: ModernBoxyInput(
                          controller: TextEditingController(
                            text: formattedDate,
                          ),
                          labelText: 'Payment Date',
                          suffixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    ModernBoxyInput(
                      controller: _notesCtrl,
                      focusNode: _notesFocus,
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
          ),

          if (showCalculator)
            InlineCalculatorPad(
              key: ValueKey(_activeCalcController.hashCode),
              controller: _activeCalcController!,
              onNext: _handleCalcNext,
              onPrevious: _activeCalcController != _principalCtrl
                  ? _handleCalcPrev
                  : null,
              onSubmit: () => _closeCalculatorSafely(dropFocus: true),
              onClose: () => _closeCalculatorSafely(dropFocus: true),
            ),
        ],
      ),
    );
  }
}
