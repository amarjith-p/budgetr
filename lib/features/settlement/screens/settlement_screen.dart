import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aurora_scaffold.dart';
import '../../../core/widgets/glass_app_bar.dart'; // Centralized AppBar
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_fab.dart'; // Centralized FAB
import '../../../core/widgets/glass_bottom_sheet.dart'; // Centralized Sheet
import '../../../core/widgets/modern_loader.dart';

import '../../../core/models/percentage_config_model.dart';
import '../../../core/models/settlement_model.dart';
import '../../../core/widgets/date_filter_row.dart';
import '../../settings/services/settings_service.dart';
import '../services/settlement_service.dart';
import '../widgets/settlement_chart.dart';
import '../widgets/settlement_input_sheet.dart';
import '../widgets/settlement_table.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final _settlementService = SettlementService();
  final _settingsService = SettingsService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  List<Map<String, int>> _yearMonthData = [];
  List<int> _availableYears = [];
  List<int> _availableMonthsForYear = [];
  int? _selectedYear;
  int? _selectedMonth;

  bool _isLoading = false;
  Settlement? _settlementData;
  PercentageConfig? _percentageConfig;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    _yearMonthData = await _settlementService.getAvailableMonthsForSettlement();
    final years = _yearMonthData.map((e) => e['year']!).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    _availableYears = years;

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
    HapticFeedback.lightImpact();
    if (_selectedYear == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a year and month.'),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _settlementData = null;
    });

    try {
      final latestConfig = await _settingsService.getPercentageConfig();
      final recordId =
          '$_selectedYear${_selectedMonth.toString().padLeft(2, '0')}';
      final settlement = await _settlementService.getSettlementById(recordId);

      setState(() {
        _percentageConfig = latestConfig;
        _settlementData = settlement;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showSettlementInputSheet() {
    // Using Centralized GlassBottomSheet
    GlassBottomSheet.show(context, child: const SettlementInputSheet()).then((
      _,
    ) {
      if (_selectedYear != null && _selectedMonth != null) {
        _fetchSettlementData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      accentColor1: AppColors.royalBlue,
      accentColor2: AppColors.vibrantOrange,

      // Centralized Glass App Bar
      appBar: const GlassAppBar(title: 'Settlement Analysis'),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: DateFilterRow(
                    selectedYear: _selectedYear,
                    selectedMonth: _selectedMonth,
                    availableYears: _availableYears,
                    availableMonths: _availableMonthsForYear,
                    onYearSelected: _onYearSelected,
                    onMonthSelected: (val) =>
                        setState(() => _selectedMonth = val),
                    showRefresh: false,
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: _fetchSettlementData,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        // Centralized Gradient
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'FETCH DATA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Expanded(child: _buildContentArea()),
              ],
            ),
          ),

          // Centralized Glass FAB
          GlassFAB(
            label: "Update Settlement",
            icon: Icons.edit_note_rounded,
            onTap: _showSettlementInputSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (_isLoading) {
      return const Center(child: ModernLoader());
    }

    if (_settlementData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a month to view analysis',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Allocation vs. Expense',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 24,
            child: SettlementChart(
              settlement: _settlementData!,
              percentageConfig: _percentageConfig,
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'Settlement Details',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.all(8),
            borderRadius: 24,
            child: SettlementTable(
              settlement: _settlementData!,
              percentageConfig: _percentageConfig,
              currencyFormat: _currencyFormat,
            ),
          ),
        ],
      ),
    );
  }
}
