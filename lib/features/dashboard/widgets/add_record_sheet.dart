import 'package:budget/core/widgets/modern_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/widgets/calculator_keyboard.dart';
import '../../../core/widgets/modern_dropdown.dart';
import '../../../core/models/financial_record_model.dart';
import '../../../core/models/percentage_config_model.dart';
import '../services/dashboard_service.dart';
import '../../settings/services/settings_service.dart';

// --- DESIGN SYSTEM IMPORTS ---
import '../../../core/design/budgetr_colors.dart';
import '../../../core/design/budgetr_styles.dart';
import '../../../core/design/budgetr_components.dart';

class AddRecordSheet extends StatefulWidget {
  final FinancialRecord? recordToEdit;
  final DateTime? initialDate;

  const AddRecordSheet({super.key, this.recordToEdit, this.initialDate});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  final _dashboardService = DashboardService();
  final _settingsService = SettingsService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final ScrollController _scrollController = ScrollController();
  final LocalAuthentication _auth = LocalAuthentication();

  // Controllers
  late TextEditingController _salaryController;
  late TextEditingController _extraIncomeController;
  late TextEditingController _emiController;

  final FocusNode _salaryFocus = FocusNode();
  final FocusNode _extraFocus = FocusNode();
  final FocusNode _emiFocus = FocusNode();

  int? _selectedYear;
  int? _selectedMonth;
  final List<int> _years = List.generate(
    10,
    (index) => DateTime.now().year - 2 + index,
  );
  final List<int> _months = List.generate(12, (index) => index + 1);

  double _effectiveIncome = 0;
  PercentageConfig? _config;

  // Keyboard
  TextEditingController? _activeController;
  bool _isKeyboardVisible = false;
  bool _useSystemKeyboard = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.recordToEdit != null;

    _salaryController = TextEditingController(
      text: widget.recordToEdit?.salary.toString() ?? '',
    );
    _extraIncomeController = TextEditingController(
      text: widget.recordToEdit?.extraIncome.toString() ?? '',
    );
    _emiController = TextEditingController(
      text: widget.recordToEdit?.emi.toString() ?? '',
    );

    _initializeConfig();

