import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/modern_boxy_button.dart';

class CloseBudgetConfirmationSheet extends StatelessWidget {
  final double salaryIncome;
  final double extraIncome;
  final double deductions;
  final double effectiveIncome;
  final double totalSpent;
  final double outOfBucket;
  final double totalRemaining;
  final double budgetedRemaining;
  final List<Map<String, dynamic>> bucketDetails;

  const CloseBudgetConfirmationSheet({
    Key? key,
    required this.salaryIncome,
    required this.extraIncome,
    required this.deductions,
    required this.effectiveIncome,
    required this.totalSpent,
    required this.outOfBucket,
    required this.totalRemaining,
    required this.budgetedRemaining,
    required this.bucketDetails,
  }) : super(key: key);

  // --- BIG HERO BOXY METRIC ---
  Widget _buildBoxyMetric(String label, double amount, Color color, ThemeData theme) {
    final sign = amount < 0 ? '-₹' : '₹';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: color.withOpacity(0.3), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: color,
              ),
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CurrencyText(
                amount: amount.abs(),
                sign: sign,
                amountStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: color,
                ),
                symbolStyle: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DETAILED BREAKDOWN LIST ROW ---
  Widget _buildDetailRow(String label, double amount, ThemeData theme, {Color? customColor, bool isDeduction = false}) {
    final displayColor = customColor ?? theme.colorScheme.onSurface;
    final sign = isDeduction ? '-₹' : (amount < 0 ? '-₹' : '₹');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: CurrencyText(
                  amount: amount.abs(),
                  sign: sign,
                  amountStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: displayColor, letterSpacing: -0.5),
                  symbolStyle: TextStyle(fontSize: 10, color: displayColor.withOpacity(0.7)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MINI INLINE METRIC FOR BUCKETS ---
  Widget _buildMiniMetric(String label, double amount, Color color) {
    final sign = amount < 0 ? '-₹' : '₹';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color.withOpacity(0.8)), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurrencyText(
              amount: amount.abs(), 
              sign: sign, 
              amountStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5), 
              symbolStyle: TextStyle(fontSize: 10, color: color.withOpacity(0.8))
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Semantic Colors based on global theme
    final spendColor = TransactionColors.expense(theme);
    final incomeColor = TransactionColors.income(theme);
    final warningColor = Colors.orangeAccent.shade700;
    
    final budgetedSpent = totalSpent - outOfBucket;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Close Budget', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('Review your final monthly metrics before locking.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // SCROLLABLE CONTENT
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(DesignTokens.spacingLg),
                  children: [
                    
                    // --- SECTION 1: INCOME SUMMARY ---
                    Text('INCOME SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)),
                    const SizedBox(height: DesignTokens.spacingMd),
                    
                    Row(
                      children: [
                        _buildBoxyMetric('EFFECTIVE INCOME', effectiveIncome, theme.colorScheme.primary, theme),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingSm),
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacingMd),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Salary Income', salaryIncome, theme),
                          _buildDetailRow('Extra Income', extraIncome, theme),
                          _buildDetailRow('Deductions', deductions, theme, customColor: spendColor, isDeduction: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacingXl),

                    // --- SECTION 2: SPENDING & REMAINING ---
                    Text('SPEND & REMAINING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)),
                    const SizedBox(height: DesignTokens.spacingMd),
                    
                    Row(
                      children: [
                        _buildBoxyMetric('TOTAL SPENT', totalSpent, spendColor, theme),
                        const SizedBox(width: DesignTokens.spacingMd),
                        _buildBoxyMetric('TOTAL REMAINING', totalRemaining, totalRemaining >= 0 ? incomeColor : spendColor, theme),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingSm),
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacingMd),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Budgeted Spent (w/o Out of Bucket)', budgetedSpent, theme),
                          _buildDetailRow('Budgeted Remaining', budgetedRemaining, theme, customColor: budgetedRemaining >= 0 ? incomeColor : spendColor),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1),
                          ),
                          _buildDetailRow('Out of Bucket Spent', outOfBucket, theme, customColor: warningColor),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacingXl),

                    // --- SECTION 3: BUCKET BREAKDOWN ---
                    Text('BUCKET PERFORMANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)),
                    const SizedBox(height: DesignTokens.spacingMd),
                    
                    ...bucketDetails.map((b) {
                      final isOver = b['remaining'] < 0;
                      final remainingColor = isOver ? spendColor : incomeColor;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
                        padding: const EdgeInsets.all(DesignTokens.spacingMd),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          border: Border.all(color: isOver ? spendColor.withOpacity(0.4) : theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.donut_small_rounded, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    b['name'].toString().toUpperCase(), 
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: theme.colorScheme.primary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
                              child: Divider(color: theme.dividerColor.withOpacity(0.5)),
                            ),
                            Row(
                              children: [
                                _buildMiniMetric('Allocated', b['allocated'], theme.colorScheme.onSurface),
                                // --- FIX: ADDED STRICT HORIZONTAL SPACING BETWEEN METRICS ---
                                const SizedBox(width: DesignTokens.spacingSm),
                                _buildMiniMetric('Spent', b['spent'], spendColor),
                                const SizedBox(width: DesignTokens.spacingSm),
                                _buildMiniMetric(isOver ? 'Overspent' : 'Remaining', b['remaining'], remainingColor),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: DesignTokens.spacingLg),
                    
                    // --- WARNING BANNER ---
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spacingMd),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3))
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Closing this budget is permanent. These statistics will be frozen and saved for historical analytics.',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.error, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // FOOTER ACTIONS
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.dividerColor, width: 1.0)),
                ),
                child: Row(
                  children: [
                    Expanded(child: ModernBoxyButton(onPressed: () => Navigator.pop(context, false), label: 'CANCEL', isOutlined: true)),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(flex: 2, child: ModernBoxyButton(onPressed: () => Navigator.pop(context, true), label: 'CONFIRM & CLOSE')),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}