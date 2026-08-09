// features/settings/views/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/theme_switcher_card.dart';
import '../../../core/theme/design_tokens.dart';
import '../../notifications/views/notification_manager_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

          // --- YOUR EXISTING THEME SWITCHER LOGIC ---
          // (Update the UI inside this file using the snippet below)
          const ThemeSwitcherCard(),

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
        borderRadius: BorderRadius.circular(8), // Boxy sharp corner
        border: Border.all(
          color: theme.dividerColor,
          width: 1.0,
        ), // Rigid border
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
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
                  borderRadius: BorderRadius.circular(
                    4,
                  ), // Sharp square icon background
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
}
