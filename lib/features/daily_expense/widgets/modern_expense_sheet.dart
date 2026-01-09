import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

// --- CORE IMPORTS ---
import '../../../core/widgets/modern_loader.dart';
import '../../../core/models/transaction_category_model.dart';
import '../../../core/services/category_service.dart';
import '../../../core/widgets/status_bottom_sheet.dart';
import '../../../core/design/budgetr_colors.dart';
import '../../../core/design/budgetr_styles.dart';

// --- FEATURE IMPORTS ---
import '../../settings/services/settings_service.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../settlement/services/settlement_service.dart';
import '../../credit_tracker/models/credit_models.dart';
import '../../credit_tracker/services/credit_service.dart';
import '../../notifications/services/budget_notification_service.dart';
import '../models/expense_models.dart';
import '../services/expense_service.dart';

class ModernExpenseSheet extends StatefulWidget {
  final ExpenseTransactionModel? txnToEdit;
  const ModernExpenseSheet({super.key, this.txnToEdit});

  @override
  State<ModernExpenseSheet> createState() => _ModernExpenseSheetState();
}

class _ModernExpenseSheetState extends State<ModernExpenseSheet> {
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS ---
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final FocusNode _amountNode = FocusNode();
  final FocusNode _notesNode = FocusNode();

  // --- LOGIC STATE ---
  bool _isCreditEntry = false;
  bool _isLinkedTransaction = false;
  bool _attemptedSave = false; // Triggers validation highlights

  // Selections
  ExpenseAccountModel? _selectedAccount;
  ExpenseAccountModel? _toAccount;
  CreditCardModel? _selectedCreditCard;

  // Data
  List<ExpenseAccountModel> _accounts = [];
  List<CreditCardModel> _creditCards = [];
  List<String> _buckets = [];
  List<String> _globalFallbackBuckets = [];
  List<TransactionCategoryModel> _allCategories = [];

  // Fields
  DateTime _date = DateTime.now();
  String? _selectedBucket;
  String _type = 'Expense';
  String? _category;
  String? _subCategory;

  bool _isLoading = false;
  bool _isMonthSettled = false;
  bool _showCalculator = true;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Toggle UI based on focus
    _notesNode.addListener(() {
      if (_notesNode.hasFocus) {
        setState(() => _showCalculator = false);
      } else {
        setState(() => _showCalculator = true);
      }
    });

