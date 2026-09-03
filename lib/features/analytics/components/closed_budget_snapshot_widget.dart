import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/futuristic_loader.dart';
import '../../../core/constants/date_time_constants.dart';

// --- LOCAL PROVIDER: Fetches snapshot by joining with MonthlyBudgets ---
final _snapshotForMonthProvider = StreamProvider.family
    .autoDispose<ClosedBudgetSnapshot?, DateTime>((ref, date) {
      final db = ref.watch(databaseProvider);

      final query =
          db.select(db.closedBudgetSnapshots).join([
            drift.innerJoin(
              db.monthlyBudgets,
              db.monthlyBudgets.id.equalsExp(db.closedBudgetSnapshots.budgetId),
            ),
          ])..where(
            db.monthlyBudgets.month.equals(date.month) &
                db.monthlyBudgets.year.equals(date.year),
          );

      return query.watchSingleOrNull().map(
        (row) => row?.readTableOrNull(db.closedBudgetSnapshots),
      );
    });

class _ParsedBucketData {
  final String name;
  final double allocated;
  final double spent;

  _ParsedBucketData({
    required this.name,
    required this.allocated,
    required this.spent,
  });
}

class ClosedBudgetSnapshotWidget extends ConsumerStatefulWidget {
  const ClosedBudgetSnapshotWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ClosedBudgetSnapshotWidget> createState() =>
      _ClosedBudgetSnapshotWidgetState();
}

