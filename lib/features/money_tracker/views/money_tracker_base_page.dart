// features/money_tracker/views/money_tracker_base_page.dart
import 'package:budgetr/features/analytics/components/closed_budget_snapshot_widget.dart';
import 'package:budgetr/features/analytics/providers/pinned_widgets_provider.dart';
import 'package:budgetr/features/budgets/views/budget_management_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_bottom_nav.dart';
import '../../../core/theme/design_tokens.dart';

import '../../accounts/views/accounts_tab.dart';
import '../../accounts/components/account_form_bottom_sheet.dart';
import '../../transactions/views/transaction_form_page.dart';
import '../../transactions/views/records_tab.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/providers/transaction_filter_provider.dart';
import '../../transactions/components/transaction_filter_bottom_sheet.dart';

import '../providers/bottom_nav_provider.dart';
import 'money_tracker_home_tab.dart';

import '../../custom_budgets/views/custom_budget_dashboard_page.dart';
import '../../analytics/components/balance_trend_widget.dart';
import '../../analytics/components/cash_flow_widget.dart';
import '../../analytics/components/spending_widget.dart';
import '../../analytics/components/budget_simulator_widget.dart';
import '../../analytics/components/credit_tracker_widget.dart';

import '../../insights/views/insights_tab.dart';

class MoneyTrackerBasePage extends ConsumerWidget {
  const MoneyTrackerBasePage({Key? key}) : super(key: key);

  void _openAddAccountForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => const AccountFormBottomSheet(),
    );
  }

  void _openTransactionForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionFormPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(moneyTrackerNavProvider);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final globalFilterState = ref.watch(transactionFilterProvider('GLOBAL'));

    final List<Widget> pages = [
      const MoneyTrackerHomeTab(),
      const RecordsTab(),
      const AccountsTab(),
      const BudgetManagementTab(),
      const _AnalyticsTab(),
      const InsightsTab(),
    ];

    final List<String> tabTitles = [
      'Overview',
      'Transactions',
      'Accounts',
      'Budgets',
      'Analytics',
      'Insights',
    ];

    final List<String> tabSubtitles = [
      'Financial snapshot',
      'Complete Money Trail',
      'Money, All in One Place',
      'Control Your Spending',
      'Explore Your Finances',
      'Finance Health',
    ];

    IconData? trailingIcon;
    VoidCallback? onTrailingPressed;

    IconData? extraTrailingIcon;
    Color? extraIconColor;
    VoidCallback? onExtraTrailingPressed;

    if (currentIndex == 1) {
      trailingIcon = globalFilterState.isActive
          ? Icons.filter_alt_rounded
          : Icons.filter_alt_outlined;
      onTrailingPressed = () {
        HapticFeedback.lightImpact();
        final allTxs = ref.read(allTransactionsProvider).asData?.value ?? [];
        TransactionFilterBottomSheet.show(context, 'GLOBAL', allTxs);
      };
    } else if (currentIndex == 2) {
      trailingIcon = Icons.add_card_rounded;
      onTrailingPressed = () => _openAddAccountForm(context);
      extraTrailingIcon = isSelectionMode
          ? Icons.close_rounded
          : Icons.calculate_outlined;
      extraIconColor = isSelectionMode
          ? Theme.of(context).colorScheme.primary
          : null;
      onExtraTrailingPressed = () {
        HapticFeedback.lightImpact();
        if (isSelectionMode) {
          ref.read(selectionModeProvider.notifier).state = false;
          ref.read(selectedAccountsProvider.notifier).state = {};
        } else {
          ref.read(selectionModeProvider.notifier).state = true;
        }
      };
    } else if (currentIndex == 3) {
      trailingIcon = Icons.tune_rounded;
      onTrailingPressed = () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomBudgetDashboardPage()),
        );
      };
    } else if (currentIndex == 5) {
      // --- EXPORT BUTTON DELEGATED TO THE MASTER APPBAR ---
      trailingIcon = Icons.ios_share_rounded;
      onTrailingPressed = () {
        HapticFeedback.lightImpact();
        InsightExportUI.show(context, ref);
      };
    }

    return Scaffold(
      extendBody: true,
      appBar: ModernAppBar(
        title: tabTitles[currentIndex],
        subtitle: tabSubtitles[currentIndex],
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.maybePop(context),
        trailingIcon: trailingIcon,
        onTrailingPressed: onTrailingPressed,
        extraTrailingIcon: extraTrailingIcon,
        extraIconColor: extraIconColor,
        onExtraTrailingPressed: onExtraTrailingPressed,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[currentIndex],
      ),
      bottomNavigationBar: ModernBottomNav(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(moneyTrackerNavProvider.notifier).state = index;
        },
        onAddPressed: () => _openTransactionForm(context),
      ),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(pinnedWidgetsProvider);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        if (!pinned.contains('BALANCE_TREND')) const BalanceTrendWidget(),
        if (!pinned.contains('CASH_FLOW')) const CashFlowWidget(),
        if (!pinned.contains('SPENDING')) const SpendingWidget(),
        if (!pinned.contains('CREDIT_TRACKER')) const CreditTrackerWidget(),
        if (!pinned.contains('BUDGET_SIMULATOR')) const BudgetSimulatorWidget(),
        if (!pinned.contains('BUDGET_SNAPSHOT'))
          const ClosedBudgetSnapshotWidget(),
        if (pinned.length >= 6)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text(
                'All widgets are pinned to your Home Tab.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
