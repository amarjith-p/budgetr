import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/inline_calculator_pad.dart';
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

  final Map<TextEditingController, FocusNode> _focusNodes = {};
  TextEditingController? _activeCalcController;

  final List<String> _accountTypes = [
    'Savings Account', 'Current Account', 'Salary Account', 
    'Digital Wallets', 'Liquid Money', 'Credit Cards'
  ];

  final Map<String, List<String>> _providerGroups = {
    'Commercial Banks': [
      'Axis Bank', 'Bank of Baroda', 'Bank of India', 'Canara Bank',
      'Central Bank of India', 'Federal Bank', 'HDFC Bank', 'ICICI Bank',
      'IDFC First Bank', 'Indian Bank', 'IndusInd Bank', 'Kotak Mahindra Bank',
      'Punjab National Bank (PNB)', 'South Indian Bank', 'State Bank of India (SBI)',
      'Union Bank of India', 'Yes Bank', 'Other'
    ],
    'Small Finance Banks': [
      'AU Small Finance Bank', 'Equitas Small Finance Bank',
      'Ujjivan Small Finance Bank'
    ],
    'Digital Wallets': [
      'Airtel Payments Bank', 'Amazon Pay', 'Cred', 'Freecharge',
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

    _focusNodes[_nameCtrl] = FocusNode();
    _focusNodes[_providerCtrl] = FocusNode();
    _focusNodes[_last4Ctrl] = FocusNode();
    _focusNodes[_balanceCtrl] = FocusNode();
    _focusNodes[_limitCtrl] = FocusNode();
    _focusNodes[_billDateCtrl] = FocusNode();
    _focusNodes[_dueDateCtrl] = FocusNode();

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

    addNormalFocusListener(_nameCtrl);
    addNormalFocusListener(_last4Ctrl);
  }

  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _nameCtrl.dispose(); _providerCtrl.dispose(); _typeCtrl.dispose();
    _last4Ctrl.dispose(); _balanceCtrl.dispose(); _limitCtrl.dispose();
    _billDateCtrl.dispose(); _dueDateCtrl.dispose();
    super.dispose();
  }

  void _closeCalculatorSafely() {
    if (_activeCalcController != null) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty ? '' : BodmasCalculator.evaluate(text);
      setState(() => _activeCalcController = null);
    }
  }

  void _showTypePicker() {
    _closeCalculatorSafely();
    showModalBottomSheet(
      context: context,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: _accountTypes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_accountTypes[index], style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              setState(() {
                _typeCtrl.text = _accountTypes[index];
                _providerCtrl.clear();
              });
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  void _showProviderPicker() {
    _closeCalculatorSafely();
    final isWallet = _typeCtrl.text == 'Digital Wallets';
    final Map<String, List<String>> filteredGroups = {};

    if (isWallet) {
      filteredGroups['Digital Wallets'] = _providerGroups['Digital Wallets']!;
    } else {
      filteredGroups['Commercial Banks'] = _providerGroups['Commercial Banks']!;
      filteredGroups['Small Finance Banks'] = _providerGroups['Small Finance Banks']!;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingMd),
                child: Text('Select Provider', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final groupName = filteredGroups.keys.elementAt(index);
                    final providers = filteredGroups[groupName]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg, vertical: DesignTokens.spacingSm),
                          child: Text(
                            groupName.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...providers.map((provider) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
                          title: Text(provider, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          onTap: () {
                            setState(() => _providerCtrl.text = provider);
                            Navigator.pop(ctx);
                          },
                        )).toList(),
                        
                        if (index < filteredGroups.length - 1)
                          Divider(height: 32, color: Theme.of(context).dividerColor),
                      ],
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

  Future<void> _submit() async {
    _closeCalculatorSafely();

    if (!_formKey.currentState!.validate()) return;

    final isCC = _typeCtrl.text == 'Credit Cards';
    final isLiquid = _typeCtrl.text == 'Liquid Money';
    
    final providerName = isLiquid ? 'Cash' : _providerCtrl.text.trim();
    final last4 = isLiquid ? 'CASH' : _last4Ctrl.text.trim();

    final success = await ref.read(accountActionProvider.notifier).saveAccount(
      existingId: widget.existingAccount?.id,
      name: _nameCtrl.text.trim(),
      providerName: providerName,
      type: _typeCtrl.text,
      last4: last4,
      balance: isCC ? 0.0 : (double.tryParse(_balanceCtrl.text) ?? 0.0),
      creditLimit: isCC ? double.tryParse(_limitCtrl.text) : null,
      billDate: isCC ? int.tryParse(_billDateCtrl.text) : null,
      dueDate: isCC ? int.tryParse(_dueDateCtrl.text) : null,
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
  }

  void _handleCalcPrev() {
    if (_activeCalcController == _dueDateCtrl) _openCalculatorFor(_billDateCtrl);
    else if (_activeCalcController == _billDateCtrl) _openCalculatorFor(_limitCtrl);
    else if (_activeCalcController == _limitCtrl || _activeCalcController == _balanceCtrl) {
      _closeCalculatorSafely();
      _focusNodes[_nameCtrl]!.requestFocus(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isCC = _typeCtrl.text == 'Credit Cards';
    final isLiquid = _typeCtrl.text == 'Liquid Money';

    final showCalculator = _activeCalcController != null;

    // We completely removed the dangerous `bottomInset > 0` fallback from here.
    // FocusNode listeners perfectly manage hiding/showing the respective keyboards.

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
                                  validator: (v) => v!.isEmpty ? 'Req' : null
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
                              validator: (v) => v!.length != 4 ? 'Must be 4' : null,
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
                      validator: (v) => v!.isEmpty ? 'Req' : null, 
                      textInputAction: TextInputAction.next,
                      onTap: _closeCalculatorSafely,
                      // EXPLICITLY intercept native "Next" and jump cleanly to the calculator
                      onFieldSubmitted: (_) => _openCalculatorFor(isCC ? _limitCtrl : _balanceCtrl), 
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    if (isCC) ...[
                      ModernBoxyInput(
                        controller: _limitCtrl, 
                        focusNode: _focusNodes[_limitCtrl],
                        labelText: 'Credit Limit (₹)', 
                        readOnly: true,
                        onTap: () => _openCalculatorFor(_limitCtrl), 
                        validator: (v) => v!.isEmpty ? 'Req' : null
                      ),
                      const SizedBox(height: DesignTokens.spacingMd),
                      Row(
                        children: [
                          Expanded(child: ModernBoxyInput(controller: _billDateCtrl, focusNode: _focusNodes[_billDateCtrl], labelText: 'Bill Date (1-31)', readOnly: true, onTap: () => _openCalculatorFor(_billDateCtrl), validator: (v) => (int.tryParse(v!) ?? 0) > 31 ? 'Inv' : null)),
                          const SizedBox(width: DesignTokens.spacingMd),
                          Expanded(child: ModernBoxyInput(controller: _dueDateCtrl, focusNode: _focusNodes[_dueDateCtrl], labelText: 'Due Date (1-31)', readOnly: true, onTap: () => _openCalculatorFor(_dueDateCtrl), validator: (v) => (int.tryParse(v!) ?? 0) > 31 ? 'Inv' : null)),
                        ],
                      ),
                    ] else ...[
                      ModernBoxyInput(
                        controller: _balanceCtrl, 
                        focusNode: _focusNodes[_balanceCtrl],
                        labelText: 'Current Balance (₹)', 
                        readOnly: true,
                        onTap: () => _openCalculatorFor(_balanceCtrl), 
                        validator: (v) => v!.isEmpty ? 'Req' : null
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
              onNext: isCC && _activeCalcController != _dueDateCtrl ? _handleCalcNext : null,
              onPrevious: _handleCalcPrev,
              onSubmit: _closeCalculatorSafely,
              onClose: _closeCalculatorSafely,
            ),
        ],
      ),
    );
  }
}