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

class HeatmapHeaderCard extends ConsumerStatefulWidget {
  const HeatmapHeaderCard({Key? key}) : super(key: key);

  @override
  ConsumerState<HeatmapHeaderCard> createState() => _HeatmapHeaderCardState();
}

class _HeatmapHeaderCardState extends ConsumerState<HeatmapHeaderCard> {
  int _currentAdviceIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final month = ref.watch(heatmapSelectedMonthProvider);
    final heatmapData = ref.watch(heatmapDailySpendProvider);
    final days = heatmapData.days;
    final includedBudget = heatmapData.includedBudget;
    final advices = heatmapData.advices;

    // Safety bounds check if data changes
    if (_currentAdviceIndex >= advices.length) {
      _currentAdviceIndex = 0;
    }

    double monthTotal = 0;
    for (var d in days) {
      monthTotal += d.totalSpend;
    }

    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();

    final bool isCurrentMonth =
        month.year == now.year && month.month == now.month;
    final bool isPastMonth =
        month.year < now.year ||
        (month.year == now.year && month.month < now.month);

    int daysElapsed = daysInMonth;
    if (isCurrentMonth) {
      daysElapsed = now.day;
    } else if (!isPastMonth) {
      daysElapsed = 1;
    }

    double projectedTotal = 0;
    if (daysElapsed > 0) {
      projectedTotal = (monthTotal / daysElapsed) * daysInMonth;
    }

    final currentAdvice = advices.isNotEmpty
        ? advices[_currentAdviceIndex]
        : null;

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
                  setState(() => _currentAdviceIndex = 0);
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
                  setState(() => _currentAdviceIndex = 0);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.4,
                  ),
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
              if (includedBudget > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Limit: ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: CurrencyText(
                          amount: includedBudget,
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

          if (currentAdvice != null) ...[
            const SizedBox(height: 12),

            // --- DYNAMIC HEIGHT ADVICE SWIPER ---
            GestureDetector(
              onHorizontalDragEnd: (details) {
                int velocity = details.primaryVelocity?.toInt() ?? 0;
                if (velocity < -300) {
                  // Swipe Left (Next)
                  if (_currentAdviceIndex < advices.length - 1) {
                    HapticFeedback.lightImpact();
                    setState(() => _currentAdviceIndex++);
                  }
                } else if (velocity > 300) {
                  // Swipe Right (Prev)
                  if (_currentAdviceIndex > 0) {
                    HapticFeedback.lightImpact();
                    setState(() => _currentAdviceIndex--);
                  }
                }
              },
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: Container(
                    key: ValueKey(_currentAdviceIndex),
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: currentAdvice.color.withOpacity(
                        isDark ? 0.15 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: currentAdvice.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          currentAdvice.icon,
                          size: 18,
                          color: currentAdvice.color,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentAdvice.text,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: currentAdvice.color,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (advices.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                            child: Icon(
                              Icons.swipe_rounded,
                              size: 12,
                              color: currentAdvice.color.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- DOT INDICATORS ---
            if (advices.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(advices.length, (idx) {
                    final isActive = _currentAdviceIndex == idx;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: isActive ? 16 : 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
