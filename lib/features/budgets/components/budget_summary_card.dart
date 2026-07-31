import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/components/currency_text.dart';

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

    return Slidable(
      enabled: !isClosed, 
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.65, 
        children: [
          // --- PERFECTED BOXY SLIDABLE ACTIONS ---
          _buildBoxyAction(
            label: 'Edit',
            icon: Icons.edit_rounded,
            color: Colors.blueAccent.shade700,
            onTap: onEdit,
          ),
          _buildBoxyAction(
            label: 'Close',
            icon: Icons.lock_rounded,
            color: Colors.orangeAccent.shade700,
            onTap: onClose,
          ),
          _buildBoxyAction(
            label: 'Delete',
            icon: Icons.delete_rounded,
            color: theme.colorScheme.error,
            onTap: onDelete,
          ),
        ],
      ),
      child: Container(
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
            onTap: onTap,
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
                          // --- FIX: INTEGRATED CLOSED BADGE ---
                          if (isClosed)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded, size: 10, color: theme.colorScheme.error),
                                  const SizedBox(width: 4),
                                  Text('CLOSED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.colorScheme.error, letterSpacing: 1.0)),
                                ],
                              ),
                            ),
                          
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
                              color: isClosed ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary, 
                            ),
                            symbolStyle: TextStyle(
                              fontSize: 14,
                              color: (isClosed ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary).withOpacity(0.8),
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
                          _buildMiniRow('Salary', salaryIncome, Icons.work_outline_rounded, theme.colorScheme.primary, theme),
                          const SizedBox(height: 8),
                          _buildMiniRow('Extra', extraIncome, Icons.add_card_rounded, Colors.blueAccent.shade400, theme),
                          const SizedBox(height: 8),
                          _buildMiniRow('Deductions', deductions, Icons.remove_circle_outline_rounded, theme.colorScheme.error, theme, isDeduction: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- FIX: MARGIN PADDING TO MATCH BOXY SLIDABLE CARD ---
  Widget _buildBoxyAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomSlidableAction(
      onPressed: (_) => onTap(),
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero, 
      child: Container(
        margin: const EdgeInsets.only(left: 8), 
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16), 
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 6),
            Text(
              label, 
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniRow(String title, double amount, IconData icon, Color color, ThemeData theme, {bool isDeduction = false}) {
    final sign = isDeduction ? '-' : '+';
    final isZero = amount == 0.0;
    
    final displayColor = isClosed || isZero ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4) : color;
    final textColor = isClosed || isZero ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4) : (isDeduction ? theme.colorScheme.error : theme.colorScheme.onSurface);

    return Row(
      children: [
        Icon(icon, size: 12, color: displayColor), 
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isZero ? displayColor : theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        CurrencyText(
          amount: amount,
          sign: '$sign₹',
          amountStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: textColor),
          symbolStyle: TextStyle(fontSize: 9, color: textColor.withOpacity(0.7)),
        ),
      ],
    );
  }
}