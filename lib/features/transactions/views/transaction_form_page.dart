import 'package:budgetr/core/models/transaction_category_model.dart';
import 'package:budgetr/features/transactions/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/components/docked_calculator_pad.dart';
import '../../../core/utils/bodmas_calculator.dart';

import '../../accounts/providers/account_provider.dart';
import '../../category_manager/providers/category_provider.dart';
import '../providers/transaction_provider.dart';

// --- UI DATA WRAPPERS ---
class _AccountItem {
  final String id;
  final String name;
  _AccountItem(this.id, this.name);
}

class _BucketItem {
  final int id;
  final String name;
  _BucketItem(this.id, this.name);
}

class TransactionFormPage extends ConsumerStatefulWidget {
  final TransactionWithDetails? existingTransaction;
  final String? preSelectedAccountId;

  const TransactionFormPage({
    Key? key, 
    this.existingTransaction,
    this.preSelectedAccountId,
  }) : super(key: key);

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  int _typeIndex = 0;
  final List<String> _types = ['Expense', 'Income', 'Transfer'];

  // Math State
  String _expression = '';
  String _liveResult = '0.00';

  // Form State
  late TextEditingController _notesCtrl;
  DateTime _selectedDateTime = DateTime.now();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _selectedSubCategory;
  int? _selectedBucketId;
  
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    final txDetails = widget.existingTransaction;
    if (txDetails != null) {
      final tx = txDetails.transaction;
      _typeIndex = _types.indexOf(tx.type);
      _expression = tx.amount.toStringAsFixed(2);
      _liveResult = tx.amount.toStringAsFixed(2);
      _selectedDateTime = tx.date;
      _notesCtrl = TextEditingController(text: tx.notes ?? '');
      _selectedCategoryId = tx.categoryId;
      _selectedSubCategory = tx.subCategory;
      
      // Decodes External DB Mappings back to the UI state
      if (tx.type == 'Transfer') {
        if (tx.toAccountId == 'EXTERNAL_IN') {
          _selectedAccountId = 'EXTERNAL';
          _selectedToAccountId = tx.accountId;
        } else if (tx.toAccountId == 'EXTERNAL_OUT') {
          _selectedAccountId = tx.accountId;
          _selectedToAccountId = 'EXTERNAL';
        } else {
          _selectedAccountId = tx.accountId;
          _selectedToAccountId = tx.toAccountId;
        }
      } else {
        _selectedAccountId = tx.accountId;
      }
      
      // Load bucket or fallback to Out of Bucket (-1)
      _selectedBucketId = tx.bucketId ?? -1;
    } else {
      _notesCtrl = TextEditingController();
      _selectedAccountId = widget.preSelectedAccountId;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // --- HARDENED MATH LOGIC ---
  void _onCalcKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
      } else if (key == '⌫') {
        if (_expression.isNotEmpty) _expression = _expression.substring(0, _expression.length - 1);
      } else if (key == '=') {
        _expression = _liveResult;
      } else {
        final isOperator = ['+', '-', '×', '÷'].contains(key);
        if (isOperator && _expression.isNotEmpty) {
          final lastChar = _expression[_expression.length - 1];
          if (['+', '-', '×', '÷'].contains(lastChar)) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
        }
        
        if (_expression.length < 25) {
          _expression += key;
        }
      }
      
      String rawResult = BodmasCalculator.evaluate(_expression);
      double? parsed = double.tryParse(rawResult);
      
