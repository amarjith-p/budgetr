// lib/features/heatmap/components/heatmap_header_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/components/bento_card.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/constants/date_time_constants.dart';
import '../providers/heatmap_month_provider.dart';
import '../providers/heatmap_daily_spend_provider.dart';
import 'heatmap_bucket_filter_sheet.dart';

class HeatmapHeaderCard extends ConsumerWidget {
  const HeatmapHeaderCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final month = ref.watch(heatmapSelectedMonthProvider);
    final days = ref.watch(heatmapDailySpendProvider);

    double monthTotal = 0;
    for (var d in days) {
      monthTotal += d.totalSpend;
    }

    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();
    int daysElapsed = daysInMonth;
    if (month.year == now.year && month.month == now.month) {
      daysElapsed = now.day;
    } else if (now.isBefore(DateTime(month.year, month.month))) {
      daysElapsed = 1;
    }

    double projectedTotal = 0;
    if (daysElapsed > 0) {
      projectedTotal = (monthTotal / daysElapsed) * daysInMonth;
    }

    return BentoCard(
      onTap: () {
        HapticFeedback.lightImpact();
        HeatmapBucketFilterSheet.show(context, ref);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(heatmapSelectedMonthProvider.notifier).state =
                      DateTime(month.year, month.month - 1);
                },
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_view_month_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateTimeConstants.fullMonths[month.month - 1]} ${month.year}'
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // --- FIX: Removed sign: '' so the default Rupee symbol displays ---
                  CurrencyText(
                    amount: monthTotal,
                    amountStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(heatmapSelectedMonthProvider.notifier).state =
                      DateTime(month.year, month.month + 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pace: ~',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Flexible(
                  child: CurrencyText(
                    amount: projectedTotal,
                    amountStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    symbolStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
