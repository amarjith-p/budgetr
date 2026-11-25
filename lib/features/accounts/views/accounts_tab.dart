// lib/features/accounts/views/accounts_tab.dart
import 'dart:ui';
import 'package:budgetr/core/components/currency_text.dart';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:budgetr/core/components/premium_empty_state.dart';
import 'package:budgetr/core/database/app_database.dart';
import 'package:budgetr/features/accounts/components/account_form_bottom_sheet.dart';
import 'package:budgetr/features/accounts/components/premium_account_card.dart';
import 'package:budgetr/features/transactions/views/account_transactions_page.dart';
import 'package:budgetr/features/transactions/views/credit_transaction_page.dart';
import 'package:budgetr/features/transactions/views/loan_transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/account_provider.dart';
import '../providers/loan_math_provider.dart';
import '../providers/credit_math_provider.dart';
import '../components/global_summary_card.dart';
import '../components/account_balance_visibility_sheet.dart';

final selectionModeProvider = StateProvider.autoDispose<bool>((ref) => false);
final selectedAccountsProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => <String>{},
);
final archivedAccountsExpandedProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class AccountsTab extends ConsumerWidget {
  const AccountsTab({Key? key}) : super(key: key);

  void _openForm(BuildContext context, {var existingAccount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) =>
          AccountFormBottomSheet(existingAccount: existingAccount),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final theme = Theme.of(context);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedIds = ref.watch(selectedAccountsProvider);
    final isArchivedExpanded = ref.watch(archivedAccountsExpandedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: accountsAsync.when(
        loading: () => const Center(
          child: FuturisticLoader(size: 80, label: "LOADING ACCOUNTS.."),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (accounts) {
          // --- VISUAL UI LISTS ---
          final creditCards = accounts
              .where((a) => a.type == 'Credit Cards' && !a.isClosed)
              .toList();
          final bankAccounts = accounts
              .where((a) =>
                  a.type != 'Credit Cards' && a.type != 'Loan' && !a.isClosed)
              .toList();
          final activeLoans = accounts
              .where((a) => a.type == 'Loan' && !a.isClosed)
              .toList();
          final archivedAccounts = accounts
              .where((a) => a.isClosed)
              .toList();

          // --- FIX 3: UNIVERSAL MATH STANDARD & BALANCE PRIVACY ---
          // Calculates visible (without hidden), hidden, and full global totals
          double visibleBankBalance = 0.0;
          double visibleCreditBalance = 0.0;
          double visibleLoanOutstanding = 0.0;

          double hiddenBankBalance = 0.0;
          double hiddenCreditBalance = 0.0;
          double hiddenLoanOutstanding = 0.0;

          double totalBankBalance = 0.0;
          double totalCreditBalance = 0.0;
          double totalLoanOutstanding = 0.0;

          int hiddenCount = 0;

          for (var acc in accounts) {
            if (acc.isClosed) continue;

            final isHiddenInAccounts = acc.hideBalanceInAccounts;
            if (isHiddenInAccounts) hiddenCount++;

            if (acc.type == 'Credit Cards') {
              final dues = ref
                  .watch(creditCardMetricsProvider(acc))
                  .totalOutstanding;
              totalCreditBalance += dues;
              if (isHiddenInAccounts) {
                hiddenCreditBalance += dues;
              } else {
                visibleCreditBalance += dues;
              }
            } else if (acc.type == 'Loan' && !acc.isClosed) {
              final rawLoanDue = ref.watch(
                loanTotalOutstandingProvider(acc),
              );
              final loanDue = rawLoanDue > 0 ? rawLoanDue : 0.0;
              totalLoanOutstanding += loanDue;
              if (isHiddenInAccounts) {
                hiddenLoanOutstanding += loanDue;
              } else {
                visibleLoanOutstanding += loanDue;
              }
            } else if (acc.type != 'Credit Cards' && acc.type != 'Loan') {
              totalBankBalance += acc.balance;
              if (isHiddenInAccounts) {
                hiddenBankBalance += acc.balance;
              } else {
                visibleBankBalance += acc.balance;
              }
            }
          }

          final bool hasHiddenInAccounts = hiddenCount > 0;

          double customTotal = 0.0;
          for (var acc in accounts) {
            if (selectedIds.contains(acc.id) && !acc.isClosed) {
              if (acc.type == 'Loan') {
                final rawLoanDue = ref.watch(loanTotalOutstandingProvider(acc));
                final loanDue = rawLoanDue > 0 ? rawLoanDue : 0.0;
                customTotal -= loanDue;
              } else if (acc.type == 'Credit Cards') {
                customTotal += ref
                    .watch(creditCardMetricsProvider(acc))
                    .totalOutstanding;
              } else {
                customTotal += acc.balance;
              }
            }
          }

          if (accounts.isEmpty) {
            return const PremiumEmptyState(
              title: 'No Accounts Found',
              subtitle:
                  'Add your account details to unlock insights and populate your dashboard.',
              icon: Icons.account_balance_wallet_rounded,
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (isSelectionMode)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySelectionHeaderDelegate(
                    customTotal: customTotal,
                    selectedCount: selectedIds.length,
                    theme: theme,
                  ),
                ),
              SliverToBoxAdapter(
                child: GlobalSummaryCard(
                  assets: visibleBankBalance,
                  liabilities: visibleCreditBalance, // Naturally negative if owed
                  loans: -visibleLoanOutstanding, // Forced negative for calculation
                  hiddenAssets: hiddenBankBalance,
                  hiddenLiabilities: hiddenCreditBalance,
                  hiddenLoans: -hiddenLoanOutstanding,
                  totalAssets: totalBankBalance,
                  totalLiabilities: totalCreditBalance,
                  totalLoans: -totalLoanOutstanding,
                  hasHidden: hasHiddenInAccounts,
                  hiddenCount: hiddenCount,
                ),
              ),
              if (bankAccounts.isNotEmpty) ...[
                _buildSectionHeader(context, 'ACCOUNTS', totalBankBalance),
                _buildList(
                  context,
                  ref,
                  bankAccounts,
                  isSelectionMode,
                  selectedIds,
                ),
              ],
              if (creditCards.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'CREDIT CARDS',
                  totalCreditBalance,
                ),
                _buildList(
                  context,
                  ref,
                  creditCards,
                  isSelectionMode,
                  selectedIds,
                ),
              ],
              if (activeLoans.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'ACTIVE LOANS',
                  -totalLoanOutstanding,
                ),
                _buildList(
                  context,
                  ref,
                  activeLoans,
                  isSelectionMode,
                  selectedIds,
                  isLoan: true,
                ),
              ],
              if (archivedAccounts.isNotEmpty) ...[
                _buildArchivedSectionHeader(
                  context,
                  ref,
                  archivedAccounts.length,
                  isArchivedExpanded,
                ),
                if (isArchivedExpanded)
                  _buildList(
                    context,
                    ref,
                    archivedAccounts,
                    isSelectionMode,
                    selectedIds,
                    isSettled: true,
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArchivedSectionHeader(
    BuildContext context,
    WidgetRef ref,
    int count,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spacingLg,
          DesignTokens.spacingLg,
          DesignTokens.spacingLg,
          DesignTokens.spacingSm,
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(archivedAccountsExpandedProvider.notifier).state =
                !isExpanded;
          },
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                isDark ? 0.3 : 0.45,
              ),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.35),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'ARCHIVED ACCOUNTS',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  isExpanded ? 'Hide' : 'Show',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, double total) {
    final theme = Theme.of(context);
    final signText = total < 0 ? '- ₹ ' : (total > 0 ? '+ ₹ ' : '₹ ');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spacingLg,
          DesignTokens.spacingLg,
          DesignTokens.spacingLg,
          DesignTokens.spacingSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: CurrencyText(
                amount: total.abs(),
                sign: signText,
                amountStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.5,
                ),
                symbolStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Account> items,
    bool isSelectionMode,
    Set<String> selectedIds, {
    bool isLoan = false,
    bool isSettled = false,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
      sliver: SliverReorderableList(
        itemCount: items.length,
        onReorder: (int oldIndex, int newIndex) {
          if (isSelectionMode || isSettled) return;
          if (oldIndex < newIndex) newIndex -= 1;
          final mutableList = List<Account>.from(items);
          final item = mutableList.removeAt(oldIndex);
          mutableList.insert(newIndex, item);
          ref.read(accountActionProvider.notifier).reorderAccounts(mutableList);
        },
        itemBuilder: (context, index) {
          final acc = items[index];
          final isSelected = selectedIds.contains(acc.id);

          void handleTapAction() {
            if (isSelectionMode && !isSettled) {
              HapticFeedback.selectionClick();
              final currentIds = ref.read(selectedAccountsProvider);
              final newIds = Set<String>.from(currentIds);
              if (isSelected) {
                newIds.remove(acc.id);
              } else {
                newIds.add(acc.id);
              }
              ref.read(selectedAccountsProvider.notifier).state = newIds;
            } else if (!isSelectionMode) {
              if (acc.type == 'Loan') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoanTransactionPage(account: acc),
                  ),
                );
              } else if (acc.type == 'Credit Cards') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreditTransactionPage(account: acc),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountTransactionsPage(account: acc),
                  ),
                );
              }
            }
          }

          Widget cardChild = BoxySlidableCard(
            customBorderRadius: BorderRadius.circular(8.0),
            customBackgroundColor: Colors.transparent,
            onEdit: (isSelectionMode || isSettled)
                ? null
                : () => _openForm(context, existingAccount: acc),
            onVisibility: (isSelectionMode || isSettled)
                ? null
                : () => AccountBalanceVisibilitySheet.show(context, acc),
            onArchive: (isSelectionMode || isSettled)
                ? null
                : () {
                    final bool isAccountLoan = acc.type == 'Loan';
                    ConfirmationBottomSheet.show(
                      context,
                      title: isAccountLoan
                          ? 'Settle & Archive Loan?'
                          : 'Archive Account?',
                      description: isAccountLoan
                          ? 'This will mark ${acc.name} as settled and archived. It will be removed from your dashboard and fresh transactions, but all historical records and analytics will be preserved. Proceed?'
                          : 'Are you sure you want to archive ${acc.name}? It will be hidden from new transactions, but all historical records and analytics will be preserved.',
                      confirmText:
                          isAccountLoan ? 'SETTLE & ARCHIVE' : 'ARCHIVE',
                      onConfirm: () => ref
                          .read(accountActionProvider.notifier)
                          .toggleArchiveAccount(acc.id, true),
                    );
                  },
            onUnarchive: (isSelectionMode || !isSettled)
                ? null
                : () {
                    ConfirmationBottomSheet.show(
                      context,
                      title: 'Unarchive Account?',
                      description:
                          'Restore ${acc.name} to active accounts? It will be available for fresh transactions again.',
                      confirmText: 'UNARCHIVE',
                      onConfirm: () => ref
                          .read(accountActionProvider.notifier)
                          .toggleArchiveAccount(acc.id, false),
                    );
                  },
            onDelete: isSelectionMode
                ? null
                : () {
                    ConfirmationBottomSheet.show(
                      context,
                      title: 'Delete Account?',
                      description:
                          'Are you sure you want to remove ${acc.name}?',
                      confirmText: 'DELETE',
                      isDestructive: true,
                      onConfirm: () => ref
                          .read(accountActionProvider.notifier)
                          .deleteAccount(acc.id),
                    );
                  },
            child: Stack(
              children: [
                PremiumAccountCard(account: acc, onCardTap: handleTapAction),
                if (isSelectionMode && !isSettled)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: isSelected
                              ? Colors.transparent
                              : Theme.of(
                                  context,
                                ).scaffoldBackgroundColor.withOpacity(0.65),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 3.0,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
          );

          if (!isSelectionMode && !isSettled) {
            return ReorderableDelayedDragStartListener(
              key: ValueKey(acc.id),
              index: index,
              child: cardChild,
            );
          } else {
            return KeyedSubtree(key: ValueKey(acc.id), child: cardChild);
          }
        },
      ),
    );
  }
}

class _StickySelectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double customTotal;
  final int selectedCount;
  final ThemeData theme;

  _StickySelectionHeaderDelegate({
    required this.customTotal,
    required this.selectedCount,
    required this.theme,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final customSign = customTotal < 0
        ? '- ₹ '
        : (customTotal > 0 ? '+ ₹ ' : '₹ ');

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: theme.scaffoldBackgroundColor.withOpacity(
            overlapsContent || isDark ? 0.85 : 0.95,
          ),
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spacingLg,
            DesignTokens.spacingMd,
            DesignTokens.spacingLg,
            DesignTokens.spacingSm,
          ),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(
                isDark ? 0.2 : 0.6,
              ),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$selectedCount SELECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: CurrencyText(
                    amount: customTotal.abs(),
                    sign: customSign,
                    amountStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: -1.0,
                    ),
                    symbolStyle: TextStyle(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 90.0;

  @override
  double get minExtent => 90.0;

  @override
  bool shouldRebuild(covariant _StickySelectionHeaderDelegate oldDelegate) {
    return customTotal != oldDelegate.customTotal ||
        selectedCount != oldDelegate.selectedCount;
  }
}
