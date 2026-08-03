import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/inline_calculator_pad.dart';
import '../../../core/components/global_selection_sheet.dart'; 
import '../../../core/utils/bodmas_calculator.dart';
import '../providers/account_provider.dart';

class AccountFormBottomSheet extends ConsumerStatefulWidget {
  final Account? existingAccount;
  const AccountFormBottomSheet({Key? key, this.existingAccount}) : super(key: key);

  @override
  ConsumerState<AccountFormBottomSheet> createState() => _AccountFormBottomSheetState();
}

class _AccountFormBottomSheetState extends ConsumerState<AccountFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _providerCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _last4Ctrl;
  late TextEditingController _balanceCtrl;
  late TextEditingController _limitCtrl;
  late TextEditingController _billDateCtrl;
  late TextEditingController _dueDateCtrl;

  // New Loan Controllers
  late TextEditingController _purposeCtrl;
  late TextEditingController _loanAmtCtrl;
  late TextEditingController _interestCtrl;
  late TextEditingController _tenureCtrl;
  late TextEditingController _startDateCtrl;
  late TextEditingController _emiDateCtrl;
  late TextEditingController _endDateCtrl;

  final Map<TextEditingController, FocusNode> _focusNodes = {};
  TextEditingController? _activeCalcController;

  final List<String> _accountTypes = [
    'Savings Account', 'Current Account', 'Salary Account', 
    'Digital/Payment Banks', 'Liquid Money', 'Credit Cards', 'Loan'
  ];

  final Map<String, List<String>> _providerGroups = {
    'Commercial/Foreign Banks': [
      'Axis Bank', 'Bandhan Bank', 'Bank of Baroda', 'Bank of India', 'Bank of Maharashtra', 'Canara Bank',
      'Central Bank of India', 'City Union Bank', 'CSB Bank', 'DBS Bank', 'DCB Bank', 'Deutsche Bank', 'Dhanalakshmi Bank', 'Doha Bank', 'Federal Bank', 'HSBC Bank', 'HDFC Bank', 'ICICI Bank',
      'IDBI Bank', 'IDFC First Bank', 'Indian Bank', 'Indian Overseas Bank', 'IndusInd Bank', 'Jammu & Kashmir Bank', 'Karnataka Bank', 'Karur Vysya Bank',
      'Kerala Gramin Bank', 'Kotak Mahindra Bank', 'Nainital Bank', 'Punjab & Sind Bank', 'Punjab National Bank (PNB)', 'RBL Bank', 'SBM Bank', 'South Indian Bank', 'Standard Chartered Bank', 'State Bank of India (SBI)',
      'Tamilnad Mercantile Bank', 'UCO Bank', 'Union Bank of India', 'Yes Bank', 'Other'
    ],
    'Small Finance Banks': [
      'AU Small Finance Bank', 'Capital Small Finance Bank', 'Equitas Small Finance Bank', 'ESAF Small Finance Bank', 'Jana Small Finance Bank', 'Suryoday Small Finance Bank', 'Ujjivan Small Finance Bank',
      'Slice Small Finance Bank', 'Shivalik Small Finance Bank', 'Unity Small Finance Bank', 'Utkarsh Small Finance Bank', 'Other'
    ],
    'Digital/Payment Banks': [
      'Airtel Payments Bank', 'Fino Payments Bank', 'India Post Payments Bank', 'Jio Payments Bank', 'NSDL Payments Bank', 'Amazon Pay', 'Cred', 'Freecharge',
      'Google Pay', 'Jio Payments Bank', 'MobiKwik', 'Paytm', 'PhonePe', 'Other'
    ],
  };

  @override
  void initState() {
    super.initState();
    final acc = widget.existingAccount;
    
    _nameCtrl = TextEditingController(text: acc?.name ?? '');
    _providerCtrl = TextEditingController(text: acc?.providerName ?? '');
    _typeCtrl = TextEditingController(text: acc?.type ?? 'Savings Account');
    _last4Ctrl = TextEditingController(text: acc?.last4 ?? '');
    _balanceCtrl = TextEditingController(text: acc?.balance.toString() ?? '');
    _limitCtrl = TextEditingController(text: acc?.creditLimit?.toString() ?? '');
    _billDateCtrl = TextEditingController(text: acc?.billDate?.toString() ?? '');
    _dueDateCtrl = TextEditingController(text: acc?.dueDate?.toString() ?? '');

    _purposeCtrl = TextEditingController(text: acc?.loanPurpose ?? '');
    _loanAmtCtrl = TextEditingController(text: acc?.loanPrincipal?.toString() ?? '');
    _interestCtrl = TextEditingController(text: acc?.interestRate?.toString() ?? '');
    _tenureCtrl = TextEditingController(text: acc?.tenureMonths?.toString() ?? '');
    _startDateCtrl = TextEditingController(text: acc?.loanStartDate?.toIso8601String().split('T').first ?? '');
    _emiDateCtrl = TextEditingController(text: acc?.emiDate?.toIso8601String().split('T').first ?? '');
    _endDateCtrl = TextEditingController(text: acc?.loanEndDate?.toIso8601String().split('T').first ?? '');

    _focusNodes[_nameCtrl] = FocusNode();
    _focusNodes[_providerCtrl] = FocusNode();
    _focusNodes[_last4Ctrl] = FocusNode();
    _focusNodes[_balanceCtrl] = FocusNode();
    _focusNodes[_limitCtrl] = FocusNode();
    _focusNodes[_billDateCtrl] = FocusNode();
    _focusNodes[_dueDateCtrl] = FocusNode();
    _focusNodes[_loanAmtCtrl] = FocusNode();
    _focusNodes[_interestCtrl] = FocusNode();
    _focusNodes[_purposeCtrl] = FocusNode();

    void addCalcFocusListener(TextEditingController ctrl) {
      _focusNodes[ctrl]!.addListener(() {
        if (_focusNodes[ctrl]!.hasFocus && _activeCalcController != ctrl) {
          _openCalculatorFor(ctrl);
        }
      });
    }

    void addNormalFocusListener(TextEditingController ctrl) {
      _focusNodes[ctrl]!.addListener(() {
        if (_focusNodes[ctrl]!.hasFocus && _activeCalcController != null) {
          _closeCalculatorSafely();
        }
      });
    }

    addCalcFocusListener(_balanceCtrl);
    addCalcFocusListener(_limitCtrl);
    addCalcFocusListener(_billDateCtrl);
    addCalcFocusListener(_dueDateCtrl);
    addCalcFocusListener(_loanAmtCtrl);
    addCalcFocusListener(_interestCtrl);

    addNormalFocusListener(_nameCtrl);
    addNormalFocusListener(_last4Ctrl);
    addNormalFocusListener(_purposeCtrl);

    _last4Ctrl.addListener(() {
      final text = _last4Ctrl.text;
      String numbersOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (numbersOnly.length > 4) {
        numbersOnly = numbersOnly.substring(0, 4);
      }
      if (text != numbersOnly) {
        _last4Ctrl.text = numbersOnly;
        _last4Ctrl.selection = TextSelection.collapsed(offset: numbersOnly.length);
      }
      setState(() {}); 
    });

    _billDateCtrl.addListener(() => _enforceDateLimits(_billDateCtrl));
    _dueDateCtrl.addListener(() => _enforceDateLimits(_dueDateCtrl));
  }

  void _enforceDateLimits(TextEditingController ctrl) {
    if (ctrl.text.isEmpty) return;
    final val = int.tryParse(ctrl.text);
    if (val != null) {
      if (val > 31) {
        ctrl.text = '31';
        ctrl.selection = TextSelection.collapsed(offset: 2);
      } else if (val < 1 && ctrl.text != '0') {
        ctrl.text = '1';
        ctrl.selection = TextSelection.collapsed(offset: 1);
      }
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _nameCtrl.dispose(); _providerCtrl.dispose(); _typeCtrl.dispose();
    _last4Ctrl.dispose(); _balanceCtrl.dispose(); _limitCtrl.dispose();
    _billDateCtrl.dispose(); _dueDateCtrl.dispose();
    _purposeCtrl.dispose(); _loanAmtCtrl.dispose(); _interestCtrl.dispose();
    _tenureCtrl.dispose(); _startDateCtrl.dispose(); _emiDateCtrl.dispose(); _endDateCtrl.dispose();
    super.dispose();
  }

  void _closeCalculatorSafely() {
    if (_activeCalcController != null) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty ? '' : BodmasCalculator.evaluate(text);
      setState(() => _activeCalcController = null);
    }
  }

  void _showTypePicker() async {
    _closeCalculatorSafely();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Account Type',
      items: _accountTypes,
      selectedValue: _typeCtrl.text,
    );
    
    if (selected != null && mounted) {
      setState(() {
        _typeCtrl.text = selected;
        _providerCtrl.clear();
      });
    }
  }

  void _showProviderPicker() async {
    _closeCalculatorSafely();
    final isWallet = _typeCtrl.text == 'Digital/Payment Banks';
    final Map<String, List<String>> filteredGroups = {};

    if (isWallet) {
      filteredGroups['Digital/Payment Banks'] = _providerGroups['Digital/Payment Banks']!;
    } else {
      filteredGroups['Commercial/Foreign Banks'] = _providerGroups['Commercial/Foreign Banks']!;
      filteredGroups['Small Finance Banks'] = _providerGroups['Small Finance Banks']!;
    }

    final selected = await GlobalSelectionSheet.showGrouped(
      context: context,
      title: 'Select Provider',
      groupedItems: filteredGroups,
      selectedValue: _providerCtrl.text,
    );

    if (selected != null && mounted) {
      setState(() => _providerCtrl.text = selected);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    _closeCalculatorSafely();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
    }
  }

  Future<void> _submit() async {
    _closeCalculatorSafely();
    if (!_formKey.currentState!.validate()) return;

    final isCC = _typeCtrl.text == 'Credit Cards';
    final isLiquid = _typeCtrl.text == 'Liquid Money';
    final isLoan = _typeCtrl.text == 'Loan';
    
    final providerName = isLiquid ? 'Cash' : _providerCtrl.text.trim();
    final last4 = isLiquid ? 'CASH' : _last4Ctrl.text.trim();
    
    final balance = isCC ? 0.0 : (isLoan ? (double.tryParse(_loanAmtCtrl.text) ?? 0.0) : (double.tryParse(_balanceCtrl.text) ?? 0.0));

    final success = await ref.read(accountActionProvider.notifier).saveAccount(
      existingId: widget.existingAccount?.id,
      name: _nameCtrl.text.trim(),
      providerName: providerName,
      type: _typeCtrl.text,
      last4: last4,
      balance: balance,
      creditLimit: isCC ? double.tryParse(_limitCtrl.text) : null,
      billDate: isCC ? int.tryParse(_billDateCtrl.text) : null,
      dueDate: isCC ? int.tryParse(_dueDateCtrl.text) : null,
      loanPurpose: isLoan ? _purposeCtrl.text.trim() : null,
      loanPrincipal: isLoan ? (double.tryParse(_loanAmtCtrl.text) ?? 0.0) : null,
      interestRate: isLoan ? (double.tryParse(_interestCtrl.text) ?? 0.0) : null,
      tenureMonths: isLoan ? (int.tryParse(_tenureCtrl.text) ?? 0) : null,
      emiDate: isLoan ? DateTime.tryParse(_emiDateCtrl.text) : null,
      loanStartDate: isLoan ? DateTime.tryParse(_startDateCtrl.text) : null,
      loanEndDate: isLoan ? DateTime.tryParse(_endDateCtrl.text) : null,
    );

    if (success && mounted) Navigator.pop(context);
  }

  void _openCalculatorFor(TextEditingController controller) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    if (_activeCalcController != null && _activeCalcController != controller) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty ? '' : BodmasCalculator.evaluate(text);
    }
    
    setState(() => _activeCalcController = controller);
    
    if (!_focusNodes[controller]!.hasFocus) {
      _focusNodes[controller]!.requestFocus();
    }
  }

  void _handleCalcNext() {
    if (_activeCalcController == _limitCtrl) _openCalculatorFor(_billDateCtrl);
    else if (_activeCalcController == _billDateCtrl) _openCalculatorFor(_dueDateCtrl);
    else if (_activeCalcController == _loanAmtCtrl) _openCalculatorFor(_interestCtrl);
  }

  void _handleCalcPrev() {
    if (_activeCalcController == _dueDateCtrl) _openCalculatorFor(_billDateCtrl);
    else if (_activeCalcController == _billDateCtrl) _openCalculatorFor(_limitCtrl);
    else if (_activeCalcController == _interestCtrl) _openCalculatorFor(_loanAmtCtrl);
    else if (_activeCalcController == _limitCtrl || _activeCalcController == _balanceCtrl) {
      _closeCalculatorSafely();
      _focusNodes[_nameCtrl]!.requestFocus(); 
    }
    else if (_activeCalcController == _loanAmtCtrl) {
      _closeCalculatorSafely();
      _focusNodes[_purposeCtrl]!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    final isCC = _typeCtrl.text == 'Credit Cards';
    final isLiquid = _typeCtrl.text == 'Liquid Money';
    final isLoan = _typeCtrl.text == 'Loan';
    final showCalculator = _activeCalcController != null;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: showCalculator ? DesignTokens.spacingLg : bottomInset + DesignTokens.spacingLg,
                left: DesignTokens.spacingLg, 
                right: DesignTokens.spacingLg, 
                top: DesignTokens.spacingSm,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                        decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text(widget.existingAccount == null ? 'Add Account' : 'Edit Account',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: DesignTokens.spacingLg),
                    
                    InkWell(
                      onTap: _showTypePicker,
                      child: AbsorbPointer(
                        child: ModernBoxyInput(
                          controller: _typeCtrl,
                          labelText: 'Account Type',
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),
                    
                    if (!isLiquid) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: InkWell(
                              onTap: _showProviderPicker,
                              child: AbsorbPointer(
                                child: ModernBoxyInput(
                                  controller: _providerCtrl, 
                                  focusNode: _focusNodes[_providerCtrl],
                                  labelText: 'Provider Name', 
                                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingMd),
                          Expanded(
                            flex: 4,
                            child: ModernBoxyInput(
                              controller: _last4Ctrl, 
                              focusNode: _focusNodes[_last4Ctrl],
                              labelText: 'Last 4 Digits', 
                              keyboardType: TextInputType.number,
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_last4Ctrl.text.length}/4',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _last4Ctrl.text.length == 4 
                                            ? theme.colorScheme.primary 
                                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              validator: (v) => v == null || v.length != 4 ? 'Must be 4 digits' : null,
                              textInputAction: TextInputAction.next,
                              onTap: _closeCalculatorSafely,
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spacingMd),
                    ],
                    
                    ModernBoxyInput(
                      controller: _nameCtrl, 
                      focusNode: _focusNodes[_nameCtrl],
                      labelText: 'Custom Account Name', 
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null, 
                      textInputAction: TextInputAction.next,
                      onTap: _closeCalculatorSafely,
                      onFieldSubmitted: (_) {
                        if (isCC) _openCalculatorFor(_limitCtrl);
                        else if (isLoan) _focusNodes[_purposeCtrl]!.requestFocus();
                        else _openCalculatorFor(_balanceCtrl);
                      }, 
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    if (isLoan) ...[
                      ModernBoxyInput(
                        controller: _purposeCtrl,
                        focusNode: _focusNodes[_purposeCtrl],
                        labelText: 'Purpose of Loan',
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        textInputAction: TextInputAction.next,
                        onTap: _closeCalculatorSafely,
                        onFieldSubmitted: (_) => _openCalculatorFor(_loanAmtCtrl),
                      ),
                      const SizedBox(height: DesignTokens.spacingMd),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ModernBoxyInput(
                              controller: _loanAmtCtrl,
                              focusNode: _focusNodes[_loanAmtCtrl],
                              labelText: 'Principal Amount (₹)',
                              readOnly: true,
                              onTap: () => _openCalculatorFor(_loanAmtCtrl),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingMd),
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _interestCtrl,
                              focusNode: _focusNodes[_interestCtrl],
                              labelText: 'Interest %',
                              readOnly: true,
                              onTap: () => _openCalculatorFor(_interestCtrl),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spacingMd),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _tenureCtrl,
                              labelText: 'Tenure (Months)',
                              keyboardType: TextInputType.number,
                              onTap: _closeCalculatorSafely,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingMd),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(_emiDateCtrl),
                              child: AbsorbPointer(
                                child: ModernBoxyInput(
                                  controller: _emiDateCtrl,
                                  labelText: 'EMI Start Date',
                                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spacingMd),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(_startDateCtrl),
                              child: AbsorbPointer(
                                child: ModernBoxyInput(
                                  controller: _startDateCtrl,
                                  labelText: 'Start Date',
                                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingMd),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(_endDateCtrl),
                              child: AbsorbPointer(
                                child: ModernBoxyInput(
                                  controller: _endDateCtrl,
                                  labelText: 'End Date',
                                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (isCC) ...[
                      ModernBoxyInput(
                        controller: _limitCtrl, 
                        focusNode: _focusNodes[_limitCtrl],
                        labelText: 'Credit Limit (₹)', 
                        readOnly: true,
                        onTap: () => _openCalculatorFor(_limitCtrl), 
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null
                      ),
                      const SizedBox(height: DesignTokens.spacingMd),
                      Row(
                        children: [
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _billDateCtrl, 
                              focusNode: _focusNodes[_billDateCtrl], 
                              labelText: 'Bill Date (1-31)', 
                              readOnly: true, 
                              onTap: () => _openCalculatorFor(_billDateCtrl), 
                              validator: (v) => v == null || v.isEmpty 
                                  ? 'Required' 
                                  : ((int.tryParse(v) ?? 0) < 1 || (int.tryParse(v) ?? 0) > 31 ? 'Invalid date' : null)
                            )
                          ),
                          const SizedBox(width: DesignTokens.spacingMd),
                          Expanded(
                            child: ModernBoxyInput(
                              controller: _dueDateCtrl, 
                              focusNode: _focusNodes[_dueDateCtrl], 
                              labelText: 'Due Date (1-31)', 
                              readOnly: true, 
                              onTap: () => _openCalculatorFor(_dueDateCtrl), 
                              validator: (v) => v == null || v.isEmpty 
                                  ? 'Required' 
                                  : ((int.tryParse(v) ?? 0) < 1 || (int.tryParse(v) ?? 0) > 31 ? 'Invalid date' : null)
                            )
                          ),
                        ],
                      ),
                    ] else ...[
                      ModernBoxyInput(
                        controller: _balanceCtrl, 
                        focusNode: _focusNodes[_balanceCtrl],
                        labelText: 'Current Balance (₹)', 
                        readOnly: true,
                        onTap: () => _openCalculatorFor(_balanceCtrl), 
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null
                      ),
                    ],
                    
                    const SizedBox(height: DesignTokens.spacingLg),
                    Row(
                      children: [
                        Expanded(child: ModernBoxyButton(onPressed: () => Navigator.pop(context), label: 'Cancel', isOutlined: true)),
                        const SizedBox(width: DesignTokens.spacingMd),
                        Expanded(flex: 2, child: ModernBoxyButton(onPressed: _submit, label: 'Save Account', isLoading: ref.watch(accountActionProvider).isLoading)),
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
              onNext: (isCC && _activeCalcController != _dueDateCtrl) || (isLoan && _activeCalcController != _interestCtrl) ? _handleCalcNext : null,
              onPrevious: _handleCalcPrev,
              onSubmit: _closeCalculatorSafely,
              onClose: _closeCalculatorSafely,
            ),
        ],
      ),
    );
  }
}