import 'package:budgetr/core/components/currency_text.dart';
import 'package:budgetr/features/transactions/views/account_transactions_page.dart';
import 'package:budgetr/features/transactions/views/credit_transaction_page.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/account_provider.dart';
import '../components/premium_account_card.dart';
import '../components/account_form_bottom_sheet.dart';
import '../../../core/database/app_database.dart'; // Needed for the Account type

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

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (accounts) {
          final creditCards = accounts.where((a) => a.type == 'Credit Cards').toList();
          final bankAccounts = accounts.where((a) => a.type != 'Credit Cards').toList();

          // --- FIX: Restored native database sum calculations ---
          final totalBankBalance = bankAccounts.fold(0.0, (sum, acc) => sum + acc.balance);
          final totalCreditBalance = creditCards.fold(0.0, (sum, acc) => sum + acc.balance);

          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts added yet.'));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (bankAccounts.isNotEmpty) ...[
                _buildSectionHeader(context, 'BANK ACCOUNTS & WALLETS', totalBankBalance),
                _buildList(context, ref, bankAccounts),
              ],
              if (creditCards.isNotEmpty) ...[
                _buildSectionHeader(context, 'CREDIT CARDS', totalCreditBalance),
                _buildList(context, ref, creditCards),
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
    
    // Globally standardized sign
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

  Widget _buildList(BuildContext context, WidgetRef ref, List<Account> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
      // --- FIX: Drag-and-drop Reorderable List ---
      sliver: SliverReorderableList(
        itemCount: items.length,
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1; 
          }
          final mutableList = List<Account>.from(items);
          final item = mutableList.removeAt(oldIndex);
          mutableList.insert(newIndex, item);
          
          ref.read(accountActionProvider.notifier).reorderAccounts(mutableList);
        },
        itemBuilder: (context, index) {
          final acc = items[index];
          
          return ReorderableDelayedDragStartListener(
            key: ValueKey(acc.id),
            index: index,
            child: BoxySlidableCard(
              customBorderRadius: BorderRadius.circular(16.0), 
              customBackgroundColor: Colors.transparent, 
              onEdit: () => _openForm(context, existingAccount: acc),
              onDelete: () {
                ConfirmationBottomSheet.show(
                  context,
                  title: 'Delete Account?',
                  description: 'Are you sure you want to remove ${acc.name}?',
                  confirmText: 'DELETE',
                  isDestructive: true,
                  onConfirm: () => ref.read(accountActionProvider.notifier).deleteAccount(acc.id),
                );
              },
              child: PremiumAccountCard(
                account: acc,
                onCardTap: () {
                  if (acc.type == 'Credit Cards') {
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
                },
              ),
            ),
          );
        },
      ),
    );
  }
}