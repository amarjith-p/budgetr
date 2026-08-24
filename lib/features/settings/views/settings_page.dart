// features/settings/views/settings_page.dart
import 'package:budgetr/core/components/global_selection_sheet.dart';
import 'package:budgetr/features/settings/providers/location_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/theme_switcher_card.dart';
import '../../../core/theme/design_tokens.dart';
import '../../notifications/views/notification_manager_screen.dart';
import '../../auth/auth_state.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final securitySettings = ref.watch(securitySettingsProvider);
    final locationPref = ref.watch(locationSettingsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Settings',
        subtitle: 'APP CONFIGURATION',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        children: [
          _buildSectionHeader('PREFERENCES', theme),
          const SizedBox(height: 8),

          // --- EXISTING THEME SWITCHER ---
          const ThemeSwitcherCard(),
          const SizedBox(height: 16), // Spacing between cards
          // --- NEW: LOCATION PREFERENCE ---
          _buildBoxySettingsGroup(
            context,
            children: [
              _buildBoxyTile(
                context,
                icon: Icons.pin_drop_rounded,
                title: 'Location Capture',
                subtitle: locationPref == LocationPreference.current
                    ? 'Use current GPS location'
                    : (locationPref == LocationPreference.map
                          ? 'Always choose on map'
                          : 'Ask each time'),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final result = await GlobalSelectionSheet.showSimple(
                    context: context,
                    title: 'Location Capture Method',
                    items: const [
                      'Use current GPS location',
                      'Always choose on map',
                      'Ask each time',
                    ],
                    selectedValue: locationPref == LocationPreference.current
                        ? 'Use current GPS location'
                        : (locationPref == LocationPreference.map
                              ? 'Always choose on map'
                              : 'Ask each time'),
                  );

                  if (result != null) {
                    final notifier = ref.read(
                      locationSettingsProvider.notifier,
                    );
                    if (result == 'Use current GPS location') {
                      notifier.updatePreference(LocationPreference.current);
                    } else if (result == 'Always choose on map') {
                      notifier.updatePreference(LocationPreference.map);
                    } else {
                      notifier.updatePreference(LocationPreference.ask);
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- NEW: SECURITY SECTION ---
          _buildSectionHeader('SECURITY', theme),
          const SizedBox(height: 8),
          _buildBoxySettingsGroup(
            context,
            children: [
              _buildBoxyToggleRow(
                context,
                title: 'App Lock (Passcode)',
                subtitle: 'Require PIN to open the app',
                value: securitySettings.appLockEnabled,
                onChanged: (val) => ref
                    .read(securitySettingsProvider.notifier)
                    .toggleAppLock(val),
              ),
              _buildDivider(theme),
              _buildBoxyToggleRow(
                context,
                title: 'Biometric Unlock',
                subtitle: 'Use fingerprint or face ID',
                value: securitySettings.biometricsEnabled,
                onChanged: securitySettings.appLockEnabled
                    ? (val) => ref
                          .read(securitySettingsProvider.notifier)
                          .toggleBiometrics(val)
                    : null, // Disabled if App Lock is off
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionHeader('MODULES & ALERTS', theme),
          const SizedBox(height: 8),

          // --- BOXY NOTIFICATION MENU ---
          _buildBoxySettingsGroup(
            context,
            children: [
              _buildBoxyTile(
                context,
                icon: Icons.notifications_active_rounded,
                title: 'Notification Center',
                subtitle: 'Manage intelligent alerts & schedules',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationManagerScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildBoxyToggleRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onChanged != null;

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
                    color: isEnabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(
                      isEnabled ? 1.0 : 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: isEnabled
                  ? (val) {
                      HapticFeedback.lightImpact();
                      onChanged(val);
                    }
                  : null,
              activeColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxyTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(
                    isDark ? 0.15 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
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
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, color: theme.dividerColor.withOpacity(0.5));
  }
}
