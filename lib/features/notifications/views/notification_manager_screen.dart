// lib/features/notifications/views/notification_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/notification_provider.dart';
import 'developer_notification_screen.dart';

class NotificationManagerScreen extends ConsumerWidget {
  const NotificationManagerScreen({Key? key}) : super(key: key);

  String _formatTime(int hour, int minute) {
    final hr = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final min = minute.toString().padLeft(2, '0');
    return '$hr:$min $ampm';
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
    bool isLoan,
  ) async {
    HapticFeedback.lightImpact();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isLoan ? settings.loanAlertHour : settings.ccAlertHour,
        minute: isLoan ? settings.loanAlertMinute : settings.ccAlertMinute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      if (isLoan) {
        ref
            .read(notificationSettingsProvider.notifier)
            .updateSettings(
              settings.copyWith(
                loanAlertHour: time.hour,
                loanAlertMinute: time.minute,
              ),
            );
      } else {
        ref
            .read(notificationSettingsProvider.notifier)
            .updateSettings(
              settings.copyWith(
                ccAlertHour: time.hour,
                ccAlertMinute: time.minute,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const appBar = ModernAppBar(
      title: 'Alerts',
      subtitle: 'NOTIFICATION CENTER',
      leadingIcon: Icons.arrow_back_rounded,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: appBar.preferredSize,
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DeveloperNotificationScreen(),
              ),
            );
          },
          child: appBar,
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        children: [
          _buildBoxyMasterToggle(context, ref, settings),

          if (settings.enableNotifications) ...[
            const SizedBox(height: DesignTokens.spacingXl),

            // --- NEW: SYSTEM SECURITY ---
            _buildSectionHeader('SYSTEM SECURITY', theme),
            const SizedBox(height: 8),
            _buildBoxySettingsGroup(
              context,
              children: [
                _buildBoxyToggleRow(
                  context,
                  title: 'Daily Backup Reminder',
                  subtitle: 'Warn me 24 hours after last backup',
                  value: settings.backupReminderEnabled,
                  onChanged: (val) => ref
                      .read(notificationSettingsProvider.notifier)
                      .updateSettings(
                        settings.copyWith(backupReminderEnabled: val),
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingXl),

            _buildSectionHeader('ACTIVE MODULES', theme),
            const SizedBox(height: 8),

            // --- CREDIT CARDS ---
            _buildCreditCardBoxyGroup(context, ref, settings, theme, isDark),
            const SizedBox(height: DesignTokens.spacingMd),

            // --- LOANS ---
            _buildLoanBoxyGroup(context, ref, settings, theme, isDark),

            const SizedBox(height: DesignTokens.spacingXl),
          ],
        ],
      ),
    );
  }

  Widget _buildBoxyMasterToggle(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.enableNotifications
            ? theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: settings.enableNotifications
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.dividerColor,
          width: settings.enableNotifications ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: settings.enableNotifications
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  size: 20,
                  color: settings.enableNotifications
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Master Switch',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: settings.enableNotifications
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.enableNotifications
                        ? 'System active'
                        : 'All alerts muted',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: settings.enableNotifications,
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              ref
                  .read(notificationSettingsProvider.notifier)
                  .updateSettings(settings.copyWith(enableNotifications: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardBoxyGroup(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Icon(
              Icons.credit_card_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            'CREDIT CARDS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Statement & Due Date tracking',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            Container(
              color: theme.scaffoldBackgroundColor.withOpacity(0.5),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('DELIVERY SCHEDULE', theme),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(context, ref, settings, false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Daily Alert Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              _formatTime(
                                settings.ccAlertHour,
                                settings.ccAlertMinute,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('CRITICAL ALERTS', theme),
                  const SizedBox(height: 8),
                  _buildBoxySettingsGroup(
                    context,
                    children: [
                      _buildBoxyToggleRow(
                        context,
                        title: 'Statement Generation',
                        subtitle: 'On exact bill date',
                        value: settings.notifyOnBillDate,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notifyOnBillDate: val),
                            ),
                      ),
                      _buildDivider(theme),
                      _buildBoxyToggleRow(
                        context,
                        title: 'Payment Due Date',
                        subtitle: 'Final deadline reminder',
                        value: settings.notifyOnDueDate,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notifyOnDueDate: val),
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('ADVANCE WARNINGS', theme),
                  const SizedBox(height: 8),
                  _buildBoxySettingsGroup(
                    context,
                    children: [
                      _buildBoxyToggleRow(
                        context,
                        title: '1 Day Before',
                        value: settings.notify1DayBefore,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notify1DayBefore: val),
                            ),
                      ),
                      _buildDivider(theme),
                      _buildBoxyToggleRow(
                        context,
                        title: '3 Days Before',
                        value: settings.notify3DaysBefore,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notify3DaysBefore: val),
                            ),
                      ),
                      _buildDivider(theme),
                      _buildBoxyToggleRow(
                        context,
                        title: '5 Days Before',
                        value: settings.notify5DaysBefore,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notify5DaysBefore: val),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanBoxyGroup(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            'LOANS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Monthly EMI reminders',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            Container(
              color: theme.scaffoldBackgroundColor.withOpacity(0.5),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('DELIVERY SCHEDULE', theme),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(context, ref, settings, true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Daily Alert Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              _formatTime(
                                settings.loanAlertHour,
                                settings.loanAlertMinute,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('CRITICAL ALERTS', theme),
                  const SizedBox(height: 8),
                  _buildBoxySettingsGroup(
                    context,
                    children: [
                      _buildBoxyToggleRow(
                        context,
                        title: 'EMI Date',
                        subtitle: 'Reminder on exact EMI date',
                        value: settings.notifyOnEmiDate,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notifyOnEmiDate: val),
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader('ADVANCE WARNINGS', theme),
                  const SizedBox(height: 8),
                  _buildBoxySettingsGroup(
                    context,
                    children: [
                      _buildBoxyToggleRow(
                        context,
                        title: '1 Day Before',
                        value: settings.notifyLoan1DayBefore,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notifyLoan1DayBefore: val),
                            ),
                      ),
                      _buildDivider(theme),
                      _buildBoxyToggleRow(
                        context,
                        title: '3 Days Before',
                        value: settings.notifyLoan3DaysBefore,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notifyLoan3DaysBefore: val),
                            ),
                      ),
                      _buildDivider(theme),
                      _buildBoxyToggleRow(
                        context,
                        title: '5 Days Before',
                        value: settings.notifyLoan5DaysBefore,
                        onChanged: (val) => ref
                            .read(notificationSettingsProvider.notifier)
                            .updateSettings(
                              settings.copyWith(notifyLoan5DaysBefore: val),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildBoxySettingsGroup(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildBoxyToggleRow(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                onChanged(val);
              },
              activeColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, color: theme.dividerColor.withOpacity(0.5));
  }
}