class _ClosedBudgetSnapshotWidgetState
    extends ConsumerState<ClosedBudgetSnapshotWidget> {
  // --- FIX: Default to Last Month natively ---
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month - 1,
  );

  // --- MODERN MONTH/YEAR PICKER DIALOG ---
  Future<void> _pickMonthYear() async {
    HapticFeedback.selectionClick();
    DateTime tempDate = _selectedMonth;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Dialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setDialogState(
                              () => tempDate = DateTime(
                                tempDate.year - 1,
                                tempDate.month,
                              ),
                            );
                          },
                        ),
                        Text(
                          '${tempDate.year}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setDialogState(
                              () => tempDate = DateTime(
                                tempDate.year + 1,
                                tempDate.month,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(12, (index) {
                        final m = index + 1;
                        final isSelected =
                            tempDate.year == _selectedMonth.year &&
                            m == _selectedMonth.month;

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx, DateTime(tempDate.year, m));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(isDark ? 0.3 : 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                DateTimeConstants.shortMonths[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
    }
  }

  List<_ParsedBucketData> _parseBuckets(ClosedBudgetSnapshot snapshot) {
    try {
      final List<dynamic> decoded = jsonDecode(snapshot.bucketDetailsJson);
      return decoded.map((e) {
        return _ParsedBucketData(
          name: e['name']?.toString() ?? 'Unknown',
          allocated: (e['allocated'] ?? e['budgeted'] ?? 0.0).toDouble(),
          spent: (e['spent'] ?? 0.0).toDouble(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildMetric(
    String label,
    double amount,
    ThemeData theme, {
    bool isDeduction = false,
  }) {
    final displayAmount = (isDeduction && amount > 0) ? -amount : amount;
    final isNegative = displayAmount < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: CurrencyText(
            amount: displayAmount,
            amountStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isNegative
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            symbolStyle: TextStyle(
              fontSize: 10,
              color:
                  (isNegative
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface)
                      .withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final snapshotAsync = ref.watch(_snapshotForMonthProvider(_selectedMonth));

    final allocatedColor = Colors.green.shade600;
    final spentColor = theme.colorScheme.error.withOpacity(0.9);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BUDGET SNAPSHOT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _pickMonthYear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateTimeConstants.shortMonths[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          snapshotAsync.when(
            loading: () => const SizedBox(
              height: 250,
              child: Center(
                child: FuturisticLoader(size: 80, label: "LOADING SNAPSHOT.."),
              ),
            ),
            error: (e, st) =>
                SizedBox(height: 250, child: Center(child: Text('Error: $e'))),
            data: (snapshot) {
              if (snapshot == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No snapshot found.\nBudget must be closed to generate insights.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }

              final buckets = _parseBuckets(snapshot);

              // --- NEW: Calculate Total Spend of that month's budget ---
              final double totalBudgetSpent = buckets.fold(
                0.0,
                (sum, b) => sum + b.spent,
              );

              double maxY = 0;
              for (var b in buckets) {
                final highest = max(b.allocated, b.spent);
                if (highest > maxY) maxY = highest;
              }
              maxY = maxY > 0 ? maxY * 1.15 : 1000;

              double yInterval = maxY > 0 ? (maxY / 4) : 250.0;

              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            'Salary',
                            snapshot.salaryIncome,
                            theme,
                          ),
                        ),
                        VerticalDivider(
                          color: theme.dividerColor.withOpacity(0.4),
                          thickness: 1,
                          width: 24,
                        ),
                        Expanded(
                          child: _buildMetric(
                            'Extra Inc.',
                            snapshot.extraIncome,
                            theme,
                          ),
                        ),
                        VerticalDivider(
                          color: theme.dividerColor.withOpacity(0.4),
                          thickness: 1,
                          width: 24,
                        ),
                        Expanded(
                          child: _buildMetric(
                            'Deductions',
                            snapshot.deductions,
                            theme,
                            isDeduction: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            'Out Bucket',
                            snapshot.totalOutOfBucket,
                            theme,
                            isDeduction: true,
                          ),
                        ),
                        VerticalDivider(
                          color: theme.dividerColor.withOpacity(0.4),
                          thickness: 1,
                          width: 24,
                        ),
                        Expanded(
                          // --- CHANGED: Displays Total Budgeted Spend ---
                          child: _buildMetric(
                            'Budget Spent',
                            totalBudgetSpent,
                            theme,
                            isDeduction:
                                true, // Ensures it renders in red like an expense
                          ),
                        ),
                        VerticalDivider(
                          color: theme.dividerColor.withOpacity(0.4),
                          thickness: 1,
                          width: 24,
                        ),
                        Expanded(
                          child: _buildMetric(
                            'Net Saved',
                            snapshot.totalRemaining,
                            theme,
                            isDeduction: snapshot.totalRemaining < 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(color: allocatedColor, label: 'Allocated'),
                      const SizedBox(width: 16),
                      _LegendItem(color: spentColor, label: 'Spent'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (buckets.isEmpty)
                    const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('No bucket data found in snapshot.'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipPadding: const EdgeInsets.all(12),
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final b = buckets[groupIndex];

                                final savedAmount = b.allocated - b.spent;
                                final bool isSaved = savedAmount >= 0;
                                final String savedLabel = isSaved
                                    ? 'Saved'
                                    : 'Overspent';
                                final Color savedColor = isSaved
                                    ? Colors.greenAccent.shade100
                                    : Colors.orangeAccent.shade100;

                                return BarTooltipItem(
                                  '${b.name}\n',
                                  const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          'Allocated: ₹ ${CurrencyFormatter.format(b.allocated)}\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                        color: Colors.blueGrey.shade100,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'Spent: ₹ ${CurrencyFormatter.format(b.spent)}\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                        color: Colors.blueGrey.shade100,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '$savedLabel: ₹ ${CurrencyFormatter.format(savedAmount.abs())}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                        color: savedColor,
                                      ),
                                    ),
                                  ],
                                );
                              },
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
                                reservedSize: 40,
                                interval: yInterval,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0 || value == maxY)
                                    return const SizedBox.shrink();
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 4,
                                    child: Text(
                                      _compactAmount(value),
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  if (value < 0 || value >= buckets.length)
                                    return const SizedBox.shrink();

                                  String rawName = buckets[value.toInt()].name;
                                  String shortName = rawName.length > 3
                                      ? rawName.substring(0, 3)
                                      : rawName;

                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 8,
                                    child: Text(
                                      shortName.toUpperCase(),
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: yInterval,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: theme.dividerColor.withOpacity(0.5),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          barGroups: buckets.asMap().entries.map((entry) {
                            final index = entry.key;
                            final bucket = entry.value;

                            return BarChartGroupData(
                              x: index,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: bucket.allocated,
                                  color: allocatedColor,
                                  width: 10,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: bucket.spent,
                                  color: spentColor,
                                  width: 10,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _compactAmount(double amount) {
    if (amount >= 10000000)
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
