import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double? heightFactor;

  const GlassBottomSheet({super.key, required this.child, this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Handles keyboard overlap automatically
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ), // Reduced radius for professional look
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: double.infinity,
            // Use heightFactor if provided, otherwise let it wrap content
            height: heightFactor != null
                ? MediaQuery.of(context).size.height * heightFactor!
                : null,
            decoration: BoxDecoration(
              // 95% Opacity = Professional Dark Mode (Less Vibrant background bleed)
              color: AppColors.deepVoid.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: AppColors.glassBorder, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Vital: Wraps content height
                children: [
                  // --- Drag Handle ---
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // --- Content ---
                  // Flexible allows the child to be smaller than the screen
                  // but scrollable if it gets too big.
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Static helper to show the sheet easily from anywhere
  static Future<T?> show<T>(BuildContext context, {required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => GlassBottomSheet(child: child),
    );
  }
}
