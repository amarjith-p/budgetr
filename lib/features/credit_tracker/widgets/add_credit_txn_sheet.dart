import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/modern_dropdown.dart';
import '../../../core/widgets/modern_loader.dart';
import '../../../core/widgets/calculator_keyboard.dart'; // Import Custom Keyboard
import '../../../core/models/percentage_config_model.dart';
import '../../settings/services/settings_service.dart';
import '../models/credit_models.dart';
import '../services/credit_service.dart';

class AddCreditTransactionSheet extends StatefulWidget {
  final CreditTransactionModel? transactionToEdit;

  const AddCreditTransactionSheet({super.key, this.transactionToEdit});

  @override
  State<AddCreditTransactionSheet> createState() =>
      _AddCreditTransactionSheetState();
}

class _AddCreditTransactionSheetState extends State<AddCreditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Focus Nodes
  final FocusNode _amountNode = FocusNode();
  final FocusNode _notesNode = FocusNode();

  // Keys for Auto-Scroll
  final GlobalKey _amountFieldKey = GlobalKey();
  final GlobalKey _notesFieldKey = GlobalKey();

  CreditCardModel? _selectedCard;
  List<CreditCardModel> _cards = [];
  List<String> _buckets = [];

  DateTime _date = DateTime.now();
  String? _selectedBucket;
  String _type = 'Expense';
  String? _category;
  String? _subCategory;

  bool _isLoading = false;
  bool _showCustomKeyboard = false;

  final Map<String, List<String>> _expenseCategories = {
    'Shopping': ['Clothing', 'Electronics', 'Groceries', 'Home'],
    'Food': ['Dining Out', 'Delivery', 'Drinks'],
    'Travel': ['Flight', 'Cab', 'Hotel', 'Fuel'],
    'Utilities': ['Phone', 'Internet', 'Electricity'],
    'Entertainment': ['Movies', 'Subscription', 'Events'],
    'Medical': ['Pharmacy', 'Doctor', 'Insurance'],
    'Other': ['Miscellaneous'],
  };

  final Map<String, List<String>> _incomeCategories = {
    'Repayment': ['Bill Payment', 'Refund'],
    'Rewards': ['Cashback', 'Points Redemption'],
  };

  @override
  void initState() {
    super.initState();
    _loadData();

    // Focus Listeners
    _amountNode.addListener(() {
      if (_amountNode.hasFocus) {
        setState(() => _showCustomKeyboard = true);
        _scrollToField(_amountFieldKey);
      }
    });

    _notesNode.addListener(() {
      if (_notesNode.hasFocus) {
        setState(() => _showCustomKeyboard = false);
        _scrollToField(_notesFieldKey);
      }
    });
  }

  @override
  void dispose() {
    _amountNode.dispose();
    _notesNode.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _scrollToField(GlobalKey key) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    final cardStream = CreditService().getCreditCards().first;
    final configFuture = SettingsService().getPercentageConfig();

    final results = await Future.wait([cardStream, configFuture]);

    if (mounted) {
      setState(() {
        _cards = results[0] as List<CreditCardModel>;
        final config = results[1] as PercentageConfig;
        _buckets = config.categories.map((e) => e.name).toList();

        if (widget.transactionToEdit != null) {
          final t = widget.transactionToEdit!;
          _amountCtrl.text = t.amount.toStringAsFixed(2);
          if (_amountCtrl.text.endsWith(".00")) {
            _amountCtrl.text = t.amount.toStringAsFixed(0);
          }
          _notesCtrl.text = t.notes;
          _date = t.date.toDate();
          _type = t.type;
          _category = t.category;
          _subCategory = t.subCategory;
          _selectedBucket = t.bucket.isNotEmpty ? t.bucket : null;

          _selectedCard = _cards.firstWhere(
            (c) => c.id == t.cardId,
            orElse: () => _cards.isNotEmpty ? _cards.first : _cards[0],
          );
        } else {
          _selectedCard = null;
          _selectedBucket = null;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final bucketValue = _type == 'Expense' ? (_selectedBucket!) : 'Repayment';

      final txn = CreditTransactionModel(
        id: widget.transactionToEdit?.id ?? '',
        cardId: _selectedCard!.id,
        amount: double.parse(_amountCtrl.text),
        date: Timestamp.fromDate(_date),
        bucket: bucketValue,
        type: _type,
        category: _category!,
        subCategory: _subCategory ?? 'General',
        notes: _notesCtrl.text,
      );

      if (widget.transactionToEdit != null) {
        await CreditService().updateTransaction(txn);
      } else {
        await CreditService().addTransaction(txn);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    final categories = _type == 'Expense'
        ? _expenseCategories
        : _incomeCategories;
    final categoryKeys = categories.keys.toList();
    final subCategories =
        (_category != null && categories.containsKey(_category))
        ? categories[_category]!
        : <String>[];

    final bottomPadding = _showCustomKeyboard
        ? 0.0
        : MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xff0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isEditing ? "Edit Transaction" : "Add Transaction",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    AbsorbPointer(
                      absorbing: isEditing,
                      child: Opacity(
                        opacity: isEditing ? 0.5 : 1.0,
                        child: _buildSelectField<CreditCardModel>(
                          label: "Credit Card",
                          value: _selectedCard,
                          items: _cards,
                          labelBuilder: (c) => "${c.bankName} - ${c.name}",
                          onSelect: (v) => setState(() => _selectedCard = v),
                          validator: (v) =>
                              v == null ? 'Please select a card' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _typeButton(
                            "Expense",
                            Colors.redAccent,
                            _type == 'Expense',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _typeButton(
                            "Payment/Income",
                            Colors.greenAccent,
                            _type == 'Income',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        // Dismiss keyboards when picking date
                        _amountNode.unfocus();
                        _notesNode.unfocus();
                        setState(() => _showCustomKeyboard = false);

                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) =>
                              Theme(data: ThemeData.dark(), child: child!),
                        );

                        if (pickedDate != null) {
                          if (!mounted) return;
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_date),
                            builder: (context, child) =>
                                Theme(data: ThemeData.dark(), child: child!),
                          );

                          if (pickedTime != null) {
                            setState(() {
                              _date = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _inputDeco('Date & Time').copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(_date),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field (Custom Keyboard)
                    TextFormField(
                      key: _amountFieldKey,
                      focusNode: _amountNode,
                      controller: _amountCtrl,
                      keyboardType: TextInputType.none,
                      showCursor: true,
                      readOnly: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: _inputDeco(
                        'Amount',
                      ).copyWith(prefixText: '₹ '),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      onTap: () {
                        if (!_amountNode.hasFocus) {
                          FocusScope.of(context).requestFocus(_amountNode);
                        }
                        setState(() => _showCustomKeyboard = true);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_type == 'Expense') ...[
                      _buildSelectField<String>(
                        label: "Budget Bucket",
                        value: _selectedBucket,
                        items: _buckets,
                        labelBuilder: (v) => v,
                        onSelect: (v) => setState(() => _selectedBucket = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectField<String>(
                            label: "Category",
                            value: _category,
                            items: categoryKeys,
                            labelBuilder: (v) => v,
                            onSelect: (v) => setState(() {
                              _category = v;
                              _subCategory = null;
                            }),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                        if (_category != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSelectField<String>(
                              label: "Sub-Category",
                              value: _subCategory,
                              items: subCategories,
                              labelBuilder: (v) => v,
                              onSelect: (v) => setState(() => _subCategory = v),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes Field (System Keyboard)
                    TextFormField(
                      key: _notesFieldKey,
                      focusNode: _notesNode,
                      controller: _notesCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco('Notes (Optional)'),
                      textInputAction: TextInputAction.done,
                      // Hide KB on Done
                      onFieldSubmitted: (_) => _notesNode.unfocus(),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A86FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: ModernLoader(size: 24),
                              )
                            : Text(
                                isEditing
                                    ? "Update Transaction"
                                    : "Add Transaction",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CUSTOM KEYBOARD
          if (_showCustomKeyboard)
            CalculatorKeyboard(
              onKeyPress: (val) =>
                  CalculatorKeyboard.handleKeyPress(_amountCtrl, val),
              onBackspace: () =>
                  CalculatorKeyboard.handleBackspace(_amountCtrl),
              onClear: () => _amountCtrl.clear(),
              onEquals: () => CalculatorKeyboard.handleEquals(_amountCtrl),
              onClose: () {
                setState(() => _showCustomKeyboard = false);
                _amountNode.unfocus();
              },
              onPrevious: () {
                // No previous field really suitable (Date is popup), so close/unfocus
                setState(() => _showCustomKeyboard = false);
                _amountNode.unfocus();
              },
              onNext: () {
                // Next -> Focus Notes (System Keyboard)
                setState(() => _showCustomKeyboard = false);
                FocusScope.of(context).requestFocus(_notesNode);
              },
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildSelectField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required Function(T) onSelect,
    String? Function(T?)? validator,
  }) {
    return FormField<T>(
      validator: validator,
      initialValue: value,
      builder: (FormFieldState<T> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                // Dismiss keyboard if open
                _amountNode.unfocus();
                _notesNode.unfocus();
                setState(() => _showCustomKeyboard = false);

                showSelectionSheet<T>(
                  context: context,
                  title: "Select $label",
                  items: items,
                  selectedItem: value,
                  labelBuilder: labelBuilder,
                  onSelect: (v) {
                    if (v != null) {
                      onSelect(v);
                      state.didChange(v);
                    }
                  },
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _inputDeco(label).copyWith(
                  errorText: state.errorText,
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                ),
                isEmpty: value == null,
                child: Text(
                  value != null ? labelBuilder(value) : '',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _typeButton(String label, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() {
        _type = label == 'Expense' ? 'Expense' : 'Income';
        _category = null;
        _subCategory = null;
        if (_type == 'Income') {
          _selectedBucket = null;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.white12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
