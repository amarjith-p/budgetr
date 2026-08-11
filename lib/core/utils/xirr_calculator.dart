// lib/core/utils/xirr_calculator.dart
import 'dart:math';

class CashFlow {
  final double amount;
  final DateTime date;

  CashFlow(this.amount, this.date);
}

class XirrCalculator {
  /// Calculates the Extended Internal Rate of Return (XIRR) using the Newton-Raphson method.
  /// Expects a list of [CashFlow] objects where outflows (investments) are negative
  /// and inflows (returns/current value) are positive.
  static double calculate(List<CashFlow> cashFlows) {
    if (cashFlows.length < 2) return 0.0;

    bool hasPositive = false;
    bool hasNegative = false;
    for (var cf in cashFlows) {
      if (cf.amount > 0.01) hasPositive = true;
      if (cf.amount < -0.01) hasNegative = true;
    }

    // XIRR requires at least one positive and one negative cash flow
    if (!hasPositive || !hasNegative) return 0.0;

    // Chronological sort to safely determine Day 0
    final sortedFlows = List<CashFlow>.from(cashFlows)
      ..sort((a, b) => a.date.compareTo(b.date));
    final d0 = sortedFlows.first.date;

    double xnpv(double rate) {
      double result = 0.0;
      for (var cf in sortedFlows) {
        final days = cf.date.difference(d0).inDays;
        result += cf.amount / pow(1.0 + rate, days / 365.0);
      }
      return result;
    }

    double xnpvDerivative(double rate) {
      double result = 0.0;
      for (var cf in sortedFlows) {
        final days = cf.date.difference(d0).inDays;
        if (days > 0) {
          result -=
              (days / 365.0) *
              cf.amount /
              pow(1.0 + rate, (days / 365.0) + 1.0);
        }
      }
      return result;
    }

    double rate = 0.1; // 10% Initial guess
    for (int i = 0; i < 100; i++) {
      final npv = xnpv(rate);
      final derivative = xnpvDerivative(rate);
      if (derivative == 0) break;

      final newRate = rate - (npv / derivative);
      // Precision threshold
      if ((newRate - rate).abs() < 0.0001) return newRate;
      rate = newRate;
    }

    return rate;
  }
}
