import 'dart:ui';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/date_time_constants.dart';
import '../providers/budget_provider.dart';
import 'budget_creation_view.dart';
import 'budget_dashboard_view.dart';

class BudgetManagementTab extends ConsumerWidget {
  const BudgetManagementTab({Key? key}) : super(key: key);

  void _shiftMonth(WidgetRef ref, int offset) {
    final current = ref.read(budgetDateProvider);
    ref.read(budgetDateProvider.notifier).state = DateTime(
      current.year,
      current.month + offset,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(budgetDateProvider);
    final budgetAsync = ref.watch(monthlyBudgetStreamProvider);
    final theme = Theme.of(context);

    final monthString =
        '${DateTimeConstants.fullMonths[selectedDate.month - 1]} ${selectedDate.year}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // STICKY MONTH PICKER
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: theme.scaffoldBackgroundColor.withOpacity(0.85),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => _shiftMonth(ref, -1),
                    ),
                    Text(
                      monthString.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => _shiftMonth(ref, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: budgetAsync.when(
              loading: () => const Center(
                child: FuturisticLoader(
                  size: 80,
                  label: "LOADING BUCKET CONFIGURATIONS..",
                ),
              ),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (budget) {
                if (budget == null) {
                  return BudgetCreationView(date: selectedDate);
                }
                return BudgetDashboardView(budget: budget);
              },
            ),
          ),
        ],
      ),
    );
  }
}
