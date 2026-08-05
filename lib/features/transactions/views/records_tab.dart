import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/transaction_provider.dart';
import '../providers/transaction_filter_provider.dart';
import '../components/transaction_card.dart';
import '../components/active_filter_banner.dart';
import '../../accounts/providers/account_provider.dart';

class RecordsTab extends ConsumerWidget {
  const RecordsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final filterState = ref.watch(transactionFilterProvider('GLOBAL'));
    final accountsAsync = ref.watch(accountsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          // --- HIDE THE INTERNAL TRANSFER LEG FROM RECORDS UI ---
          final validTransactions = transactions
              .where(
                (txData) => !txData.transaction.id.endsWith('_SOURCETRANSFER'),
              )
              .toList();

          if (validTransactions.isEmpty) {
            return Center(
              child: Text(
                'No transactions logged yet.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final rawAccounts = accountsAsync.asData?.value ?? [];
          double currentGlobalBalance = rawAccounts
              .where((a) => a.type != 'Loan')
              .fold(0.0, (sum, acc) => sum + acc.balance);

          final globalClosingBalances = <String, double>{};
          double totalGlobalImpact = 0;

          bool isLoanAccount(String? id) {
            if (id == null) return false;
            return rawAccounts.any((a) => a.id == id && a.type == 'Loan');
          }

          for (var txData in validTransactions) {
            final t = txData.transaction;
            bool isLoanFee =
                t.subCategory == 'Loan Interest' ||
                t.subCategory == 'Tax on Interest' ||
                t.subCategory == 'Bank Charges on Loan';

            if (t.type == 'Income') {
              totalGlobalImpact += t.amount;
            } else if (t.type == 'Expense' && !isLoanFee) {
              totalGlobalImpact -= t.amount;
            } else if (t.type == 'Transfer') {
              if (t.toAccountId == 'EXTERNAL_IN') {
                totalGlobalImpact += t.amount;
              } else if (t.toAccountId == 'EXTERNAL_OUT') {
                totalGlobalImpact -= t.amount;
              } else if (isLoanAccount(t.toAccountId)) {
                totalGlobalImpact -= t.amount;
              }
            }
          }

          double runningBal = currentGlobalBalance - totalGlobalImpact;

          for (var txData in validTransactions.reversed) {
            final t = txData.transaction;
            bool isLoanFee =
                t.subCategory == 'Loan Interest' ||
                t.subCategory == 'Tax on Interest' ||
                t.subCategory == 'Bank Charges on Loan';

            if (t.type == 'Income') {
              runningBal += t.amount;
            } else if (t.type == 'Expense' && !isLoanFee) {
              runningBal -= t.amount;
            } else if (t.type == 'Transfer') {
              if (t.toAccountId == 'EXTERNAL_IN') {
                runningBal += t.amount;
              } else if (t.toAccountId == 'EXTERNAL_OUT') {
                runningBal -= t.amount;
              } else if (isLoanAccount(t.toAccountId)) {
                runningBal -= t.amount;
              }
            }
            globalClosingBalances[t.id] = runningBal;
          }

          final filteredRecords = TransactionFilterHelper.applyForRecords(
            validTransactions,
            filterState,
          );

          final groupedRecords = <String, List<RecordItem>>{};
          const fullMonths = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];

          for (var record in filteredRecords) {
            final tx = record.data.transaction;
            final groupKey = '${fullMonths[tx.date.month - 1]} ${tx.date.year}';
            groupedRecords.putIfAbsent(groupKey, () => []).add(record);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (filterState.isActive)
                SliverToBoxAdapter(
                  child: ActiveFilterBanner(
                    filterState: filterState,
                    onClear: () =>
                        ref
                                .read(
                                  transactionFilterProvider('GLOBAL').notifier,
                                )
                                .state =
                            const TransactionFilterState(),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: DesignTokens.spacingMd),
              ),

              if (filteredRecords.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No results match your filters.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                ...groupedRecords.entries.map((entry) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyGlobalMonthHeaderDelegate(
                          title: entry.key,
                          theme: theme,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingMd,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final record = entry.value[index];
                            return TransactionCard(
                              data: record.data,
                              currentAccountId: record.perspectiveAccountId,
                              isGlobalView: true,
                              closingBalance:
                                  globalClosingBalances[record
                                      .data
                                      .transaction
                                      .id],
                            );
                          }, childCount: entry.value.length),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: DesignTokens.spacingMd),
                      ),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
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
  bool shouldRebuild(covariant _StickyGlobalMonthHeaderDelegate oldDelegate) =>
      title != oldDelegate.title;
}
