// lib/features/investments/components/investment_projection_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/utils/xirr_calculator.dart';
import '../../../core/constants/date_time_constants.dart';

class InvestmentProjectionCard extends StatefulWidget {
  final Investment investment;
  final List<InvestmentLog> logs;
  final VoidCallback onFlip;

  const InvestmentProjectionCard({
    Key? key,
    required this.investment,
    required this.logs,
    required this.onFlip,
  }) : super(key: key);

  @override
  State<InvestmentProjectionCard> createState() =>
      _InvestmentProjectionCardState();
}

class _InvestmentProjectionCardState extends State<InvestmentProjectionCard> {
  late double _targetAmount;
  late int _monthsToGoal;
  late double _expectedReturn;
  late double _averageSip;

  @override
  void initState() {
    super.initState();
    _analyzeLedgerData();
  }

  /// Analyzes ledger and prioritizes User Inputs over AI defaults
  void _analyzeLedgerData() {
    // 1. Calculate Net Cash Flows from Logs
    double netInvestmentsInLogs = 0.0;
    for (final log in widget.logs) {
      if (log.type == 'Deposit') {
        netInvestmentsInLogs += log.amount;
      }
      if (log.type == 'Withdrawal') {
        netInvestmentsInLogs -= log.amount;
      }
    }

    // Reverse-engineer the Day 0 base principal
    double baseInvested = max(
      0.0,
      widget.investment.initialAmount - netInvestmentsInLogs,
    );

    // 2. Calculate Historical XIRR for fallback Return
    List<CashFlow> cfs = [CashFlow(-baseInvested, widget.investment.startDate)];
    for (final log in widget.logs) {
      if (log.type == 'Deposit') {
        cfs.add(CashFlow(-log.amount, log.date));
      }
      if (log.type == 'Withdrawal') {
        cfs.add(CashFlow(log.amount, log.date));
      }
    }
    cfs.add(CashFlow(widget.investment.currentValue, DateTime.now()));
    double xirr = XirrCalculator.calculate(cfs) * 100;

    // --- A. EXPECTED RETURN (User Input > XIRR > 12%) ---
    if (widget.investment.expectedReturn != null &&
        widget.investment.expectedReturn! > 0) {
      _expectedReturn = widget.investment.expectedReturn!;
    } else if (xirr.isFinite && xirr > 0 && xirr < 100) {
      _expectedReturn = double.parse(xirr.toStringAsFixed(1));
    } else {
      _expectedReturn = 12.0;
    }

    // 3. Calculate Lifelong Habit (Average Monthly SIP)
    int daysActive = DateTime.now()
        .difference(widget.investment.startDate)
        .inDays;
    double activeMonths = max(1.0, daysActive / 30.44);
    _averageSip = max(0.0, netInvestmentsInLogs / activeMonths);

    // --- B. TARGET AMOUNT (User Input > AI Default) ---
    if (widget.investment.targetAmount != null &&
        widget.investment.targetAmount! > 0) {
      _targetAmount = widget.investment.targetAmount!;
    } else {
      _targetAmount = (widget.investment.currentValue * 2).clamp(
        10000.0,
        double.infinity,
      );
      _targetAmount =
          (_targetAmount / 10000).ceil() * 10000; // Round to nearest 10k
    }

    // --- C. EXPECTED END DATE (User Input > AI Default) ---
    if (widget.investment.expectedEndDate != null &&
        widget.investment.expectedEndDate!.isAfter(DateTime.now())) {
      int daysToGoal = widget.investment.expectedEndDate!
          .difference(DateTime.now())
          .inDays;
      _monthsToGoal = max(1, (daysToGoal / 30.44).round());
    } else {
      _monthsToGoal = 60; // Default 5 years (60 months)
    }
  }

