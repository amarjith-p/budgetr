import 'dart:ui';
import 'package:budgetr/core/components/currency_text.dart';
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

extension CreditAccountExtensions on Account {
  int get safeBillingDay => billDate ?? 15; 
  int get safeDueDay => dueDate ?? 5;      
  
  // --- NEW: THE EFFECTIVE DATE ENGINE ---
  DateTime getEffectiveDate(TransactionRecord tx) {
    if (tx.isSpillover) {
      final bDay = safeBillingDay;
      DateTime nextBillDate = DateTime(tx.date.year, tx.date.month, bDay);
      if (tx.date.day > bDay) {
        nextBillDate = DateTime(tx.date.year, tx.date.month + 1, bDay);
      }
      return nextBillDate.add(const Duration(days: 1)); // Forces it into next cycle
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

  const CreditTransactionPage({Key? key, required this.account}) : super(key: key);

  List<BillingCycle> _groupIntoCycles(List<TransactionWithDetails> transactions) {
    if (transactions.isEmpty) return [];

    final bDay = account.safeBillingDay;
    final dDay = account.safeDueDay;
    
    List<BillingCycle> cycles = [];
    
    DateTime oldest = transactions.last.transaction.date;
    DateTime newest = transactions.first.transaction.date;
    DateTime now = DateTime.now();
    if (now.isAfter(newest)) newest = now;

    DateTime currentEnd = DateTime(newest.year, newest.month, bDay);
    if (newest.day > bDay) {
      currentEnd = DateTime(newest.year, newest.month + 1, bDay);
    }

    DateTime pointerEnd = currentEnd;
    while (pointerEnd.isAfter(oldest) || pointerEnd.isAtSameMomentAs(oldest)) {
      DateTime pointerStart = DateTime(pointerEnd.year, pointerEnd.month - 1, bDay + 1);
      
      DateTime pointerDue = DateTime(pointerEnd.year, pointerEnd.month + 1, dDay);
      if (dDay > bDay && pointerEnd.month == pointerStart.month) {
        pointerDue = DateTime(pointerEnd.year, pointerEnd.month, dDay);
      }

      final cycleTxs = transactions.where((t) {
        // --- USES EFFECTIVE DATE INSTEAD OF RECEIPT DATE ---
        final effectiveDate = account.getEffectiveDate(t.transaction); 
        return (effectiveDate.isAfter(pointerStart) || effectiveDate.isAtSameMomentAs(pointerStart)) && 
               (effectiveDate.isBefore(pointerEnd) || effectiveDate.isAtSameMomentAs(pointerEnd));
      }).toList();

      cycles.add(BillingCycle(
        startDate: pointerStart, 
        endDate: pointerEnd, 
        dueDate: pointerDue, 
        transactions: cycleTxs
      ));

      pointerEnd = DateTime(pointerEnd.year, pointerEnd.month - 1, bDay);
    }

    for (int i = 0; i < cycles.length - 1; i++) {
      final currentCycle = cycles[i];
      final previousCycle = cycles[i + 1];
      
      final paymentsToMove = currentCycle.transactions.where((tx) {
        final t = tx.transaction;
        bool isIncoming = t.type == 'Income' || (t.type == 'Transfer' && t.toAccountId == account.id);
        bool isRepaymentCat = tx.category?.name == 'Repayment';
        bool isBeforeDue = t.date.isBefore(previousCycle.dueDate.add(const Duration(days: 1)));

        return isIncoming && isRepaymentCat && isBeforeDue;
      }).toList();

      if (paymentsToMove.isNotEmpty) {
        currentCycle.transactions.removeWhere((tx) => paymentsToMove.contains(tx));
        previousCycle.transactions.insertAll(0, paymentsToMove);
        previousCycle.transactions.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
      }
    }

    return cycles;
  }

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
          final cycles = _groupIntoCycles(transactions);
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingMd),
                  child: _CreditSummaryCard(
                    cycles: cycles, 
                    account: account, 
                    allTransactions: transactions,
                  ),
                ),
              ),
              
              if (transactions.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text('No credit activity yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                ...cycles.where((c) => c.transactions.isNotEmpty || cycles.indexOf(c) <= 1).map((cycle) {
                  final isCurrentUnbilled = cycles.indexOf(cycle) == 0;
                  final headerTitle = isCurrentUnbilled ? 'UNBILLED (Ends ${cycle.title})' : 'STATEMENT - ${cycle.title}';

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyCycleHeaderDelegate(title: headerTitle, theme: theme),
                      ),
                      if (cycle.transactions.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: Text('No transactions in this cycle.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12))),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => TransactionCard(data: cycle.transactions[index], currentAccountId: account.id),
                              childCount: cycle.transactions.length,
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

class _CreditSummaryCard extends StatelessWidget {
  final List<BillingCycle> cycles;
  final Account account;
  final List<TransactionWithDetails> allTransactions;

  const _CreditSummaryCard({
    required this.cycles, 
    required this.account,
    required this.allTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme; 
    final now = DateTime.now();

    BillingCycle? lastCycle = cycles.length > 1 ? cycles[1] : null;
    DateTime? lastStatementDate = lastCycle?.endDate;

    double historicalNet = 0;           
    double currentCycleNet = 0;         
    double paymentsSinceStatement = 0;  

    for (var tx in allTransactions) {
      final t = tx.transaction;
      bool isExpense = t.type == 'Expense' || (t.type == 'Transfer' && t.accountId == account.id);
      bool isPayment = t.type == 'Income' || (t.type == 'Transfer' && t.toAccountId == account.id);
      bool isRepayment = tx.category?.name == 'Repayment';
      
      double netAmount = 0;
      if (isExpense) netAmount = -t.amount;      
      else if (isPayment) netAmount = t.amount;  

      // --- USES EFFECTIVE DATE FOR MATH ---
      DateTime effectiveDate = account.getEffectiveDate(t);

      if (lastStatementDate == null || effectiveDate.isAfter(lastStatementDate)) {
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
    double adjustedUnbilled = currentCycleNet + remainingDueNet; 

    String statusText = 'NO DUES';
    Color statusColor = theme.colorScheme.primary;
    int daysUntilDue = 0;
    
    if (lastCycle != null) {
      daysUntilDue = lastCycle.dueDate.difference(now).inDays;
      if (remainingDueNet < 0) { 
        if (daysUntilDue < 0) {
          statusText = 'OVERDUE (-₹${remainingDueNet.abs().toStringAsFixed(2)})';
          statusColor = theme.colorScheme.error;
        } else if (paymentsSinceStatement > 0) {
          statusText = 'PARTIAL (-₹${remainingDueNet.abs().toStringAsFixed(2)} LEFT)';
          statusColor = Colors.orangeAccent.shade700;
        } else {
          statusText = 'UNPAID';
          statusColor = theme.colorScheme.error;
        }
      } else if (remainingDueNet > 0) { 
        statusText = 'SURPLUS (+₹${remainingDueNet.toStringAsFixed(2)})';
        statusColor = theme.colorScheme.primary;
      } else if (remainingDueNet == 0 && historicalNet < 0) {
        statusText = 'PAID IN FULL';
        statusColor = theme.colorScheme.primary;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UNBILLED', style: textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    CurrencyText(
                      amount: adjustedUnbilled,
                      showSignForPositive: true,
                      amountStyle: textTheme.titleLarge!,
                    ),
                    const SizedBox(height: 12),
                    
                    if (cycles.isNotEmpty)
                      _buildMiniInfo(Icons.calendar_today_rounded, 'Bills on ${cycles[0].endDate.day} ${DateTimeConstants.shortMonths[cycles[0].endDate.month - 1]}', theme),
                    
                    if (cycles.isNotEmpty && remainingDueNet != 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: _buildMiniInfo(
                          Icons.compare_arrows_rounded, 
                          'Includes ${remainingDueNet < 0 ? '-' : '+'}₹${remainingDueNet.abs().toStringAsFixed(2)} prev. balance', 
                          theme
                        ),
                      ),
                  ],
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.3)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LAST STATEMENT', style: textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    CurrencyText(
                      amount: historicalNet,
                      showSignForPositive: true,
                      amountStyle: textTheme.titleLarge!,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(statusText, style: textTheme.labelSmall?.copyWith(color: statusColor)),
                    ),
                    const SizedBox(height: 8),
                    if (lastCycle != null && remainingDueNet < 0)
                      _buildMiniInfo(
                        daysUntilDue < 0 ? Icons.warning_rounded : Icons.timer_outlined, 
                        daysUntilDue < 0 ? 'Due passed' : 'Due in $daysUntilDue days', 
                        theme,
                        isAlert: daysUntilDue < 0
                      )
                    else if (lastCycle != null)
                      _buildMiniInfo(Icons.check_circle_outline_rounded, 'Cleared', theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text, ThemeData theme, {bool isAlert = false}) {
    final color = isAlert ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text, 
            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StickyCycleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final ThemeData theme;

  _StickyCycleHeaderDelegate({required this.title, required this.theme});

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
            title,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: theme.colorScheme.primary),
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
  bool shouldRebuild(covariant _StickyCycleHeaderDelegate oldDelegate) => title != oldDelegate.title;
}