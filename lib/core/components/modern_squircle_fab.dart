import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ModernSquircleFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const ModernSquircleFab({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // High contrast: Pure Black in Light Mode, Pure White in Dark Mode
    final bgColor = isDark ? Colors.white : Colors.black;
    final fgColor = isDark ? Colors.black : Colors.white;

    return Material(
      color: bgColor,
      // A smooth 16px border radius creates a perfect "Squircle" 
      // instead of a sharp box or a circular pill.
      borderRadius: BorderRadius.circular(16.0),
      // A very subtle, tight elevation to lift it just slightly off the scrolling list
      elevation: 4,
      shadowColor: bgColor.withOpacity(0.4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16.0),
        splashColor: fgColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0, 
            vertical: 16.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fgColor, size: 22),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}