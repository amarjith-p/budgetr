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
    ConfirmationBottomSheet.show(
      context,
      title: 'Reset to Defaults?',
      description: 'This will delete all custom categories and restore system defaults. This action cannot be undone.',
      confirmText: 'RESET',
      isDestructive: true,
      onConfirm: () {
        ref.read(categoryActionProvider.notifier).resetToDefaults();
      },
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