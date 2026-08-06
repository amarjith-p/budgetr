import 'dart:ui';
import 'package:budgetr/core/components/currency_text.dart';
import 'package:budgetr/features/transactions/components/active_filter_banner.dart';
import 'package:budgetr/features/transactions/components/transaction_filter_bottom_sheet.dart';
import 'package:budgetr/features/transactions/providers/transaction_filter_provider.dart';
import 'package:budgetr/features/transactions/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/date_time_constants.dart';
import '../providers/transaction_provider.dart';
import '../components/transaction_card.dart';
import 'transaction_form_page.dart';
import '../../accounts/providers/account_provider.dart';

extension CreditAccountExtensions on Account {
  int get safeBillingDay => billDate ?? 15;
  int get safeDueDay => dueDate ?? 5;

  DateTime getEffectiveDate(TransactionRecord tx) {
    if (tx.isSpillover) {
      final bDay = safeBillingDay;
      DateTime nextBillDate = DateTime(
        tx.date.year,
        tx.date.month,
        bDay,
        23,
        59,
        59,
      );
      if (tx.date.day > bDay) {
        nextBillDate = DateTime(
          tx.date.year,
          tx.date.month + 1,
          bDay,
          23,
          59,
          59,
        );
      }
      return nextBillDate.add(const Duration(days: 1));
    }
    return tx.date;
  }
}

class BillingCycle {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime dueDate;
  final List<TransactionWithDetails> transactions;

  BillingCycle({
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    required this.transactions,
  });

  String get title {
    return '${endDate.day.toString().padLeft(2, '0')} ${DateTimeConstants.shortMonths[endDate.month - 1]} ${endDate.year}';
  }
}

class CreditTransactionPage extends ConsumerWidget {
  final Account account;
  const CreditTransactionPage({Key? key, required this.account})
    : super(key: key);

