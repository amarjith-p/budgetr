// features/insights/components/insight_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/insight_filter_provider.dart';

class InsightFilterBar extends StatelessWidget {
  final InsightFilterState filterState;
  final String accountDisplayName;
  final VoidCallback onAccountTap;
  final VoidCallback onTimeframeTap;
  final VoidCallback onResetTap; // <-- NEW: Reset callback

  const InsightFilterBar({
    Key? key,
    required this.filterState,
    required this.accountDisplayName,
    required this.onAccountTap,
    required this.onTimeframeTap,
    required this.onResetTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String timeLabel = filterState.timeFrame;
    if (timeLabel == 'Custom Range' && filterState.customRange != null) {
      timeLabel =
          "${DateFormat('dd MMM').format(filterState.customRange!.start)} - ${DateFormat('dd MMM').format(filterState.customRange!.end)}";
    }

    final theme = Theme.of(context);

    return Row(
      children: [
        // Account Dropdown
        Expanded(
          flex: 4,
          child: _buildDropdownBtn(
            context,
            accountDisplayName,
            Icons.account_balance_wallet_outlined,
            onAccountTap,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingSm),

        // Timeframe Dropdown
        Expanded(
          flex: 3,
          child: _buildDropdownBtn(
            context,
            timeLabel,
            Icons.calendar_today_rounded,
            onTimeframeTap,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingSm),

        // --- NEW: Reset Button ---
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onResetTap();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownBtn(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
