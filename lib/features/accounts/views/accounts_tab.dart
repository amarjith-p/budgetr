// features/accounts/views/accounts_tab.dart
import 'dart:ui';
import 'package:budgetr/core/components/currency_text.dart';
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

final selectionModeProvider = StateProvider.autoDispose<bool>((ref) => false);
final selectedAccountsProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => <String>{},
);

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (accounts) {
          final creditCards = accounts
              .where((a) => a.type == 'Credit Cards')
              .toList();
          final bankAccounts = accounts
              .where((a) => a.type != 'Credit Cards' && a.type != 'Loan')
              .toList();
          final activeLoans = accounts
              .where((a) => a.type == 'Loan' && !a.isClosed)
              .toList();
          final settledLoans = accounts
              .where((a) => a.type == 'Loan' && a.isClosed)
              .toList();

          final totalBankBalance = bankAccounts.fold(
            0.0,
            (sum, acc) => sum + acc.balance,
          );

          double totalCreditBalance = 0.0;
          for (var card in creditCards) {
            totalCreditBalance += ref
                .watch(creditCardMetricsProvider(card))
                .totalOutstanding;
          }

          double totalLoanOutstanding = 0.0;
          for (var loan in activeLoans) {
            totalLoanOutstanding += ref.watch(
              loanTotalOutstandingProvider(loan),
            );
          }

          double customTotal = 0.0;
          for (var acc in accounts) {
            if (selectedIds.contains(acc.id) && !acc.isClosed) {
              if (acc.type == 'Loan') {
                customTotal -= ref.watch(loanTotalOutstandingProvider(acc));
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
                  assets: totalBankBalance, // Passes as positive
                  liabilities: totalCreditBalance, // Naturally negative if owed
                  loans:
                      -totalLoanOutstanding, // --- FIXED: FORCED NEGATIVE SO IT DEDUCTS CORRECTLY ---
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
              if (settledLoans.isNotEmpty) ...[
                _buildSectionHeader(context, 'SETTLED LOANS', 0.0),
                _buildList(
                  context,
                  ref,
                  settledLoans,
                  isSelectionMode,
                  selectedIds,
                  isLoan: true,
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

  Widget _buildSectionHeader(BuildContext context, String title, double total) {
    final theme = Theme.of(context);
    // --- FIXED: RESTORED THE RUPEE SYMBOLS ---
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
              if (isLoan) {
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
            customBorderRadius: BorderRadius.circular(16.0),
            customBackgroundColor: Colors.transparent,
            onEdit: (isSelectionMode || isSettled)
                ? null
                : () => _openForm(context, existingAccount: acc),
            onSettle: (isSelectionMode || !isLoan || isSettled)
                ? null
                : () {
                    ConfirmationBottomSheet.show(
                      context,
                      title: 'Settle Loan?',
                      description:
                          'This will permanently mark the loan as settled, remove it from your dashboard, and lock it to read-only mode. Proceed?',
                      confirmText: 'SETTLE',
                      onConfirm: () => ref
                          .read(accountActionProvider.notifier)
                          .settleLoan(acc.id),
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
                          borderRadius: BorderRadius.circular(16.0),
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
    // --- FIXED: RESTORED THE RUPEE SYMBOLS ---
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
              borderRadius: BorderRadius.circular(16.0),
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
