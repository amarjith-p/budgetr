import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'modern_dropdown.dart';

class DateFilterRow extends StatelessWidget {
  final int? selectedYear;
  final int? selectedMonth;
  final List<int> availableYears;
  final List<int> availableMonths;
  final Function(int?) onYearSelected;
  final Function(int?) onMonthSelected;
  final VoidCallback? onRefresh;
  final bool showRefresh;

  const DateFilterRow({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.availableYears,
    required this.availableMonths,
    required this.onYearSelected,
    required this.onMonthSelected,
    this.onRefresh,
    this.showRefresh = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ModernDropdownPill<int>(
            label: selectedYear?.toString() ?? 'Year',
            isActive: selectedYear != null,
            icon: Icons.calendar_today_outlined,
            onTap: () => showSelectionSheet<int>(
              context: context,
              title: 'Select Year',
              items: availableYears,
              labelBuilder: (y) => y.toString(),
              onSelect: onYearSelected,
              selectedItem: selectedYear,
              showReset: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ModernDropdownPill<int>(
            label: selectedMonth != null
                ? DateFormat('MMMM').format(DateTime(0, selectedMonth!))
                : 'Month',
            isActive: selectedMonth != null,
            icon: Icons.calendar_view_month_outlined,
            isEnabled: selectedYear != null,
            onTap: () => showSelectionSheet<int>(
              context: context,
              title: 'Select Month',
              items: availableMonths,
              labelBuilder: (m) => DateFormat('MMMM').format(DateTime(0, m)),
              onSelect: onMonthSelected,
              selectedItem: selectedMonth,
              showReset: true,
            ),
          ),
        ),
        if (showRefresh && onRefresh != null) ...[
          const SizedBox(width: 12), // Add spacing
          IconButton(
            icon: const Icon(Icons.downloading),
            onPressed: onRefresh,
            tooltip: 'Fetch Data',
          ),
        ],
      ],
    );
  }
}
