import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/financial_record_model.dart';

class BudgetAllocationsList extends StatelessWidget {
  final FinancialRecord record;
  final NumberFormat currencyFormat;

  const BudgetAllocationsList({
    super.key,
    required this.record,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final entries = record.allocations.entries.toList();
    // Sort by value descending
    entries.sort((a, b) => b.value.compareTo(a.value));

    final Color cardColor = const Color(0xFF1B263B).withOpacity(0.6);
    final Color accentColor = const Color(0xFF3A86FF);

    return Column(
      children: entries.map((entry) {
        final percent = record.allocationPercentages[entry.key] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
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
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                "${percent.toInt()}%",
                style: TextStyle(
                  color: accentColor,
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
              currencyFormat.format(entry.value),
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
}
