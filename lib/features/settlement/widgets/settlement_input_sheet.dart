import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/models/financial_record_model.dart';
import '../../../core/models/percentage_config_model.dart';
import '../../../core/models/settlement_model.dart';
import '../../../core/widgets/calculator_keyboard.dart';
import '../../../core/widgets/modern_dropdown.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../settings/services/settings_service.dart';
import '../services/settlement_service.dart';

class SettlementInputSheet extends StatefulWidget {
  const SettlementInputSheet({super.key});

  @override
  State<SettlementInputSheet> createState() => _SettlementInputSheetState();
}

class _SettlementInputSheetState extends State<SettlementInputSheet> {
  final _settlementService = SettlementService();
  final _dashboardService = DashboardService();
  final _settingsService = SettingsService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final ScrollController _scrollController = ScrollController();

  List<Map<String, int>> _yearMonthData = [];
  List<int> _availableYears = [];
  List<int> _availableMonthsForYear = [];
  int? _selectedYear;
  int? _selectedMonth;

  FinancialRecord? _budgetRecord;
  Settlement? _existingSettlement;
  PercentageConfig? _percentageConfig;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  double _totalExpense = 0.0;
  TextEditingController? _activeController;
  bool _isKeyboardVisible = false;
  bool _useSystemKeyboard = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    _yearMonthData = await _settlementService.getAvailableMonthsForSettlement();
    final years = _yearMonthData.map((e) => e['year']!).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    _availableYears = years;

    // Always load the fresh config when opening the sheet
    _percentageConfig = await _settingsService.getPercentageConfig();

