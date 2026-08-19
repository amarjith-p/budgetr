import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/providers/account_provider.dart';
import '../../accounts/providers/credit_math_provider.dart';
import '../../accounts/providers/loan_math_provider.dart';
import '../../investments/providers/investment_provider.dart';
import '../../debts/providers/debt_provider.dart';

class NetWorthMetrics {
  final double totalAssets; // ALWAYS POSITIVE
  final double totalInvestments; // ALWAYS POSITIVE
  final double totalCreditCards; // ALWAYS NEGATIVE
  final double totalLoans; // ALWAYS NEGATIVE
  final double netDebts; // POSITIVE IF OWED TO YOU, NEGATIVE IF YOU OWE

  const NetWorthMetrics({
    this.totalAssets = 0.0,
    this.totalInvestments = 0.0,
    this.totalCreditCards = 0.0,
    this.totalLoans = 0.0,
    this.netDebts = 0.0,
  });

  // Pure Algebraic Sum: Adding negative liabilities mathematically subtracts them.
  double get netWorth =>
      totalAssets + totalInvestments + totalCreditCards + totalLoans + netDebts;
}

final netWorthMetricsProvider = Provider<AsyncValue<NetWorthMetrics>>((ref) {
  final accountsAsync = ref.watch(accountsStreamProvider);
  final investmentsAsync = ref.watch(investmentsStreamProvider);
  final debtsAsync = ref.watch(allDebtsProvider);

  if (accountsAsync.isLoading ||
      investmentsAsync.isLoading ||
      debtsAsync.isLoading) {
    return const AsyncLoading();
  }

  if (accountsAsync.hasError)
    return AsyncError(accountsAsync.error!, accountsAsync.stackTrace!);
  if (investmentsAsync.hasError)
    return AsyncError(investmentsAsync.error!, investmentsAsync.stackTrace!);
  if (debtsAsync.hasError)
    return AsyncError(debtsAsync.error!, debtsAsync.stackTrace!);

  final accounts = accountsAsync.value ?? [];
  final investments = investmentsAsync.value ?? [];
  final debts = debtsAsync.value ?? [];

  double totalAssets = 0.0;
  double totalCreditCards = 0.0;
  double totalLoans = 0.0;

  for (var acc in accounts) {
    if (acc.type == 'Credit Cards') {
      // Credit card provider naturally returns a negative value when you owe money
      totalCreditCards += ref
          .watch(creditCardMetricsProvider(acc))
          .totalOutstanding;
    } else if (acc.type == 'Loan' && !acc.isClosed) {
      // IMPORTANT FIX: Loan outstandings are mathematically positive in the DB.
      // We MUST subtract them here so they become negative liabilities.
      totalLoans -= ref.watch(loanTotalOutstandingProvider(acc));
    } else if (acc.type != 'Credit Cards' && acc.type != 'Loan') {
      totalAssets += acc.balance;
    }
  }

  double totalInvestments = 0.0;
  for (var inv in investments) {
    if (!inv.isClosed) {
      totalInvestments += inv.currentValue;
    }
  }

  double totalBorrowed = 0.0;
  double totalLent = 0.0;
  for (var d in debts) {
    if (!d.isSettled) {
      final remaining = d.amount - d.settledAmount;
      if (d.type == 'Borrowed') {
        totalBorrowed -= remaining; // Stored as negative liability
      } else if (d.type == 'Lent') {
        totalLent += remaining; // Stored as positive asset
      }
    }
  }

  final netDebts = totalLent + totalBorrowed;

  return AsyncData(
    NetWorthMetrics(
      totalAssets: totalAssets,
      totalInvestments: totalInvestments,
      totalCreditCards: totalCreditCards,
      totalLoans: totalLoans,
      netDebts: netDebts,
    ),
  );
});