  void _adjustTarget(double amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _targetAmount = max(10000.0, _targetAmount + amount);
    });
  }

  void _adjustMonths(int m) {
    HapticFeedback.selectionClick();
    setState(() {
      _monthsToGoal = max(
        1,
        min(600, _monthsToGoal + m),
      ); // 1 month to 50 years limits
    });
  }

  void _adjustRate(double r) {
    HapticFeedback.selectionClick();
    setState(() {
      _expectedReturn = max(1.0, min(50.0, _expectedReturn + r));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- AI MATHEMATICAL ENGINE ---
    final double p = widget.investment.currentValue; // Principal
    final double pmt = _averageSip; // Current Habit
    final int n = _monthsToGoal; // Target Horizon in Months
    final double rAnnual = _expectedReturn / 100;
    final double r = rAnnual / 12; // Monthly Rate

    double projectedValue = 0.0;
    double requiredSip = 0.0;

    if (r == 0) {
      projectedValue = p + (pmt * n);
      requiredSip = max(0.0, (_targetAmount - p) / n);
    } else {
      // Future Value of current assets + ongoing SIP
      projectedValue =
          p * pow(1 + r, n) + pmt * ((pow(1 + r, n) - 1) / r) * (1 + r);

      // Calculate how much SIP is actually required to hit target
      double futureValueOfPrincipal = p * pow(1 + r, n);
      double shortfallFromPrincipal = _targetAmount - futureValueOfPrincipal;

      if (shortfallFromPrincipal > 0) {
        requiredSip =
            shortfallFromPrincipal / (((pow(1 + r, n) - 1) / r) * (1 + r));
      }
    }

    final bool isOnTrack = requiredSip <= _averageSip;
    final double progress = (projectedValue / _targetAmount).clamp(0.0, 1.0);

    // --- EXACT MONTHLY DATE CALCULATION ---
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month + _monthsToGoal, now.day);
    final String targetYearStr =
        '${DateTimeConstants.shortMonths[targetDate.month - 1]} ${targetDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.colorScheme.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI PROJECTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: widget.onFlip,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.flip_to_front_rounded,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SMART INPUT CONTROLS (Updated increments to 10k)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildAdjuster(
                  'TARGET GOAL',
                  '₹${(_targetAmount / 1000).toStringAsFixed(0)}K',
                  () => _adjustTarget(-10000), // Decrement by 10k
                  () => _adjustTarget(10000), // Increment by 10k
                  theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildAdjuster(
                  'END DATE',
                  targetYearStr,
                  () => _adjustMonths(-1),
                  () => _adjustMonths(1),
                  theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildAdjuster(
                  'RETURN',
                  '${_expectedReturn.toStringAsFixed(1)}%',
                  () => _adjustRate(-0.5),
                  () => _adjustRate(0.5),
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // PROGRESS BAR
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: isOnTrack ? Colors.green : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isOnTrack ? Colors.green : theme.colorScheme.primary)
                              .withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AI PREDICTION OUTPUTS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROJECTED VALUE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CurrencyText(
                        amount: projectedValue,
                        sign: '₹ ',
                        amountStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isOnTrack
                              ? Colors.green
                              : theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                        symbolStyle: TextStyle(
                          fontSize: 14,
                          color: isOnTrack
                              ? Colors.green
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'REQUIRED MTHLY SIP',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: CurrencyText(
                        amount: requiredSip,
                        sign: '₹ ',
                        amountStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isOnTrack
                              ? Colors.green
                              : theme.colorScheme.error,
                          letterSpacing: -0.5,
                        ),
                        symbolStyle: TextStyle(
                          fontSize: 12,
                          color: isOnTrack
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // AI VERDICT & SUGGESTION
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isOnTrack
                    ? Icons.check_circle_rounded
                    : Icons.tips_and_updates_rounded,
                color: isOnTrack ? Colors.green : Colors.orangeAccent.shade700,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOnTrack
                      ? "Excellent! Your current average SIP of ₹${_averageSip.toStringAsFixed(0)} is more than enough to reach your goal by $targetYearStr."
                      : "Your historical SIP is ₹${_averageSip.toStringAsFixed(0)}. You must increase it to ₹${requiredSip.toStringAsFixed(0)}/mo to hit your target by $targetYearStr.",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOnTrack
                        ? Colors.green
                        : Colors.orangeAccent.shade700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- COMPACT STEPPER WIDGET ---
  Widget _buildAdjuster(
    String label,
    String value,
    VoidCallback onDec,
    VoidCallback onInc,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onDec,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onInc,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.add_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