      if (parsed != null) {
        if (parsed.isNaN || parsed.isInfinite) {
          _liveResult = '0.00';
        } else if (parsed >= 1000000000000) { 
          _liveResult = '999999999999.99';
          if (key != '⌫') _expression = '999999999999.99'; 
        } else if (parsed <= -1000000000000) {
          _liveResult = '-999999999999.99';
          if (key != '⌫') _expression = '-999999999999.99';
        } else {
          _liveResult = parsed.toStringAsFixed(2);
        }
      } else {
        _liveResult = rawResult.isEmpty ? '0.00' : rawResult;
      }
    });
  }

  // --- FORMATTERS ---
  String _formatDateTime(DateTime d) {
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}, $time';
  }

  // --- PICKERS & DIALOGS ---
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context, initialDate: _selectedDateTime, firstDate: DateTime(2000), lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDateTime));
      if (time != null) setState(() => _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
    }
  }

  void _showSelector<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context, shape: DesignTokens.bottomSheetShape, isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, maxChildSize: 0.8, minChildSize: 0.4, expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController, itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
                    title: Text(labelBuilder(item), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    onTap: () { onSelected(item); Navigator.pop(ctx); },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotesEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Transaction Note', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: DesignTokens.spacingMd),
              TextField(
                controller: _notesCtrl,
                autofocus: true,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'What was this for?',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) {
                  setState(() {}); 
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  setState(() {}); 
                  Navigator.pop(ctx);
                },
                child: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_liveResult) ?? 0.0;
    
    final isExpense = _typeIndex == 0;
    final isTransfer = _typeIndex == 2;
    
    // Check for dangling operator in expression
    final hasDanglingOperator = _expression.isNotEmpty && ['+', '-', '×', '÷'].contains(_expression[_expression.length - 1]);

    if (amount <= 0 || hasDanglingOperator || _selectedAccountId == null || 
       (isTransfer && _selectedToAccountId == null) ||
       (isTransfer && _selectedAccountId == 'EXTERNAL' && _selectedToAccountId == 'EXTERNAL') || 
       (!isTransfer && _selectedCategoryId == null) ||
       (isExpense && _selectedBucketId == null)) {
      setState(() => _showValidationErrors = true);
      HapticFeedback.heavyImpact();
      return;
    }

    final success = await ref.read(transactionActionProvider.notifier).saveTransaction(
      existingId: widget.existingTransaction?.transaction.id,
      type: _types[_typeIndex],
      amount: amount,
      date: _selectedDateTime,
      accountId: _selectedAccountId!,
      toAccountId: _selectedToAccountId,
      categoryId: _selectedCategoryId,
      subCategory: _selectedSubCategory,
      bucketId: _selectedBucketId == -1 ? null : _selectedBucketId,
      notes: _notesCtrl.text.trim(),
    );

    if (success && mounted) Navigator.pop(context);
  }

  // --- 2-COLUMN UNIFIED TABLE CELL ---
  Widget _buildTableCell(String label, String? value, IconData icon, VoidCallback? onTap, bool isError) {
    final theme = Theme.of(context);
    final hasValue = value != null && value.isNotEmpty;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: isError ? theme.colorScheme.error : theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label, 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w800, 
                        letterSpacing: 0.5, 
                        color: isError ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant
                      ), 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasValue ? value : (onTap != null ? 'Select' : ''),
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: hasValue ? FontWeight.w800 : FontWeight.w500,
                  color: isError ? theme.colorScheme.error : (hasValue ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); 
    
    final isExpense = _typeIndex == 0;
    final isIncome = _typeIndex == 1;
    final isTransfer = _typeIndex == 2;

    final txColor = TransactionColors.getTypeColor(_types[_typeIndex], theme);

    // --- AMOUNT VALIDATION LOGIC ---
    final amountVal = double.tryParse(_liveResult) ?? 0.0;
    final hasDanglingOperator = _expression.isNotEmpty && ['+', '-', '×', '÷'].contains(_expression[_expression.length - 1]);
    final hasAmountError = _showValidationErrors && (amountVal <= 0 || hasDanglingOperator);
    final displayAmountColor = hasAmountError ? theme.colorScheme.error : txColor;

    final rawAccounts = ref.watch(accountsStreamProvider).asData?.value ?? [];
    final rawCategories = ref.watch(categoriesStreamProvider).asData?.value ?? [];
    final rawBuckets = ref.watch(bucketsStreamProvider).asData?.value ?? [];
    
    final accountItems = rawAccounts.map((a) => _AccountItem(a.id, a.name)).toList();
    if (isTransfer) {
      accountItems.add(_AccountItem('EXTERNAL', 'External Account'));
    }

    final bucketItems = rawBuckets.map((b) => _BucketItem(b.id, b.name)).toList();
    bucketItems.add(_BucketItem(-1, 'Out of Bucket'));

    final activeCategories = rawCategories.where((c) => c.type == _types[_typeIndex]).toList();
    final selectedCatMatch = rawCategories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final activeSubCategories = selectedCatMatch?.subCategories ?? [];
    
    final selectedAccMatch = accountItems.where((a) => a.id == _selectedAccountId).firstOrNull;
    final selectedToAccMatch = accountItems.where((a) => a.id == _selectedToAccountId).firstOrNull;
    final selectedBucketMatch = bucketItems.where((b) => b.id == _selectedBucketId).firstOrNull;

    final List<Widget> cells = [
      _buildTableCell('DATE & TIME', _formatDateTime(_selectedDateTime), Icons.calendar_today_rounded, _pickDateTime, false),
      
      _buildTableCell(
        isTransfer ? 'FROM ACCOUNT' : 'ACCOUNT', selectedAccMatch?.name, Icons.account_balance_wallet_rounded,
        () => _showSelector<_AccountItem>(title: 'Select Account', items: accountItems, labelBuilder: (a) => a.name, onSelected: (a) => setState(() => _selectedAccountId = a.id)),
        _showValidationErrors && _selectedAccountId == null
      ),
    ];

    if (isTransfer) {
      cells.add(_buildTableCell(
        'TO ACCOUNT', selectedToAccMatch?.name, Icons.sync_alt_rounded,
        () => _showSelector<_AccountItem>(title: 'Select Destination', items: accountItems.where((a) => a.id != _selectedAccountId && !(_selectedAccountId == 'EXTERNAL' && a.id == 'EXTERNAL')).toList(), labelBuilder: (a) => a.name, onSelected: (a) => setState(() => _selectedToAccountId = a.id)),
        _showValidationErrors && _selectedToAccountId == null
      ));
    } else {
      cells.add(_buildTableCell(
        'CATEGORY', selectedCatMatch?.name, Icons.category_rounded,
        () => _showSelector<TransactionCategoryModel>(title: 'Select Category', items: activeCategories, labelBuilder: (c) => c.name, onSelected: (c) => setState(() { _selectedCategoryId = c.id; _selectedSubCategory = null; })),
        _showValidationErrors && _selectedCategoryId == null
      ));
      
      if (activeSubCategories.isNotEmpty || _selectedSubCategory != null) {
        cells.add(_buildTableCell(
          'SUBCATEGORY', _selectedSubCategory, Icons.subdirectory_arrow_right_rounded,
          () { if (activeSubCategories.isNotEmpty) _showSelector<String>(title: 'Select Subcategory', items: activeSubCategories, labelBuilder: (s) => s, onSelected: (s) => setState(() => _selectedSubCategory = s)); },
          false
        ));
      }
      
      if (!isIncome) {
        cells.add(_buildTableCell(
          'BUDGET BUCKET', selectedBucketMatch?.name, Icons.donut_small_rounded,
          () => _showSelector<_BucketItem>(title: 'Assign to Bucket', items: bucketItems, labelBuilder: (b) => b.name, onSelected: (b) => setState(() => _selectedBucketId = b.id)),
          _showValidationErrors && isExpense && _selectedBucketId == null 
        ));
      }
    }
    
    cells.add(_buildTableCell('NOTES', _notesCtrl.text.isEmpty ? null : _notesCtrl.text, Icons.notes_rounded, _openNotesEditor, false));

    if (cells.length % 2 != 0) cells.add(const SizedBox.shrink()); 

    List<TableRow> tableRows = [];
    for (int i = 0; i < cells.length; i += 2) {
      tableRows.add(TableRow(children: [cells[i], cells[i + 1]]));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      resizeToAvoidBottomInset: false, 
      appBar: ModernAppBar(
        title: widget.existingTransaction != null ? 'Edit Log' : 'New Log',
        subtitle: 'TRANSACTION',
        leadingIcon: Icons.close_rounded,
        onLeadingPressed: () => Navigator.pop(context),
        trailingIcon: Icons.done_all_rounded, 
        onTrailingPressed: _submit,
      ),
      
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 60,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: ModernBoxyToggle(
                      labels: _types,
                      selectedIndex: _typeIndex,
                      onSelected: (index) => setState(() {
                        _typeIndex = index;
                        _selectedCategoryId = null; 
                        _selectedSubCategory = null;
                        if (index == 1) _selectedBucketId = null; 
                        if (index != 2 && _selectedAccountId == 'EXTERNAL') {
                          _selectedAccountId = null;
                        }
                      }),
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '₹ ',
                                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w400, color: displayAmountColor.withOpacity(0.7)),
                                    ),
                                    TextSpan(
                                      text: _expression.isEmpty ? '0.00' : _expression,
                                      style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: displayAmountColor, letterSpacing: -2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_expression.isNotEmpty && _expression != _liveResult && !hasAmountError)
                              Text(
                                '= ₹ $_liveResult',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: displayAmountColor),
                              ),
                            if (hasAmountError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  hasDanglingOperator
                                      ? 'Incomplete mathematical expression'
                                      : 'Amount must be greater than 0',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.error),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1.2),
                        ),
                        clipBehavior: Clip.antiAlias, 
                        child: Material(
                          color: Colors.transparent,
                          child: Table(
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 1.2),
                            ),
                            children: tableRows,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              flex: 40,
              child: DockedCalculatorPad(
                backgroundColor: theme.colorScheme.surface,
                actionColor: txColor,
                onKeyPress: _onCalcKeyPress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}