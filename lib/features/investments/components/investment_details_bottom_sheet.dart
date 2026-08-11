// lib/features/investments/components/investment_details_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';

class InvestmentDetailsBottomSheet extends StatelessWidget {
  final Investment investment;

  const InvestmentDetailsBottomSheet({Key? key, required this.investment})
    : super(key: key);

  static void show(BuildContext context, Investment investment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InvestmentDetailsBottomSheet(investment: investment),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildDetailBlock(
    String label,
    String? value,
    ThemeData theme, {
    Widget? customValue,
  }) {
    final displayValue = (value != null && value.isNotEmpty) ? value : '--';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        customValue ??
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 13,
                fontWeight: displayValue == '--'
                    ? FontWeight.w500
                    : FontWeight.w700,
                color: displayValue == '--'
                    ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
                    : theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }

  Widget _buildCurrencyValue(double? amount, ThemeData theme) {
    if (amount == null) {
      return Text(
        '--',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: CurrencyText(
        amount: amount,
        sign: '₹ ',
        amountStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
        symbolStyle: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset, top: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- STANDARD DRAG HANDLE ---
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg,
              ),
              child: Text(
                'Complete Asset Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // --- FLEXIBLE PREVENTS OVERFLOW ---
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. BASIC INFO ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'INVESTMENT NAME',
                              investment.name,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBlock(
                              'INVESTMENT TYPE',
                              investment.type,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'PROVIDER',
                              investment.provider,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBlock(
                              'PROVIDER URL',
                              investment.providerUrl,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'SPECIAL ID / TAG',
                              investment.specialTag,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBlock(
                              'FOLIO / ACCOUNT NO.',
                              investment.folioNo,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),

                      // --- 2. FINANCIALS ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'INITIAL AMOUNT',
                              null,
                              theme,
                              customValue: _buildCurrencyValue(
                                investment.initialAmount,
                                theme,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBlock(
                              'CURRENT VALUE',
                              null,
                              theme,
                              customValue: _buildCurrencyValue(
                                investment.currentValue,
                                theme,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'TARGET AMOUNT',
                              null,
                              theme,
                              customValue: _buildCurrencyValue(
                                investment.targetAmount,
                                theme,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBlock(
                              'EXPECTED RETURN',
                              investment.expectedReturn != null
                                  ? '${investment.expectedReturn}%'
                                  : null,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'START DATE',
                              _formatDate(investment.startDate),
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBlock(
                              'EXPECTED END DATE',
                              _formatDate(investment.expectedEndDate),
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),

                      // --- 3. PORTFOLIO DATA ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'UNITS / QTY',
                              investment.units?.toString(),
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBlock(
                              'BROKER NAME',
                              investment.brokerName,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),

                      // --- 4. LINKED BANK DATA ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'LINKED BANK NAME',
                              investment.linkedBankName,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailBlock(
                              'LINKED ACCOUNT NO.',
                              investment.linkedAccountNo,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'LINKED BANK IFSC',
                              investment.linkedAccountIfsc,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: SizedBox.shrink(),
                          ), // Empty spacer for alignment
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),

                      // --- 5. EXTRA DETAILS ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'PURPOSE',
                              investment.purpose,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailBlock(
                              'NOTES',
                              investment.notes,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
