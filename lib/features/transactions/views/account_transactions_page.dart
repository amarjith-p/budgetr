import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/transaction_provider.dart';
import '../components/transaction_card.dart';
import 'transaction_form_page.dart';

class AccountTransactionsPage extends ConsumerWidget {
  final Account account;

  const AccountTransactionsPage({Key? key, required this.account}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(accountTransactionsProvider(account.id));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      appBar: ModernAppBar(
        title: account.providerName.toUpperCase(),
        subtitle: account.name.toUpperCase(),
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      // --- NEW: Contextual FAB with Pre-selection ---
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionFormPage(preSelectedAccountId: account.id),
            ),
          );
        },
        icon: Icons.add_rounded,
        label: 'Log',
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Text(
                'No transactions logged yet.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
              )
            );
          }

          // --- NEW: Grouping Logic by Month & Year ---
          final groupedTransactions = <String, List<dynamic>>{};
          const fullMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

          for (var txData in transactions) {
            final tx = txData.transaction;
            final groupKey = '${fullMonths[tx.date.month - 1]} ${tx.date.year}';
            groupedTransactions.putIfAbsent(groupKey, () => []).add(txData);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spacingMd)),
              
              // Map through the groups and build a Sticky Header section for each
              ...groupedTransactions.entries.map((entry) {
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true, // Makes the header sticky
                      delegate: _StickyMonthHeaderDelegate(
                        title: entry.key,
                        theme: theme,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return TransactionCard(
                              data: entry.value[index],
                              currentAccountId: account.id,
                            );
                          },
                          childCount: entry.value.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spacingMd)),
                  ],
                );
              }).toList(),
              
              // Padding for the FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// --- NEW: Sticky Header Delegate with iOS Frosted Glass Effect ---
class _StickyMonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final ThemeData theme;

  _StickyMonthHeaderDelegate({required this.title, required this.theme});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          // Uses scaffold background color with opacity to create a native frosted glass look
          color: theme.scaffoldBackgroundColor.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 40.0;

  @override
  double get minExtent => 40.0;

  @override
  bool shouldRebuild(covariant _StickyMonthHeaderDelegate oldDelegate) => title != oldDelegate.title;
}