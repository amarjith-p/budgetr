import 'package:flutter/material.dart';
import '../../../core/components/currency_text.dart';

class BudgetMetricsGrid extends StatelessWidget {
  final double totalSpend;
  final double remainingBudget;
  final double allocatedAmount;
  final double projectedSpend;
  final double dailyAvg;
  final double recDaily;

  const BudgetMetricsGrid({
    Key? key,
    required this.totalSpend,
    required this.remainingBudget,
    required this.allocatedAmount,
    required this.projectedSpend,
    required this.dailyAvg,
    required this.recDaily,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOverBudget = totalSpend > allocatedAmount;
    final isProjectedOver = projectedSpend > allocatedAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverBudget
              ? theme.colorScheme.error.withOpacity(0.5)
              : theme.dividerColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  title: 'TOTAL SPENT',
                  amount: totalSpend,
                  theme: theme,
                  isError: isOverBudget,
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              // --- FIX: Added Spacing so they don't stick together on huge amounts ---
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 36,
                color: theme.dividerColor.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeroMetric(
                  title: 'REMAINING',
                  amount: remainingBudget,
                  theme: theme,
                  isError: remainingBudget < 0,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildCompactCard(
                  'Budget Limit',
                  allocatedAmount,
                  Icons.flag_outlined,
                  theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactCard(
                  'Projected',
                  projectedSpend,
                  Icons.trending_up_rounded,
                  theme,
                  isError: isProjectedOver,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactCard(
                  'Current / Day',
                  dailyAvg,
                  Icons.data_usage_rounded,
                  theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactCard(
                  'Target / Day',
                  recDaily,
                  Icons.track_changes_rounded,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required String title,
    required double amount,
    required ThemeData theme,
    required bool isError,
    required CrossAxisAlignment alignment,
  }) {
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    final sign = amount < 0 ? '-' : '';
    final boxAlignment = alignment == CrossAxisAlignment.end
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: boxAlignment,
          child: CurrencyText(
            amount: amount.abs(),
            sign: '$sign₹ ',
            amountStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: color,
            ),
            symbolStyle: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCard(
    String title,
    double amount,
    IconData icon,
    ThemeData theme, {
    bool isError = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final color = isError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    final bgColor = isError
        ? theme.colorScheme.error.withOpacity(0.1)
        : (isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.03));

    final sign = amount < 0 ? '-' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? theme.colorScheme.error.withOpacity(0.3)
              : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: isError ? color : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isError ? color : theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurrencyText(
              amount: amount.abs(),
              sign: '$sign₹ ',
              amountStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: color,
              ),
              symbolStyle: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
