// features/budgets/components/budget_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/theme/design_tokens.dart';

class BudgetSummaryCard extends StatelessWidget {
  final double salaryIncome;
  final double extraIncome;
  final double deductions;
  final bool isClosed;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const BudgetSummaryCard({
    Key? key,
    required this.salaryIncome,
    required this.extraIncome,
    required this.deductions,
    this.isClosed = false,
    required this.onTap,
    required this.onEdit,
    required this.onClose,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveIncome = (salaryIncome + extraIncome) - deductions;
    final activeRadius = BorderRadius.circular(16.0);

    return Slidable(
      key: const ValueKey('budget_summary_card'),
      enabled: !isClosed,
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.transparent,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            padding: EdgeInsets.zero,
            child: Container(
              margin: const EdgeInsets.only(right: DesignTokens.spacingSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: activeRadius,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded),
                  SizedBox(height: 4),
                  Text(
                    'Edit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.50,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onClose(),
            backgroundColor: Colors.transparent,
            foregroundColor: theme.colorScheme.onTertiaryContainer,
            padding: EdgeInsets.zero,
            child: Container(
              margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: activeRadius,
                border: Border.all(
                  color: theme.colorScheme.tertiary.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded),
                  SizedBox(height: 4),
                  Text(
                    'Close',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.transparent,
            foregroundColor: theme.colorScheme.onErrorContainer,
            padding: EdgeInsets.zero,
            child: Container(
              margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: activeRadius,
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded),
                  SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: activeRadius,
          side: BorderSide(
            color: theme.dividerColor.withOpacity(0.6),
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: activeRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        if (isClosed)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: theme.colorScheme.error.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 10,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'CLOSED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.error,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'EFFECTIVE INCOME',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 10,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CurrencyText(
                            amount: effectiveIncome,
                            sign: '₹ ', // --- FIX: RUPEE SYMBOL RESTORED ---
                            amountStyle: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isClosed
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                            ),
                            symbolStyle: TextStyle(
                              fontSize: 14,
                              color:
                                  (isClosed
                                          ? theme.colorScheme.onSurfaceVariant
                                          : theme.colorScheme.primary)
                                      .withOpacity(0.8),
                            ),
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
                          'Salary',
                          salaryIncome,
                          Icons.work_outline_rounded,
                          theme.colorScheme.primary,
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildMiniRow(
                          'Extra',
                          extraIncome,
                          Icons.add_card_rounded,
                          Colors.blueAccent.shade400,
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildMiniRow(
                          'Deductions',
                          deductions,
                          Icons.remove_circle_outline_rounded,
                          theme.colorScheme.error,
                          theme,
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

  Widget _buildMiniRow(
    String title,
    double amount,
    IconData icon,
    Color color,
    ThemeData theme, {
    bool isDeduction = false,
  }) {
    final sign = isDeduction ? '-' : '+';
    final isZero = amount == 0.0;
    final displayColor = isClosed || isZero
        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4)
        : color;
    final textColor = isClosed || isZero
        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4)
        : (isDeduction ? theme.colorScheme.error : theme.colorScheme.onSurface);

    // --- FIX: SpaceBetween pulls labels left and amounts fully right ---
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: displayColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isZero
                    ? displayColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: CurrencyText(
              amount: amount,
              sign: '$sign ₹ ', // --- FIX: RUPEE SYMBOL RESTORED ---
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
          ),
        ),
      ],
    );
  }
}
