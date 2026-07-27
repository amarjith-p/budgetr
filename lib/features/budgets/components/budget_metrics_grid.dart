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
      padding: const EdgeInsets.all(16), // Tighter outer padding
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16), // Tighter outer radius
        border: Border.all(color: isOverBudget ? theme.colorScheme.error.withOpacity(0.5) : theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // --- ROW 1: PRIMARY HERO METRICS ---
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
              Container(width: 1, height: 36, color: theme.dividerColor.withOpacity(0.5)), // Shorter divider
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
          
          const SizedBox(height: 16), // Reduced gap
          
          // --- ROW 2 & 3: COMPACT BENTO GRID ---
          Row(
            children: [
              Expanded(child: _buildCompactCard('Budget Limit', allocatedAmount, Icons.flag_outlined, theme)),
              const SizedBox(width: 8), // Tighter gap between columns
              Expanded(child: _buildCompactCard('Projected', projectedSpend, Icons.trending_up_rounded, theme, isError: isProjectedOver)),
            ],
          ),
          const SizedBox(height: 8), // Tighter gap between rows
          Row(
            children: [
              Expanded(child: _buildCompactCard('Current / Day', dailyAvg, Icons.data_usage_rounded, theme)),
              const SizedBox(width: 8), // Tighter gap between columns
              Expanded(child: _buildCompactCard('Target / Day', recDaily, Icons.track_changes_rounded, theme)),
            ],
          ),
        ],
      ),
    );
  }

  // Large, bold metrics framing the top of the card
  Widget _buildHeroMetric({
    required String title, 
    required double amount, 
    required ThemeData theme, 
    required bool isError,
    required CrossAxisAlignment alignment,
  }) {
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    final sign = amount < 0 ? '-' : '';
    
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title, 
          style: TextStyle(
            fontSize: 9, // Scaled down
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.0, 
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)
          )
        ),
        const SizedBox(height: 4), // Tighter gap
        CurrencyText(
          amount: amount.abs(),
          sign: '$sign₹',
          amountStyle: TextStyle(
            fontSize: 22, // Scaled down from 26
            fontWeight: FontWeight.w900, 
            letterSpacing: -1.0, 
            color: color
          ),
          symbolStyle: TextStyle(
            fontSize: 12, // Scaled down from 14
            color: color.withOpacity(0.8)
          ),
        ),
      ],
    );
  }

  // Soft, tinted inner cards for secondary metrics (Compact Version)
  Widget _buildCompactCard(String title, double amount, IconData icon, ThemeData theme, {bool isError = false}) {
    final isDark = theme.brightness == Brightness.dark;
    final color = isError ? theme.colorScheme.error : theme.colorScheme.onSurface;
    
    // Dynamic soft backgrounds based on theme and error state
    final bgColor = isError 
        ? theme.colorScheme.error.withOpacity(0.1) 
        : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03));

    final sign = amount < 0 ? '-' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Tighter inner padding
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10), // Tighter corner radius
        border: Border.all(
          color: isError ? theme.colorScheme.error.withOpacity(0.3) : Colors.transparent, 
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: isError ? color : theme.colorScheme.onSurfaceVariant), // Smaller icon
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(
                    fontSize: 10, // Scaled down from 11
                    fontWeight: FontWeight.w700, 
                    color: isError ? color : theme.colorScheme.onSurfaceVariant
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Tighter gap
          CurrencyText(
            amount: amount.abs(),
            sign: '$sign₹',
            amountStyle: TextStyle(
              fontSize: 14, // Scaled down from 16
              fontWeight: FontWeight.w900, 
              letterSpacing: -0.5, 
              color: color
            ),
            symbolStyle: TextStyle(
              fontSize: 10, // Scaled down from 12
              color: color.withOpacity(0.8)
            ),
          ),
        ],
      ),
    );
  }
}