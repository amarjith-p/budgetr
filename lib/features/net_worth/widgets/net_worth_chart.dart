import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/net_worth_model.dart';

// --- DESIGN SYSTEM IMPORTS ---
import '../../../core/design/budgetr_colors.dart';
import '../../../core/design/budgetr_styles.dart';

class NetWorthChart extends StatelessWidget {
  final List<NetWorthRecord> sortedRecords;
  final NumberFormat currencyFormat;
  final Color accentColor;

  const NetWorthChart({
    super.key,
    required this.sortedRecords,
    required this.currencyFormat,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    int n = sortedRecords.length;

    for (int i = 0; i < n; i++) {
      double val = sortedRecords[i].amount;
      spots.add(FlSpot(i.toDouble(), val));
      sumX += i;
      sumY += val;
      sumXY += (i * val);
      sumXX += (i * i);
    }

    // Linear Regression for Trend Line
    List<FlSpot> trendSpots = [];
    if (n > 1) {
      double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
      double intercept = (sumY - slope * sumX) / n;
      for (int i = 0; i < n; i++) {
        trendSpots.add(FlSpot(i.toDouble(), slope * i + intercept));
      }
    }

    // Determine Y-Axis Interval
    double minY = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.isEmpty
        ? 100
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double range = maxY - minY;
    if (range == 0) range = maxY == 0 ? 100 : maxY;
    double interval = range / 4;
    if (interval == 0) interval = 10;

    // Adjust Y Range for padding
    double chartMinY = minY - (range * 0.1);
    double chartMaxY = maxY + (range * 0.1);

    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BudgetrColors.cardSurface.withOpacity(0.6),
        borderRadius: BudgetrStyles.radiusM,
        border: BudgetrStyles.glassBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("GROWTH TREND", style: BudgetrStyles.caption),
              if (n > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 14, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        "Linear Projection",
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: chartMinY,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value < minY || value > maxY) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          NumberFormat.compactCurrency(
                            symbol: '',
                            decimalDigits: 0,
                            locale: 'en_IN',
                          ).format(value),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < n) {
                          // FIX: Removed .toDate() as .date is already DateTime
                          final date = sortedRecords[index].date;

                          // Show label only for specific indices to avoid crowding
                          if (n > 6 && index % (n ~/ 4) != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM yy').format(date),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        BudgetrColors.background.withOpacity(0.95),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        if (spot.barIndex == 0) return null; // Skip Trend Line

                        // FIX: Removed .toDate() as .date is already DateTime
                        final date = sortedRecords[spot.x.toInt()].date;

                        return LineTooltipItem(
                          '${DateFormat('MMM yyyy').format(date)}\n',
                          const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: currencyFormat.format(spot.y),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Trend Line
                  LineChartBarData(
                    spots: trendSpots,
                    isCurved: false,
                    color: Colors.white.withOpacity(0.3),
                    barWidth: 1,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                  // Actual Data Line
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accentColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: accentColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.3),
                          accentColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
