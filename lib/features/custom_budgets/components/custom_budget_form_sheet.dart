// features/custom_budgets/components/custom_budget_form_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/inline_calculator_pad.dart';
import '../../../core/components/global_selection_sheet.dart'; 
import '../../../core/utils/bodmas_calculator.dart';
import '../../accounts/providers/account_provider.dart';
import '../../category_manager/providers/category_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/custom_budget_provider.dart';

class CustomBudgetFormSheet extends ConsumerStatefulWidget {
  final CustomBudget? existingBudget;

  const CustomBudgetFormSheet({Key? key, this.existingBudget}) : super(key: key);

  @override
  ConsumerState<CustomBudgetFormSheet> createState() => _CustomBudgetFormSheetState();
}

class _CustomBudgetFormSheetState extends ConsumerState<CustomBudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _timeframeCtrl;
  late TextEditingController _customDateCtrl;
  
  late TextEditingController _categoryCtrl;
  late TextEditingController _subCategoryCtrl;
  late TextEditingController _bucketCtrl;
  late TextEditingController _accountCtrl;

  final Map<TextEditingController, FocusNode> _focusNodes = {};
  TextEditingController? _activeCalcController;

  final List<String> _timeFrames = ['Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom'];
  
  DateTime? _customStart;
  DateTime? _customEnd;

  String? _selectedCategoryId;
  String? _selectedSubCategory;
  int? _selectedBucketId;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBudget;
    
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _amountCtrl = TextEditingController(text: b?.amountLimit.toStringAsFixed(2) ?? '');
    _timeframeCtrl = TextEditingController(text: b?.timeFrame ?? 'Monthly');
    _customDateCtrl = TextEditingController();
    
    _categoryCtrl = TextEditingController();
    _subCategoryCtrl = TextEditingController(text: b?.subCategory ?? '');
    _bucketCtrl = TextEditingController();
    _accountCtrl = TextEditingController();

    if (b != null) {
      _customStart = b.startDate;
      _customEnd = b.endDate;
      if (b.timeFrame == 'Custom') {
        _customDateCtrl.text = '${b.startDate.day} ${DateTimeConstants.shortMonths[b.startDate.month - 1]} - ${b.endDate.day} ${DateTimeConstants.shortMonths[b.endDate.month - 1]}';
      }
      _selectedCategoryId = b.categoryId;
      _selectedSubCategory = b.subCategory;
      _selectedBucketId = b.bucketId;
      _selectedAccountId = b.accountId;
    }

    _focusNodes[_nameCtrl] = FocusNode();
    _focusNodes[_amountCtrl] = FocusNode();

    _focusNodes[_amountCtrl]!.addListener(() {
      if (_focusNodes[_amountCtrl]!.hasFocus && _activeCalcController != _amountCtrl) {
        _openCalculatorFor(_amountCtrl);
      }
    });

    _focusNodes[_nameCtrl]!.addListener(() {
      if (_focusNodes[_nameCtrl]!.hasFocus && _activeCalcController != null) {
        _closeCalculatorSafely();
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (b != null) {
        final categories = ref.read(categoriesStreamProvider).asData?.value ?? [];
        final buckets = ref.read(bucketsStreamProvider).asData?.value ?? [];
        final accounts = ref.read(accountsStreamProvider).asData?.value ?? [];
        
        if (b.categoryId != null) {
          _categoryCtrl.text = categories.where((c) => c.id == b.categoryId).firstOrNull?.name ?? '';
        }
        if (b.bucketId != null) {
          _bucketCtrl.text = buckets.where((bk) => bk.id == b.bucketId).firstOrNull?.name ?? '';
        }
        if (b.accountId != null) {
          _accountCtrl.text = accounts.where((a) => a.id == b.accountId).firstOrNull?.name ?? '';
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _nameCtrl.dispose(); _amountCtrl.dispose(); _timeframeCtrl.dispose();
    _customDateCtrl.dispose(); _categoryCtrl.dispose(); _subCategoryCtrl.dispose();
    _bucketCtrl.dispose(); _accountCtrl.dispose();
    super.dispose();
  }

  void _closeCalculatorSafely() {
    if (_activeCalcController != null) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty ? '' : BodmasCalculator.evaluate(text);
      setState(() => _activeCalcController = null);
    }
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

  void _showTimeframePicker() async {
    _closeCalculatorSafely();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Timeframe',
      items: _timeFrames,
      selectedValue: _timeframeCtrl.text,
    );
    
    if (selected != null && mounted) {
      setState(() {
        _timeframeCtrl.text = selected;
        if (selected != 'Custom') {
          _customDateCtrl.clear();
          _customStart = null;
          _customEnd = null;
        }
      });
      if (selected == 'Custom') _pickDateRange();
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: Theme.of(context).colorScheme.primary),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _customDateCtrl.text = '${_customStart!.day} ${DateTimeConstants.shortMonths[_customStart!.month - 1]} - ${_customEnd!.day} ${DateTimeConstants.shortMonths[_customEnd!.month - 1]}';
      });
    } else if (_timeframeCtrl.text == 'Custom' && _customStart == null) {
      setState(() => _timeframeCtrl.text = 'Monthly');
    }
  }

  void _showCategoryPicker() async {
    _closeCalculatorSafely();
    final categories = ref.read(categoriesStreamProvider).asData?.value ?? [];
    final expenseCats = categories.where((c) => c.type == 'Expense').toList();
    
    final items = ['None', ...expenseCats.map((c) => c.name)];
    
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Category',
      items: items,
      selectedValue: _categoryCtrl.text.isEmpty ? 'None' : _categoryCtrl.text,
    );
    
    if (selected != null && mounted) {
      setState(() {
        if (selected == 'None') {
          _categoryCtrl.clear();
          _selectedCategoryId = null;
          _subCategoryCtrl.clear();
          _selectedSubCategory = null;
        } else {
          _categoryCtrl.text = selected;
          _selectedCategoryId = expenseCats.firstWhere((c) => c.name == selected).id;
          _subCategoryCtrl.clear();
          _selectedSubCategory = null;
        }
      });
    }
  }

  void _showSubCategoryPicker() async {
    _closeCalculatorSafely();
    final categories = ref.read(categoriesStreamProvider).asData?.value ?? [];
    final selectedCatMatch = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final activeSubCategories = selectedCatMatch?.subCategories ?? [];

    if (activeSubCategories.isEmpty) return;
    
    final items = ['None', ...activeSubCategories];

    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Subcategory',
      items: items,
      selectedValue: _subCategoryCtrl.text.isEmpty ? 'None' : _subCategoryCtrl.text,
    );
    
    if (selected != null && mounted) {
      setState(() {
        if (selected == 'None') {
          _subCategoryCtrl.clear();
          _selectedSubCategory = null;
        } else {
          _subCategoryCtrl.text = selected;
          _selectedSubCategory = selected;
        }
      });
    }
  }

  void _showBucketPicker() async {
    _closeCalculatorSafely();
    final buckets = ref.read(bucketsStreamProvider).asData?.value ?? [];
    
    final items = ['None', ...buckets.map((b) => b.name)];
    
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Bucket',
      items: items,
      selectedValue: _bucketCtrl.text.isEmpty ? 'None' : _bucketCtrl.text,
    );
    
    if (selected != null && mounted) {
      setState(() {
        if (selected == 'None') {
          _bucketCtrl.clear();
          _selectedBucketId = null;
        } else {
          _bucketCtrl.text = selected;
          _selectedBucketId = buckets.firstWhere((b) => b.name == selected).id;
        }
      });
    }
  }

  void _showAccountPicker() async {
    _closeCalculatorSafely();
    final accounts = ref.read(accountsStreamProvider).asData?.value ?? [];
    
    final items = ['None', ...accounts.map((a) => a.name)];
    
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Account',
      items: items,
      selectedValue: _accountCtrl.text.isEmpty ? 'None' : _accountCtrl.text,
    );
    
    if (selected != null && mounted) {
      setState(() {
        if (selected == 'None') {
          _accountCtrl.clear();
          _selectedAccountId = null;
        } else {
          _accountCtrl.text = selected;
          _selectedAccountId = accounts.firstWhere((a) => a.name == selected).id;
        }
      });
    }
  }

  void _submit() {
    _closeCalculatorSafely();
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameCtrl.text.trim();
    final limit = double.tryParse(BodmasCalculator.evaluate(_amountCtrl.text)) ?? 0.0;
    if (limit <= 0) return;

    DateTime start = DateTime.now();
    DateTime end = DateTime.now();
    final now = DateTime.now();
    
    if (_timeframeCtrl.text == 'Custom' && _customStart != null && _customEnd != null) {
      start = _customStart!;
      end = _customEnd!;
    } else {
      switch (_timeframeCtrl.text) {
        case 'Daily':
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Weekly':
          final diff = now.weekday - 1;
          start = DateTime(now.year, now.month, now.day - diff);
          end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          break;
        case 'Monthly':
          start = DateTime(now.year, now.month, 1);
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          end = DateTime(now.year, now.month, daysInMonth, 23, 59, 59);
          break;
        case 'Yearly':
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
      }
    }

    ref.read(customBudgetActionProvider.notifier).saveBudget(
      existingId: widget.existingBudget?.id,
      name: name,
      amountLimit: limit,
      timeFrame: _timeframeCtrl.text,
      startDate: start,
      endDate: end,
      categoryId: _selectedCategoryId,
      subCategory: _selectedSubCategory,
      bucketId: _selectedBucketId,
      accountId: _selectedAccountId,
    ).then((success) {
      if (success && mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final showCalculator = _activeCalcController != null;

    final categories = ref.watch(categoriesStreamProvider).asData?.value ?? [];
    final selectedCatMatch = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final activeSubCategories = selectedCatMatch?.subCategories ?? [];

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
                    Text(widget.existingBudget == null ? 'New Budget Target' : 'Edit Target',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: DesignTokens.spacingLg),
                    
                    ModernBoxyInput(
                      controller: _nameCtrl, 
                      focusNode: _focusNodes[_nameCtrl],
                      labelText: 'Budget Name', 
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null, 
                      textInputAction: TextInputAction.next,
                      onTap: _closeCalculatorSafely,
                      onFieldSubmitted: (_) => _openCalculatorFor(_amountCtrl), 
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),
                    
                    ModernBoxyInput(
                      controller: _amountCtrl, 
                      focusNode: _focusNodes[_amountCtrl],
                      labelText: 'Amount Limit (₹)', 
                      readOnly: true,
                      onTap: () => _openCalculatorFor(_amountCtrl), 
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),
                    
                    InkWell(
                      onTap: _showTimeframePicker,
                      child: AbsorbPointer(
                        child: ModernBoxyInput(
                          controller: _timeframeCtrl,
                          labelText: 'Timeframe',
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                        ),
                      ),
                    ),
                    
                    if (_timeframeCtrl.text == 'Custom') ...[
                      const SizedBox(height: DesignTokens.spacingMd),
                      InkWell(
                        onTap: _pickDateRange,
                        child: AbsorbPointer(
                          child: ModernBoxyInput(
                            controller: _customDateCtrl,
                            labelText: 'Custom Date Range',
                            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: DesignTokens.spacingMd),

                    InkWell(
                      onTap: _showCategoryPicker,
                      child: AbsorbPointer(
                        child: ModernBoxyInput(
                          controller: _categoryCtrl,
                          labelText: 'Target Category (Optional)',
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    if (_categoryCtrl.text.isNotEmpty && activeSubCategories.isNotEmpty) ...[
                      InkWell(
                        onTap: _showSubCategoryPicker,
                        child: AbsorbPointer(
                          child: ModernBoxyInput(
                            controller: _subCategoryCtrl,
                            labelText: 'Subcategory (Optional)',
                            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingMd),
                    ],

                    InkWell(
                      onTap: _showBucketPicker,
                      child: AbsorbPointer(
                        child: ModernBoxyInput(
                          controller: _bucketCtrl,
                          labelText: 'Budget Bucket (Optional)',
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    InkWell(
                      onTap: _showAccountPicker,
                      child: AbsorbPointer(
                        child: ModernBoxyInput(
                          controller: _accountCtrl,
                          labelText: 'Account (Optional)',
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                        ),
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacingLg),
                    Row(
                      children: [
                        Expanded(child: ModernBoxyButton(onPressed: () => Navigator.pop(context), label: 'Cancel', isOutlined: true)),
                        const SizedBox(width: DesignTokens.spacingMd),
                        Expanded(flex: 2, child: ModernBoxyButton(onPressed: _submit, label: 'Save Target', isLoading: ref.watch(customBudgetActionProvider).isLoading)),
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
              onNext: null,
              onPrevious: () { 
                _closeCalculatorSafely(); 
                _focusNodes[_nameCtrl]!.requestFocus(); 
              },
              onSubmit: _closeCalculatorSafely,
              onClose: _closeCalculatorSafely,
            ),
        ],
      ),
    );
  }
}