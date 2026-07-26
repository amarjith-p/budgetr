import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  
  // --- NEW: Optional extra action ---
  final IconData? extraTrailingIcon;
  final VoidCallback? onExtraTrailingPressed;
  final Color? extraIconColor;

  final VoidCallback? onTitleLongPress;

  const ModernAppBar({
    Key? key,
    required this.title,
    required this.subtitle,
    this.leadingIcon = Icons.arrow_back_rounded,
    this.onLeadingPressed,
    this.trailingIcon,
    this.onTrailingPressed,
    this.extraTrailingIcon,
    this.onExtraTrailingPressed,
    this.extraIconColor,
    this.onTitleLongPress,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(80.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLg, 
          vertical: DesignTokens.spacingMd,
        ),
        child: Row(
          children: [
            if (leadingIcon != null)
              _GlassIconButton(
                icon: leadingIcon!,
                onTap: onLeadingPressed ?? () => Navigator.maybePop(context),
                isDark: isDark,
              )
            else
              const SizedBox(width: 44), 
            const SizedBox(width: DesignTokens.spacingMd),
            
            Expanded(
              child: GestureDetector(
                onLongPress: onTitleLongPress,
                behavior: HitTestBehavior.opaque, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // --- NEW: EXTRA ACTION BUTTON ---
            if (extraTrailingIcon != null) ...[
              _GlassIconButton(
                icon: extraTrailingIcon!,
                onTap: onExtraTrailingPressed,
                isDark: isDark,
                customColor: extraIconColor,
              ),
              const SizedBox(width: 8),
            ],

            if (trailingIcon != null)
              _GlassIconButton(
                icon: trailingIcon!,
                onTap: onTrailingPressed,
                isDark: isDark,
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final Color? customColor; 

  const _GlassIconButton({
    required this.icon,
    this.onTap,
    required this.isDark,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: customColor?.withOpacity(0.1) ?? (isDark 
               ? Colors.white.withOpacity(0.05) 
               : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(
                icon, 
                color: customColor ?? theme.colorScheme.onSurface, 
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}