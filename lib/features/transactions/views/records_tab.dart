import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/transaction_provider.dart';
import '../providers/transaction_filter_provider.dart';
import '../components/transaction_card.dart';

class RecordsTab extends ConsumerWidget {
  const RecordsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final filterState = ref.watch(transactionFilterProvider('GLOBAL'));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Text('No transactions logged yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold))
            );
          }

          final filteredRecords = TransactionFilterHelper.applyForRecords(transactions, filterState);

          if (filteredRecords.isEmpty) {
            return Center(
              child: Text('No results match your filters.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold))
            );
          }

          final groupedRecords = <String, List<RecordItem>>{};
          const fullMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

          for (var record in filteredRecords) {
            final tx = record.data.transaction;
            final groupKey = '${fullMonths[tx.date.month - 1]} ${tx.date.year}';
            groupedRecords.putIfAbsent(groupKey, () => []).add(record);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spacingMd)),
              
              ...groupedRecords.entries.map((entry) {
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true, 
                      delegate: _StickyGlobalMonthHeaderDelegate(title: entry.key, theme: theme),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final record = entry.value[index];
                            return TransactionCard(
                              data: record.data, 
                              currentAccountId: record.perspectiveAccountId,
                              isGlobalView: true,
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
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _StickyGlobalMonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final ThemeData theme;

  _StickyGlobalMonthHeaderDelegate({required this.title, required this.theme});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: theme.scaffoldBackgroundColor.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: theme.colorScheme.primary),
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
  bool shouldRebuild(covariant _StickyGlobalMonthHeaderDelegate oldDelegate) => title != oldDelegate.title;
}