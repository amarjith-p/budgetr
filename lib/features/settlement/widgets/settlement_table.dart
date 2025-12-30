import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/percentage_config_model.dart';
import '../../../core/models/settlement_model.dart';

class SettlementTable extends StatelessWidget {
  final Settlement settlement;
  final PercentageConfig? percentageConfig;
  final NumberFormat currencyFormat;

  const SettlementTable({
    super.key,
    required this.settlement,
    this.percentageConfig,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final entries = settlement.allocations.entries.toList();

    // Sorting Logic (Preserved)
    if (percentageConfig != null) {
      entries.sort((a, b) {
        int idxA = percentageConfig!.categories.indexWhere(
          (c) => c.name == a.key,
        );
        int idxB = percentageConfig!.categories.indexWhere(
          (c) => c.name == b.key,
        );
        if (idxA == -1) idxA = 999;
        if (idxB == -1) idxB = 999;
        return idxA.compareTo(idxB);
      });
    } else {
      entries.sort((a, b) => b.value.compareTo(a.value));
    }

    return Column(
      children: [
        // 1. Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _buildHeaderCell(
                "Bucket",
                flex: 4,
                align: CrossAxisAlignment.start,
              ),
              _buildHeaderCell(
                "Allocated",
                flex: 3,
                align: CrossAxisAlignment.end,
              ),
              _buildHeaderCell(
                "Spent / Bal",
                flex: 3,
                align: CrossAxisAlignment.end,
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white12, height: 1),

        // 2. Data Rows
        ...entries.map((entry) {
          final key = entry.key;
          final allocated = entry.value;
          final spent = settlement.expenses[key] ?? 0.0;
          final balance = allocated - spent;

          return Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                // Bucket Name
                Expanded(
                  flex: 4,
                  child: Text(
                    key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Allocated Amount
                Expanded(
                  flex: 3,
                  child: Text(
                    currencyFormat.format(allocated),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
                // Spent / Balance Column
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currencyFormat.format(spent),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(balance),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0
                              ? AppColors.successGreen
                              : AppColors.dangerRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // 3. Total Row (Footer)
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.royalBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  currencyFormat.format(settlement.totalIncome),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(settlement.totalExpense),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currencyFormat.format(settlement.totalBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: settlement.totalBalance >= 0
                            ? AppColors.successGreen
                            : AppColors.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(
    String text, {
    required int flex,
    required CrossAxisAlignment align,
  }) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.royalBlue,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
