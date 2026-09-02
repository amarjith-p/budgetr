// lib/features/heatmap/components/heatmap_grid.dart
import 'package:budgetr/features/transactions/views/transaction_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/currency_text.dart';
import '../models/day_spend_summary.dart';
import '../providers/heatmap_daily_spend_provider.dart';
import '../providers/heatmap_selected_date_provider.dart';

class HeatmapGrid extends ConsumerWidget {
  const HeatmapGrid({Key? key}) : super(key: key);

  Widget _buildLegendItem(ThemeData theme, Color color, Widget labelWidget) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        labelWidget,
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final days = ref.watch(heatmapDailySpendProvider);
    final selectedDate = ref.watch(heatmapSelectedDateProvider);

    if (days.isEmpty) return const SizedBox.shrink();

    final firstDay = days.first.date;
    final prefixDays = firstDay.weekday - 1; // Mon = 1, so offset = 0
    final totalCells = prefixDays + days.length;
    final today = DateTime.now();

    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // --- FIX: Increased Dark Mode contrast for 0 Spend cells ---
    final colorNoData = isDark
        ? Colors.white.withOpacity(0.12)
        : theme.dividerColor.withOpacity(0.5);

    DaySpendSummary? referenceDay;
    if (selectedDate != null) {
      referenceDay = days
          .where(
            (d) =>
                d.date.year == selectedDate.year &&
                d.date.month == selectedDate.month &&
                d.date.day == selectedDate.day,
          )
          .firstOrNull;
    }
    if (referenceDay == null) {
      referenceDay = days
          .where(
            (d) =>
                d.date.year == today.year &&
                d.date.month == today.month &&
                d.date.day == today.day,
          )
          .firstOrNull;
    }
    if (referenceDay == null && days.isNotEmpty) {
      referenceDay = days.first;
    }

    final t = referenceDay?.dailyTarget ?? 0.0;

    final legendTextStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.2,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map(
                (d) => SizedBox(
                  width: 30,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < prefixDays) return const SizedBox.shrink();

            final summary = days[index - prefixDays];
            final date = summary.date;

            final isSelected =
                selectedDate?.year == date.year &&
                selectedDate?.month == date.month &&
                selectedDate?.day == date.day;

            final isToday =
                today.year == date.year &&
                today.month == date.month &&
                today.day == date.day;

            Color fillColor;
            switch (summary.level) {
              case HeatmapColorLevel.green:
                fillColor = TransactionColors.income(theme).withOpacity(0.8);
                break;
              case HeatmapColorLevel.orange:
                fillColor = TransactionColors.transfer(theme).withOpacity(0.8);
                break;
              case HeatmapColorLevel.red:
                fillColor = TransactionColors.expense(theme).withOpacity(0.8);
                break;
              case HeatmapColorLevel.noData:
                fillColor = colorNoData;
                break;
              case HeatmapColorLevel.future:
                fillColor = Colors.transparent;
                break;
            }

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (isSelected) {
                  ref.read(heatmapSelectedDateProvider.notifier).state = null;
                } else {
                  ref.read(heatmapSelectedDateProvider.notifier).state = date;
                }
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionFormPage(initialDate: date),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.onSurface, width: 2)
                      : (isToday
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : null),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ||
                            isToday ||
                            summary.level != HeatmapColorLevel.future
                        ? FontWeight.w900
                        : FontWeight.w600,
                    color: summary.level == HeatmapColorLevel.future
                        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4)
                        : (summary.level == HeatmapColorLevel.noData
                              ? theme.colorScheme.onSurfaceVariant
                              : Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildLegendItem(
              theme,
              TransactionColors.income(theme).withOpacity(0.8),
              CurrencyText(
                amount: t,
                sign: '≤ ₹ ',
                amountStyle: legendTextStyle,
                symbolStyle: legendTextStyle,
              ),
            ),
            _buildLegendItem(
              theme,
              TransactionColors.transfer(theme).withOpacity(0.8),
              CurrencyText(
                amount: t * 1.5,
                sign: '≤ ₹ ',
                amountStyle: legendTextStyle,
                symbolStyle: legendTextStyle,
              ),
            ),
            _buildLegendItem(
              theme,
              TransactionColors.expense(theme).withOpacity(0.8),
              CurrencyText(
                amount: t * 1.5,
                sign: '> ₹ ',
                amountStyle: legendTextStyle,
                symbolStyle: legendTextStyle,
              ),
            ),
            _buildLegendItem(
              theme,
              colorNoData,
              Text('0 Spend', style: legendTextStyle),
            ),
          ],
        ),
      ],
    );
  }
}
