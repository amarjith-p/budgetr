import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../theme/design_tokens.dart';

class BoxySlidableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final EdgeInsetsGeometry margin;
  final BorderRadius? customBorderRadius; // Added for Squircle compatibility
  final Color? customBackgroundColor;     // Added for Premium Card backgrounds

  const BoxySlidableCard({
    Key? key, // Key is required for Slidable to track dismissals
    required this.child,
    this.onEdit,
    this.onDelete,
    this.margin = const EdgeInsets.only(bottom: DesignTokens.spacingMd),
    this.customBorderRadius,
    this.customBackgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If a custom radius is provided, use it. Otherwise, default to the strict boxy aesthetic.
    final activeRadius = customBorderRadius ?? BorderRadius.circular(DesignTokens.spacingXs);

    return Padding(
      padding: margin,
      child: Slidable(
        key: key,
        
        // SWIPE RIGHT (EDIT) - Only renders if onEdit is provided
        startActionPane: onEdit == null ? null : ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) => onEdit!(),
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.only(right: DesignTokens.spacingSm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: activeRadius, // Adapts to custom or default radius
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 1.2),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded),
                    SizedBox(height: 4),
                    Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // SWIPE LEFT (DELETE) - Only renders if onDelete is provided
        endActionPane: onDelete == null ? null : ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: activeRadius, // Adapts to custom or default radius
                  border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3), width: 1.2),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded),
                    SizedBox(height: 4),
                    Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // THE BOXY CARD CONTENT
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: customBackgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: activeRadius,
            side: BorderSide(
              // Completely hide the generic border if a transparent background is explicitly requested
              color: customBackgroundColor == Colors.transparent 
                  ? Colors.transparent 
                  : Theme.of(context).dividerColor.withOpacity(0.6), 
              width: 1.2
            ),
          ),
          child: child, // The injected UI goes here
        ),
      ),
    );
  }
}