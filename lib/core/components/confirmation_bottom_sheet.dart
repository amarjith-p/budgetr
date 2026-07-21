import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const ConfirmationBottomSheet({
    Key? key,
    required this.title,
    required this.description,
    required this.onConfirm,
    this.confirmText = 'CONFIRM',
    this.cancelText = 'CANCEL',
    this.isDestructive = false,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onConfirm,
    String confirmText = 'CONFIRM',
    String cancelText = 'CANCEL',
    bool isDestructive = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)), // Sleeker curve
      ),
      builder: (ctx) => ConfirmationBottomSheet(
        title: title,
        description: description,
        onConfirm: onConfirm,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Sleek contextual colors
    final iconColor = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;
    final iconBgColor = isDestructive 
        ? theme.colorScheme.error.withOpacity(0.1) 
        : theme.colorScheme.primary.withOpacity(0.1);
        
    final confirmBgColor = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;
    final confirmFgColor = isDestructive ? theme.colorScheme.onError : theme.colorScheme.onPrimary;

    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.spacingXl,
        right: DesignTokens.spacingXl,
        top: DesignTokens.spacingSm,
        bottom: bottomPadding > 0 ? bottomPadding : DesignTokens.spacingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Centered for a premium feel
        children: [
          // Subtle Drag Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: DesignTokens.spacingXl),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Sleek Circular Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDestructive ? Icons.delete_outline_rounded : Icons.info_outline_rounded,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          
          // Typography
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 15,
            ),
          ),
          
          const SizedBox(height: 32),

          // Independent Sleek Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmBgColor,
                      foregroundColor: confirmFgColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, true);
                      onConfirm();
                    },
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w700, 
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}