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
  
  final _principalFocus = FocusNode();
  final _interestFocus = FocusNode();
  final _taxFocus = FocusNode();
  final _notesFocus = FocusNode();

  TextEditingController? _activeCalcController;
  DateTime _selectedDate = DateTime.now();   
  
  @override
  void initState() {
    super.initState();
    _setupCalcListener(_principalCtrl, _principalFocus);
    _setupCalcListener(_interestCtrl, _interestFocus);
    _setupCalcListener(_taxCtrl, _taxFocus);

    // FIX: Hide calculator safely WITHOUT dropping focus from the notes field
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
    _notesCtrl.dispose();     
    
    _principalFocus.dispose();
    _interestFocus.dispose();
    _taxFocus.dispose();
    _notesFocus.dispose();
    super.dispose();   
  }   

  // --- SMART CALCULATOR ENGINE ---
  void _openCalculatorFor(TextEditingController controller, FocusNode focusNode) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    if (_activeCalcController != null && _activeCalcController != controller) {
      _closeCalculatorSafely(reopen: true);
    }
    
    setState(() => _activeCalcController = controller);
    if (!focusNode.hasFocus) focusNode.requestFocus();
    
    // Smooth Auto-Scroll to keep input visible above the pad
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

  // FIX: Added `dropFocus` parameter to intelligently handle keyboard handoffs
  void _closeCalculatorSafely({bool reopen = false, bool dropFocus = true}) {
    if (_activeCalcController != null) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty ? '' : BodmasCalculator.evaluate(text);
      if (!reopen) {
        setState(() => _activeCalcController = null);
        if (dropFocus) {
          FocusScope.of(context).unfocus();
        }
      }
    }
  }

  // FIX: Routes focus to the Notes field and opens system keyboard automatically
  void _handleCalcNext() {
    if (_activeCalcController == _principalCtrl) {
      _openCalculatorFor(_interestCtrl, _interestFocus);
    } else if (_activeCalcController == _interestCtrl) {
      _openCalculatorFor(_taxCtrl, _taxFocus);
    } else if (_activeCalcController == _taxCtrl) {
      _closeCalculatorSafely(dropFocus: false);
      _notesFocus.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  void _handleCalcPrev() {
    if (_activeCalcController == _taxCtrl) _openCalculatorFor(_interestCtrl, _interestFocus);
    else if (_activeCalcController == _interestCtrl) _openCalculatorFor(_principalCtrl, _principalFocus);
  }

  Future<void> _pickDate() async {     
    _closeCalculatorSafely(); // Drops focus automatically so the dialog opens cleanly
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
    _closeCalculatorSafely();
    if (!_formKey.currentState!.validate()) return;     
    
    // Evaluate math formulas before submission
    final principal = double.tryParse(BodmasCalculator.evaluate(_principalCtrl.text)) ?? 0.0;     
    final interest = double.tryParse(BodmasCalculator.evaluate(_interestCtrl.text)) ?? 0.0;     
    final tax = double.tryParse(BodmasCalculator.evaluate(_taxCtrl.text)) ?? 0.0;     
    
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
    final showCalculator = _activeCalcController != null;

    // FIX: Formats the Date into strictly padded dd/mm/yyyy
    final String formattedDate = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";

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
                      focusNode: _principalFocus,
                      readOnly: true, // Prevents system keyboard
                      onTap: () => _openCalculatorFor(_principalCtrl, _principalFocus),
                      labelText: 'Paying Principal (₹)',                 
                      validator: (v) {                   
                        if (v == null || v.trim().isEmpty) return null;                   
                        return double.tryParse(BodmasCalculator.evaluate(v)) == null ? 'Invalid math' : null;                 
                      },               
                    ),               
                    const SizedBox(height: DesignTokens.spacingMd),                              
                    
                    // 2. Paying Interest               
                    ModernBoxyInput(                 
                      controller: _interestCtrl,                 
                      focusNode: _interestFocus,
                      readOnly: true, // Prevents system keyboard
                      onTap: () => _openCalculatorFor(_interestCtrl, _interestFocus),
                      labelText: 'Paying Interest (₹)',                 
                      validator: (v) {                   
                        if (v == null || v.trim().isEmpty) return null;                   
                        return double.tryParse(BodmasCalculator.evaluate(v)) == null ? 'Invalid math' : null;                 
                      },               
                    ),               
                    const SizedBox(height: DesignTokens.spacingMd),                              
                    
                    // 3. Paying Tax               
                    ModernBoxyInput(                 
                      controller: _taxCtrl,                 
                      focusNode: _taxFocus,
                      readOnly: true, // Prevents system keyboard
                      onTap: () => _openCalculatorFor(_taxCtrl, _taxFocus),
                      labelText: 'Paying Tax (₹)',                 
                      validator: (v) {                   
                        if (v == null || v.trim().isEmpty) return null;                   
                        return double.tryParse(BodmasCalculator.evaluate(v)) == null ? 'Invalid math' : null;                 
                      },               
                    ),               
                    const SizedBox(height: DesignTokens.spacingMd),                              
                    
                    // Date Selector               
                    InkWell(                 
                      onTap: _pickDate,                 
                      child: AbsorbPointer(                   
                        child: ModernBoxyInput(                           
                          controller: TextEditingController(text: formattedDate),                     
                          labelText: 'Payment Date',                     
                          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),                   
                        ),                 
                      ),               
                    ),               
                    const SizedBox(height: DesignTokens.spacingMd),                              
                    
                    // Optional Notes               
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
          
          // --- INLINE CALCULATOR PAD ---
          if (showCalculator)
            InlineCalculatorPad(
              key: ValueKey(_activeCalcController.hashCode), 
              controller: _activeCalcController!, 
              onNext: _handleCalcNext, // Always handles transition intelligently
              onPrevious: _activeCalcController != _principalCtrl ? _handleCalcPrev : null,
              onSubmit: () => _closeCalculatorSafely(dropFocus: true),
              onClose: () => _closeCalculatorSafely(dropFocus: true),
            ),
        ],
      ),
    );   
  }
}