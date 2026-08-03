// features/custom_budgets/views/custom_budget_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/custom_budget_provider.dart';
import '../components/custom_budget_card.dart';
import '../components/custom_budget_form_sheet.dart';

class CustomBudgetDashboardPage extends ConsumerStatefulWidget {
  const CustomBudgetDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomBudgetDashboardPage> createState() => _CustomBudgetDashboardPageState();
}

class _CustomBudgetDashboardPageState extends ConsumerState<CustomBudgetDashboardPage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Active', 'Settled'];

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => const CustomBudgetFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = _selectedTabIndex == 0 ? activeCustomBudgetsProvider : settledCustomBudgetsProvider;
    final budgetsAsync = ref.watch(provider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: 'Custom Limits',
        subtitle: 'SUB BUDGETING',
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      floatingActionButton: _selectedTabIndex == 0 
        ? ModernSquircleFab(
            onPressed: _openAddSheet,
            icon: Icons.add_rounded,
            label: 'Budget',
          )
        : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingSm),
            child: ModernBoxyToggle(
              labels: _tabs,
              selectedIndex: _selectedTabIndex,
              onSelected: (index) => setState(() => _selectedTabIndex = index),
            ),
          ),
          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (budgets) {
                if (budgets.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_tabs[_selectedTabIndex].toLowerCase()} custom budgets found.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return ListView.builder(
                  padding: DesignTokens.pagePadding.copyWith(bottom: 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final bData = budgets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
                      child: CustomBudgetCard(
                        data: bData,
                        isActive: _selectedTabIndex == 0,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}