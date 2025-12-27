import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/modern_dropdown.dart'; // Contains ModernDropdownPill & showSelectionSheet
import '../../../core/models/percentage_config_model.dart';
import '../../settings/services/settings_service.dart';
import '../models/credit_models.dart';
import '../services/credit_service.dart';

class AddCreditTransactionSheet extends StatefulWidget {
  const AddCreditTransactionSheet({super.key});

  @override
  State<AddCreditTransactionSheet> createState() =>
      _AddCreditTransactionSheetState();
}

class _AddCreditTransactionSheetState extends State<AddCreditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Data
  CreditCardModel? _selectedCard;
  List<CreditCardModel> _cards = [];
  List<String> _buckets = [];

  // Selections
  DateTime _date = DateTime.now();
  String? _selectedBucket;
  String _type = 'Expense'; // 'Expense' or 'Income'
  String? _category;
  String? _subCategory;

  bool _isLoading = false;

  // Categories Map
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
  }

  Future<void> _loadData() async {
    // Load Cards
    final cardStream = CreditService().getCreditCards().first;
    final configFuture = SettingsService().getPercentageConfig();

    final results = await Future.wait([cardStream, configFuture]);

    setState(() {
      _cards = results[0] as List<CreditCardModel>;
      final config = results[1] as PercentageConfig;
      _buckets = config.categories.map((e) => e.name).toList();

      // Default selections
      if (_cards.isNotEmpty) _selectedCard = _cards.first;
      if (_buckets.isNotEmpty) _selectedBucket = _buckets.first;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCard == null) return;
    setState(() => _isLoading = true);

    final txn = CreditTransactionModel(
      id: '',
      cardId: _selectedCard!.id,
      amount: double.parse(_amountCtrl.text),
      date: Timestamp.fromDate(_date),
      bucket: _selectedBucket ?? 'Unallocated',
      type: _type,
      category: _category ?? 'General',
      subCategory: _subCategory ?? 'General',
      notes: _notesCtrl.text,
    );

    await CreditService().addTransaction(txn);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'Expense'
        ? _expenseCategories
        : _incomeCategories;
    final categoryKeys = categories.keys.toList();
    final subCategories =
        (_category != null && categories.containsKey(_category))
        ? categories[_category]!
        : <String>[];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              const Text(
                "Add Transaction",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Card Selection
              DropdownButtonFormField<CreditCardModel>(
                value: _selectedCard,
                dropdownColor: const Color(0xFF1B263B),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Select Credit Card'),
                items: _cards
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text("${c.bankName} - ${c.name}"),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCard = v),
              ),
              const SizedBox(height: 16),

              // Type (Income/Expense)
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

              // Date
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) =>
                        Theme(data: ThemeData.dark(), child: child!),
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(_date),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: _inputDeco('Amount').copyWith(prefixText: '₹ '),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Bucket Selection (Fixed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Budget Bucket",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ModernDropdownPill(
                    label: _selectedBucket ?? "Select Bucket",
                    icon: Icons.pie_chart_outline,
                    isActive: _selectedBucket != null,
                    onTap: () => showSelectionSheet<String>(
                      context: context,
                      title: "Select Budget Bucket",
                      items: _buckets,
                      selectedItem: _selectedBucket,
                      labelBuilder: (v) => v,
                      onSelect: (v) => setState(() => _selectedBucket = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category & SubCategory
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      hint: const Text(
                        "Category",
                        style: TextStyle(color: Colors.white54),
                      ),
                      dropdownColor: const Color(0xFF1B263B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco(''),
                      items: categoryKeys
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _category = v;
                        _subCategory = null; // Reset sub
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _subCategory,
                      hint: const Text(
                        "Sub-Category",
                        style: TextStyle(color: Colors.white54),
                      ),
                      dropdownColor: const Color(0xFF1B263B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco(''),
                      items: subCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _subCategory = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Notes (Optional)'),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A86FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Add Transaction",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() {
        _type = label == 'Expense' ? 'Expense' : 'Income';
        _category = null;
        _subCategory = null;
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
}
