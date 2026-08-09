import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import 'modern_boxy_toggle.dart';

class ThemeSwitcherCard extends ConsumerWidget {
  const ThemeSwitcherCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Map ThemeMode to our Boxy Toggle index[cite: 3]
    int selectedIndex = 0; // System
    if (themeMode == ThemeMode.light) selectedIndex = 1;
    if (themeMode == ThemeMode.dark) selectedIndex = 2;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0), // Boxy sharp corner
        border: Border.all(
          color: theme.dividerColor,
          width: 1.0,
        ), // Rigid border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rigid Boxy Icon Container matching Notification menu
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
                child: Icon(
                  Icons.palette_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Title and Subtitle matching the Boxy Tile text style
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Appearance',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select your preferred theme',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Your perfectly working toggle logic[cite: 3]
          ModernBoxyToggle(
            labels: const ['System', 'Light', 'Dark'],
            selectedIndex: selectedIndex,
            onSelected: (index) {
              ThemeMode newMode = ThemeMode.system;
              if (index == 1) newMode = ThemeMode.light;
              if (index == 2) newMode = ThemeMode.dark;

              // Updates the provider, instantly rebuilding main.dart[cite: 3]
              ref.read(themeModeProvider.notifier).state = newMode;
            },
          ),
        ],
      ),
    );
  }
}
