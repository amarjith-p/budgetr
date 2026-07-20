import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final Color? borderColor;

  const BentoCard({
    super.key,
    required this.child,
    this.onTap,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight;
    final outlineColor = borderColor ?? (isDark ? Colors.white12 : const Color(0xFFE5E7EB));

    return Material(
      color: backgroundColor ?? defaultBgColor,
      elevation: 0, // Strictly flat
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.bentoRadius),
        side: BorderSide(color: outlineColor, width: 1.2), // Crisp, architectural border
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: AppTokens.textLight.withOpacity(0.05),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: height,
          width: width,
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Tighter padding for boxy feel
            child: child,
          ),
        ),
      ),
    );
  }
}