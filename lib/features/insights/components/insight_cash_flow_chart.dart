// features/insights/components/insight_cash_flow_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../transactions/services/transaction_service.dart';
import '../providers/insight_filter_provider.dart';

enum _Granularity { day, week, month, quarter }

class _CashFlowBucket {
  final DateTime date;
  final String label;
  double income = 0.0;
  double expense = 0.0;

  _CashFlowBucket({required this.date, required this.label});

  double get net => income - expense;
}

class InsightCashFlowChart extends StatelessWidget {
  final List<TransactionWithDetails> allTransactions;
  final InsightFilterState filterState;

  const InsightCashFlowChart({
    Key? key,
    required this.allTransactions,
    required this.filterState,
  }) : super(key: key);

  // --- NEW: Helper method to keep Y-Axis labels clean and uniform ---
  Widget _buildYAxisLabel(double amount, String sign, ThemeData theme) {
    if (amount == 0) {
      return SizedBox(
        height: 14,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '0',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 14,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: CurrencyText(
          amount: amount,
          sign: sign,
          amountStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          symbolStyle: TextStyle(
            fontSize: 8,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Determine Date Boundaries
    final now = DateTime.now();
    DateTime currentStart = DateTime(2000);
    DateTime currentEnd = DateTime(2100);

    switch (filterState.timeFrame) {
      case 'Today':
        currentStart = DateTime(now.year, now.month, now.day);
        currentEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Week':
        currentStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        currentEnd = currentStart.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'This Month':
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Last Month':
        currentStart = DateTime(now.year, now.month - 1, 1);
        currentEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'This Year':
        currentStart = DateTime(now.year, 1, 1);
        currentEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'Last Year':
        currentStart = DateTime(now.year - 1, 1, 1);
        currentEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      case 'Custom Range':
        if (filterState.customRange != null) {
          currentStart = filterState.customRange!.start;
          currentEnd = filterState.customRange!.end.add(
            const Duration(hours: 23, minutes: 59, seconds: 59),
          );
        }
        break;
      case 'All Time':
      default:
        currentStart = DateTime(2100);
        currentEnd = DateTime(2000);
        for (var t in allTransactions) {
          if (t.transaction.date.isBefore(currentStart))
            currentStart = t.transaction.date;
          if (t.transaction.date.isAfter(currentEnd))
            currentEnd = t.transaction.date;
        }
        if (currentStart.year == 2100) {
          currentStart = DateTime.now().subtract(const Duration(days: 30));
          currentEnd = DateTime.now();
        }
        break;
    }

    // 2. Intelligent Granularity Calculation
    final int daysDiff = currentEnd.difference(currentStart).inDays;
    _Granularity granularity;

    if (daysDiff <= 31) {
      granularity = _Granularity.day;
    } else if (daysDiff <= 183) {
      granularity = _Granularity.week;
    } else if (daysDiff <= 366) {
      granularity = _Granularity.month;
    } else {
      granularity = _Granularity.quarter;
    }

    // 3. Initialize Continuous Timeline Buckets
    final List<_CashFlowBucket> buckets = [];
    DateTime pointer = DateTime(
      currentStart.year,
      currentStart.month,
      currentStart.day,
    );

    if (granularity == _Granularity.week) {
      pointer = pointer.subtract(Duration(days: pointer.weekday - 1));
    } else if (granularity == _Granularity.month) {
      pointer = DateTime(pointer.year, pointer.month, 1);
    } else if (granularity == _Granularity.quarter) {
      final quarterStartMonth = ((pointer.month - 1) ~/ 3) * 3 + 1;
      pointer = DateTime(pointer.year, quarterStartMonth, 1);
    }

    while (pointer.isBefore(currentEnd) ||
        pointer.isAtSameMomentAs(currentEnd)) {
      String label = '';
      if (granularity == _Granularity.day) {
        label = DateFormat('dd MMM').format(pointer);
      } else if (granularity == _Granularity.week) {
        label = DateFormat('dd MMM').format(pointer);
      } else if (granularity == _Granularity.month) {
        label = DateFormat('MMM yy').format(pointer);
      } else {
        final quarter = ((pointer.month - 1) ~/ 3) + 1;
        label = 'Q$quarter ${DateFormat('yy').format(pointer)}';
      }

      buckets.add(_CashFlowBucket(date: pointer, label: label));

      if (granularity == _Granularity.day) {
        pointer = pointer.add(const Duration(days: 1));
      } else if (granularity == _Granularity.week) {
        pointer = pointer.add(const Duration(days: 7));
      } else if (granularity == _Granularity.month) {
        pointer = DateTime(pointer.year, pointer.month + 1, 1);
      } else {
        pointer = DateTime(pointer.year, pointer.month + 3, 1);
      }
    }

    // 4. Process Transactions into Buckets
    double maxAmount = 1.0;
    double totalPeriodIncome = 0;
    double totalPeriodExpense = 0;

    for (var t in allTransactions) {
      final tx = t.transaction;
      final accType = t.account.type;

      if (filterState.accountId != null) {
        if (filterState.accountId == 'ASSETS') {
          if (accType == 'Credit Cards' || accType == 'Loan') continue;
        } else if (filterState.accountId == 'CREDIT') {
          if (accType != 'Credit Cards' && accType != 'Loan') continue;
        } else if (tx.accountId != filterState.accountId) {
          continue;
        }
      }

      if (tx.date.isBefore(currentStart) || tx.date.isAfter(currentEnd))
        continue;
      if (tx.type == 'Transfer') continue;
      if (tx.type == 'Income' && t.category?.name.toLowerCase() == 'repayment')
        continue;

      _CashFlowBucket? targetBucket;
      for (int i = buckets.length - 1; i >= 0; i--) {
        if (tx.date.isAfter(buckets[i].date) ||
            tx.date.isAtSameMomentAs(buckets[i].date)) {
          targetBucket = buckets[i];
          break;
        }
      }

      if (targetBucket != null) {
        if (tx.type == 'Income') {
          targetBucket.income += tx.amount;
          totalPeriodIncome += tx.amount;
          if (targetBucket.income > maxAmount) maxAmount = targetBucket.income;
        } else if (tx.type == 'Expense') {
          targetBucket.expense += tx.amount;
          totalPeriodExpense += tx.amount;
          if (targetBucket.expense > maxAmount)
            maxAmount = targetBucket.expense;
        }
      }
    }

    // 5. PURGE EMPTY BUCKETS
    buckets.removeWhere((b) => b.income == 0 && b.expense == 0);

    if (buckets.isEmpty) {
      return const SizedBox.shrink();
    }

    final double chartMaxHeight = 180.0;
    final double halfHeight = chartMaxHeight / 2;
    final double barWidth = granularity == _Granularity.day ? 12.0 : 18.0;
    final double itemSpacing = granularity == _Granularity.day ? 12.0 : 20.0;
    final double netTotal = totalPeriodIncome - totalPeriodExpense;

    String headerTitle;
    switch (granularity) {
      case _Granularity.day:
        headerTitle = 'DAILY CASH FLOW';
        break;
      case _Granularity.week:
        headerTitle = 'WEEKLY CASH FLOW';
        break;
      case _Granularity.month:
        headerTitle = 'MONTHLY CASH FLOW';
        break;
      case _Granularity.quarter:
        headerTitle = 'QUARTERLY CASH FLOW';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignTokens.spacingXl),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              headerTitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NET: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: netTotal >= 0
                        ? Colors.green
                        : theme.colorScheme.error,
                  ),
                ),
                CurrencyText(
                  amount: netTotal.abs(),
                  sign: netTotal >= 0 ? '+₹ ' : '-₹ ',
                  amountStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: netTotal >= 0
                        ? Colors.green
                        : theme.colorScheme.error,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 9,
                    color:
                        (netTotal >= 0 ? Colors.green : theme.colorScheme.error)
                            .withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingMd),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 0, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FIXED Y-AXIS: Now plots 5 distinct reference points ---
              SizedBox(
                width: 42,
                height: chartMaxHeight + 24,
                child: Column(
                  children: [
                    SizedBox(
                      height: chartMaxHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildYAxisLabel(maxAmount, '₹ ', theme),
                          _buildYAxisLabel(maxAmount / 2, '₹ ', theme),
                          _buildYAxisLabel(0, '', theme),
                          _buildYAxisLabel(maxAmount / 2, '-₹ ', theme),
                          _buildYAxisLabel(maxAmount, '-₹ ', theme),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ), // Spacer reserved for X-axis text
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: SizedBox(
                  height: chartMaxHeight + 24,
                  child: Stack(
                    children: [
                      // --- FIXED GRID LINES: Now accurately match the 5 Y-Axis labels ---
                      Positioned(
                        top: 7,
                        left: 0,
                        right:
                            0, // Aligns perfectly to the center of the 14px high text
                        height: chartMaxHeight - 14,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.3),
                            ), // Max
                            Container(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.15),
                            ), // 50% Max
                            Container(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.8),
                            ), // Zero
                            Container(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.15),
                            ), // 50% Min
                            Container(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.3),
                            ), // Min
                          ],
                        ),
                      ),

                      ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 16),
                        itemCount: buckets.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(width: itemSpacing),
                        itemBuilder: (context, index) {
                          final bucket = buckets[index];
                          final incomeHeight =
                              (bucket.income / maxAmount) * halfHeight;
                          final expenseHeight =
                              (bucket.expense / maxAmount) * halfHeight;

                          final netSign = bucket.net >= 0 ? '+' : '-';
                          final tooltipMsg =
                              'In: +₹ ${CurrencyFormatter.format(bucket.income)}\nOut: -₹ ${CurrencyFormatter.format(bucket.expense)}\nNet: $netSign₹ ${CurrencyFormatter.format(bucket.net.abs())}';

                          return Tooltip(
                            message: tooltipMsg,
                            triggerMode: TooltipTriggerMode.tap,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: halfHeight,
                                  width: barWidth,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(
                                        begin: 0.0,
                                        end: incomeHeight,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 1000,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, val, child) {
                                        return Container(
                                          width: barWidth,
                                          height: val,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.green.shade600,
                                                Colors.green.shade400,
                                              ],
                                            ),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(2),
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                Container(
                                  height: 2,
                                  width: barWidth + (itemSpacing / 2),
                                  color: theme.dividerColor,
                                ),

                                SizedBox(
                                  height: halfHeight,
                                  width: barWidth,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(
                                        begin: 0.0,
                                        end: expenseHeight,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 1000,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, val, child) {
                                        return Container(
                                          width: barWidth,
                                          height: val,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                theme.colorScheme.error,
                                                theme.colorScheme.error
                                                    .withOpacity(0.6),
                                              ],
                                            ),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  bottom: Radius.circular(2),
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  bucket.label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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
