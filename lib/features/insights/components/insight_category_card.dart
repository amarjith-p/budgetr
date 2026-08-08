// features/insights/components/insight_category_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/constants/icon_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/insight_category_model.dart';
import 'insight_subcategory_card.dart';

class InsightCategoryCard extends StatefulWidget {
  final InsightCategoryModel category;
  final bool isExpense;
  final String activeTimeframe;
  final bool isNested;

  const InsightCategoryCard({
    Key? key,
    required this.category,
    required this.isExpense,
    required this.activeTimeframe,
    this.isNested = false,
  }) : super(key: key);

  @override
  State<InsightCategoryCard> createState() => _InsightCategoryCardState();
}

class _InsightCategoryCardState extends State<InsightCategoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.isExpense ? theme.colorScheme.error : Colors.green;

    final bool isIncrease = widget.category.trendPercentage > 0;
    Color trendColor = theme.colorScheme.onSurfaceVariant;
    IconData trendIcon = Icons.remove_rounded;

    if (widget.category.previousAmount > 0) {
      trendColor = isIncrease
          ? (widget.isExpense ? theme.colorScheme.error : Colors.green)
          : (widget.isExpense ? Colors.green : theme.colorScheme.error);
      trendIcon = isIncrease
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded;
    }

    final hasChildren = widget.category.subcategories.isNotEmpty;

    return Container(
      margin: widget.isNested
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: widget.isNested ? Colors.transparent : theme.colorScheme.surface,
        borderRadius: widget.isNested
            ? BorderRadius.zero
            : BorderRadius.circular(8),
        border: widget.isNested
            ? const Border(top: BorderSide(color: Colors.transparent))
            : Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: widget.isNested
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            // --- OPTIMIZED: Highly condensed paddings when nested ---
            tilePadding: widget.isNested
                ? const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 6)
                : const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 8),
            childrenPadding: widget.isNested
                ? const EdgeInsets.fromLTRB(8, 0, 8, 8)
                : const EdgeInsets.fromLTRB(12, 0, 12, 12),
            onExpansionChanged: (expanded) {
              if (hasChildren) {
                HapticFeedback.lightImpact();
                setState(() => _isExpanded = expanded);
              }
            },
            trailing: hasChildren
                ? AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: widget.isNested ? 18 : 20,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            leading: Container(
              // --- OPTIMIZED: Shrunk icon container sizes ---
              width: widget.isNested ? 32 : 38,
              height: widget.isNested ? 32 : 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.spacingXs),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(
                widget.category.iconCode != null
                    ? IconConstants.getIconByCode(widget.category.iconCode!)
                    : Icons.category_rounded,
                color: color,
                size: widget.isNested ? 16 : 20,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.category.name,
                    style: TextStyle(
                      fontSize: widget.isNested ? 13 : 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                CurrencyText(
                  amount: widget.category.totalAmount,
                  sign: widget.isExpense ? '-₹ ' : '+₹ ',
                  amountStyle: TextStyle(
                    fontSize: widget.isNested ? 13 : 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // --- OPTIMIZED: Merged Row logic applies here too ---
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
                            '${widget.category.transactions.length} Txns',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (widget.activeTimeframe != 'All Time' &&
                              (widget.category.previousAmount > 0 ||
                                  widget.category.totalAmount > 0))
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
                                  widget.category.previousAmount == 0
                                      ? Icons.new_releases_rounded
                                      : trendIcon,
                                  size: 10,
                                  color: widget.category.previousAmount == 0
                                      ? theme.colorScheme.primary
                                      : trendColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.category.previousAmount == 0
                                      ? 'New'
                                      : '${widget.category.trendPercentage.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: widget.category.previousAmount == 0
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
                      '${(widget.category.percentage * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%',
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
                    value: widget.category.percentage.clamp(0.0, 1.0),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    color: color,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
            children: [
              if (hasChildren)
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.3,
                          ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: widget.category.subcategories
                        .map(
                          (sub) => InsightSubcategoryCard(
                            subcategory: sub,
                            isExpense: widget.isExpense,
                            activeTimeframe: widget.activeTimeframe,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
