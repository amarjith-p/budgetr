import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_tokens.dart';
import 'modern_boxy_button.dart';

class CustomBottomSheets {
  
  static void showError(BuildContext context, {required String message}) {
    HapticFeedback.heavyImpact(); // Strong feedback for an error state
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent, // Ensures custom border radius shows
      builder: (context) {
        final theme = Theme.of(context);
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
          ),
          padding: EdgeInsets.only(
            left: DesignTokens.spacingLg,
            right: DesignTokens.spacingLg,
            top: DesignTokens.spacingSm,
            bottom: bottomPadding > 0 ? bottomPadding : DesignTokens.spacingLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Forces buttons to full width
            children: [
              // Standard Drag Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              
              // Sleek Tinted Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    Icons.security_update_warning_rounded, 
                    color: theme.colorScheme.error, 
                    size: 36
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              
              // Premium Typography
              Text(
                'Authentication Failed',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -0.5
                ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, 
                  height: 1.5, 
                  fontSize: 15, 
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: DesignTokens.spacingXl),
              
              // Replaced with ModernBoxyButton
              ModernBoxyButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                label: 'TRY AGAIN',
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<bool?> showBiometricOptIn(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false, // Forces user choice
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
          ),
          padding: EdgeInsets.only(
            left: DesignTokens.spacingLg,
            right: DesignTokens.spacingLg,
            top: DesignTokens.spacingXl, // Extra top padding since there's no drag handle
            bottom: bottomPadding > 0 ? bottomPadding : DesignTokens.spacingLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Tinted Biometric Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded, 
                    color: theme.colorScheme.primary, 
                    size: 42
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              
              Text(
                'Enable Fingerprint Login?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -0.5
                ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                'Would you like to use your fingerprint or face to unlock Budgetr faster in the future?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, 
                  height: 1.5, 
                  fontSize: 15, 
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: DesignTokens.spacingXl),
              
              // Action Stack replacing standard buttons
              ModernBoxyButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context, true);
                },
                label: 'YES, ENABLE BIOMETRICS',
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              ModernBoxyButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context, false);
                },
                label: 'NO, SKIP FOR NOW',
                isOutlined: true,
              ),
            ],
          ),
        );
      },
    );
  }
}