import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/percentage_config_model.dart';
import '../../../core/models/settlement_model.dart';

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
    // Note: External decoration removed as this widget is now wrapped
    // in a GlassCard in the parent screen.
    return Column(
      children: [
        SizedBox(height: 300, child: _buildChart(settlement)),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildChart(Settlement data) {
    final keys = data.allocations.keys.toList();

    // Sorting Logic
    if (percentageConfig != null) {
      keys.sort((a, b) {
        int idxA = percentageConfig!.categories.indexWhere((c) => c.name == a);
        int idxB = percentageConfig!.categories.indexWhere((c) => c.name == b);
        if (idxA == -1) idxA = 999;
        if (idxB == -1) idxB = 999;
        return idxA.compareTo(idxB);
      });
    } else {
      keys.sort(
        (a, b) =>
            (data.allocations[b] ?? 0).compareTo(data.allocations[a] ?? 0),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(keys.length, (index) {
          final key = keys[index];
          final allocated = data.allocations[key] ?? 0.0;
          final spent = data.expenses[key] ?? 0.0;

          return BarChartGroupData(
            x: index,
            barRods: [
              // Allocated Bar (Royal Blue)
              BarChartRodData(
                toY: allocated,
                color: AppColors.royalBlue,
                width: 12,
                borderRadius: BorderRadius.circular(2),
                backDrawRodData: BackgroundBarChartRodData(show: false),
              ),
              // Spent Bar (Electric Pink)
              BarChartRodData(
                toY: spent,
                color: AppColors.electricPink,
                width: 12,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compact().format(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  String text = keys[value.toInt()];
                  if (text.length > 3) text = text.substring(0, 3);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        text.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppColors.royalBlue, 'Allocated'),
        const SizedBox(width: 24),
        _legendItem(AppColors.electricPink, 'Spent'),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
