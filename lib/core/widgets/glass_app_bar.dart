import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false, // Enforcing Left Alignment
      titleSpacing: 20, // Align with body padding
      // --- Title Styling ---
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
      ),

      // --- Smart Leading Button ---
      leading:
          leading ??
          (showBackButton && canPop
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  child: GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                )
              : null),

      // --- Actions ---
      actions: actions != null
          ? actions!.map((widget) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: widget,
              );
            }).toList()
          : null,
    );
  }
}

// --- Helper Widget for Consistent Action Buttons ---
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;
  final bool hasBorder;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.iconColor,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color ?? AppColors.glassFill,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(
                  color: (color ?? Colors.white).withOpacity(0.5),
                  width: 1,
                )
              : Border.all(color: Colors.transparent),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? AppColors.textPrimary),
      ),
    );
  }
}
