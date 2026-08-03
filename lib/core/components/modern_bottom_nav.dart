import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;

  const ModernBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.85),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
            width: 1.0,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            bottom: true,
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- LEFT TABS ---
                  _buildNavItem(context, 0, Icons.space_dashboard_rounded, Icons.space_dashboard_outlined, 'Home'),
                  _buildNavItem(context, 1, Icons.receipt_rounded, Icons.receipt_outlined, 'Records'),
                  _buildNavItem(context, 2, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Accounts'),
                  
                  // --- THE INTEGRATED CENTER FAB ---
                  _buildAddButton(context),
                  
                  // --- RIGHT TABS ---
                  _buildNavItem(context, 3, Icons.donut_large_rounded, Icons.donut_large_outlined, 'Budgets'),
                  _buildNavItem(context, 4, Icons.leaderboard_rounded, Icons.leaderboard_outlined, 'Analytics'),
                  _buildNavItem(context, 5, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Insights'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final theme = Theme.of(context);
    final isSelected = selectedIndex == index;
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.5);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            onDestinationSelected(index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  key: ValueKey(isSelected),
                  size: 22, 
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9, 
                  letterSpacing: 0.2, // Added slight tracking for premium readability
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          onAddPressed();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 44, 
              width: 44,
              decoration: BoxDecoration(
                // Added a subtle gradient to make the button look high-end
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withBlue(255).withRed(100), 
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14), 
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: theme.colorScheme.onPrimary,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}