    _amountNode.addListener(() {
      if (_amountNode.hasFocus) {
        setState(() => _showCalculator = true);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _amountNode.dispose();
    _notesNode.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 1. DATA & LOGIC
  // ===========================================================================

  Future<void> _loadData() async {
    final accsFuture = ExpenseService().getAccounts().first;
    final creditFuture = CreditService().getCreditCards().first;
    final catsFuture = CategoryService().getCategories().first;
    final configFuture = SettingsService().getPercentageConfig();

    final results =
        await Future.wait([accsFuture, creditFuture, catsFuture, configFuture]);

    if (mounted) {
      final config = results[3] as dynamic;
      _globalFallbackBuckets =
          (config.categories as List).map((e) => e.name as String).toList();
      _globalFallbackBuckets.add('Out of Bucket');

      setState(() {
        _accounts = results[0] as List<ExpenseAccountModel>;
        _creditCards = results[1] as List<CreditCardModel>;
        _allCategories = results[2] as List<TransactionCategoryModel>;

        if (widget.txnToEdit != null) {
          final t = widget.txnToEdit!;
          _amountCtrl.text =
              t.amount.toString().replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "");
          _notesCtrl.text = t.notes;
          _date = t.date.toDate();
          _selectedBucket = t.bucket;
          _category = t.category;
          _subCategory = t.subCategory;

          if (t.linkedCreditCardId != null &&
              t.linkedCreditCardId!.isNotEmpty) {
            _isCreditEntry = true;
            _isLinkedTransaction = true;
            _selectedCreditCard = _creditCards.firstWhere(
                (c) => c.id == t.linkedCreditCardId,
                orElse: () => _creditCards.first);
          } else {
            _selectedAccount = _accounts.firstWhere((a) => a.id == t.accountId,
                orElse: () => _accounts.first);
          }

          if (t.type == 'Transfer Out' || t.type == 'Transfer In') {
            _type = 'Transfer';
            if (_isCreditEntry) {
              _selectedAccount = _accounts.firstWhere(
                  (a) => a.id == t.accountId,
                  orElse: () => _accounts.first);
            } else {
              _selectedAccount = _accounts.firstWhere(
                  (a) => a.id == t.accountId,
                  orElse: () => _accounts.first);
              _toAccount = _accounts.firstWhere(
                  (a) => a.id == t.transferAccountId,
                  orElse: () => _accounts.first);
            }
          } else {
            _type = t.type;
          }
        }
      });
      await _updateBucketsForDate(_date);
    }
  }

  Future<void> _updateBucketsForDate(DateTime date) async {
    try {
      final isSettled =
          await SettlementService().isMonthSettled(date.year, date.month);
      if (isSettled) {
        setState(() {
          _isMonthSettled = true;
          _buckets = ['Out of Bucket'];
          _selectedBucket = 'Out of Bucket';
        });
        return;
      }
      final record =
          await DashboardService().getRecordForMonth(date.year, date.month);
      List<String> newBuckets = [];
      if (record != null && record.bucketOrder.isNotEmpty) {
        newBuckets = List.from(record.bucketOrder);
        for (var key in record.allocations.keys) {
          if (!newBuckets.contains(key)) newBuckets.add(key);
        }
      } else if (record != null) {
        final sorted = record.allocations.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        newBuckets = sorted.map((e) => e.key).toList();
      } else {
        newBuckets = List.from(_globalFallbackBuckets);
      }
      if (!newBuckets.contains('Out of Bucket'))
        newBuckets.add('Out of Bucket');
      setState(() {
        _isMonthSettled = false;
        _buckets = newBuckets;
        if (_selectedBucket != null && !_buckets.contains(_selectedBucket))
          _selectedBucket = null;
      });
    } catch (e) {
      setState(() => _buckets = List.from(_globalFallbackBuckets));
    }
  }

  // --- VALIDATION & SAVE ---
  Future<void> _save() async {
    setState(() => _attemptedSave = true);

    // 1. Amount Validation
    final double amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) {
      _showError("Amount must be greater than 0");
      return;
    }

    // 2. Source Account Validation
    bool showCredit = _isCreditEntry && _type != 'Transfer';
    if (showCredit) {
      if (_selectedCreditCard == null) {
        _showError("Please select a Credit Card");
        return;
      }
    } else {
      if (_selectedAccount == null) {
        _showError("Please select a Source Account");
        return;
      }
    }

    // 3. Category Validation (Not Transfer)
    if (_type != 'Transfer' && _category == null) {
      _showError("Please select a Category");
      return;
    }

    // 4. Bucket Validation (Expense Only)
    if (_type == 'Expense' && _selectedBucket == null) {
      _showError("Please select a Bucket");
      return;
    }

    // 5. Transfer Target Validation
    if (_type == 'Transfer') {
      if (_isCreditEntry) {
        // Paying Bill
        if (_selectedCreditCard == null) {
          _showError("Please select the Credit Card to pay");
          return;
        }
      } else {
        // Normal Transfer
        if (_toAccount == null) {
          _showError("Please select a Destination Account");
          return;
        }
        if (_toAccount!.id == _selectedAccount!.id) {
          _showError("Source and Destination accounts cannot be the same");
          return;
        }
      }
    }

    // --- CREDIT POOL CHECK ---
    ExpenseAccountModel? targetPoolAccount;
    if (_isCreditEntry ||
        (_type == 'Transfer' && _selectedCreditCard != null)) {
      try {
        targetPoolAccount = _accounts.firstWhere((a) =>
            a.bankName == 'Credit Card Pool Account' ||
            a.accountType == 'Credit Card');
      } catch (e) {
        _showError("Credit Pool Account missing. Create one in Settings.");
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      bool isEditing = widget.txnToEdit != null;

      if (isEditing) {
        final newTxn = ExpenseTransactionModel(
          id: widget.txnToEdit!.id,
          accountId: _selectedAccount!.id,
          amount: amount,
          date: Timestamp.fromDate(_date),
          bucket: _selectedBucket ?? 'Unallocated',
          type: _type,
          category: _category!,
          subCategory: _subCategory ?? 'General',
          notes: _notesCtrl.text,
          linkedCreditCardId: widget.txnToEdit!.linkedCreditCardId,
          transferAccountId: widget.txnToEdit!.transferAccountId,
          transferAccountName: widget.txnToEdit!.transferAccountName,
          transferAccountBankName: widget.txnToEdit!.transferAccountBankName,
        );
        await ExpenseService().updateTransaction(newTxn);
        if (mounted)
          await BudgetNotificationService().checkAndTriggerNotification(newTxn);
      } else {
        if (_type == 'Transfer') {
          if (_isCreditEntry) {
            final transferOut = ExpenseTransactionModel(
              id: '',
              accountId: _selectedAccount!.id,
              amount: amount,
              date: Timestamp.fromDate(_date),
              bucket: 'Unallocated',
              type: 'Transfer Out',
              category: 'Transfer',
              subCategory: 'Credit Card Bill',
              notes: _notesCtrl.text,
              transferAccountId: targetPoolAccount!.id,
              transferAccountName: _selectedCreditCard!.name,
              transferAccountBankName: _selectedCreditCard!.bankName,
              linkedCreditCardId: _selectedCreditCard!.id,
            );
            await ExpenseService().addTransaction(transferOut);
            BudgetNotificationService()
                .checkAndTriggerNotification(transferOut);
          } else {
            final transferOut = ExpenseTransactionModel(
              id: '',
              accountId: _selectedAccount!.id,
              amount: amount,
              date: Timestamp.fromDate(_date),
              bucket: 'Unallocated',
              type: 'Transfer Out',
              category: 'Transfer',
              subCategory: 'General',
              notes: _notesCtrl.text,
              transferAccountId: _toAccount!.id,
              transferAccountName: _toAccount!.name,
              transferAccountBankName: _toAccount!.bankName,
            );
            await ExpenseService().addTransaction(transferOut);
            BudgetNotificationService()
                .checkAndTriggerNotification(transferOut);
          }
        } else {
          final bucketValue =
              _type == 'Expense' ? (_selectedBucket!) : 'Income';
          final finalAccountId =
              _isCreditEntry ? targetPoolAccount!.id : _selectedAccount!.id;
          final ccId = _isCreditEntry ? _selectedCreditCard!.id : null;

          final txn = ExpenseTransactionModel(
            id: '',
            accountId: finalAccountId,
            amount: amount,
            date: Timestamp.fromDate(_date),
            bucket: bucketValue,
            type: _type,
            category: _category!,
            subCategory: _subCategory ?? 'General',
            notes: _notesCtrl.text,
            linkedCreditCardId: ccId,
          );
          await ExpenseService().addTransaction(txn);
          BudgetNotificationService().checkAndTriggerNotification(txn);
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError("Error saving: $e");
    }
  }

  void _showError(String msg) {
    showStatusSheet(
      context: context,
      title: "Validation Error",
      message: msg,
      icon: Icons.warning_amber_rounded,
      color: BudgetrColors.error,
    );
  }

  // --- ACTIONS ---
  Future<void> _pickDate() async {
    _amountNode.unfocus();
    _notesNode.unfocus();
    final d = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (c, child) => Theme(data: ThemeData.dark(), child: child!));

    if (d != null) {
      if (!mounted) return;
      final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_date),
          builder: (c, child) => Theme(data: ThemeData.dark(), child: child!));

      if (t != null) {
        final newDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
        setState(() => _date = newDate);
        await _updateBucketsForDate(newDate);
      }
    }
  }

  // ===========================================================================
  // 2. DESIGN & LAYOUT
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    if (_type == 'Income')
      typeColor = BudgetrColors.success;
    else if (_type == 'Transfer')
      typeColor = BudgetrColors.accent;
    else
      typeColor = BudgetrColors.error;

    // Handle Keyboard Height so sheet isn't covered
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        decoration: const BoxDecoration(
          color: BudgetrColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hug content
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        _buildSegment("Expense", Colors.redAccent),
                        _buildSegment("Income", Colors.greenAccent),
                        _buildSegment("Transfer", Colors.blueAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Control Bar (Date & Credit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(DateFormat('MMM dd, hh:mm a').format(_date),
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                  // Credit Toggle (Always Visible unless Linked)
                  if (!_isLinkedTransaction && widget.txnToEdit == null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCreditEntry = !_isCreditEntry;
                          if (_type == 'Transfer' && _isCreditEntry)
                            _toAccount = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isCreditEntry
                              ? Colors.redAccent.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _isCreditEntry
                                  ? Colors.redAccent
                                  : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Text("Credit Card",
                                style: TextStyle(
                                    color: _isCreditEntry
                                        ? Colors.redAccent
                                        : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Icon(
                                _isCreditEntry
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                color: _isCreditEntry
                                    ? Colors.redAccent
                                    : Colors.white38,
                                size: 20),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ),

            // 3. Hero Amount (Highlighted on Error)
            _buildHeroAmount(typeColor),

            // 4. MAIN FORM GRID
            Flexible(
              fit: FlexFit.loose,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Hug content
                    children: [
                      _buildMainGrid(), // 2x2 Fixed Grid

                      const SizedBox(height: 12),

                      // Notes (Full Width)
                      TextFormField(
                        controller: _notesCtrl,
                        focusNode: _notesNode,
                        style: BudgetrStyles.body.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Add a note...",
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.3)),
                          prefixIcon: Icon(Icons.edit_note,
                              color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Calculator & Save (4 Rows x 4 Cols + Specials)
            if (_showCalculator) ...[
              Container(color: Colors.white.withOpacity(0.05), height: 1),
              _EmbeddedCalculator(
                  controller: _amountCtrl, typeColor: typeColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const ModernLoader(size: 20)
                        : const Text("SAVE TRANSACTION",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ] else ...[
              // Done Bar for system keyboard
              Container(
                width: double.infinity,
                color: BudgetrColors.cardSurface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => FocusScope.of(context).unfocus(),
                    child: const Text("Done")),
              )
            ]
          ],
        ),
      ),
    );
  }

  // --- GRID LOGIC ---

  Widget _buildHeroAmount(Color typeColor) {
    // Check validation state
    final bool hasError =
        _attemptedSave && (double.tryParse(_amountCtrl.text) ?? 0) <= 0;
    final Color displayColor = hasError ? Colors.redAccent : typeColor;
    final Color hintColor =
        hasError ? Colors.redAccent.withOpacity(0.5) : Colors.white12;
    final Color prefixColor = hasError ? Colors.redAccent : Colors.white24;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicWidth(
        child: TextFormField(
          controller: _amountCtrl,
          focusNode: _amountNode,
          readOnly: true,
          showCursor: true,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: displayColor,
              height: 1.1),
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "0",
              hintStyle: TextStyle(color: hintColor),
              prefixText: "₹",
              prefixStyle: TextStyle(
                  fontSize: 44,
                  color: prefixColor,
                  fontWeight: FontWeight.w300),
              contentPadding: EdgeInsets.zero),
          onTap: () => FocusScope.of(context).requestFocus(_amountNode),
        ),
      ),
    );
  }

  Widget _buildMainGrid() {
    List<Widget> gridItems = [];

    // Slot 1: Source
    bool showCredit = _isCreditEntry && _type != 'Transfer';
    bool sourceError = _attemptedSave &&
        (showCredit ? _selectedCreditCard == null : _selectedAccount == null);

    gridItems.add(_buildGridItem(
        label: showCredit
            ? "PAY WITH"
            : (_type == 'Transfer' ? "FROM" : "ACCOUNT"),
        value: showCredit
            ? (_selectedCreditCard?.name ?? "Select Card")
            : (_selectedAccount?.name ?? "Select Account"),
        icon: showCredit ? Icons.credit_card : Icons.account_balance,
        isActive: true,
        hasError: sourceError,
        onTap: () {
          if (_isLinkedTransaction) return;
          if (showCredit) {
            _showSelectionSheet<CreditCardModel>(
                "Select Card",
                _creditCards,
                _selectedCreditCard,
                (c) => "${c.bankName} - ${c.name}",
                (v) => setState(() => _selectedCreditCard = v));
          } else {
            _showSelectionSheet<ExpenseAccountModel>(
                "Select Account",
                _accounts,
                _selectedAccount,
                (a) => "${a.bankName} - ${a.name}",
                (v) => setState(() => _selectedAccount = v));
          }
        }));

    // Slot 2: Target / Category
    if (_type == 'Transfer') {
      bool targetError = false;
      String targetLabel = _isCreditEntry ? "PAY BILL" : "TO";
      String targetValue = "Select";

      if (_isCreditEntry) {
        targetValue = _selectedCreditCard?.name ?? "Select Card";
        targetError = _attemptedSave && _selectedCreditCard == null;
      } else {
        targetValue = _toAccount?.name ?? "Select Account";
        targetError = _attemptedSave &&
            (_toAccount == null || _toAccount!.id == _selectedAccount?.id);
      }

      gridItems.add(_buildGridItem(
          label: targetLabel,
          value: targetValue,
          icon: Icons.login,
          isActive: true,
          hasError: targetError,
          onTap: () {
            if (_isLinkedTransaction) return;
            if (_isCreditEntry) {
              _showSelectionSheet<CreditCardModel>(
                  "Select Card",
                  _creditCards,
                  _selectedCreditCard,
                  (c) => "${c.bankName} - ${c.name}",
                  (v) => setState(() => _selectedCreditCard = v));
            } else {
              _showSelectionSheet<ExpenseAccountModel>(
                  "To Account",
                  _accounts.where((a) => a.id != _selectedAccount?.id).toList(),
                  _toAccount,
                  (a) => "${a.bankName} - ${a.name}",
                  (v) => setState(() => _toAccount = v));
            }
          }));
    } else {
      bool catError = _attemptedSave && _category == null;
      gridItems.add(_buildGridItem(
          label: "CATEGORY",
          value: _category ?? "Select",
          icon: Icons.category_outlined,
          isActive: true,
          hasError: catError,
          onTap: () {
            final relevantCats =
                _allCategories.where((c) => c.type == _type).toList();
            _showSelectionSheet<TransactionCategoryModel>(
                "Category",
                relevantCats,
                null,
                (c) => c.name,
                (v) => setState(() {
                      _category = v.name;
                      _subCategory = null;
                    }));
          }));
    }

    // Slot 3: Bucket
    bool bucketActive = _type == 'Expense';
    bool bucketError =
        _attemptedSave && bucketActive && _selectedBucket == null;
    String bucketVal = _selectedBucket ?? "Select";
    if (!bucketActive) bucketVal = "---";

    gridItems.add(_buildGridItem(
        label: "BUCKET",
        value: bucketVal,
        icon: Icons.pie_chart_outline,
        isActive: bucketActive,
        hasError: bucketError,
        onTap: () => _showSelectionSheet<String>(
            "Bucket",
            _buckets,
            _selectedBucket,
            (s) => s,
            (v) => setState(() => _selectedBucket = v))));

    // Slot 4: SubCategory
    bool subCatActive = (_category != null && _type != 'Transfer');
    String subVal = "---";
    TransactionCategoryModel? catModel;

    if (_category != null) {
      try {
        catModel = _allCategories.firstWhere((c) => c.name == _category);
      } catch (_) {}
      if (catModel != null && catModel.subCategories.isNotEmpty) {
        subVal = _subCategory ?? "Select";
      } else {
        subCatActive = false;
        subVal = "---";
      }
    }

    gridItems.add(_buildGridItem(
        label: "SUB-CATEGORY",
        value: subVal,
        icon: Icons.subdirectory_arrow_right,
        isActive: subCatActive,
        hasError: false,
        onTap: () {
          if (catModel != null) {
            _showSelectionSheet<String>(
                "Sub Category",
                catModel.subCategories,
                _subCategory,
                (s) => s,
                (v) => setState(() => _subCategory = v));
          }
        }));

    return LayoutBuilder(builder: (context, constraints) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: gridItems
            .map((item) =>
                SizedBox(width: (constraints.maxWidth - 12) / 2, child: item))
            .toList(),
      );
    });
  }

