import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/providers/transaction_provider.dart';

extension CreditMathExtensions on Account {
  int get mathBillingDay => billDate ?? 15;
  int get mathDueDay => dueDate ?? 5;

  DateTime getMathEffectiveDate(TransactionRecord tx) {
    if (tx.isSpillover) {
      final bDay = mathBillingDay;
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

class CreditCardMetrics {
  final double unbilled;
  final double billed;
  final double totalOutstanding;

  CreditCardMetrics({
    required this.unbilled,
    required this.billed,
    required this.totalOutstanding,
  });
}

final creditCardMetricsProvider = Provider.family<CreditCardMetrics, Account>((
  ref,
  account,
) {
  final transactionsAsync = ref.watch(accountTransactionsProvider(account.id));
  final transactions = transactionsAsync.asData?.value ?? [];

  if (transactions.isEmpty) {
    return CreditCardMetrics(
      unbilled: 0,
      billed: 0,
      totalOutstanding: account.balance,
    );
  }

  final bDay = account.mathBillingDay;
  final dDay = account.mathDueDay;

  DateTime oldest = transactions.last.transaction.date;
  DateTime newest = transactions.first.transaction.date;
  DateTime now = DateTime.now();
  if (now.isAfter(newest)) newest = now;

  DateTime currentEnd = DateTime(newest.year, newest.month, bDay, 23, 59, 59);
  if (newest.day > bDay) {
    currentEnd = DateTime(newest.year, newest.month + 1, bDay, 23, 59, 59);
  }
  DateTime pointerEnd = currentEnd;

  List<DateTime> cycleEnds = [];
  while (pointerEnd.isAfter(oldest) || pointerEnd.isAtSameMomentAs(oldest)) {
    cycleEnds.add(pointerEnd);
    pointerEnd = DateTime(
      pointerEnd.year,
      pointerEnd.month - 1,
      bDay,
      23,
      59,
      59,
    );
  }

  DateTime? lastStatementDate = cycleEnds.length > 1 ? cycleEnds[1] : null;

  double historicalNet = 0;
  double currentCycleNet = 0;
  double paymentsSinceStatement = 0;

  for (var txData in transactions) {
    final t = txData.transaction;
    bool isExpense =
        t.type == 'Expense' ||
        (t.type == 'Transfer' && t.accountId == account.id);
    bool isPayment =
        t.type == 'Income' ||
        (t.type == 'Transfer' && t.toAccountId == account.id);
    bool isRepayment = txData.category?.name == 'Repayment';

    double netAmount = 0;
    if (isExpense)
      netAmount = -t.amount;
    else if (isPayment)
      netAmount = t.amount;

    DateTime effectiveDate = account.getMathEffectiveDate(t);
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

  double billed = historicalNet + paymentsSinceStatement;
  double unbilled = currentCycleNet;
  double totalOutstanding = unbilled + billed;

  return CreditCardMetrics(
    unbilled: unbilled,
    billed: billed,
    totalOutstanding: totalOutstanding,
  );
});
