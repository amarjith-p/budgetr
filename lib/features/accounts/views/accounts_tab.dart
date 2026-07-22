import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../providers/account_provider.dart';
import '../components/premium_account_card.dart';
import '../components/account_form_bottom_sheet.dart';

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
      backgroundColor: Colors.transparent, // Let the base page background show
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (accounts) {
          final creditCards = accounts.where((a) => a.type == 'Credit Cards').toList();
          final bankAccounts = accounts.where((a) => a.type != 'Credit Cards').toList();

          // Calculate totals dynamically
          final totalBankBalance = bankAccounts.fold(0.0, (sum, acc) => sum + acc.balance);
          final totalCreditBalance = creditCards.fold(0.0, (sum, acc) => sum + acc.balance);

          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts added yet.'));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (bankAccounts.isNotEmpty) ...[
                _buildSectionHeader(context, 'BANK ACCOUNTS & WALLETS', totalBankBalance, false),
                _buildList(context, ref, bankAccounts),
              ],
              if (creditCards.isNotEmpty) ...[
                _buildSectionHeader(context, 'CREDIT CARDS', totalCreditBalance, true),
                _buildList(context, ref, creditCards),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Breathing room for FAB
            ],
          );
        },
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () => _openForm(context),
        icon: Icons.add_card_rounded,
        label: 'Account',
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, double total, bool isCreditCard) {
    final theme = Theme.of(context);
    
    // Formatting logic consistent with the Premium Account Card
    final signText = isCreditCard && total > 0 ? '-₹' : '₹';
    final amountText = isCreditCard && total <= 0 ? '0.00' : total.toStringAsFixed(2);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingSm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left Side: Section Title
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
            // Right Side: Section Total
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: signText, 
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8), 
                      fontWeight: FontWeight.w600, 
                      fontSize: 11,
                    ),
                  ),
                  TextSpan(
                    text: amountText, 
                    style: TextStyle(
                      color: theme.colorScheme.onSurface, 
                      fontWeight: FontWeight.w800, 
                      fontSize: 14, 
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<dynamic> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final acc = items[index];
            return BoxySlidableCard(
              key: ValueKey(acc.id),
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
              child: PremiumAccountCard(account: acc),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}