    _salaryController.addListener(_calculate);
    _extraIncomeController.addListener(_calculate);
    _emiController.addListener(_calculate);
  }

  Future<void> _initializeConfig() async {
    // LOGIC:
    // 1. If Editing: LOAD FROM RECORD. Do not touch SettingsService.
    //    This preserves the exact bucket order and percentages from when
    //    the record was originally saved.
    // 2. If Creating: LOAD FROM SETTINGS. This picks up the latest configuration.

    if (_isEditing) {
      final record = widget.recordToEdit!;
      _selectedYear = record.year;
      _selectedMonth = record.month;

      List<CategoryConfig> preservedCategories = [];

      if (record.bucketOrder.isNotEmpty) {
        // STRICT MODE: Use the saved order
        for (var name in record.bucketOrder) {
          // Retrieve the percentage used at the time of creation
          final double percentage = record.allocationPercentages[name] ?? 0.0;

          preservedCategories.add(
            CategoryConfig(
              name: name,
              percentage: percentage,
              // Note is not stored in FinancialRecord, so we leave it empty.
              // This is purely for calculation display.
            ),
          );
        }
      } else {
        // LEGACY FALLBACK:
        // For old records created before bucketOrder existed,
        // we map the percentages map directly.
        record.allocationPercentages.forEach((key, value) {
          preservedCategories.add(CategoryConfig(name: key, percentage: value));
        });
      }

      setState(() {
        _config = PercentageConfig(categories: preservedCategories);
        _calculate();
      });
    } else {
      // FRESH ENTRY: Fetch latest settings
      final masterConfig = await _settingsService.getPercentageConfig();
      final date = widget.initialDate ?? DateTime.now();

      setState(() {
        _selectedYear = date.year;
        _selectedMonth = date.month;
        _config = masterConfig;
        // _calculate() will be called via listeners when user types
      });
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _extraIncomeController.dispose();
    _emiController.dispose();
    _salaryFocus.dispose();
    _extraFocus.dispose();
    _emiFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_config == null) return;
    final salary = double.tryParse(_salaryController.text) ?? 0;
    final extra = double.tryParse(_extraIncomeController.text) ?? 0;
    final emi = double.tryParse(_emiController.text) ?? 0;

    setState(() {
      _effectiveIncome = (salary + extra) - emi;
      if (_effectiveIncome < 0) _effectiveIncome = 0;
    });
  }

  // --- Keyboard Handling ---
  void _scrollToInput(FocusNode node) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (node.context != null && mounted) {
        Scrollable.ensureVisible(
          node.context!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _setActive(TextEditingController ctrl, FocusNode node) {
    setState(() {
      _activeController = ctrl;
      if (!_useSystemKeyboard) {
        _isKeyboardVisible = true;
        FocusScope.of(context).requestFocus(node);
      } else {
        _isKeyboardVisible = false;
      }
    });
    _scrollToInput(node);
  }

  void _closeKeyboard() {
    setState(() => _isKeyboardVisible = false);
    FocusScope.of(context).unfocus();
  }

  void _switchToSystemKeyboard() {
    setState(() {
      _useSystemKeyboard = true;
      _isKeyboardVisible = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _handleNext() {
    if (_activeController == _salaryController)
      _setActive(_extraIncomeController, _extraFocus);
    else if (_activeController == _extraIncomeController)
      _setActive(_emiController, _emiFocus);
    else
      _closeKeyboard();
  }

  void _handlePrevious() {
    if (_activeController == _emiController)
      _setActive(_extraIncomeController, _extraFocus);
    else if (_activeController == _extraIncomeController)
      _setActive(_salaryController, _salaryFocus);
    else
      _closeKeyboard();
  }

  Future<void> _save() async {
    _closeKeyboard();
    if (_config == null) return;
    if (_salaryController.text.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Validation Error"),
            content: const Text("Salary is required."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    final idString =
        '$_selectedYear${_selectedMonth.toString().padLeft(2, '0')}';

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseConstants.financialRecords)
          .doc(idString)
          .get();

      if (docSnapshot.exists) {
        bool authenticated = false;
        try {
          authenticated = await _auth.authenticate(
            localizedReason: 'Authenticate to update existing budget',
            options: const AuthenticationOptions(stickyAuth: true),
          );
        } on PlatformException catch (_) {
          return;
        }

        if (!authenticated) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Authentication Failed"),
                content: const Text(
                  "Authentication is required to update an existing budget record.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Error"),
            content: Text("Error checking record: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    Map<String, double> allocations = {};
    Map<String, double> percentages = {};
    List<String> bucketOrder = [];

    // Because _config is loaded based on the mode (Edit vs New),
    // iterating through it automatically preserves the correct order.
    // If Editing: It iterates the PRESERVED order.
    // If New: It iterates the SETTINGS order.
    for (var cat in _config!.categories) {
      allocations[cat.name] = _effectiveIncome * (cat.percentage / 100.0);
      percentages[cat.name] = cat.percentage;
      bucketOrder.add(cat.name);
    }

    final record = FinancialRecord(
      id: idString,
      salary: double.tryParse(_salaryController.text) ?? 0,
      extraIncome: double.tryParse(_extraIncomeController.text) ?? 0,
      emi: double.tryParse(_emiController.text) ?? 0,
      year: _selectedYear!,
      month: _selectedMonth!,
      effectiveIncome: _effectiveIncome,
      allocations: allocations,
      allocationPercentages: percentages,
      bucketOrder: bucketOrder, // Persist the determined order
      createdAt: widget.recordToEdit?.createdAt ?? Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    await _dashboardService.setFinancialRecord(record);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_config == null) return const Center(child: ModernLoader());

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: BudgetrColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
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

                  // Header with Date Pickers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEditing ? 'Edit Budget' : 'New Budget',
                        style: BudgetrStyles.h2,
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _isEditing
                                ? null
                                : () => showSelectionSheet<int>(
                                    context: context,
                                    title: 'Select Year',
                                    items: _years,
                                    labelBuilder: (y) => y.toString(),
                                    onSelect: (v) =>
                                        setState(() => _selectedYear = v),
                                    selectedItem: _selectedYear,
                                  ),
                            child: Opacity(
                              opacity: _isEditing ? 0.5 : 1.0,
                              child: _datePill(_selectedYear.toString()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isEditing
                                ? null
                                : () => showSelectionSheet<int>(
                                    context: context,
                                    title: 'Select Month',
                                    items: _months,
                                    labelBuilder: (m) => DateFormat(
                                      'MMM',
                                    ).format(DateTime(0, m)),
                                    onSelect: (v) =>
                                        setState(() => _selectedMonth = v),
                                    selectedItem: _selectedMonth,
                                  ),
                            child: Opacity(
                              opacity: _isEditing ? 0.5 : 1.0,
                              child: _datePill(
                                DateFormat(
                                  'MMM',
                                ).format(DateTime(0, _selectedMonth!)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildInput(
                    "Base Salary",
                    _salaryController,
                    _salaryFocus,
                    BudgetrColors.success,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    "Extra Income",
                    _extraIncomeController,
                    _extraFocus,
                    BudgetrColors.success,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    "EMI / Deductions",
                    _emiController,
                    _emiFocus,
                    BudgetrColors.error,
                  ),

                  const SizedBox(height: 32),
                  // --- Projected Splits Preview ---
                  if (_effectiveIncome > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PROJECTED ALLOCATIONS",
                          style: BudgetrStyles.caption.copyWith(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._config!.categories.map((cat) {
                          final amount =
                              _effectiveIncome * (cat.percentage / 100);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: BudgetrColors.accent.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: BudgetrColors.accent
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                      child: Text(
                                        "${cat.percentage.toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          color: BudgetrColors.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(cat.name, style: BudgetrStyles.body),
                                  ],
                                ),
                                Text(
                                  _currencyFormat.format(amount),
                                  style: BudgetrStyles.h3,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // --- STICKY BOTTOM BAR ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BudgetrColors.background,
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Net Effective Income:",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      _currencyFormat.format(_effectiveIncome),
                      style: TextStyle(
                        color: BudgetrColors.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BudgetrStyles.radiusM,
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BudgetrButton(
                        text: "Save Budget",
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- KEYBOARD ---
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _isKeyboardVisible
                ? CalculatorKeyboard(
                    onKeyPress: (v) => CalculatorKeyboard.handleKeyPress(
                      _activeController!,
                      v,
                    ),
                    onBackspace: () =>
                        CalculatorKeyboard.handleBackspace(_activeController!),
                    onClear: () => _activeController!.clear(),
                    onEquals: () =>
                        CalculatorKeyboard.handleEquals(_activeController!),
                    onClose: _closeKeyboard,
                    onSwitchToSystem: _switchToSystemKeyboard,
                    onNext: _handleNext,
                    onPrevious: _handlePrevious,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _datePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController ctrl,
    FocusNode node,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          focusNode: node,
          readOnly: !_useSystemKeyboard, // KEEP THIS for custom keyboard
          showCursor: true, // KEEP THIS for custom keyboard
          keyboardType: TextInputType.number,
          style: BudgetrStyles.inputNumber,
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: TextStyle(
              color: BudgetrColors.textSecondary,
              fontSize: 20,
            ),
            hintText: '0',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BudgetrStyles.radiusS,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BudgetrStyles.radiusS,
              borderSide: BorderSide(color: accent),
            ),
          ),
          onTap: () => _setActive(ctrl, node),
        ),
      ],
    );
  }
}
