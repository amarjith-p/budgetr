import 'package:budgetr/features/analytics/components/closed_budget_snapshot_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pinned_widgets_provider.dart';

import 'balance_trend_widget.dart';
import 'cash_flow_widget.dart';
import 'spending_widget.dart';
import 'credit_tracker_widget.dart';
import 'budget_simulator_widget.dart';

class PinnedWidgetsDisplay extends ConsumerWidget {
  const PinnedWidgetsDisplay({Key? key}) : super(key: key);

  Widget _getWidgetInstance(String id) {
    switch (id) {
      case 'BALANCE_TREND':
        return const BalanceTrendWidget();
      case 'CASH_FLOW':
        return const CashFlowWidget();
      case 'SPENDING':
        return const SpendingWidget();
      case 'CREDIT_TRACKER':
        return const CreditTrackerWidget();
      case 'BUDGET_SIMULATOR':
        return const BudgetSimulatorWidget();
      case 'BUDGET_SNAPSHOT':
        return const ClosedBudgetSnapshotWidget();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedWidgets = ref.watch(pinnedWidgetsProvider);

    // Completely clean Home Tab if nothing is pinned.
    if (pinnedWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: pinnedWidgets
          .map(
            (id) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _getWidgetInstance(id),
            ),
          )
          .toList(),
    );
  }
}