  Widget _buildSegment(String label, Color color) {
    final isSelected = _type == label;
    final isDisabled = _isLinkedTransaction ||
        (widget.txnToEdit != null && label == 'Transfer');
    return Expanded(
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {
                setState(() {
                  _type = label;
                  _category = null;
                  _subCategory = null;
                  if ((_type == 'Income' && !_isCreditEntry) ||
                      _type == 'Transfer') _selectedBucket = null;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected ? Border.all(color: color.withOpacity(0.5)) : null,
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: isSelected ? color : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildGridItem(
      {required String label,
      required String value,
      required IconData icon,
      required bool isActive,
      required bool hasError,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasError
                  ? Colors.redAccent
                  : (isActive
                      ? Colors.white.withOpacity(0.08)
                      : Colors.transparent)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon,
                size: 14, color: isActive ? Colors.white38 : Colors.white12),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.white38 : Colors.white12,
                    fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.white24,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _showSelectionSheet<T>(String title, List<T> items, T? selected,
      String Function(T) labelGen, Function(T) onSel) {
    _amountNode.unfocus();
    _notesNode.unfocus();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: BudgetrColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2))),
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(title,
                          style:
                              BudgetrStyles.h2.copyWith(color: Colors.white))),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        bool isSelected = false;
                        if (selected != null && item != null) {
                          if (item is ExpenseAccountModel &&
                              selected is ExpenseAccountModel)
                            isSelected = item.id == selected.id;
                          else if (item is CreditCardModel &&
                              selected is CreditCardModel)
                            isSelected = item.id == selected.id;
                          else
                            isSelected = item == selected;
                        }
                        return ListTile(
                          onTap: () {
                            onSel(item);
                            Navigator.pop(context);
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          tileColor: isSelected
                              ? BudgetrColors.accent.withOpacity(0.1)
                              : Colors.white.withOpacity(0.03),
                          leading: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: BudgetrColors.accent)
                              : const Icon(Icons.circle_outlined,
                                  color: Colors.white24),
                          title: Text(labelGen(item),
                              style: TextStyle(
                                  color: isSelected
                                      ? BudgetrColors.accent
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ));
  }
}

// ===========================================================================
// 3. 4-COLUMN CALCULATOR
// ===========================================================================

class _EmbeddedCalculator extends StatelessWidget {
  final TextEditingController controller;
  final Color typeColor;

  const _EmbeddedCalculator(
      {required this.controller, required this.typeColor});

  void _onKey(String value) {
    final text = controller.text;
    final selection = controller.selection;
    int start = selection.start >= 0 ? selection.start : text.length;
    int end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, value);
    controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + value.length));
  }

