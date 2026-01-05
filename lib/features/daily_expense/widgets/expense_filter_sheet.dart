import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_models.dart';

class ExpenseFilterSheet extends StatefulWidget {
  final List<ExpenseTransactionModel> allTxns;
  final String currentType;
  final String currentSort;
  final DateTimeRange? currentDateRange;
  final Set<String> currentCategories;
  final Set<String> currentBuckets;
  final Function(
    String type,
    String sort,
    DateTimeRange? range,
    Set<String> categories,
    Set<String> buckets,
  ) onApply;

  const ExpenseFilterSheet({
    super.key,
    required this.allTxns,
    required this.currentType,
    required this.currentSort,
    required this.currentDateRange,
    required this.currentCategories,
    required this.currentBuckets,
    required this.onApply,
  });

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late String _selectedType;
  late String _sortOption;
  DateTimeRange? _dateRange;
  late Set<String> _selectedCategories;
  late Set<String> _selectedBuckets;

  final Color _accentColor = const Color(0xFF00B4D8);

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
    _sortOption = widget.currentSort;
    _dateRange = widget.currentDateRange;
    _selectedCategories = Set.from(widget.currentCategories);
    _selectedBuckets = Set.from(widget.currentBuckets);
  }

  @override
  Widget build(BuildContext context) {
    final uniqueCategories =
        widget.allTxns.map((e) => e.category).toSet().toList()..sort();
    final uniqueBuckets = widget.allTxns.map((e) => e.bucket).toSet().toList()
      ..sort();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
            color: Color(0xff0D1B2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Filter & Sort",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = 'All';
                          _sortOption = 'Newest';
                          _dateRange = null;
                          _selectedCategories.clear();
                          _selectedBuckets.clear();
                        });
                        widget.onApply('All', 'Newest', null, {},
                            {}); // Instant apply on reset? Or wait?
                        // Actually standard behavior is just reset local state, user presses Apply.
                        // But to close logic we can keep it inside Apply.
                        Navigator.pop(
                            context); // Close on Reset as per original logic, or just reset state?
                        // Original logic did: Reset state AND pop.
                      },
                      child: const Text("Reset",
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("Sort By"),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _sortChip("Newest"),
                      _sortChip("Oldest"),
                      _sortChip("Amount High"),
                      _sortChip("Amount Low"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("Type"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _typeButton("All")),
                    const SizedBox(width: 6),
                    Expanded(child: _typeButton("Expense")),
                    const SizedBox(width: 6),
                    Expanded(child: _typeButton("Income")),
                    const SizedBox(width: 6),
                    Expanded(child: _typeButton("Transfer")),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("Date Range"),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: _accentColor,
                            onPrimary: Colors.white,
                            surface: const Color(0xFF1B263B),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (range != null) {
                      setState(() => _dateRange = range);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white54, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          _dateRange == null
                              ? "All Time"
                              : "${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        if (_dateRange != null)
                          GestureDetector(
                            onTap: () {
                              setState(() => _dateRange = null);
                            },
                            child: const Icon(Icons.close,
                                color: Colors.white54, size: 18),
                          )
                        else
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white24, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (uniqueBuckets.isNotEmpty) ...[
                  _buildSectionTitle("Buckets"),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          uniqueBuckets.map((b) => _bucketChip(b)).toList()),
                  const SizedBox(height: 24),
                ],
                if (uniqueCategories.isNotEmpty) ...[
                  _buildSectionTitle("Categories"),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: uniqueCategories
                          .map((c) => _categoryChip(c))
                          .toList()),
                  const SizedBox(height: 40),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        _selectedType,
                        _sortOption,
                        _dateRange,
                        _selectedCategories,
                        _selectedBuckets,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Apply Filters",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      );

  Widget _sortChip(String label) {
    final isSelected = _sortOption == label;
    return GestureDetector(
      onTap: () => setState(() => _sortOption = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _accentColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label) {
    final isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? _accentColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _accentColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _accentColor : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    final isSelected = _selectedCategories.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(label);
          } else {
            _selectedCategories.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _bucketChip(String label) {
    final isSelected = _selectedBuckets.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedBuckets.remove(label);
          } else {
            _selectedBuckets.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
