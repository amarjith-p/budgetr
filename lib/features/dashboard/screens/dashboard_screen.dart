import 'package:budget/core/widgets/modern_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/financial_record_model.dart';
import '../../../core/widgets/modern_dropdown.dart';
import '../services/dashboard_service.dart';
import '../widgets/add_record_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();

  // Center the page controller at a large index to allow infinite-like scrolling
  final int _initialIndex = 12 * 50;
  late final PageController _pageController;

  // Theme Constants
  final Color _bgColor = const Color(0xff0D1B2A);
  final Color _accentColor = const Color(0xFF3A86FF);
  final Color _cardColor = const Color(0xFF1B263B).withOpacity(0.6);
  final Color _greenColor = const Color(0xFF00E676);
  final Color _redColor = const Color(0xFFFF5252);

  DateTime _currentDate = DateTime.now();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final now = DateTime.now();
    final diff = index - _initialIndex;
    setState(() {
      _currentDate = DateTime(now.year, now.month + diff);
    });
  }

  // --- JUMP TO DATE LOGIC ---
  void _showJumpToDateSheet() {
    HapticFeedback.lightImpact();

    // Lists for Dropdowns
    final years = List.generate(
      20,
      (index) => DateTime.now().year - 10 + index,
    );
    final months = List.generate(12, (index) => index + 1);

    int selectedYear = _currentDate.year;
    int selectedMonth = _currentDate.month;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
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
                  "Jump to Date",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Selectors
                Row(
                  children: [
                    // Year
                    Expanded(
                      child: ModernDropdownPill<int>(
                        label: selectedYear.toString(),
                        isActive: true,
                        icon: Icons.calendar_today,
                        onTap: () => showSelectionSheet<int>(
                          context: context,
                          title: 'Select Year',
                          items: years,
                          labelBuilder: (y) => y.toString(),
                          // FIX: Handle nullable value from selection
                          onSelect: (val) {
                            if (val != null) {
                              setModalState(() => selectedYear = val);
                            }
                          },
                          selectedItem: selectedYear,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Month
                    Expanded(
                      child: ModernDropdownPill<int>(
                        label: DateFormat(
                          'MMM',
                        ).format(DateTime(0, selectedMonth)),
                        isActive: true,
                        icon: Icons.calendar_view_month,
                        onTap: () => showSelectionSheet<int>(
                          context: context,
                          title: 'Select Month',
                          items: months,
                          labelBuilder: (m) =>
                              DateFormat('MMMM').format(DateTime(0, m)),
                          // FIX: Handle nullable value from selection
                          onSelect: (val) {
                            if (val != null) {
                              setModalState(() => selectedMonth = val);
                            }
                          },
                          selectedItem: selectedMonth,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Go Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final monthDiff =
                          (selectedYear - now.year) * 12 +
                          (selectedMonth - now.month);
                      final targetIndex = _initialIndex + monthDiff;

                      Navigator.pop(context);

                      _pageController.animateToPage(
                        targetIndex,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Go to Month",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddRecordSheet([FinancialRecord? record]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => AddRecordSheet(recordToEdit: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Budget Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- Month Selector ---
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final now = DateTime.now();
                final diff = index - _initialIndex;
                final date = DateTime(now.year, now.month + diff);

                return Center(
                  child: GestureDetector(
                    onTap: _showJumpToDateSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMMM yyyy').format(date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_drop_down,
                            color: _accentColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- Content ---
          Expanded(
            child: StreamBuilder<List<FinancialRecord>>(
              stream: _dashboardService.getFinancialRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: ModernLoader());
                }

                final records = snapshot.data ?? [];
                final currentRecord = records.firstWhere(
                  (r) =>
                      r.year == _currentDate.year &&
                      r.month == _currentDate.month,
                  orElse: () => FinancialRecord(
                    id: '',
                    salary: 0,
                    extraIncome: 0,
                    emi: 0,
                    year: _currentDate.year,
                    month: _currentDate.month,
                    effectiveIncome: 0,
                    allocations: {},
                    allocationPercentages: {},
                    createdAt: Timestamp.now(),
                  ),
                );

                final hasData = currentRecord.id.isNotEmpty;

                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        children: [
                          if (hasData) ...[
                            _buildSummaryCard(currentRecord),
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Budget Allocations",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAllocationsList(currentRecord),
                          ] else
                            _buildEmptyState(),
                        ],
                      ),
                    ),

                    // --- Floating Glass Capsule ---
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _showAddRecordSheet(
                            hasData ? currentRecord : null,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_accentColor, const Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasData
                                      ? Icons.edit_outlined
                                      : Icons.add_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  hasData ? "Edit Budget" : "Create Budget",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(FinancialRecord record) {
    final totalIncome = record.salary + record.extraIncome;
    final totalDeductions = record.emi;
    final balance = record.effectiveIncome;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardColor, _cardColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "NET EFFECTIVE INCOME",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  "Gross Income",
                  totalIncome,
                  _greenColor,
                  Icons.arrow_downward,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _summaryItem(
                  "Deductions",
                  totalDeductions,
                  _redColor,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationsList(FinancialRecord record) {
    final entries = record.allocations.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.map((entry) {
        final percent = record.allocationPercentages[entry.key] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                "${percent.toInt()}%",
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              entry.key,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Text(
              _currencyFormat.format(entry.value),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Budget Found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap 'Create Budget' to plan\nfor ${DateFormat('MMMM').format(_currentDate)}.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
