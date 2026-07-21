import 'package:flutter/material.dart';

class CustomSnackbars {
  /// Shows a positive/success notification
  static void showSuccess(BuildContext context, {required String message}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Keeping your established success color logic
    final successColor = isDark ? const Color(0xFF3A86FF) : theme.colorScheme.primary;

    _showSnackbar(
      context, 
      message: message, 
      backgroundColor: successColor, 
      icon: Icons.check_circle_outline_rounded,
    );
  }

  /// Shows an error/destructive notification
  static void showError(BuildContext context, {required String message}) {
    final theme = Theme.of(context);

    _showSnackbar(
      context, 
      message: message, 
      backgroundColor: theme.colorScheme.error, 
      icon: Icons.error_outline_rounded,
    );
  }

  /// Private helper to maintain consistent, minimal styling across all snackbars
  static void _showSnackbar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    // Hide any currently visible snackbar to prevent awkward queuing 
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        // Matching your AppTokens.padRadius for consistent boxy aesthetics
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(16.0),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}