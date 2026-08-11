// lib/core/utils/drawdown_calculator.dart
import '../database/app_database.dart';

class DrawdownCalculator {
  /// Calculates the Maximum Drawdown (MDD) of an investment using a Time-Weighted
  /// NAV approach to mathematically isolate market performance from cash flows.
  static double calculate(double startBal, List<InvestmentLog> logs) {
    double nav = 100.0; // Starting baseline index
    double peakNav = 100.0;
    double maxDrawdown = 0.0;

    double currentBalance = startBal;

    // Ensure chronological execution to simulate the timeline forward
    final sortedLogs = List<InvestmentLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final log in sortedLogs) {
      if (log.type == 'Update') {
        // Only market updates affect the actual NAV performance index
        if (currentBalance > 0) {
          double returnPct = (log.amount - currentBalance) / currentBalance;
          nav = nav * (1.0 + returnPct);
        }
        currentBalance = log.amount;

        // Check for new peaks or new deepest drawdowns
        if (nav > peakNav) {
          peakNav = nav;
        } else {
          double drawdown = (nav - peakNav) / peakNav;
          if (drawdown < maxDrawdown) maxDrawdown = drawdown;
        }
      } else if (log.type == 'Deposit') {
        currentBalance +=
            log.amount; // Increases balance, but doesn't affect NAV
      } else if (log.type == 'Withdrawal') {
        currentBalance -=
            log.amount; // Decreases balance, but doesn't affect NAV
        if (currentBalance < 0) currentBalance = 0.0;
      }
    }

    return maxDrawdown * 100; // Returns as a percentage (e.g., -15.5)
  }
}
