import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- ADDED CURRENT & LAST MONTH ---
enum TrendTimeframe {
  week,
  month,
  currentMonth,
  lastMonth,
  year,
  allTime,
  custom,
}

class AnalyticsTimeframeSelector extends StatelessWidget {
  final TrendTimeframe selectedTimeframe;
  final ValueChanged<TrendTimeframe> onSelected;
  final VoidCallback onCustomTapped;

  const AnalyticsTimeframeSelector({
    Key? key,
    required this.selectedTimeframe,
    required this.onSelected,
    required this.onCustomTapped,
  }) : super(key: key);

  Widget _buildTimeframePill(
    String label,
    TrendTimeframe type,
    ThemeData theme,
    bool isDark,
  ) {
    bool isSelected = selectedTimeframe == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onSelected(type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          isDark ? 0.3 : 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTimeframePill('1W', TrendTimeframe.week, theme, isDark),
          _buildTimeframePill('1M', TrendTimeframe.month, theme, isDark),
          _buildTimeframePill(
            'C.MO',
            TrendTimeframe.currentMonth,
            theme,
            isDark,
          ),
          _buildTimeframePill('L.MO', TrendTimeframe.lastMonth, theme, isDark),
          _buildTimeframePill('1Y', TrendTimeframe.year, theme, isDark),
          _buildTimeframePill('ALL', TrendTimeframe.allTime, theme, isDark),

          Expanded(
            child: GestureDetector(
              onTap: onCustomTapped,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selectedTimeframe == TrendTimeframe.custom
                      ? theme.colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: selectedTimeframe == TrendTimeframe.custom
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.1 : 0.05,
                            ),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 10,
                      color: selectedTimeframe == TrendTimeframe.custom
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
