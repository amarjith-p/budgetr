// features/insights/components/insight_breakdown_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/theme/design_tokens.dart';

class InsightBreakdownScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final double totalAmount;
  final double previousAmount;
  final double trendPercentage;
  final int txnCount;
  final bool isExpense;
  final IconData icon;
  final List<Widget> childrenCards;

  const InsightBreakdownScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.totalAmount,
    required this.previousAmount,
    required this.trendPercentage,
    required this.txnCount,
    required this.isExpense,
    required this.icon,
    required this.childrenCards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isExpense ? theme.colorScheme.error : Colors.green;

    final bool isIncrease = trendPercentage > 0;
    Color trendColor = theme.colorScheme.onSurfaceVariant;
    IconData trendIcon = Icons.remove_rounded;

    if (previousAmount > 0) {
      trendColor = isIncrease
          ? (isExpense ? theme.colorScheme.error : Colors.green)
          : (isExpense ? Colors.green : theme.colorScheme.error);
      trendIcon = isIncrease
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: DesignTokens.spacingLg,
          right: DesignTokens.spacingLg,
          top: DesignTokens.spacingSm,
          bottom: 120,
        ),
        children: [
          // --- PARENT HEADER CARD ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                CurrencyText(
                  amount: totalAmount,
                  sign: isExpense ? '-₹ ' : '+₹ ',
                  amountStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -1.0,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 18,
                    color: color.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: theme.dividerColor.withOpacity(0.5), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          'TRANSACTIONS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$txnCount',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 24, color: theme.dividerColor),
                    Column(
                      children: [
                        Text(
                          'TREND',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (previousAmount == 0 && totalAmount == 0)
                          Text(
                            '-',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          )
                        else if (previousAmount == 0)
                          Text(
                            'New',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          Row(
                            children: [
                              Icon(trendIcon, size: 14, color: trendColor),
                              const SizedBox(width: 4),
                              Text(
                                '${trendPercentage.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: trendColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spacingXl),

          Text(
            'BREAKDOWN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: DesignTokens.spacingMd),

          // --- CHILDREN CARDS ---
          ...childrenCards,
        ],
      ),
    );
  }
}
