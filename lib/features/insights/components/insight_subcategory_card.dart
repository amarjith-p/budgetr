// features/insights/components/insight_subcategory_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/currency_text.dart';
import '../models/insight_subcategory_model.dart';
import '../../transactions/components/transaction_card.dart';

class InsightSubcategoryCard extends StatefulWidget {
  final InsightSubcategoryModel subcategory;
  final bool isExpense;
  final String activeTimeframe;

  const InsightSubcategoryCard({
    Key? key,
    required this.subcategory,
    required this.isExpense,
    required this.activeTimeframe,
  }) : super(key: key);

  @override
  State<InsightSubcategoryCard> createState() => _InsightSubcategoryCardState();
}

class _InsightSubcategoryCardState extends State<InsightSubcategoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.isExpense ? theme.colorScheme.error : Colors.green;

    final bool isIncrease = widget.subcategory.trendPercentage > 0;
    Color trendColor = theme.colorScheme.onSurfaceVariant;
    IconData trendIcon = Icons.remove_rounded;

    if (widget.subcategory.previousAmount > 0) {
      trendColor = isIncrease
          ? (widget.isExpense ? theme.colorScheme.error : Colors.green)
          : (widget.isExpense ? Colors.green : theme.colorScheme.error);
      trendIcon = isIncrease
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded;
    }

    final hasTransactions = widget.subcategory.transactions.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // --- OPTIMIZED: The tightest paddings for the deepest level ---
          tilePadding: const EdgeInsets.only(
            left: 8,
            right: 8,
            top: 2,
            bottom: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          onExpansionChanged: (expanded) {
            if (hasTransactions) {
              HapticFeedback.lightImpact();
              setState(() => _isExpanded = expanded);
            }
          },
          trailing: hasTransactions
              ? AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                )
              : const SizedBox.shrink(),
          leading: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.subcategory.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              CurrencyText(
                amount: widget.subcategory.totalAmount,
                sign: widget.isExpense ? '-₹ ' : '+₹ ',
                amountStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color.withOpacity(0.9),
                ),
                symbolStyle: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // --- OPTIMIZED: Merged row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          '${widget.subcategory.transactions.length} Txns',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (widget.activeTimeframe != 'All Time' &&
                            (widget.subcategory.previousAmount > 0 ||
                                widget.subcategory.totalAmount > 0))
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                widget.subcategory.previousAmount == 0
                                    ? Icons.new_releases_rounded
                                    : trendIcon,
                                size: 10,
                                color: widget.subcategory.previousAmount == 0
                                    ? theme.colorScheme.primary
                                    : trendColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.subcategory.previousAmount == 0
                                    ? 'New'
                                    : '${widget.subcategory.trendPercentage.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: widget.subcategory.previousAmount == 0
                                      ? theme.colorScheme.primary
                                      : trendColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(widget.subcategory.percentage * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: widget.subcategory.percentage.clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                  color: color.withOpacity(0.8),
                  minHeight: 3,
                ),
              ),
            ],
          ),
          children: [
            if (hasTransactions)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: widget.subcategory.transactions.map((txn) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: TransactionCard(
                        data: txn,
                        currentAccountId: txn.transaction.accountId,
                        isGlobalView: true,
                        isCompactLayout: true,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
