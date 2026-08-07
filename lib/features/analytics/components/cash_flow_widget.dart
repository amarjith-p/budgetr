// features/analytics/components/cash_flow_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../accounts/providers/account_provider.dart';
import '../../transactions/providers/transaction_provider.dart';

import 'analytics_account_selection_sheet.dart';
import 'analytics_timeframe_selector.dart';
import 'analytics_account_selector_pill.dart';

class CashFlowWidget extends ConsumerStatefulWidget {
  const CashFlowWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<CashFlowWidget> createState() => _CashFlowWidgetState();
}

class _CashFlowWidgetState extends ConsumerState<CashFlowWidget> {
  String _accountFilterId = 'ALL';
  TrendTimeframe _timeframe = TrendTimeframe.currentMonth;

  DateTime? _customStart;
  DateTime? _customEnd;

  bool _hideOutOfBucket = false;

  Future<void> _pickCustomDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeframe = TrendTimeframe.custom;
        _customStart = picked.start;
        _customEnd = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  Widget _buildFlowBar(
    String label,
    double amount,
    double pct,
    Color color,
    ThemeData theme,
    String sign,
  ) {
    if (amount == 0) sign = '₹ ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: CurrencyText(
                  amount: amount,
                  sign: sign,
                  amountStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBattleBar(
    String label,
    double income,
    double expense,
    double netPosition,
    ThemeData theme,
    String sign,
  ) {
    final total = income + expense;
    final int incFlex = total == 0 ? 1 : (income / total * 1000).toInt();
    final int expFlex = total == 0 ? 1 : (expense / total * 1000).toInt();

    final Color netColor = netPosition >= 0
        ? Colors.green
        : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: CurrencyText(
                  amount: netPosition.abs(),
                  sign: sign,
                  amountStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: netColor,
                    letterSpacing: -0.5,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 10,
                    color: netColor.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: incFlex,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    flex: expFlex,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 2,
                  color: theme.scaffoldBackgroundColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INCOME',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: Colors.green.withOpacity(0.8),
              ),
            ),
            Text(
              'EXPENSE',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.error.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) =>
          SizedBox(height: 180, child: Center(child: Text('Error: $e'))),
      data: (rawAccounts) {
        return transactionsAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) =>
              SizedBox(height: 180, child: Center(child: Text('Error: $e'))),
          data: (transactions) {
            final targetAccounts = rawAccounts.where((a) {
              if (a.type == 'Loan') return false;
              if (_accountFilterId == 'ASSETS' && a.type == 'Credit Cards')
                return false;
              if (_accountFilterId == 'CREDIT' && a.type != 'Credit Cards')
                return false;
              if (_accountFilterId != 'ALL' &&
                  _accountFilterId != 'ASSETS' &&
                  _accountFilterId != 'CREDIT') {
                return a.id == _accountFilterId;
              }
              return true;
            }).toList();

            final targetIds = targetAccounts.map((a) => a.id).toSet();

            DateTime now = DateTime.now();
            DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
            DateTime start;

            if (_timeframe == TrendTimeframe.custom &&
                _customStart != null &&
                _customEnd != null) {
              start = DateTime(
                _customStart!.year,
                _customStart!.month,
                _customStart!.day,
              );
              end = _customEnd!;
            } else {
              switch (_timeframe) {
                case TrendTimeframe.week:
                  start = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(const Duration(days: 6));
                  break;
                case TrendTimeframe.month:
                  start = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(const Duration(days: 29));
                  break;
                case TrendTimeframe.currentMonth:
                  start = DateTime(now.year, now.month, 1);
                  break;
                case TrendTimeframe.lastMonth:
                  int targetYear = now.month == 1 ? now.year - 1 : now.year;
                  int targetMonth = now.month == 1 ? 12 : now.month - 1;
                  start = DateTime(targetYear, targetMonth, 1);
                  end = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);
                  break;
                case TrendTimeframe.year:
                  start = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(const Duration(days: 364));
                  break;
                case TrendTimeframe.allTime:
                default:
                  start = DateTime(2000);
                  break;
              }
            }

            double totalIncome = 0.0;
            double totalExpense = 0.0;

            for (var txData in transactions) {
              final t = txData.transaction;
              final date = t.date;

              if (t.id.endsWith('_SOURCETRANSFER')) continue;
              if (date.isBefore(start) || date.isAfter(end)) continue;

              bool fromTarget = targetIds.contains(t.accountId);
              bool isOutOfBucket = t.bucketId == null || t.bucketId == -1;

              // --- FIX: Strictly isolated to Income and Expense types ---
              if (t.type == 'Income' && fromTarget) {
                totalIncome += t.amount;
              } else if (t.type == 'Expense' && fromTarget) {
                if (_hideOutOfBucket && isOutOfBucket) continue;
                totalExpense += t.amount;
              }
            }

            double netPosition = totalIncome - totalExpense;
            String netSign = netPosition > 0
                ? '+₹ '
                : (netPosition < 0 ? '-₹ ' : '₹ ');

            double maxVal = max(totalIncome, totalExpense);
            if (maxVal == 0) maxVal = 1;

            double incPct = (totalIncome / maxVal).clamp(0.0, 1.0);
            double expPct = (totalExpense / maxVal).clamp(0.0, 1.0);

            String dropdownLabel = 'All Accounts';
            if (_accountFilterId == 'ASSETS')
              dropdownLabel = 'Assets Only';
            else if (_accountFilterId == 'CREDIT')
              dropdownLabel = 'Liabilities Only';
            else if (_accountFilterId != 'ALL') {
              dropdownLabel =
                  rawAccounts
                      .where((a) => a.id == _accountFilterId)
                      .firstOrNull
                      ?.name ??
                  'Unknown';
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.swap_vert_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CASH FLOW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      AnalyticsAccountSelectorPill(
                        label: dropdownLabel,
                        onTap: () => AnalyticsAccountSelectionSheet.show(
                          context,
                          rawAccounts,
                          _accountFilterId,
                          (newId) =>
                              setState(() => _accountFilterId = newId ?? 'ALL'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildFlowBar(
                    'TOTAL INCOME',
                    totalIncome,
                    incPct,
                    Colors.green,
                    theme,
                    '+₹ ',
                  ),
                  const SizedBox(height: 10),
                  _buildFlowBar(
                    'TOTAL EXPENSE',
                    totalExpense,
                    expPct,
                    theme.colorScheme.error,
                    theme,
                    '-₹ ',
                  ),
                  const SizedBox(height: 10),

                  _buildBattleBar(
                    'NET POSITION',
                    totalIncome,
                    totalExpense,
                    netPosition,
                    theme,
                    netSign,
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(isDark ? 0.3 : 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.donut_small_rounded,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Budgeted Expenses Only',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: _hideOutOfBucket,
                            activeColor: theme.colorScheme.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              setState(() => _hideOutOfBucket = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  AnalyticsTimeframeSelector(
                    selectedTimeframe: _timeframe,
                    onSelected: (type) => setState(() => _timeframe = type),
                    onCustomTapped: _pickCustomDateRange,
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
