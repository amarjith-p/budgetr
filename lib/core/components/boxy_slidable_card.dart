import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../theme/design_tokens.dart';

class BoxySlidableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onClone; 
  final VoidCallback? onSplit; 
  final VoidCallback? onSettle; // <-- NEW
  final VoidCallback? onDelete;
  final EdgeInsetsGeometry margin;
  final BorderRadius? customBorderRadius; 
  final Color? customBackgroundColor;     

  const BoxySlidableCard({
    Key? key, 
    required this.child,
    this.onEdit,
    this.onClone, 
    this.onSplit, 
    this.onSettle, // <-- NEW
    this.onDelete,
    this.margin = const EdgeInsets.only(bottom: DesignTokens.spacingMd),
    this.customBorderRadius,
    this.customBackgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeRadius = customBorderRadius ?? BorderRadius.circular(DesignTokens.spacingXs);
    
    int startActionCount = (onEdit != null ? 1 : 0) + (onClone != null ? 1 : 0);
    double startExtent = startActionCount * 0.25;

    // Dynamically calculate end swipe width including the new Settle action
    int endActionCount = (onDelete != null ? 1 : 0) + (onSplit != null ? 1 : 0) + (onSettle != null ? 1 : 0);
    double endExtent = endActionCount * 0.25;

    return Padding(
      padding: margin,
      child: Slidable(
        key: key,
        
        // SWIPE RIGHT (CLONE & EDIT)
        startActionPane: startActionCount == 0 ? null : ActionPane(
          motion: const DrawerMotion(),
          extentRatio: startExtent,
          children: [
            if (onClone != null)
              CustomSlidableAction(
                onPressed: (_) => onClone!(),
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                padding: EdgeInsets.zero,
                child: Container(
                  margin: const EdgeInsets.only(right: DesignTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: activeRadius, 
                    border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.content_copy_rounded),
                      SizedBox(height: 4),
                      Text('Clone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            if (onEdit != null)
              CustomSlidableAction(
                onPressed: (_) => onEdit!(),
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                padding: EdgeInsets.zero,
                child: Container(
                  margin: const EdgeInsets.only(right: DesignTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: activeRadius, 
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

        // SWIPE LEFT (SETTLE, SPLIT & DELETE)
        endActionPane: endActionCount == 0 ? null : ActionPane(
          motion: const DrawerMotion(),
          extentRatio: endExtent,
          children: [
            // --- NEW: SETTLE ACTION ---
            if (onSettle != null)
              CustomSlidableAction(
                onPressed: (_) => onSettle!(),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                child: Container(
                  margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: activeRadius, 
                    border: Border.all(color: Colors.green.shade800.withOpacity(0.5), width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded),
                      SizedBox(height: 4),
                      Text('Settle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            if (onSplit != null)
              CustomSlidableAction(
                onPressed: (_) => onSplit!(),
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                padding: EdgeInsets.zero,
                child: Container(
                  margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: activeRadius, 
                    border: Border.all(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3), width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call_split_rounded),
                      SizedBox(height: 4),
                      Text('Split', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            if (onDelete != null)
              CustomSlidableAction(
                onPressed: (_) => onDelete!(),
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                padding: EdgeInsets.zero,
                child: Container(
                  margin: const EdgeInsets.only(left: DesignTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: activeRadius, 
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
        
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: customBackgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: activeRadius,
            side: BorderSide(
              color: customBackgroundColor == Colors.transparent 
                   ? Colors.transparent 
                   : Theme.of(context).dividerColor.withOpacity(0.6), 
               width: 1.2
            ),
          ),
          child: child, 
        ),
      ),
    );
  }
}