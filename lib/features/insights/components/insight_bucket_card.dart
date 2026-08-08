// features/insights/components/insight_bucket_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/insight_bucket_model.dart';
import 'insight_category_card.dart';

class InsightBucketCard extends StatefulWidget {
  final InsightBucketModel bucket;
  final String activeTimeframe;

  const InsightBucketCard({
    Key? key,
    required this.bucket,
    required this.activeTimeframe,
  }) : super(key: key);

  @override
  State<InsightBucketCard> createState() => _InsightBucketCardState();
}

class _InsightBucketCardState extends State<InsightBucketCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = theme.colorScheme.error;

    final bool isIncrease = widget.bucket.trendPercentage > 0;
    Color trendColor = theme.colorScheme.onSurfaceVariant;
    IconData trendIcon = Icons.remove_rounded;

    if (widget.bucket.previousAmount > 0) {
      trendColor = isIncrease ? theme.colorScheme.error : Colors.green;
      trendIcon = isIncrease
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded;
    }

    final hasChildren = widget.bucket.categories.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
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
            // --- OPTIMIZED: Tighter Paddings ---
            tilePadding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 4,
              bottom: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            leading: Container(
              // --- OPTIMIZED: Sleeker Icon Box (38 instead of 42) ---
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.spacingXs),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(Icons.donut_small_rounded, color: color, size: 20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.bucket.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                CurrencyText(
                  amount: widget.bucket.totalAmount,
                  sign: '-₹ ',
                  amountStyle: TextStyle(
                    fontSize: 14,
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
                // --- OPTIMIZED: Stats and Trend merged into one row ---
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
                            '${widget.bucket.transactions.length} Txns',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (widget.activeTimeframe != 'All Time' &&
                              (widget.bucket.previousAmount > 0 ||
                                  widget.bucket.totalAmount > 0))
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
                                  widget.bucket.previousAmount == 0
                                      ? Icons.new_releases_rounded
                                      : trendIcon,
                                  size: 10,
                                  color: widget.bucket.previousAmount == 0
                                      ? theme.colorScheme.primary
                                      : trendColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.bucket.previousAmount == 0
                                      ? 'New'
                                      : '${widget.bucket.trendPercentage.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: widget.bucket.previousAmount == 0
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
                      '${(widget.bucket.percentage * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%',
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
                    value: widget.bucket.percentage.clamp(0.0, 1.0),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    color: color,
                    minHeight: 3, // Thinner progress bar
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
                    children: widget.bucket.categories
                        .map(
                          (cat) => InsightCategoryCard(
                            category: cat,
                            isExpense: true,
                            activeTimeframe: widget.activeTimeframe,
                            isNested: true,
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
