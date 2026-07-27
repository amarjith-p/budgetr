import 'package:flutter/material.dart';
import '../../../core/components/currency_text.dart';

class BudgetSummaryCard extends StatelessWidget {
  final double salaryIncome;
  final double extraIncome;
  final double deductions;
  final VoidCallback onTap; // <-- NEW: Added tap handler

  const BudgetSummaryCard({
    Key? key,
    required this.salaryIncome,
    required this.extraIncome,
    required this.deductions,
    required this.onTap, // <-- NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveIncome = (salaryIncome + extraIncome) - deductions;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap, // <-- NEW: Attached tap handler
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor, width: 1.0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // --- LEFT COLUMN: HERO METRIC ---
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'EFFECTIVE INCOME',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new_rounded, size: 10, color: theme.colorScheme.primary.withOpacity(0.5)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        CurrencyText(
                          amount: effectiveIncome,
                          sign: '₹',
                          amountStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: theme.colorScheme.primary,
                          ),
                          symbolStyle: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.primary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // --- VERTICAL DIVIDER ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: VerticalDivider(
                      width: 1, 
                      thickness: 1, 
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),

                  // --- RIGHT COLUMN: DENSE BREAKDOWN ---
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMiniRow(
                          title: 'Salary',
                          amount: salaryIncome,
                          icon: Icons.work_outline_rounded,
                          color: theme.colorScheme.primary,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildMiniRow(
                          title: 'Extra',
                          amount: extraIncome,
                          icon: Icons.add_card_rounded,
                          color: Colors.blueAccent.shade400, 
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildMiniRow(
                          title: 'Deductions',
                          amount: deductions,
                          icon: Icons.remove_circle_outline_rounded,
                          color: theme.colorScheme.error,
                          theme: theme,
                          isDeduction: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- ULTRA COMPACT INLINE LIST ROW ---
  Widget _buildMiniRow({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    bool isDeduction = false,
  }) {
    final sign = isDeduction ? '-' : '+';
    
    final isZero = amount == 0.0;
    final displayColor = isZero ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4) : color;
    final textColor = isZero ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4) : (isDeduction ? theme.colorScheme.error : theme.colorScheme.onSurface);

    return Row(
      children: [
        Icon(icon, size: 12, color: displayColor), 
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isZero ? displayColor : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        CurrencyText(
          amount: amount,
          sign: '$sign₹',
          amountStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: textColor,
          ),
          symbolStyle: TextStyle(
            fontSize: 9,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}