  List<BillingCycle> _groupIntoCycles(
    List<TransactionWithDetails> transactions,
    Account liveAccount,
  ) {
    if (transactions.isEmpty) return [];
    final bDay = liveAccount.safeBillingDay;
    final dDay = liveAccount.safeDueDay;
    List<BillingCycle> cycles = [];

    DateTime oldest = transactions.last.transaction.date;
    DateTime newest = transactions.first.transaction.date;
    DateTime now = DateTime.now();
    if (now.isAfter(newest)) newest = now;

    DateTime currentEnd = DateTime(newest.year, newest.month, bDay, 23, 59, 59);
    if (newest.day > bDay) {
      currentEnd = DateTime(newest.year, newest.month + 1, bDay, 23, 59, 59);
    }
    DateTime pointerEnd = currentEnd;

    while (pointerEnd.isAfter(oldest) || pointerEnd.isAtSameMomentAs(oldest)) {
      DateTime pointerStart = DateTime(
        pointerEnd.year,
        pointerEnd.month - 1,
        bDay + 1,
        0,
        0,
        0,
      );
      DateTime pointerDue;
      if (dDay > bDay) {
        pointerDue = DateTime(
          pointerEnd.year,
          pointerEnd.month,
          dDay,
          23,
          59,
          59,
        );
      } else {
        pointerDue = DateTime(
          pointerEnd.year,
          pointerEnd.month + 1,
          dDay,
          23,
          59,
          59,
        );
      }
      final cycleTxs = transactions.where((t) {
        final effectiveDate = liveAccount.getEffectiveDate(t.transaction);
        return (effectiveDate.isAfter(pointerStart) ||
                effectiveDate.isAtSameMomentAs(pointerStart)) &&
            (effectiveDate.isBefore(pointerEnd) ||
                effectiveDate.isAtSameMomentAs(pointerEnd));
      }).toList();
      cycles.add(
        BillingCycle(
          startDate: pointerStart,
          endDate: pointerEnd,
          dueDate: pointerDue,
          transactions: cycleTxs,
        ),
      );
      pointerEnd = DateTime(
        pointerEnd.year,
        pointerEnd.month - 1,
        bDay,
        23,
        59,
        59,
      );
    }

    for (int i = 0; i < cycles.length - 1; i++) {
      final currentCycle = cycles[i];
      final previousCycle = cycles[i + 1];
      final paymentsToMove = currentCycle.transactions.where((tx) {
        final t = tx.transaction;
        bool isIncoming =
            t.type == 'Income' ||
            (t.type == 'Transfer' && t.toAccountId == liveAccount.id);
        bool isRepaymentCat = tx.category?.name == 'Repayment';
        bool isBeforeDue = t.date.isBefore(
          previousCycle.dueDate.add(const Duration(days: 1)),
        );
        return isIncoming && isRepaymentCat && isBeforeDue;
      }).toList();
      if (paymentsToMove.isNotEmpty) {
        currentCycle.transactions.removeWhere(
          (tx) => paymentsToMove.contains(tx),
        );
        previousCycle.transactions.insertAll(0, paymentsToMove);
        previousCycle.transactions.sort(
          (a, b) => b.transaction.date.compareTo(a.transaction.date),
        );
      }
    }
    return cycles;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      accountTransactionsProvider(account.id),
    );
    final filterState = ref.watch(transactionFilterProvider(account.id));
    final accountsAsync = ref.watch(accountsStreamProvider);
    final liveAccount =
        accountsAsync.asData?.value
            .where((a) => a.id == account.id)
            .firstOrNull ??
        account;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: liveAccount.providerName.toUpperCase(),
        subtitle: liveAccount.name.toUpperCase(),
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
        trailingIcon: filterState.isActive
            ? Icons.filter_alt_rounded
            : Icons.filter_alt_outlined,
        onTrailingPressed: () {
          final txList = transactionsAsync.asData?.value ?? [];
          TransactionFilterBottomSheet.show(context, liveAccount.id, txList);
        },
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TransactionFormPage(preSelectedAccountId: liveAccount.id),
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
          final closingBalances = <String, double>{};
          double totalNetImpact = 0;
          for (var txData in transactions) {
            final t = txData.transaction;
            if (t.type == 'Income') {
              totalNetImpact += t.amount;
            } else if (t.type == 'Expense') {
              totalNetImpact -= t.amount;
            } else if (t.type == 'Transfer') {
              if (t.accountId == liveAccount.id) {
                totalNetImpact -= t.amount;
              } else if (t.toAccountId == liveAccount.id) {
                totalNetImpact += t.amount;
              }
            }
          }
          double runningBal = liveAccount.balance - totalNetImpact;

          for (var txData in transactions.reversed) {
            final t = txData.transaction;
            if (t.type == 'Income') {
              runningBal += t.amount;
            } else if (t.type == 'Expense') {
              runningBal -= t.amount;
            } else if (t.type == 'Transfer') {
              if (t.accountId == liveAccount.id) {
                runningBal -= t.amount;
              } else if (t.toAccountId == liveAccount.id) {
                runningBal += t.amount;
              }
            }
            closingBalances[t.id] = runningBal;
          }

