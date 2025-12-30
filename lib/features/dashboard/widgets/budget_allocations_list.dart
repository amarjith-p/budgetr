import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/financial_record_model.dart';
import '../../../core/design/budgetr_colors.dart';
import '../screens/bucket_details_screen.dart'; // Import new screen

class BudgetAllocationsList extends StatelessWidget {
  final FinancialRecord record;
  final NumberFormat currencyFormat;
  final Map<String, double> spendingMap;

  const BudgetAllocationsList({
    super.key,
    required this.record,
    required this.currencyFormat,
    this.spendingMap = const {},
  });

  @override
  Widget build(BuildContext context) {
    final entries = record.allocations.entries.toList();
    // Sort by value descending
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.map((entry) {
        final bucketName = entry.key;
        final allocated = entry.value;
        final percent = record.allocationPercentages[bucketName] ?? 0;

        // Spending Calculations
        final spent = spendingMap[bucketName] ?? 0.0;
        final remaining = allocated - spent;
        final double progress = allocated > 0
            ? (spent / allocated).clamp(0.0, 1.0)
            : 0.0;

        final bool isOverBudget = spent > allocated;

        return GestureDetector(
          // NEW: Navigation Logic on Tap
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BucketDetailsScreen(
                  bucketName: bucketName,
                  year: record.year,
                  month: record.month,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BudgetrColors.cardSurface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                // Top Row: Percentage | Name | Allocation
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BudgetrColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${percent.toInt()}%",
                        style: const TextStyle(
                          color: BudgetrColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        bucketName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Optional: Chevron to indicate clickability
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white24,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(allocated),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar (Sticky Bar)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation(
                      isOverBudget ? Colors.redAccent : BudgetrColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom Row: Spent vs Remaining/Over
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Used: ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: currencyFormat.format(spent),
                            style: TextStyle(
                              color: isOverBudget
                                  ? Colors.redAccent
                                  : Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: isOverBudget ? "Over: " : "Left: ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: currencyFormat.format(remaining.abs()),
                            style: TextStyle(
                              color: isOverBudget
                                  ? Colors.redAccent
                                  : const Color(0xFF00E676),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
