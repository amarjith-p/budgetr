import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/percentage_config_model.dart';
import '../../../core/models/settlement_model.dart';

// --- DESIGN SYSTEM IMPORTS ---
import '../../../core/design/budgetr_colors.dart';
import '../../../core/design/budgetr_styles.dart';

class SettlementChart extends StatelessWidget {
  final Settlement settlement;
  final PercentageConfig? percentageConfig;

  const SettlementChart({
    super.key,
    required this.settlement,
    this.percentageConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: BudgetrColors.cardSurface.withOpacity(0.6),
        borderRadius: BudgetrStyles.radiusM,
        border: BudgetrStyles.glassBorder,
      ),
      child: Column(
        children: [
          SizedBox(height: 300, child: _buildChart(settlement)),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildChart(Settlement data) {
    final keys = data.allocations.keys.toList();
    // Sort logic
    keys.sort((a, b) {
      final pA =
          percentageConfig?.categories
              .firstWhere(
                (c) => c.name == a,
                orElse: () => CategoryConfig(name: '', percentage: 0),
              )
              .percentage ??
          0;
      final pB =
          percentageConfig?.categories
              .firstWhere(
                (c) => c.name == b,
                orElse: () => CategoryConfig(name: '', percentage: 0),
              )
              .percentage ??
          0;
      return pB.compareTo(pA); // Descending
    });

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final allocated = data.allocations[key] ?? 0;
      final spent = data.expenses[key] ?? 0;
      if (allocated > maxY) maxY = allocated;
      if (spent > maxY) maxY = spent;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: allocated,
              color: BudgetrColors.accent,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: spent,
              color: const Color(0xFFFF006E),
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
          barsSpace: 8,
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.1, // Add buffer
        barGroups: barGroups, // <--- FIXED: Added this line
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => BudgetrColors.cardSurface.withOpacity(0.9),
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final category = keys[group.x.toInt()];
              final type = rodIndex == 0 ? 'Allocated' : 'Spent';
              return BarTooltipItem(
                '$category\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text:
                        '$type: ${NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0).format(rod.toY)}',
                    style: TextStyle(
                      color: rod.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < keys.length) {
                  String text = keys[value.toInt()];
                  if (text.length > 3) text = text.substring(0, 3);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        text.toUpperCase(),
                        style: BudgetrStyles.caption.copyWith(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(BudgetrColors.accent, 'Allocated'),
        const SizedBox(width: 24),
        _legendItem(const Color(0xFFFF006E), 'Spent'),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: BudgetrStyles.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
