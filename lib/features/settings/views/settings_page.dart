// lib/features/settings/views/settings_page.dart

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

    // Helper to ensure the Sheet Items and SelectedValue match EXACTLY
    String getLocationPrefString(LocationPreference pref) {
      switch (pref) {
        case LocationPreference.current:
          return 'Use current GPS location';
        case LocationPreference.map:
          return 'Always choose on map';
        case LocationPreference.ask:
          return 'Ask each time';
      }
    }

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
          // --- FULL WIDTH: THEME ---
          _buildSectionTitle('APPEARANCE', theme),
          const SizedBox(height: 12),
          const ThemeSwitcherCard(),

          const SizedBox(height: 24),

          // --- 2-COLUMN BENTO GRID: SECURITY ---
          _buildSectionTitle('SECURITY', theme),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBentoToggleCard(
                  context,
                  title: 'App Lock',
                  subtitle: 'Require PIN',
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFFE71D36),
                  value: securitySettings.appLockEnabled,
                  onChanged: (val) => ref
                      .read(securitySettingsProvider.notifier)
                      .toggleAppLock(val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBentoToggleCard(
                  context,
                  title: 'Biometrics',
                  subtitle: 'Face/Touch ID',
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF2EC4B6),
                  value: securitySettings.biometricsEnabled,
                  onChanged: securitySettings.appLockEnabled
                      ? (val) => ref
                            .read(securitySettingsProvider.notifier)
                            .toggleBiometrics(val)
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- FULL WIDTH BENTO: PREFERENCES ---
          _buildSectionTitle('SYSTEM', theme),
          const SizedBox(height: 12),
          _buildBentoActionCard(
            context,
            icon: Icons.share_location_rounded,
            title: 'Location Capture',
            subtitle: locationPref == LocationPreference.current
                ? 'Using GPS'
                : (locationPref == LocationPreference.map
                      ? 'Choosing on map'
                      : 'Asking each time'),
            onTap: () async {
              HapticFeedback.selectionClick();

              final items = const [
                'Use current GPS location',
                'Always choose on map',
                'Ask each time',
              ];
              final currentSelection = getLocationPrefString(locationPref);

              // Using the base .show() method to inject custom Radio Button UI
              final result = await GlobalSelectionSheet.show<String>(
                context: context,
                title: 'Location Capture Method',
                builder: (sheetContext, scrollController) => ListView.separated(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.3),
                    indent: 24,
                    endIndent: 24,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = currentSelection == item;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      title: Text(
                        item,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w600,
                          fontSize: 15,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              ),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(sheetContext, item);
                      },
                    );
                  },
                ),
              );

              if (result != null) {
                final notifier = ref.read(locationSettingsProvider.notifier);
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

          const SizedBox(height: 16),

          _buildBentoActionCard(
            context,
            icon: Icons.notifications_active_rounded,
            title: 'Notification Center',
            subtitle: 'Manage Notification alerts',
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

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
    );
  }

  // --- SQUARE BENTO CARD (Used for Toggles) ---
  Widget _buildBentoToggleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onChanged != null;

    return Container(
      height: 140, // Fixed height for square-ish bento blocks
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Transform.scale(
                scale: 0.8,
                alignment: Alignment.topRight,
                child: Switch(
                  value: value,
                  onChanged: isEnabled
                      ? (val) {
                          HapticFeedback.lightImpact();
                          onChanged(val);
                        }
                      : null,
                  activeColor: theme.colorScheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: -0.3,
                  color: isEnabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(
                    isEnabled ? 1.0 : 0.5,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- RECTANGULAR BENTO CARD (Used for Actions/Navigation) ---
  Widget _buildBentoActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.3,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
