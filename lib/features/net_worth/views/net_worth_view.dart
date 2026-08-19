import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/net_worth_provider.dart';
import '../components/net_worth_summary_card.dart';
import '../components/net_worth_record_card.dart';
import 'net_worth_reconciliation_page.dart';

class NetWorthView extends StatelessWidget {
  final NetWorthMetrics metrics;
  final AsyncValue<List<NetWorthRecord>> recordsAsync;

  const NetWorthView({
    super.key,
    required this.metrics,
    required this.recordsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Pass the entire record list safely to the Summary Card
    final records = recordsAsync.asData?.value ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Net Worth',
        subtitle: 'FINANCIAL HEALTH',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NetWorthReconciliationPage(),
            ),
          );
        },
        icon: Icons.add_chart_rounded,
        label: 'Reconcile',
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. LIVE SUMMARY CARD (Now receives full record history)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: NetWorthSummaryCard(metrics: metrics, records: records),
            ),
          ),

          // 2. HISTORICAL RECORDS HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingMd,
                DesignTokens.spacingLg,
                DesignTokens.spacingSm,
              ),
              child: Text(
                'HISTORICAL SNAPSHOTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // 3. HISTORICAL RECORDS LIST OR PREMIUM EMPTY STATE
          recordsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: Center(child: Text('Error loading history: $e')),
            ),
            data: (records) {
              if (records.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: PremiumEmptyState(
                    title: 'No Snapshots Yet',
                    subtitle:
                        'Tap "Reconcile" to calculate and save your first monthly net worth snapshot.',
                    icon: Icons.analytics_outlined,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingMd,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: NetWorthRecordCard(record: records[index]),
                    );
                  }, childCount: records.length),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
