import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math_expressions/math_expressions.dart';

import '../../../core/models/financial_record_model.dart';
import '../../../core/models/settlement_model.dart';
import '../../../core/services/firestore_service.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final _firestoreService = FirestoreService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  List<Map<String, int>> _yearMonthData = [];
  List<int> _availableYears = [];
  List<int> _availableMonthsForYear = [];
  int? _selectedYear;
  int? _selectedMonth;

  bool _isLoading = false;
  Settlement? _settlementData;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    _yearMonthData = await _firestoreService.getAvailableMonthsForSettlement();
    final years = _yearMonthData.map((e) => e['year']!).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    _availableYears = years;

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
      _settlementData = null;
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

  Future<void> _fetchSettlementData() async {
    if (_selectedYear == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a year and month.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _settlementData = null;
    });
    final recordId =
        '$_selectedYear${_selectedMonth.toString().padLeft(2, '0')}';
    final settlement = await _firestoreService.getSettlementById(recordId);
    setState(() {
      _settlementData = settlement;
      _isLoading = false;
    });
  }

  void _showSettlementInputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      builder: (context) => const SettlementInputSheet(),
    ).then((_) {
      if (_selectedYear != null && _selectedMonth != null) {
        _fetchSettlementData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settlement Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildYearDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildMonthDropdown()),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _fetchSettlementData,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Fetch Settlement Data'),
              ),
            ),
            const Divider(height: 32),
            Expanded(child: _buildContentArea()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSettlementInputSheet,
        icon: const Icon(Icons.edit_document),
        label: const Text('Enter/Edit Settlement'),
      ),
    );
  }

  InputDecoration _modernDropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedYear,
      decoration: _modernDropdownDecoration('Year'),
      items: _availableYears
          .map(
            (year) =>
                DropdownMenuItem(value: year, child: Text(year.toString())),
          )
          .toList(),
      onChanged: _onYearSelected,
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedMonth,
      decoration: _modernDropdownDecoration('Month'),
      onChanged: _selectedYear == null
          ? null
          : (value) => setState(() => _selectedMonth = value),
      items: _availableMonthsForYear
          .map(
            (month) => DropdownMenuItem(
              value: month,
              child: Text(DateFormat('MMMM').format(DateTime(0, month))),
            ),
          )
          .toList(),
    );
  }

  Widget _buildContentArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_settlementData == null) {
      return const Center(
        child: Text(
          'No data fetched or settlement not found for the selected month.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: Column(
        children: [
          Text(
            'Allocation vs. Expense',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              SizedBox(
                height: 300,
                child: _buildSettlementChart(_settlementData!),
              ),
              const SizedBox(height: 12),
              _buildChartLegend(),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Settlement Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildSettlementTable(_settlementData!),
        ],
      ),
    );
  }

  Widget _buildSettlementChart(Settlement data) {
    List<BarChartGroupData> barGroups = [];
    int i = 0;

    // Sort keys to ensure consistent order (e.g., alphabetical or by predefined logic)
    // Here we just use the order from the allocations map
    final keys = data.allocations.keys.toList();

    for (var key in keys) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data.allocations[key] ?? 0,
              color: Colors.blue,
              width: 16,
            ),
            BarChartRodData(
              toY: data.expenses[key] ?? 0,
              color: Colors.red,
              width: 16,
            ),
          ],
        ),
      );
      i++;
    }
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          // ... right/top titles false
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  // Show first 3 chars of category name
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      keys[value.toInt()].substring(0, 3).toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        // ... rest same
      ),
    );
  }

  Widget _buildSettlementTable(Settlement data) {
    List<DataRow> rows = [];

    data.allocations.forEach((key, allocated) {
      final spent = data.expenses[key] ?? 0.0;
      final balance = allocated - spent;
      rows.add(_createDataRow(key, allocated, spent, balance));
    });

    // Add Total Row
    rows.add(
      DataRow(
        cells: [
          const DataCell(
            Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataCell(
            Text(
              _currencyFormat.format(data.totalIncome),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(data.totalExpense),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _currencyFormat.format(data.totalBalance),
                  style: TextStyle(
                    color: data.totalBalance >= 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return DataTable(
      columnSpacing: 20,
      columns: const [
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Allocated'), numeric: true),
        DataColumn(label: Text('Spent / Bal'), numeric: true),
      ],
      rows: rows,
    );
  }

  // ... rest of class
}

class SettlementInputSheet extends StatefulWidget {
  const SettlementInputSheet({super.key});
  @override
  State<SettlementInputSheet> createState() => _SettlementInputSheetState();
}

class SettlementInputSheet extends StatefulWidget {
  const SettlementInputSheet({super.key});
  @override
  State<SettlementInputSheet> createState() => _SettlementInputSheetState();
}

class _SettlementInputSheetState extends State<SettlementInputSheet> {
  // ... services variables

  FinancialRecord? _budgetRecord;
  // Dynamic controllers
  final Map<String, TextEditingController> _controllers = {};
  double _totalExpense = 0.0;

  // ...

  Future<void> _fetchData() async {
    // ... fetch logic
    setState(() {
      _budgetRecord = results[0] as FinancialRecord;
      _existingSettlement = results[1] as Settlement?;

      // Initialize controllers dynamically based on fetched record
      _controllers.clear();
      _budgetRecord!.allocations.keys.forEach((key) {
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
      });

      _calculateTotalExpense();
    });
  }

  void _calculateTotalExpense() {
    double sum = 0.0;
    _controllers.values.forEach((c) {
      sum += double.tryParse(c.text) ?? 0.0;
    });
    setState(() => _totalExpense = sum);
  }

  Future<void> _onSettle() async {
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

    // ... save logic
  }

 Widget _buildSettlementForm() {
    final totalBalance = _budgetRecord!.effectiveIncome - _totalExpense;
    
    return GestureDetector(
      onTap: () => setState(() => _isKeyboardVisible = false),
      child: ListView(
        children: [
          // Dynamic List
          ..._budgetRecord!.allocations.entries.map((entry) {
             return _buildSettlementRow(
                title: entry.key,
                allocated: entry.value,
                controller: _controllers[entry.key]!,
             );
          }),
          const Divider(),
          // ... Total Income / Balance Tiles (same as before)
        ],
      ),
    );
  }
  
  // ... rest of class

}
  Widget _buildSettlementRow({
    required String title,
    required double allocated,
    required TextEditingController controller,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('Allocated: ${_currencyFormat.format(allocated)}'),
      trailing: SizedBox(
        width: 150,
        child: TextFormField(
          controller: controller,
          readOnly: true,
          showCursor: true,
          decoration: const InputDecoration(
            labelText: 'Enter Expense',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ),
          onTap: () {
            setState(() {
              _isKeyboardVisible = true;
              _activeController = controller;
            });
          },
        ),
      ),
    );
  }
}

class _CalculatorKeyboard extends StatelessWidget {
  final void Function(String) onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onEquals;

  const _CalculatorKeyboard({
    required this.onKeyPress,
    required this.onBackspace,
    required this.onClear,
    required this.onEquals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withAlpha(240),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('('),
              _buildKey(')'),
              _buildKey('C', onAction: onClear, isFunction: true),
              _buildKey(
                '⌫',
                onAction: onBackspace,
                isFunction: true,
                icon: Icons.backspace_outlined,
              ),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
              _buildKey('÷', onAction: () => onKeyPress('/'), isFunction: true),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
              _buildKey('×', onAction: () => onKeyPress('*'), isFunction: true),
            ],
          ),
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
              _buildKey('-', isFunction: true),
            ],
          ),
          Row(
            children: [
              _buildKey('.'),
              _buildKey('0'),
              _buildKey(
                '=',
                onAction: onEquals,
                isFunction: true,
                isEquals: true,
              ),
              _buildKey('+', isFunction: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(
    String text, {
    VoidCallback? onAction,
    bool isFunction = false,
    bool isEquals = false,
    IconData? icon,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: isEquals
            ? FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: () =>
                    onAction != null ? onAction() : onKeyPress(text),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: isFunction
                      ? Colors.cyanAccent.shade400
                      : Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                child: icon != null
                    ? Icon(icon, size: 20)
                    : Text(
                        text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
      ),
    );
  }
}