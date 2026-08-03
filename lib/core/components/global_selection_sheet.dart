import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class GlobalSelectionSheet {
  /// Base builder for ultimate flexibility if you ever need a custom UI inside the sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext sheetContext, ScrollController scrollController) builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Minimal Drag Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd, top: DesignTokens.spacingMd),
                    decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // Sheet Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Text(
                    title, 
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)
                  ),
                ),
                const Divider(height: 1),
                // Injected List
                Expanded(
                  child: builder(sheetContext, scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Helper for a simple flat list of strings (e.g., Account Types, Genders, Statuses)
  static Future<String?> showSimple({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String selectedValue,
  }) {
    return show<String>(
      context: context,
      title: title,
      builder: (sheetContext, scrollController) => ListView.separated(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          height: 1, 
          color: Theme.of(context).dividerColor.withOpacity(0.3), 
          indent: 24, 
          endIndent: 24
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedValue == item;
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            title: Text(
              item, 
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, 
                fontSize: 15,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface
              )
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded, 
              size: 14, 
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)
            ),
            onTap: () => Navigator.pop(sheetContext, item),
          );
        },
      ),
    );
  }

  /// Helper for a grouped list of strings (e.g., Provider Banks grouped by type)
  static Future<String?> showGrouped({
    required BuildContext context,
    required String title,
    required Map<String, List<String>> groupedItems,
    required String selectedValue,
  }) {
    return show<String>(
      context: context,
      title: title,
      builder: (sheetContext, scrollController) => ListView.builder(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: groupedItems.length,
        itemBuilder: (context, index) {
          final groupName = groupedItems.keys.elementAt(index);
          final items = groupedItems[groupName]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  groupName.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                final item = entry.value;
                final isSelected = selectedValue == item;
                
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(
                        item, 
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, 
                          fontSize: 15,
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface
                        )
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      onTap: () => Navigator.pop(sheetContext, item),
                    ),
                    if (!isLast)
                      Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2), indent: 24, endIndent: 24),
                  ],
                );
              }).toList(),
              
              if (index < groupedItems.length - 1)
                Divider(height: 32, thickness: 4, color: Theme.of(context).dividerColor.withOpacity(0.05)),
            ],
          );
        },
      ),
    );
  }
}