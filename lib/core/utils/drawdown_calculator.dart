// lib/core/utils/drawdown_calculator.dart
import 'dart:math';
import '../database/app_database.dart';

class DrawdownCalculator {
  /// Calculates the maximum peak-to-trough decline (Drawdown) of an investment.
  /// Strictly isolates Market Performance ('Update') from Cash Flows ('Deposit' / 'Withdrawal').
  static double calculate(double initialBalance, List<InvestmentLog> logs) {
    if (logs.isEmpty) return 0.0;

    // 1. Filter out Passive Income (Dividends/Interest) as they don't affect NAV Drawdown.
    // 2. Sort chronologically to walk the timeline forward.
    final validLogs = List<InvestmentLog>.from(
      logs.where(
        (l) =>
            l.type == 'Deposit' || l.type == 'Withdrawal' || l.type == 'Update',
      ),
    )..sort((a, b) => a.date.compareTo(b.date));

    double peak = initialBalance;
    double current = initialBalance;
    double maxDrawdown = 0.0;

    for (final log in validLogs) {
      if (log.type == 'Deposit') {
        // A deposit increases current value, but we must also increase the peak
        // by the exact same amount so it doesn't artificially look like a market recovery.
        current += log.amount;
        peak += log.amount;
      } else if (log.type == 'Withdrawal') {
        // A withdrawal drops the current value. To prevent this from looking like a market crash,
        // we scale the peak down proportionally.
        // (e.g., Withdrawing 50% of your money reduces the High-Water Mark by 50%).
        if (current > 0) {
          double withdrawalRatio = log.amount / current;
          peak = peak * max(0.0, (1.0 - withdrawalRatio));
        }
        current -= log.amount;
        if (current < 0) current = 0.0;
      } else if (log.type == 'Update') {
        // This is a pure Market Update. Here is where actual drawdowns happen.
        current = log.amount;

        if (current > peak) {
          // New All-Time High reached!
          peak = current;
        } else if (peak > 0) {
          // Market value dropped below the peak. Calculate the drawdown percentage.
          double drawdown = ((peak - current) / peak) * 100.0;
          if (drawdown > maxDrawdown) {
            maxDrawdown = drawdown;
          }
        }
      }
    }

    return maxDrawdown; // Returns as a percentage (e.g., 15.4)
  }
}
