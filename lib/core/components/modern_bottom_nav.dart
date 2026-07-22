import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_tokens.dart';

class ModernBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const ModernBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64, // Sleek, compact height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Records',
                isSelected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Accounts',
                isSelected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _NavItem(
                icon: Icons.donut_small_outlined, // Sleeker than the standard pie chart
                activeIcon: Icons.donut_small_rounded,
                label: 'Budgets',
                isSelected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
              _NavItem(
                icon: Icons.insert_chart_outlined, // Minimalist analytics icon
                activeIcon: Icons.bar_chart_rounded,
                label: 'Analytics',
                isSelected: selectedIndex == 4,
                onTap: () => onDestinationSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A highly controlled, private navigation item for the custom bar.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Stark primary for active, muted transparent for inactive
    final color = isSelected 
        ? theme.colorScheme.primary 
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Triggers a premium, physical tap sensation on the device
          HapticFeedback.lightImpact(); 
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Smooth, bouncing scale transition for the icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected), // Forces the AnimatedSwitcher to recognize the change
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            // Animated typography weight and color
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.2,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}