  void _onBackspace() {
    final text = controller.text;
    final selection = controller.selection;
    int start = selection.start >= 0 ? selection.start : text.length;
    if (start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      controller.value = TextEditingValue(
          text: newText, selection: TextSelection.collapsed(offset: start - 1));
    }
  }

  void _onClear() {
    controller.clear();
  }

  void _onEquals() {
    String expression =
        controller.text.replaceAll('×', '*').replaceAll('÷', '/');
    try {
      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);
      controller.text =
          result.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "");
      controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length));
    } catch (e) {/* ignore */}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff121212),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            _key('C', color: Colors.redAccent, onTap: _onClear),
            _key('(', color: Colors.white54),
            _key(')', color: Colors.white54),
            _key('÷', color: Colors.blueAccent)
          ]),
          Row(children: [
            _key('7'),
            _key('8'),
            _key('9'),
            _key('×', color: Colors.blueAccent)
          ]),
          Row(children: [
            _key('4'),
            _key('5'),
            _key('6'),
            _key('-', color: Colors.blueAccent)
          ]),
          Row(children: [
            _key('1'),
            _key('2'),
            _key('3'),
            _key('+', color: Colors.blueAccent)
          ]),
          Row(children: [
            _key('0'),
            _key('.', color: Colors.white70),
            _backspaceKey(),
            _equalsKey(typeColor)
          ]),
        ],
      ),
    );
  }

  Widget _key(String label, {Color? color, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap ?? () => _onKey(label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.white)),
        ),
      ),
    );
  }

  Widget _backspaceKey() {
    return Expanded(
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.backspace_outlined,
              size: 18, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _equalsKey(Color color) {
    return Expanded(
      child: InkWell(
        onTap: _onEquals,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)),
          child: Text('=',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }
}
