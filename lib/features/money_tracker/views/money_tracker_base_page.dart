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

    // --- FULL 6-TAB PAGES ARRAY ---
    final List<Widget> pages = [
      const MoneyTrackerHomeTab(),
      const RecordsTab(),
      const AccountsTab(),
      const BudgetManagementTab(),
      const _PlaceholderTab(title: 'ANALYTICS'),
      const _PlaceholderTab(title: 'INSIGHTS'),
    ];

    // --- DYNAMIC TRAILING & EXTRA TRAILING CONFIGURATION ---
    IconData? trailingIcon;
    VoidCallback? onTrailingPressed;

    IconData? extraTrailingIcon;
    Color? extraIconColor;
    VoidCallback? onExtraTrailingPressed;

    if (currentIndex == 1) {
      trailingIcon = globalFilterState.isActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined;
      onTrailingPressed = () {
        HapticFeedback.lightImpact();
        final allTxs = ref.read(allTransactionsProvider).asData?.value ?? [];
        TransactionFilterBottomSheet.show(context, 'GLOBAL', allTxs);
      };
    } else if (currentIndex == 2) {
      trailingIcon = Icons.add_card_rounded;
      onTrailingPressed = () => _openAddAccountForm(context);
      extraTrailingIcon = isSelectionMode ? Icons.close_rounded : Icons.calculate_outlined;
      extraIconColor = isSelectionMode ? Theme.of(context).colorScheme.primary : null;
      onExtraTrailingPressed = () {
        HapticFeedback.lightImpact();
        if (isSelectionMode) {
          ref.read(selectionModeProvider.notifier).state = false;
          ref.read(selectedAccountsProvider.notifier).state = {};
        } else {
          ref.read(selectionModeProvider.notifier).state = true;
        }
      };
    }

    return Scaffold(
      extendBody: true, 
      appBar: ModernAppBar(
        title: 'Tracker',
        subtitle: 'FINANCE',
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

// --- PLACEHOLDER UI FOR UPCOMING FEATURES ---
class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}