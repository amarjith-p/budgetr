import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/icon_constants.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/boxy_slidable_card.dart'; // The new global component
import '../providers/category_provider.dart';
import 'category_form_bottom_sheet.dart';

class CategoryListWidget extends ConsumerWidget {
  final String categoryType;
  
  const CategoryListWidget({Key? key, required this.categoryType}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (categories) {
        final filteredList = categories.where((c) => c.type == categoryType).toList();

        if (filteredList.isEmpty) {
          return Center(child: Text('No $categoryType categories found.'));
        }

        return ListView.builder(
          padding: DesignTokens.pagePadding,
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final category = filteredList[index];
            final iconData = IconConstants.getIconByCode(category.iconCode);
            final boxyRadius = BorderRadius.circular(DesignTokens.spacingXs);

            return BoxySlidableCard(
              key: ValueKey(category.id),
              
              // Define what happens on Swipe Right (Edit)
              onEdit: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: DesignTokens.bottomSheetShape,
                  builder: (ctx) => CategoryFormBottomSheet(
                    initialType: categoryType,
                    categoryToEdit: category,
                  ),
                );
              },
              
              // Define what happens on Swipe Left (Delete)
              onDelete: () {
                ConfirmationBottomSheet.show(
                  context,
                  title: 'Delete Category?',
                  description: 'Are you sure you want to delete "${category.name}"?',
                  confirmText: 'DELETE',
                  isDestructive: true,
                  onConfirm: () {
                    ref.read(categoryActionProvider.notifier).deleteCategory(category.id);
                  },
                );
              },
              
              // Pass the inner UI
              child: ExpansionTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: boxyRadius,
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                  ),
                  child: Icon(iconData, color: Theme.of(context).colorScheme.primary, size: 22),
                ),
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                subtitle: Text('${category.subCategories.length} Subcategories', style: const TextStyle(fontSize: 12)),
                shape: const Border(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spacingMd, 
                      0, 
                      DesignTokens.spacingMd, 
                      DesignTokens.spacingMd
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: DesignTokens.spacingSm,
                        runSpacing: DesignTokens.spacingXs,
                        children: category.subCategories.map((sub) => Chip(
                          label: Text(sub, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: boxyRadius),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}