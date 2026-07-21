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

    // Map ThemeMode to our Boxy Toggle index
    int selectedIndex = 0; // System
    if (themeMode == ThemeMode.light) selectedIndex = 1;
    if (themeMode == ThemeMode.dark) selectedIndex = 2;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0), // Matching your padRadius
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8.0),
              Text(
                'App Appearance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          ModernBoxyToggle(
            labels: const ['System', 'Light', 'Dark'],
            selectedIndex: selectedIndex,
            onSelected: (index) {
              ThemeMode newMode = ThemeMode.system;
              if (index == 1) newMode = ThemeMode.light;
              if (index == 2) newMode = ThemeMode.dark;
              
              // Updates the provider, instantly rebuilding main.dart
              ref.read(themeModeProvider.notifier).state = newMode;
            },
          ),
        ],
      ),
    );
  }
}