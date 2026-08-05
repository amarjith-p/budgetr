import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/providers/transaction_provider.dart';

final loanTotalOutstandingProvider = Provider.family
    .autoDispose<double, Account>((ref, account) {
      if (account.type != 'Loan') return account.balance;

      final transactionsAsync = ref.watch(
        accountTransactionsProvider(account.id),
      );
      final transactions = transactionsAsync.asData?.value ?? [];

      final double principal = account.loanPrincipal ?? 0.0;
      final double rate = account.interestRate ?? 0.0;
      final int months = account.tenureMonths ?? 0;

      final double currentBalance = account.balance;

      double totalInterest = account.totalInterestPayable ?? 0.0;
      bool isCustomInterest = account.totalInterestPayable != null;

      if (!isCustomInterest && principal > 0 && rate > 0 && months > 0) {
        double r = rate / 12 / 100;
        double emi =
            principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
        totalInterest = (emi * months) - principal;
      }

      double? taxAmount = account.totalTaxPayable;
      double? bankChargesAmount = account.bankCharges; // <-- NEW

      double interestPaid = 0.0;
      double taxPaid = 0.0;
      double chargesPaid = 0.0; // <-- NEW

      for (final item in transactions) {
        if (item.transaction.subCategory == 'Loan Interest') {
          interestPaid += item.transaction.amount;
        } else if (item.transaction.subCategory == 'Tax on Interest') {
          taxPaid += item.transaction.amount;
        } else if (item.transaction.subCategory == 'Bank Charges') {
          chargesPaid += item.transaction.amount; // <-- NEW
        }
      }

      double remainingInterest = totalInterest - interestPaid;

      double remainingTax = 0.0;
      if (taxAmount != null) {
        remainingTax = taxAmount - taxPaid;
      }

      double remainingCharges = 0.0;
      if (bankChargesAmount != null) {
        remainingCharges = bankChargesAmount - chargesPaid; // <-- NEW
      }

      return currentBalance +
          remainingInterest +
          remainingTax +
          remainingCharges;
    });
