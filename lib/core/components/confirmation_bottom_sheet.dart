import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_tokens.dart';
import 'modern_boxy_button.dart';

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
    HapticFeedback.lightImpact();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent, // Ensures the custom shape corner radius shows
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
        crossAxisAlignment: CrossAxisAlignment.center, // Centered for a premium feel
        children: [
          // Standard Custom Drag Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg, top: DesignTokens.spacingSm),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          // Sleek Circular Icon
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDestructive ? Icons.delete_outline_rounded : Icons.info_outline_rounded,
              color: iconColor,
              size: 36,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          
          // Typography
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
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
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: DesignTokens.spacingXl),

          // Replaced with ModernBoxyButton
          Row(
            children: [
              Expanded(
                child: ModernBoxyButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, false);
                  },
                  label: cancelText,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: ModernBoxyButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, true);
                    onConfirm();
                  },
                  label: confirmText,
                  backgroundColor: confirmBgColor,
                  foregroundColor: confirmFgColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}