import 'package:budgetr/features/transactions/components/transaction_filter_bottom_sheet.dart';
import 'package:budgetr/features/transactions/providers/transaction_filter_provider.dart';
import 'package:budgetr/features/transactions/providers/transaction_provider.dart';
import 'package:budgetr/features/transactions/views/records_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_bottom_nav.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/theme/design_tokens.dart';
import '../../accounts/views/accounts_tab.dart'; // Gives access to selection providers
import '../../accounts/components/account_form_bottom_sheet.dart';
import '../../transactions/views/transaction_form_page.dart';
import '../providers/bottom_nav_provider.dart';

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
    final isSelectionMode = ref.watch(selectionModeProvider); // From AccountsTab
    final globalFilterState = ref.watch(transactionFilterProvider('GLOBAL')); // Watch filter state

    final List<Widget> pages = [
      const _PlaceholderTab(title: 'MONEY TRACKER HOME'),
      const RecordsTab(), // <-- NEW: Injected Global Records Tab
      const AccountsTab(),
      const _PlaceholderTab(title: 'BUDGET MANAGEMENT'),
      const _PlaceholderTab(title: 'ANALYTICS & INSIGHTS'),
    ];

    // Determine the extra trailing icon dynamically based on the active tab
    IconData? activeExtraIcon;
    Color? activeExtraColor;
    
    if (currentIndex == 2) {
      activeExtraIcon = isSelectionMode ? Icons.close_rounded : Icons.calculate_outlined;
      activeExtraColor = isSelectionMode ? Theme.of(context).colorScheme.primary : null;
    } else if (currentIndex == 1) {
      activeExtraIcon = globalFilterState.isActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined;
      activeExtraColor = globalFilterState.isActive ? Theme.of(context).colorScheme.primary : null;
    }

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Tracker',
        subtitle: 'FINANCE',
        leadingIcon: Icons.arrow_back_rounded,
        
        extraTrailingIcon: activeExtraIcon,
        extraIconColor: activeExtraColor,
        onExtraTrailingPressed: () {
          HapticFeedback.lightImpact();
          if (currentIndex == 2) {
            // Accounts Calculator Toggle
            if (isSelectionMode) {
              ref.read(selectionModeProvider.notifier).state = false;
              ref.read(selectedAccountsProvider.notifier).state = {};
            } else {
              ref.read(selectionModeProvider.notifier).state = true;
            }
          } else if (currentIndex == 1) {
            // Global Records Filter Sheet
            final allTxs = ref.read(allTransactionsProvider).asData?.value ?? [];
            TransactionFilterBottomSheet.show(context, 'GLOBAL', allTxs);
          }
        },
        
        trailingIcon: currentIndex == 2 ? Icons.add_card_rounded : null,
        onTrailingPressed: currentIndex == 2 ? () => _openAddAccountForm(context) : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[currentIndex],
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () => _openTransactionForm(context),
        icon: Icons.add_rounded,
        label: 'Log',
      ),
      bottomNavigationBar: ModernBottomNav(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(moneyTrackerNavProvider.notifier).state = index;
        },
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}