    final now = DateTime.now();
    if (_availableYears.contains(now.year)) {
      _selectedYear = now.year;
      final months = _yearMonthData
          .where((data) => data['year'] == now.year)
          .map((data) => data['month']!)
          .toSet()
          .toList();
      months.sort((a, b) => b.compareTo(a));
      _availableMonthsForYear = months;
      if (_availableMonthsForYear.contains(now.month)) {
        _selectedMonth = now.month;
      }
    }
    setState(() {});
  }

  void _onYearSelected(int? year) {
    setState(() {
      _selectedYear = year;
      _selectedMonth = null;
      _budgetRecord = null;
      _controllers.clear();
      if (year != null) {
        final months = _yearMonthData
            .where((d) => d['year'] == year)
            .map((d) => d['month']!)
            .toSet()
            .toList();
        months.sort((a, b) => b.compareTo(a));
        _availableMonthsForYear = months;
      } else {
        _availableMonthsForYear = [];
      }
    });
  }

  Future<void> _fetchData() async {
    if (_selectedYear == null || _selectedMonth == null) return;
    final recordId =
        '$_selectedYear${_selectedMonth.toString().padLeft(2, '0')}';

    try {
      // Re-fetch config here too just to be absolutely safe
      final configFuture = _settingsService.getPercentageConfig();
      final results = await Future.wait([
        _dashboardService.getRecordById(recordId),
        _settlementService.getSettlementById(recordId),
        configFuture,
      ]);

      setState(() {
        _budgetRecord = results[0] as FinancialRecord;
        _existingSettlement = results[1] as Settlement?;
        _percentageConfig = results[2] as PercentageConfig;

        _controllers.clear();
        _focusNodes.clear();

        _budgetRecord!.allocations.forEach((key, _) {
          double initialValue = 0.0;
          if (_existingSettlement != null &&
              _existingSettlement!.expenses.containsKey(key)) {
            initialValue = _existingSettlement!.expenses[key]!;
          }
          final ctrl = TextEditingController(
            text: initialValue == 0 ? '' : initialValue.toString(),
          );
          ctrl.addListener(_calculateTotalExpense);
          _controllers[key] = ctrl;
          _focusNodes[key] = FocusNode();
        });

        _calculateTotalExpense();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching data: $e"),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  void _calculateTotalExpense() {
    double sum = 0.0;
    for (var ctrl in _controllers.values) {
      sum += double.tryParse(ctrl.text) ?? 0.0;
    }
    setState(() => _totalExpense = sum);
  }

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

  void _switchToSystemKeyboard() {
    setState(() {
      _useSystemKeyboard = true;
      _isKeyboardVisible = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _closeKeyboard() {
    setState(() => _isKeyboardVisible = false);
    FocusScope.of(context).unfocus();
  }

  void _handleNext() {
    if (_activeController == null) return;
    _navigateInput(1);
  }

  void _handlePrevious() {
    if (_activeController == null) return;
    _navigateInput(-1);
  }

  void _navigateInput(int direction) {
    final entries = _budgetRecord!.allocations.entries.toList();
    // Sort logic
    if (_percentageConfig != null) {
      entries.sort((a, b) {
        int idxA = _percentageConfig!.categories.indexWhere(
          (c) => c.name == a.key,
        );
        int idxB = _percentageConfig!.categories.indexWhere(
          (c) => c.name == b.key,
        );
        if (idxA == -1) idxA = 999;
        if (idxB == -1) idxB = 999;
        return idxA.compareTo(idxB);
      });
    } else {
      entries.sort((a, b) => b.value.compareTo(a.value));
    }

    int currentIndex = -1;
    for (int i = 0; i < entries.length; i++) {
      if (_controllers[entries[i].key] == _activeController) {
        currentIndex = i;
        break;
      }
    }

    int nextIndex = currentIndex + direction;
    if (nextIndex >= 0 && nextIndex < entries.length) {
      final nextKey = entries[nextIndex].key;
      _setActive(_controllers[nextKey]!, _focusNodes[nextKey]!);
    } else {
      _closeKeyboard();
    }
  }

  Future<void> _onSettle() async {
    _closeKeyboard();
    if (_budgetRecord == null) return;

    Map<String, double> expenses = {};
    _controllers.forEach((key, ctrl) {
      expenses[key] = double.tryParse(ctrl.text) ?? 0.0;
    });

    final settlement = Settlement(
      id: _budgetRecord!.id,
      year: _budgetRecord!.year,
      month: _budgetRecord!.month,
      allocations: _budgetRecord!.allocations,
      expenses: expenses,
      totalIncome: _budgetRecord!.effectiveIncome,
      totalExpense: _totalExpense,
      settledAt: Timestamp.now(),
    );

    try {
      await _settlementService.saveSettlement(settlement);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settlement saved successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: AppColors.deepVoid,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: ModernDropdownPill<int>(
                            label: _selectedYear?.toString() ?? 'Year',
                            isActive: _selectedYear != null,
                            icon: Icons.calendar_today_outlined,
                            onTap: () => showSelectionSheet<int>(
                              context: context,
                              title: 'Select Year',
                              items: _availableYears,
                              labelBuilder: (y) => y.toString(),
                              onSelect: _onYearSelected,
                              selectedItem: _selectedYear,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ModernDropdownPill<int>(
                            label: _selectedMonth != null
                                ? DateFormat(
                                    'MMMM',
                                  ).format(DateTime(0, _selectedMonth!))
                                : 'Month',
                            isActive: _selectedMonth != null,
                            icon: Icons.calendar_view_month_outlined,
                            isEnabled: _selectedYear != null,
                            onTap: () => showSelectionSheet<int>(
                              context: context,
                              title: 'Select Month',
                              items: _availableMonthsForYear,
                              labelBuilder: (m) =>
                                  DateFormat('MMMM').format(DateTime(0, m)),
                              onSelect: (val) =>
                                  setState(() => _selectedMonth = val),
                              selectedItem: _selectedMonth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.downloading_rounded,
                              color: AppColors.royalBlue,
                            ),
                            onPressed: _fetchData,
                            tooltip: 'Fetch Budget Data',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: _budgetRecord == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.touch_app_outlined,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Select a month and fetch data',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildSettlementForm(),
                  ),
                ],
              ),
            ),
          ),
          if (_budgetRecord != null) _buildStickyBottomBar(),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
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

  Widget _buildStickyBottomBar() {
    final income = _budgetRecord!.effectiveIncome;
    final balance = income - _totalExpense;
    final isOverBudget = balance < 0;
    final progress = income > 0
        ? (_totalExpense / income).clamp(0.0, 1.0)
        : 0.0;
    final statusColor = isOverBudget
        ? AppColors.dangerRed
        : AppColors.successGreen;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.deepVoid.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Spent: ${_currencyFormat.format(_totalExpense)}",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isOverBudget
                        ? "Over by ${_currencyFormat.format(balance.abs())}"
                        : "Left: ${_currencyFormat.format(balance)}",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          foregroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onSettle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor: AppColors.royalBlue.withOpacity(0.4),
                        ).copyWith(elevation: MaterialStateProperty.all(8)),
                        child: const Text(
                          'Settle Budget',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettlementForm() {
    final entries = _budgetRecord!.allocations.entries.toList();
    // Sorting logic
    if (_percentageConfig != null) {
      entries.sort((a, b) {
        int idxA = _percentageConfig!.categories.indexWhere(
          (c) => c.name == a.key,
        );
        int idxB = _percentageConfig!.categories.indexWhere(
          (c) => c.name == b.key,
        );
        if (idxA == -1) idxA = 999;
        if (idxB == -1) idxB = 999;
        return idxA.compareTo(idxB);
      });
    } else {
      entries.sort((a, b) => b.value.compareTo(a.value));
    }

    return GestureDetector(
      onTap: _closeKeyboard,
      child: ListView.separated(
        controller: _scrollController,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        padding: const EdgeInsets.only(bottom: 20),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _buildSettlementRow(
            title: entry.key,
            allocated: entry.value,
            controller: _controllers[entry.key]!,
          );
        },
      ),
    );
  }

  Widget _buildSettlementRow({
    required String title,
    required double allocated,
    required TextEditingController controller,
  }) {
    if (!_focusNodes.containsKey(title)) _focusNodes[title] = FocusNode();
    final focusNode = _focusNodes[title]!;

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allocated: ${_currencyFormat.format(allocated)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: GestureDetector(
              onTap: () => _setActive(controller, focusNode),
              child: AbsorbPointer(
                absorbing: !_useSystemKeyboard,
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: !_useSystemKeyboard,
                  showCursor: true,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricPink,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.electricPink,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
