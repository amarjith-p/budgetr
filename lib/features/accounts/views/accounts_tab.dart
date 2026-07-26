import 'dart:ui';
import 'package:budgetr/core/components/currency_text.dart';
import 'package:budgetr/features/transactions/views/account_transactions_page.dart';
import 'package:budgetr/features/transactions/views/credit_transaction_page.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/account_provider.dart';
import '../components/premium_account_card.dart';
import '../components/account_form_bottom_sheet.dart';
import '../../../core/database/app_database.dart'; 

// Local State Providers exposed to Base Page
final selectionModeProvider = StateProvider.autoDispose<bool>((ref) => false);
final selectedAccountsProvider = StateProvider.autoDispose<Set<String>>((ref) => <String>{});

class AccountsTab extends ConsumerWidget {
  const AccountsTab({Key? key}) : super(key: key);

  void _openForm(BuildContext context, {var existingAccount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => AccountFormBottomSheet(existingAccount: existingAccount),
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
          final creditCards = accounts.where((a) => a.type == 'Credit Cards').toList();
          final bankAccounts = accounts.where((a) => a.type != 'Credit Cards').toList();

          final totalBankBalance = bankAccounts.fold(0.0, (sum, acc) => sum + acc.balance);
          final totalCreditBalance = creditCards.fold(0.0, (sum, acc) => sum + acc.balance);

          double customTotal = 0.0;
          for (var acc in accounts) {
            if (selectedIds.contains(acc.id)) customTotal += acc.balance; 
          }

          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts added yet.'));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              
              // --- FIX: Premium Sticky Header ---
              if (isSelectionMode)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySelectionHeaderDelegate(
                    customTotal: customTotal,
                    selectedCount: selectedIds.length,
                    theme: theme,
                  ),
                ),

              if (bankAccounts.isNotEmpty) ...[
                _buildSectionHeader(context, 'BANK ACCOUNTS & WALLETS', totalBankBalance),
                _buildList(context, ref, bankAccounts, isSelectionMode, selectedIds),
              ],
              if (creditCards.isNotEmpty) ...[
                _buildSectionHeader(context, 'CREDIT CARDS', totalCreditBalance),
                _buildList(context, ref, creditCards, isSelectionMode, selectedIds),
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
    final signText = total < 0 ? '-₹' : (total > 0 ? '+₹' : '₹');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingSm),
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
            CurrencyText(
              amount: total,
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
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Account> items, bool isSelectionMode, Set<String> selectedIds) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
      sliver: SliverReorderableList(
        itemCount: items.length,
        onReorder: (int oldIndex, int newIndex) {
          if (isSelectionMode) return; 
          
          if (oldIndex < newIndex) newIndex -= 1; 
          final mutableList = List<Account>.from(items);
          final item = mutableList.removeAt(oldIndex);
          mutableList.insert(newIndex, item);
          
          ref.read(accountActionProvider.notifier).reorderAccounts(mutableList);
        },
        itemBuilder: (context, index) {
          final acc = items[index];
          final isSelected = selectedIds.contains(acc.id);
          
          Widget cardChild = BoxySlidableCard(
            customBorderRadius: BorderRadius.circular(16.0), 
            customBackgroundColor: Colors.transparent, 
            onEdit: isSelectionMode ? null : () => _openForm(context, existingAccount: acc),
            onDelete: isSelectionMode ? null : () {
              ConfirmationBottomSheet.show(
                context,
                title: 'Delete Account?',
                description: 'Are you sure you want to remove ${acc.name}?',
                confirmText: 'DELETE',
                isDestructive: true,
                onConfirm: () => ref.read(accountActionProvider.notifier).deleteAccount(acc.id),
              );
            },
            child: Stack(
              children: [
                PremiumAccountCard(
                  account: acc,
                  onCardTap: () {
                    if (isSelectionMode) {
                      HapticFeedback.selectionClick();
                      final currentIds = ref.read(selectedAccountsProvider);
                      final newIds = Set<String>.from(currentIds);
                      if (isSelected) {
                        newIds.remove(acc.id);
                      } else {
                        newIds.add(acc.id);
                      }
                      ref.read(selectedAccountsProvider.notifier).state = newIds;
                    } else {
                      if (acc.type == 'Credit Cards') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreditTransactionPage(account: acc)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AccountTransactionsPage(account: acc)));
                      }
                    }
                  },
                ),
                
                if (isSelectionMode)
                  Positioned.fill(
                    child: IgnorePointer( 
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          color: isSelected ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.65),
                          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3.0) : null,
                        ),
                        child: isSelected 
                          ? Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                  ),
                                  child: Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 18),
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

          if (!isSelectionMode) {
            return ReorderableDelayedDragStartListener(key: ValueKey(acc.id), index: index, child: cardChild);
          } else {
            return KeyedSubtree(key: ValueKey(acc.id), child: cardChild);
          }
        },
      ),
    );
  }
}

// --- NEW: Sticky Header Delegate ---
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = theme.brightness == Brightness.dark;
    final customSign = customTotal < 0 ? '-₹' : (customTotal > 0 ? '+₹' : '₹');

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          // Fades to a frosted glass background when scrolling
          color: theme.scaffoldBackgroundColor.withOpacity(overlapsContent || isDark ? 0.85 : 0.95),
          padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingMd, DesignTokens.spacingLg, DesignTokens.spacingSm),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.2 : 0.6),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$selectedCount SELECTED', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1.5)
                ),
                CurrencyText(
                  amount: customTotal,
                  sign: customSign,
                  amountStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: -1.0),
                  symbolStyle: TextStyle(color: theme.colorScheme.primary.withOpacity(0.8)),
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
    return customTotal != oldDelegate.customTotal || selectedCount != oldDelegate.selectedCount;
  }
}