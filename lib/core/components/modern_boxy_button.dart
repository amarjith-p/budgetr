import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ModernBoxyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor; 
  final Color? foregroundColor; 

  const ModernBoxyButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boxyRadius = BorderRadius.circular(DesignTokens.spacingXs);
    final theme = Theme.of(context);

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: boxyRadius),
            side: BorderSide(
              color: backgroundColor ?? theme.dividerColor, 
              width: 1.5
            ),
            foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
          ),
          onPressed: isLoading ? null : onPressed,
          // Intelligent Overflow: FittedBox prevents text breaking on narrow flex layouts
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              maxLines: 1,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: boxyRadius),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(strokeWidth: 2.5, color: foregroundColor ?? Colors.white)
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  maxLines: 1,
                ),
              ),
      ),
    );
  }
}