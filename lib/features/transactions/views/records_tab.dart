// lib/features/transactions/views/records_tab.dart
import 'dart:ui';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:budgetr/core/components/premium_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../providers/transaction_provider.dart';
import '../providers/transaction_filter_provider.dart';
import '../components/transaction_card.dart';
import '../components/active_filter_banner.dart';
import '../../accounts/providers/account_provider.dart';

// --- NEW SEARCH & SUMMARY COMPONENTS ---
import '../components/records_search_bar.dart';
import '../components/records_smart_summary_card.dart';

class RecordsTab extends ConsumerStatefulWidget {
  const RecordsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends ConsumerState<RecordsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final filterState = ref.watch(transactionFilterProvider('GLOBAL'));
    final accountsAsync = ref.watch(accountsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: transactionsAsync.when(
        loading: () => const Center(
          child: FuturisticLoader(size: 80, label: "LOADING TRANSACTIONS.."),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          // --- HIDE THE INTERNAL TRANSFER LEG FROM RECORDS UI ---
          final validTransactions = transactions
              .where(
                (txData) => !txData.transaction.id.endsWith('_SOURCETRANSFER'),
              )
              .toList();

          if (validTransactions.isEmpty) {
            return const PremiumEmptyState(
              title: 'No Transactions Found',
              subtitle:
                  'Add your first transaction to unlock insights and populate your records.',
              icon: Icons.currency_rupee_rounded,
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

          // 1. APPLY BASE FILTERS
          final filteredRecords = TransactionFilterHelper.applyForRecords(
            validTransactions,
            filterState,
          );

          // 2. APPLY TEXT SEARCH
          final q = _searchQuery.trim().toLowerCase();
          final searchedRecords = filteredRecords.where((record) {
            if (q.isEmpty) return true;
            final tx = record.data.transaction;

            final catName =
                (tx.categoryName ??
                        record.data.category?.name ??
                        'Uncategorized')
                    .toLowerCase();
            final subCatName = (tx.subCategory ?? '').toLowerCase();
            final accName = record.data.account.name.toLowerCase();

            // --- NEW: Added provider name (e.g. HDFC, SBI) to search ---
            final accProvider = record.data.account.providerName.toLowerCase();

            final notes = (tx.notes ?? '').toLowerCase();
            final locationName = (tx.locationName ?? '').toLowerCase();

            // --- NEW: Added bucket name to search ---
            final bucketName = (tx.bucketName ?? record.data.bucket?.name ?? '')
                .toLowerCase();

            final amountStr = tx.amount.toString();

            return catName.contains(q) ||
                subCatName.contains(q) ||
                accName.contains(q) ||
                accProvider.contains(q) ||
                notes.contains(q) ||
                locationName.contains(q) ||
                bucketName.contains(q) ||
                amountStr.contains(q);
          }).toList();

          // 3. GROUP RESULTS
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

          for (var record in searchedRecords) {
            final tx = record.data.transaction;
            final groupKey = '${fullMonths[tx.date.month - 1]} ${tx.date.year}';
            groupedRecords.putIfAbsent(groupKey, () => []).add(record);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- SEARCH BAR ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacingMd,
                    DesignTokens.spacingMd,
                    DesignTokens.spacingMd,
                    0,
                  ),
                  child: RecordsSearchBar(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ),

              // --- SMART SUMMARY CARD ---
              if (filterState.isActive || _searchQuery.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spacingMd,
                      DesignTokens.spacingMd,
                      DesignTokens.spacingMd,
                      0,
                    ),
                    child: RecordsSmartSummaryCard(
                      searchedRecords: searchedRecords,
                    ),
                  ),
                ),

              // --- ACTIVE FILTER BANNER ---
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

              if (searchedRecords.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No results match your search or filters.',
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
