import 'package:budgetr/core/components/modern_app_bar.dart';
import 'package:budgetr/core/components/modern_squircle_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/modern_boxy_toggle.dart'; // New Component
import '../providers/category_provider.dart';
import '../components/category_list_widget.dart';
import '../components/category_form_bottom_sheet.dart';

class CategoryManagerPage extends ConsumerStatefulWidget {
  const CategoryManagerPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryManagerPage> createState() => _CategoryManagerPageState();
}

class _CategoryManagerPageState extends ConsumerState<CategoryManagerPage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Expense', 'Income'];

  void _handleReset(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Restore Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Restores system defaults and automatically re-links any legacy transactions without breaking logged history.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                  ),
                ),
                leading: Icon(
                  Icons.restore_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: const Text(
                  'Restore Defaults (Keep Custom)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Recommended • Keeps all custom categories & links',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(categoryActionProvider.notifier)
                      .resetToDefaults(keepCustomCategories: true);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor),
                ),
                leading: Icon(
                  Icons.cleaning_services_rounded,
                  color: theme.colorScheme.error,
                ),
                title: const Text(
                  'Reset & Clean Unused Custom',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Removes unused custom categories; keeps ones used in transactions',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ConfirmationBottomSheet.show(
                    context,
                    title: 'Reset & Clean Unused?',
                    description:
                        'Restores system defaults and removes custom categories that have no logged transactions. Categories in use will be preserved.',
                    confirmText: 'RESET',
                    isDestructive: true,
                    onConfirm: () {
                      ref
                          .read(categoryActionProvider.notifier)
                          .resetToDefaults(keepCustomCategories: false);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => CategoryFormBottomSheet(initialType: _tabs[_selectedTabIndex]),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(categoryActionProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString().replaceAll('Exception: ', ''))),
        );
      }
    });

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Categories',
        subtitle: 'MANAGEMENT',
        leadingIcon: Icons.arrow_back_rounded,
        trailingIcon: Icons.restore_outlined,
        onTrailingPressed: () => _handleReset(context),
      ),
      body: Column(
        children: [
          // Injecting the Modern Pill Toggle globally
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingSm),
            child: ModernBoxyToggle( // <-- Updated Class Name
              labels: _tabs,
              selectedIndex: _selectedTabIndex,
              onSelected: (index) {
                setState(() => _selectedTabIndex = index);
              },
            ),
          ),
          // Renders the list based on the active selection
          Expanded(
            child: CategoryListWidget(categoryType: _tabs[_selectedTabIndex]),
          ),
        ],
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () => _openAddSheet(context),
        icon: Icons.add_rounded, // Using the rounded Material icon variant
        label: 'Category',
      ),
    );
  }
}