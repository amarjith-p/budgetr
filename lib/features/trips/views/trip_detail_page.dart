// lib/features/trips/views/trip_detail_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../transactions/components/transaction_card.dart';
import '../providers/trip_provider.dart';
import '../models/trip_period_model.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';

// --- NEW IMPORT FOR EXPORT ---
import '../services/trip_export_service.dart';

class TripDetailPage extends ConsumerStatefulWidget {
  final Trip trip;
  const TripDetailPage({Key? key, required this.trip}) : super(key: key);

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage> {
  int _tabIndex = 0; // 0 = Transactions, 1 = Categories

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trips = ref.watch(allTripsProvider).asData?.value ?? [];
    final liveTrip =
        trips.where((t) => t.id == widget.trip.id).firstOrNull ?? widget.trip;

    final txs = ref.watch(tripTransactionsProvider(liveTrip));
    final exclusions = jsonDecode(liveTrip.excludedTxIdsJson) as List<dynamic>;

    double totalExpense = 0;
    double totalIncome = 0;
    final Map<String, double> categoryTotals = {};

    for (var txData in txs) {
      final t = txData.transaction;
      if (t.type == 'Expense') {
        totalExpense += t.amount;
        final cat = t.categoryName ?? 'Uncategorized';
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
      } else if (t.type == 'Income') {
        totalIncome += t.amount;
      }
    }

    final netSpend = totalExpense - totalIncome;
    final periods = TripPeriod.parseList(liveTrip.periodsJson);

    int totalDays = 0;
    for (var p in periods) {
      final end = p.end ?? DateTime.now();
      totalDays += end.difference(p.start).inDays;
    }
    if (totalDays < 1) totalDays = 1;
    final dailyAvg = netSpend / totalDays;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: liveTrip.name,
        subtitle: 'TRIP DASHBOARD',
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),

        // --- ADDED EXPORT ICON INTEGRATION ---
        trailingIcon: Icons.ios_share_rounded,
        extraIconColor: theme.colorScheme.primary,
        onTrailingPressed: () {
          HapticFeedback.selectionClick();
          TripExportUI.show(
            context,
            trip: liveTrip,
            netSpend: netSpend,
            totalExpense: totalExpense,
            totalIncome: totalIncome,
            dailyAvg: dailyAvg,
            transactions: txs,
          );
        },
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: _buildSummaryCard(
                theme,
                isDark,
                liveTrip,
                netSpend,
                totalExpense,
                totalIncome,
                dailyAvg,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ModernBoxyToggle(
                labels: const ['Transactions', 'Categories'],
                selectedIndex: _tabIndex,
                onSelected: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _tabIndex = index);
                },
              ),
            ),
          ),

          if (_tabIndex == 0)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final txData = txs[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2.0, right: 8.0),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ConfirmationBottomSheet.show(
                              context,
                              title: 'Exclude from Trip?',
                              description:
                                  'This transaction will be hidden from this trip\'s dashboard and won\'t affect your trip budget. It will safely remain in your main ledger.',
                              confirmText: 'EXCLUDE',
                              isDestructive: true,
                              onConfirm: () {
                                ref
                                    .read(tripActionProvider.notifier)
                                    .toggleExclusion(
                                      liveTrip,
                                      txData.transaction.id,
                                    );
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.remove_circle_outline_rounded,
                                  size: 12,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Exclude from Trip',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      TransactionCard(
                        data: txData,
                        currentAccountId: txData.transaction.accountId,
                        isGlobalView: true,
                      ),
                      const SizedBox(height: 2),
                    ],
                  );
                }, childCount: txs.length),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cat = categoryTotals.keys.elementAt(index);
                  final amt = categoryTotals[cat]!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        CurrencyText(
                          amount: amt,
                          sign: '',
                          amountStyle: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: TransactionColors.getTypeColor(
                              'Expense',
                              theme,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: categoryTotals.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    bool isDark,
    Trip trip,
    double netSpend,
    double expense,
    double income,
    double dailyAvg,
  ) {
    final isActive = trip.status == 'ACTIVE';
    final isPaused = trip.status == 'PAUSED';

    final labelStyle = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      letterSpacing: -0.5,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.0),
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
              Text(
                'NET TRIP SPEND',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (isActive
                              ? Colors.green
                              : (isPaused
                                    ? Colors.orange
                                    : theme.colorScheme.onSurfaceVariant))
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trip.status,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isActive
                        ? Colors.green
                        : (isPaused
                              ? Colors.orange
                              : theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CurrencyText(
            amount: netSpend.abs(),
            sign: netSpend < 0 ? '+  ' : '',
            amountStyle: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            symbolStyle: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),

          if (trip.budget != null && trip.budget! > 0) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                double progress = (netSpend / trip.budget!).clamp(0.0, 1.0);
                bool overBudget = netSpend > trip.budget!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Budget Used', style: labelStyle),
                        Text(
                          overBudget
                              ? 'OVER BUDGET'
                              : '${CurrencyFormatter.format(trip.budget! - netSpend)} left',
                          style: labelStyle.copyWith(
                            color: overBudget
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 4,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: overBudget
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL EXPENSE', style: labelStyle),
                    const SizedBox(height: 6),
                    CurrencyText(
                      amount: expense,
                      sign: '',
                      amountStyle: valueStyle,
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 16,
                thickness: 1,
                color: theme.dividerColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL INCOME', style: labelStyle),
                    const SizedBox(height: 6),
                    CurrencyText(
                      amount: income,
                      sign: '',
                      amountStyle: valueStyle,
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 16,
                thickness: 1,
                color: theme.dividerColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DAILY AVG', style: labelStyle),
                    const SizedBox(height: 6),
                    CurrencyText(
                      amount: dailyAvg.abs(),
                      sign: '',
                      amountStyle: valueStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (trip.status != 'COMPLETED') ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isPaused ? 'RESUME' : 'PAUSE',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(tripActionProvider.notifier)
                          .updateTripStatus(
                            trip,
                            isPaused ? 'ACTIVE' : 'PAUSED',
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.stop_rounded, size: 16),
                    label: const Text(
                      'END TRIP',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(tripActionProvider.notifier)
                          .updateTripStatus(trip, 'COMPLETED');
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
