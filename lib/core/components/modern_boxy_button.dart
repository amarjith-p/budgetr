import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernBoxyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isOutlined;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  const ModernBoxyButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.isOutlined = false,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = theme.colorScheme.primary;
    final defaultFg = theme.colorScheme.onPrimary;

    final activeBg = backgroundColor ?? defaultBg;
    final activeFg = foregroundColor ?? defaultFg;

    if (isOutlined) {
      return SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: (isLoading || onPressed == null)
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          style: OutlinedButton.styleFrom(
            // --- FIX 1: Override Flutter's massive default padding ---
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            foregroundColor: activeBg,
            side: BorderSide(
              color: (onPressed == null || isLoading)
                  ? theme.dividerColor
                  : activeBg.withOpacity(0.3),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            overlayColor: activeBg.withOpacity(0.1),
            backgroundColor: Colors.transparent,
          ),
          child: _buildChild(theme, activeBg),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: (isLoading || onPressed == null)
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          // --- FIX 1: Override Flutter's massive default padding ---
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          backgroundColor: activeBg,
          foregroundColor: activeFg,
          disabledBackgroundColor: isDark
              ? Colors.white12
              : Colors.black.withOpacity(0.05),
          disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _buildChild(
          theme,
          (isLoading || onPressed == null)
              ? (isDark ? Colors.white38 : Colors.black38)
              : activeFg,
        ),
      ),
    );
  }

  Widget _buildChild(ThemeData theme, Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(color: textColor, strokeWidth: 2.5),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        // --- FIX 2: Prevents the Row from demanding infinite width inside the FittedBox ---
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: textColor,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
