import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart'; // <-- IMPORTED CURRENCY UTILITY
import '../providers/transaction_filter_provider.dart';

class ActiveFilterBanner extends StatelessWidget {
  final TransactionFilterState filterState;
  final VoidCallback onClear;

  const ActiveFilterBanner({
    Key? key,
    required this.filterState,
    required this.onClear,
  }) : super(key: key);

  List<String> _generateActiveTags() {
    List<String> tags = [];

    if (filterState.sortBy == SortOption.oldest) tags.add('Oldest');
    if (filterState.sortBy == SortOption.highestAmount) tags.add('Highest');
    if (filterState.sortBy == SortOption.lowestAmount) tags.add('Lowest');

    if (filterState.timeframe == TimeframeOption.currentMonth)
      tags.add('This Month');
    if (filterState.timeframe == TimeframeOption.lastMonth)
      tags.add('Last Month');
    if (filterState.timeframe == TimeframeOption.custom)
      tags.add('Custom Dates');

    if (filterState.types.isNotEmpty) {
      if (filterState.types.length <= 2) {
        tags.addAll(filterState.types);
      } else {
        tags.add('${filterState.types.length} Types');
      }
    }

    // --- APPLIED GLOBAL FORMATTER ---
    if (filterState.minAmount != null && filterState.maxAmount != null) {
      tags.add(
        '₹${CurrencyFormatter.format(filterState.minAmount!)} - ₹${CurrencyFormatter.format(filterState.maxAmount!)}',
      );
    } else if (filterState.minAmount != null) {
      tags.add('> ₹${CurrencyFormatter.format(filterState.minAmount!)}');
    } else if (filterState.maxAmount != null) {
      tags.add('< ₹${CurrencyFormatter.format(filterState.maxAmount!)}');
    }

    if (filterState.accountIds.isNotEmpty)
      tags.add('${filterState.accountIds.length} Accounts');
    if (filterState.categoryIds.isNotEmpty)
      tags.add('${filterState.categoryIds.length} Categories');
    if (filterState.subCategories.isNotEmpty)
      tags.add('${filterState.subCategories.length} Subcats');
    if (filterState.bucketIds.isNotEmpty)
      tags.add('${filterState.bucketIds.length} Buckets');
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeTags = _generateActiveTags();

    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.spacingMd,
        DesignTokens.spacingMd,
        DesignTokens.spacingMd,
        0,
      ),
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(
          isDark ? 0.2 : 0.4,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),

          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: activeTags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(
                        isDark ? 0.15 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activeTags[index].toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onClear();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CLEAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.error,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