          final rawCycles = _groupIntoCycles(transactions, liveAccount);
          final filteredCycles = rawCycles.map((cycle) {
            return BillingCycle(
              startDate: cycle.startDate,
              endDate: cycle.endDate,
              dueDate: cycle.dueDate,
              transactions: TransactionFilterHelper.apply(
                cycle.transactions,
                filterState,
                liveAccount.id,
              ),
            );
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingMd),
                  child: _CreditSummaryCard(
                    cycles: rawCycles,
                    account: liveAccount,
                    allTransactions: transactions,
                  ),
                ),
              ),

              if (filterState.isActive)
                SliverToBoxAdapter(
                  child: ActiveFilterBanner(
                    filterState: filterState,
                    onClear: () =>
                        ref
                                .read(
                                  transactionFilterProvider(
                                    liveAccount.id,
                                  ).notifier,
                                )
                                .state =
                            const TransactionFilterState(),
                  ),
                ),

              if (transactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No credit activity yet.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (filteredCycles.every((c) => c.transactions.isEmpty))
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
                ...filteredCycles
                    .where(
                      (c) =>
                          c.transactions.isNotEmpty ||
                          filteredCycles.indexOf(c) <= 1,
                    )
                    .map((cycle) {
                      final isCurrentUnbilled =
                          filteredCycles.indexOf(cycle) == 0;
                      final headerTitle = isCurrentUnbilled
                          ? 'UNBILLED (Ends ${cycle.title})'
                          : 'STATEMENT - ${cycle.title}';
                      return SliverMainAxisGroup(
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyCycleHeaderDelegate(
                              title: headerTitle,
                              theme: theme,
                            ),
                          ),
                          if (cycle.transactions.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                ),
                                child: Center(
                                  child: Text(
                                    filterState.isActive
                                        ? 'No matches in this cycle'
                                        : 'No transactions in this cycle.',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacingMd,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final txData = cycle.transactions[index];
                                  return TransactionCard(
                                    data: txData,
                                    currentAccountId: liveAccount.id,
                                    closingBalance:
                                        closingBalances[txData.transaction.id],
                                  );
                                }, childCount: cycle.transactions.length),
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: DesignTokens.spacingMd),
                          ),
                        ],
                      );
                    })
                    .toList(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _CreditSummaryCard extends StatelessWidget {
  final List<BillingCycle> cycles;
  final Account account;
  final List<TransactionWithDetails> allTransactions;

  const _CreditSummaryCard({
    required this.cycles,
    required this.account,
    required this.allTransactions,
  });

  Widget _buildDateMini(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    BillingCycle? lastCycle = cycles.length > 1 ? cycles[1] : null;
    DateTime? lastStatementDate = lastCycle?.endDate;

    double historicalNet = 0;
    double currentCycleNet = 0;
    double paymentsSinceStatement = 0;

    for (var tx in allTransactions) {
      final t = tx.transaction;
      bool isExpense =
          t.type == 'Expense' ||
          (t.type == 'Transfer' && t.accountId == account.id);
      bool isPayment =
          t.type == 'Income' ||
          (t.type == 'Transfer' && t.toAccountId == account.id);
      bool isRepayment = tx.category?.name == 'Repayment';
      double netAmount = 0;

      if (isExpense)
        netAmount = -t.amount;
      else if (isPayment)
        netAmount = t.amount;

      DateTime effectiveDate = account.getEffectiveDate(t);
      if (lastStatementDate == null ||
          effectiveDate.isAfter(lastStatementDate)) {
        if (isPayment && isRepayment) {
          paymentsSinceStatement += netAmount;
        } else {
          currentCycleNet += netAmount;
        }
      } else {
        historicalNet += netAmount;
      }
    }

    double remainingDueNet = historicalNet + paymentsSinceStatement;
    double adjustedUnbilled = currentCycleNet;
    if (lastCycle != null && now.isAfter(lastCycle.dueDate)) {
      adjustedUnbilled += remainingDueNet;
    }

    double totalOutstanding = currentCycleNet + remainingDueNet;
    String totalSign = totalOutstanding < -0.01
        ? '-₹ '
        : (totalOutstanding > 0.01 ? '+₹ ' : '₹ ');
    Color totalColor = totalOutstanding < -0.01
        ? theme.colorScheme.onSurface
        : Colors.green;

    String unbilledSign = adjustedUnbilled < -0.01
        ? '-₹ '
        : (adjustedUnbilled > 0.01 ? '+₹ ' : '₹ ');
    String statementSign = historicalNet < -0.01
        ? '-₹ '
        : (historicalNet > 0.01 ? '+₹ ' : '₹ ');

    String statusText = 'NO DUES';
    Color statusColor = theme.colorScheme.primary;

    // --- NEW: Contextual Sub-status Text ---
    String subStatusText = '';
    Color subStatusColor = theme.colorScheme.onSurfaceVariant;

    // --- FIX: Intelligent Contextual Date Logic ---
    DateTime activeDueDate = cycles.isNotEmpty ? cycles[0].dueDate : now;
    String dueDateLabel = 'NEXT DUE DATE';

    if (lastCycle != null) {
      final today = DateTime(now.year, now.month, now.day);
      final dueDayOnly = DateTime(
        lastCycle.dueDate.year,
        lastCycle.dueDate.month,
        lastCycle.dueDate.day,
      );
      int daysUntilDue = dueDayOnly.difference(today).inDays;

      if (remainingDueNet < -0.01) {
        // Still owe money: Lock onto the CURRENT Due Date
        activeDueDate = lastCycle.dueDate;
        dueDateLabel = 'CURRENT DUE DATE';

        if (daysUntilDue < 0) {
          statusText =
              'OVERDUE (- ₹${CurrencyFormatter.format(remainingDueNet.abs())})';
          statusColor = theme.colorScheme.error;
          subStatusText = 'OVERDUE BY ${daysUntilDue.abs()} DAYS';
          subStatusColor = theme.colorScheme.error;
        } else {
          if (paymentsSinceStatement > 0) {
            statusText =
                'PARTIAL (- ₹${CurrencyFormatter.format(remainingDueNet.abs())} LEFT)';
            statusColor = Colors.orangeAccent.shade700;
          } else {
            statusText = 'UNPAID';
            statusColor = theme.colorScheme.error;
          }

          if (daysUntilDue == 0)
            subStatusText = 'DUE TODAY';
          else if (daysUntilDue == 1)
            subStatusText = 'DUE TOMORROW';
          else
            subStatusText = 'DUE IN $daysUntilDue DAYS';

          subStatusColor = daysUntilDue <= 3
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant;
        }
      } else if (remainingDueNet > 0.01) {
        statusText =
            'SURPLUS (+ ₹${CurrencyFormatter.format(remainingDueNet)})';
        statusColor = theme.colorScheme.primary;
        subStatusText = 'PAID IN FULL';
        subStatusColor = Colors.green;
      } else if (historicalNet < -0.01) {
        statusText = 'PAID IN FULL';
        statusColor = theme.colorScheme.primary;
        subStatusText = 'NO DUES PENDING';
        subStatusColor = Colors.green;
      }
    }

    String billDateStr = cycles.isNotEmpty
        ? '${cycles[0].endDate.day} ${DateTimeConstants.shortMonths[cycles[0].endDate.month - 1]} ${cycles[0].endDate.year}'
        : '--';
    String dueDateStr = cycles.isNotEmpty
        ? '${activeDueDate.day} ${DateTimeConstants.shortMonths[activeDueDate.month - 1]} ${activeDueDate.year}'
        : '--';

    final labelStyle = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      letterSpacing: -0.5,
    );
    final symbolStyle = TextStyle(
      fontSize: 9,
      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL OUTSTANDING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CurrencyText(
              amount: totalOutstanding.abs(),
              sign: totalSign,
              amountStyle: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: totalColor,
                letterSpacing: -0.5,
              ),
              symbolStyle: TextStyle(
                fontSize: 14,
                color: totalColor.withOpacity(0.7),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateMini('NEXT BILL DATE', billDateStr, theme),
              _buildDateMini(
                dueDateLabel,
                dueDateStr,
                theme,
              ), // <-- Dynamically swaps label
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('UNBILLED', style: labelStyle),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: CurrencyText(
                          amount: adjustedUnbilled.abs(),
                          sign: unbilledSign,
                          amountStyle: valueStyle.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          symbolStyle: symbolStyle.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),

                      if (cycles.isNotEmpty &&
                          remainingDueNet < -0.01 &&
                          (lastCycle != null && now.isAfter(lastCycle.dueDate)))
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Includes -₹${CurrencyFormatter.format(remainingDueNet.abs())} prev.',
                            style: TextStyle(
                              fontSize: 8,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                VerticalDivider(
                  width: 16,
                  thickness: 1,
                  color: theme.dividerColor,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('LAST STATEMENT', style: labelStyle),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: CurrencyText(
                          amount: historicalNet.abs(),
                          sign: statementSign,
                          amountStyle: valueStyle.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          symbolStyle: symbolStyle.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),

                      if (subStatusText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            subStatusText,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: subStatusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyCycleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final ThemeData theme;
  _StickyCycleHeaderDelegate({required this.title, required this.theme});

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
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
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
  bool shouldRebuild(covariant _StickyCycleHeaderDelegate oldDelegate) =>
      title != oldDelegate.title;
}
