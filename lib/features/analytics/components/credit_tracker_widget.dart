import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/database/app_database.dart';
import '../../accounts/providers/account_provider.dart';
import '../../transactions/providers/transaction_provider.dart';

// --- LOCAL EXTENSIONS FOR CREDIT MATH ---
extension _CreditTrackerAccountExt on Account {
  int get trackBillingDay => billDate ?? 15;
  int get trackDueDay => dueDate ?? 5;

  DateTime getTrackEffectiveDate(TransactionRecord tx) {
    if (tx.isSpillover) {
      final bDay = trackBillingDay;
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

enum _SheetContext { billed, overdue, unbilled, paid }

// --- DECOUPLED DATA CLASS ---
class _CardStatusData {
  final Account account;
  final double billed;
  final double unbilled;
  final double total;

  final DateTime lastStatementDate;
  final DateTime currentDueDate;
  final int daysUntilDue;

  final DateTime nextStatementDate;
  final DateTime nextDueDate;

  final double historicalNet;

  _CardStatusData({
    required this.account,
    required this.billed,
    required this.unbilled,
    required this.total,
    required this.lastStatementDate,
    required this.currentDueDate,
    required this.daysUntilDue,
    required this.nextStatementDate,
    required this.nextDueDate,
    required this.historicalNet,
  });
}

class CreditTrackerWidget extends ConsumerWidget {
  const CreditTrackerWidget({Key? key}) : super(key: key);

  void _showDetailsSheet(
    BuildContext context,
    String title,
    List<_CardStatusData> cards,
    Color themeColor,
    ThemeData theme,
    _SheetContext sheetContext,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = theme.brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.credit_card_rounded,
                            size: 16,
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          title.toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: cards.isEmpty
                        ? Center(
                            child: Text(
                              'No cards in this category.',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: cards.length,
                            itemBuilder: (context, index) {
                              final c = cards[index];
                              final amountSign = c.total < -0.01 ? '-₹ ' : '₹ ';
                              final billedSign = c.billed < -0.01
                                  ? '-₹ '
                                  : '₹ ';
                              final unbilledSign = c.unbilled < -0.01
                                  ? '-₹ '
                                  : '₹ ';

                              // --- INTELLIGENT CONTEXTUAL DATE LOGIC ---
                              DateTime relevantBillDate;
                              DateTime relevantDueDate;
                              int daysDiff;
                              String counterText = '';
                              Color counterColor = Colors.transparent;
                              bool showCounter = false;

                              final today = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              );

                              if (sheetContext == _SheetContext.unbilled) {
                                relevantBillDate = c.nextStatementDate;
                                relevantDueDate = c.nextDueDate;

                                final genDay = DateTime(
                                  relevantBillDate.year,
                                  relevantBillDate.month,
                                  relevantBillDate.day,
                                );
                                daysDiff = genDay.difference(today).inDays;

                                if (daysDiff == 0)
                                  counterText = 'BILLS TODAY';
                                else if (daysDiff == 1)
                                  counterText = 'BILLS TOMORROW';
                                else
                                  counterText = 'BILLS IN $daysDiff DAYS';

                                counterColor = theme.colorScheme.primary;
                                showCounter = true;
                              } else {
                                relevantBillDate = c.lastStatementDate;
                                relevantDueDate = c.currentDueDate;
                                daysDiff = c.daysUntilDue;

                                if (sheetContext == _SheetContext.overdue ||
                                    daysDiff < 0) {
                                  counterText =
                                      'OVERDUE BY ${daysDiff.abs()} DAYS';
                                  counterColor = theme.colorScheme.error;
                                  showCounter = true;
                                } else if (sheetContext == _SheetContext.paid) {
                                  counterText = 'PAID IN FULL';
                                  counterColor = Colors.green;
                                  showCounter = true;
                                } else {
                                  if (daysDiff == 0)
                                    counterText = 'DUE TODAY';
                                  else if (daysDiff == 1)
                                    counterText = 'DUE TOMORROW';
                                  else
                                    counterText = 'DUE IN $daysDiff DAYS';

                                  counterColor = Colors.orangeAccent.shade700;
                                  showCounter = true;
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.dividerColor.withOpacity(0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDark ? 0.2 : 0.02,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.account.providerName
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  color:
                                                      theme.colorScheme.primary,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              Text(
                                                c.account.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: CurrencyText(
                                              amount: c.total.abs(),
                                              sign: amountSign,
                                              amountStyle: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color:
                                                    theme.colorScheme.onSurface,
                                                letterSpacing: -0.5,
                                              ),
                                              symbolStyle: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'BILLED BALANCE',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: CurrencyText(
                                                  amount: c.billed.abs(),
                                                  sign: billedSign,
                                                  amountStyle: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        c.billed < -0.01 &&
                                                            sheetContext !=
                                                                _SheetContext
                                                                    .unbilled
                                                        ? themeColor
                                                        : theme
                                                              .colorScheme
                                                              .onSurface,
                                                  ),
                                                  symbolStyle: TextStyle(
                                                    fontSize: 10,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'UNBILLED SPENDS',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: CurrencyText(
                                                  amount: c.unbilled.abs(),
                                                  sign: unbilledSign,
                                                  amountStyle: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        sheetContext ==
                                                            _SheetContext
                                                                .unbilled
                                                        ? themeColor
                                                        : theme
                                                              .colorScheme
                                                              .onSurface,
                                                  ),
                                                  symbolStyle: TextStyle(
                                                    fontSize: 10,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // --- CONTEXTUAL DATES & COUNTER PILL ---
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(isDark ? 0.3 : 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sheetContext ==
                                                            _SheetContext
                                                                .unbilled
                                                        ? 'BILLS ON'
                                                        : 'BILLED ON',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${relevantBillDate.day} ${DateTimeConstants.shortMonths[relevantBillDate.month - 1]}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                width: 1,
                                                height: 20,
                                                color: theme.dividerColor,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'DUE ON',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${relevantDueDate.day} ${DateTimeConstants.shortMonths[relevantDueDate.month - 1]}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (showCounter)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: counterColor.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: counterColor
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                counterText,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: counterColor,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 16, color: color),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: FuturisticLoader(size: 80, label: "LOADING..")),
      ),
      error: (e, st) => const SizedBox(
        height: 200,
        child: Center(child: Text('Error loading credit data')),
      ),
      data: (accounts) {
        return transactionsAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(
              child: FuturisticLoader(size: 80, label: "LOADING.."),
            ),
          ),
          error: (e, st) => const SizedBox(
            height: 200,
            child: Center(child: Text('Error loading transactions')),
          ),
          data: (transactions) {
            final creditAccounts = accounts
                .where((a) => a.type == 'Credit Cards')
                .toList();
            if (creditAccounts.isEmpty) return const SizedBox.shrink();

            List<_CardStatusData> statuses = [];
            double globalBilled = 0.0;
            double globalUnbilled = 0.0;

            for (var acc in creditAccounts) {
              final txs = transactions
                  .where(
                    (t) =>
                        t.transaction.accountId == acc.id ||
                        t.transaction.toAccountId == acc.id,
                  )
                  .toList();

              int bDay = acc.trackBillingDay;
              int dDay = acc.trackDueDay;
              DateTime now = DateTime.now();

              // 1. Calculate Current Cycle Dates
              DateTime lastStatementDate = DateTime(
                now.year,
                now.month,
                bDay,
                23,
                59,
                59,
              );
              if (now.day <= bDay) {
                lastStatementDate = DateTime(
                  now.year,
                  now.month - 1,
                  bDay,
                  23,
                  59,
                  59,
                );
              }

              DateTime currentDueDate;
              if (dDay > bDay) {
                currentDueDate = DateTime(
                  lastStatementDate.year,
                  lastStatementDate.month,
                  dDay,
                  23,
                  59,
                  59,
                );
              } else {
                currentDueDate = DateTime(
                  lastStatementDate.year,
                  lastStatementDate.month + 1,
                  dDay,
                  23,
                  59,
                  59,
                );
              }

              // 2. Calculate NEXT Cycle Dates (For Unbilled Spends)
              DateTime nextStatementDate = DateTime(
                lastStatementDate.year,
                lastStatementDate.month + 1,
                bDay,
                23,
                59,
                59,
              );
              DateTime nextDueDate;
              if (dDay > bDay) {
                nextDueDate = DateTime(
                  nextStatementDate.year,
                  nextStatementDate.month,
                  dDay,
                  23,
                  59,
                  59,
                );
              } else {
                nextDueDate = DateTime(
                  nextStatementDate.year,
                  nextStatementDate.month + 1,
                  dDay,
                  23,
                  59,
                  59,
                );
              }

              double historicalNet = 0;
              double currentCycleNet = 0;
              double paymentsSinceStatement = 0;

              for (var txData in txs) {
                final t = txData.transaction;
                bool isExpense =
                    t.type == 'Expense' ||
                    (t.type == 'Transfer' && t.accountId == acc.id);
                bool isPayment =
                    t.type == 'Income' ||
                    (t.type == 'Transfer' && t.toAccountId == acc.id);
                bool isRepayment = txData.category?.name == 'Repayment';

                double netAmount = 0;
                if (isExpense)
                  netAmount = -t.amount;
                else if (isPayment)
                  netAmount = t.amount;

                DateTime effectiveDate = acc.getTrackEffectiveDate(t);

                if (effectiveDate.isAfter(lastStatementDate)) {
                  if (isPayment && isRepayment)
                    paymentsSinceStatement += netAmount;
                  else
                    currentCycleNet += netAmount;
                } else {
                  historicalNet += netAmount;
                }
              }

              double billed = historicalNet + paymentsSinceStatement;
              double unbilled = currentCycleNet;
              double total = billed + unbilled;

              // EXACT MIDNIGHT NORMALIZATION
              final today = DateTime(now.year, now.month, now.day);
              final dueDayOnly = DateTime(
                currentDueDate.year,
                currentDueDate.month,
                currentDueDate.day,
              );
              int daysUntilDue = dueDayOnly.difference(today).inDays;

              globalBilled += billed;
              globalUnbilled += unbilled;

              statuses.add(
                _CardStatusData(
                  account: acc,
                  billed: billed,
                  unbilled: unbilled,
                  total: total,
                  lastStatementDate: lastStatementDate,
                  currentDueDate: currentDueDate,
                  daysUntilDue: daysUntilDue,
                  nextStatementDate: nextStatementDate,
                  nextDueDate: nextDueDate,
                  historicalNet: historicalNet,
                ),
              );
            }

            final totalOutstanding = globalBilled + globalUnbilled;

            // STRICT DECOUPLED LOGIC LISTS
            final billedCards = statuses
                .where((c) => c.billed < -0.01)
                .toList();
            final overdueCards = billedCards
                .where((c) => c.daysUntilDue < 0)
                .toList();
            final pendingCards = statuses
                .where((c) => c.unbilled < -0.01)
                .toList();
            final paidCards = statuses
                .where((c) => c.historicalNet < -0.01 && c.billed >= -0.01)
                .toList();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: overdueCards.isNotEmpty
                      ? theme.colorScheme.error.withOpacity(0.5)
                      : theme.dividerColor.withOpacity(0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.credit_card_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'CREDIT TRACKER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- HERO MONEY SECTION ---
                  Text(
                    'TOTAL OUTSTANDING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
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
                      sign: totalOutstanding < -0.01 ? '-₹ ' : '₹ ',
                      amountStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -1.0,
                      ),
                      symbolStyle: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UNBILLED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: CurrencyText(
                                amount: globalUnbilled.abs(),
                                sign: globalUnbilled < -0.01 ? '-₹ ' : '₹ ',
                                amountStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                                symbolStyle: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: theme.dividerColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILLED (DUE)',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: CurrencyText(
                                amount: globalBilled.abs(),
                                sign: globalBilled < -0.01 ? '-₹ ' : '₹ ',
                                amountStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: globalBilled < -0.01
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurface,
                                ),
                                symbolStyle: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1),
                  ),

                  // --- 2x2 INTERACTIVE STATUS GRID ---
                  Row(
                    children: [
                      _buildGridCard(
                        context,
                        'CARDS BILLED',
                        billedCards.length,
                        Icons.receipt_long_rounded,
                        theme.colorScheme.primary,
                        theme,
                        () => _showDetailsSheet(
                          context,
                          'Billed Cards',
                          billedCards,
                          theme.colorScheme.primary,
                          theme,
                          _SheetContext.billed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildGridCard(
                        context,
                        'OVERDUE',
                        overdueCards.length,
                        Icons.warning_rounded,
                        theme.colorScheme.error,
                        theme,
                        () => _showDetailsSheet(
                          context,
                          'Overdue Cards',
                          overdueCards,
                          theme.colorScheme.error,
                          theme,
                          _SheetContext.overdue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildGridCard(
                        context,
                        'UNBILLED (PENDING)',
                        pendingCards.length,
                        Icons.schedule_rounded,
                        Colors.orangeAccent.shade700,
                        theme,
                        () => _showDetailsSheet(
                          context,
                          'Unbilled Spends',
                          pendingCards,
                          Colors.orangeAccent.shade700,
                          theme,
                          _SheetContext.unbilled,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildGridCard(
                        context,
                        'PAID (CYCLE)',
                        paidCards.length,
                        Icons.task_alt_rounded,
                        Colors.green,
                        theme,
                        () => _showDetailsSheet(
                          context,
                          'Paid Cards',
                          paidCards,
                          Colors.green,
                          theme,
                          _SheetContext.paid,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
