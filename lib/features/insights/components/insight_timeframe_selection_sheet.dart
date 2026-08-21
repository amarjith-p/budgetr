// features/insights/components/insight_timeframe_selection_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InsightTimeframeSelectionSheet extends StatelessWidget {
  final String selectedTimeframe;
  final ValueChanged<String> onSelected;

  const InsightTimeframeSelectionSheet({
    Key? key,
    required this.selectedTimeframe,
    required this.onSelected,
  }) : super(key: key);

  static void show(
    BuildContext context,
    String selectedTimeframe,
    ValueChanged<String> onSelected,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InsightTimeframeSelectionSheet(
        selectedTimeframe: selectedTimeframe,
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildSheetOption(
    BuildContext ctx,
    String title,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    final isSelected = selectedTimeframe == value;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(ctx);
        onSelected(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.15)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // <-- NEW: Added Today and This Week
    final periods = [
      'Today',
      'This Week',
      'This Month',
      'Last Month',
      'This Year',
      'Last Year',
      'All Time',
      'Custom Range',
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select Timeframe',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: periods.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.4),
                    indent: 24,
                    endIndent: 24,
                  ),
                  itemBuilder: (context, index) {
                    final p = periods[index];
                    IconData iconData = Icons.calendar_today_rounded;
                    if (p == 'Custom Range')
                      iconData = Icons.date_range_rounded;
                    if (p == 'All Time') iconData = Icons.all_inclusive_rounded;
                    if (p == 'Today') iconData = Icons.today_rounded;
                    if (p == 'This Week') iconData = Icons.view_week_rounded;

                    return _buildSheetOption(context, p, p, iconData, theme);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
