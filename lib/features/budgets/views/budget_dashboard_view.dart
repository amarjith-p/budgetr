import 'package:budgetr/features/budgets/views/monthly_budget_transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../transactions/providers/transaction_provider.dart';
import 'budget_transactions_page.dart';

// --- IMPORT OUR COMPONENTS ---
import '../components/budget_summary_card.dart';
import '../components/budget_progress_card.dart';

class BudgetDashboardView extends ConsumerWidget {
  final MonthlyBudget budget;
  
  const BudgetDashboardView({Key? key, required this.budget}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bucketsAsync = ref.watch(bucketsStreamProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    
    final effectiveIncome = (budget.salaryIncome + budget.extraIncome) - budget.deductions;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- POM COMPONENT: SUMMARY CARD ---
          BudgetSummaryCard(
            salaryIncome: budget.salaryIncome,
            extraIncome: budget.extraIncome,
            deductions: budget.deductions,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MonthlyBudgetTransactionsPage(
                    month: budget.month,
                    year: budget.year,
                    effectiveIncome: effectiveIncome,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          Text('Bucket Allocations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          const SizedBox(height: 16),

          // --- POM COMPONENT: PROGRESS CARDS ---
          bucketsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
            data: (buckets) {
              final txs = transactionsAsync.asData?.value ?? [];
              
              // Filter to just this month's expenses
              final monthlyExpenses = txs.where((data) {
                final tx = data.transaction;
                return tx.type == 'Expense' && tx.date.month == budget.month && tx.date.year == budget.year;
              }).toList();

              // Calculate total spent per bucket ID
              Map<int, double> spentPerBucket = {};
              for (var txData in monthlyExpenses) {
                final bId = txData.transaction.bucketId ?? -1;
                spentPerBucket[bId] = (spentPerBucket[bId] ?? 0.0) + txData.transaction.amount;
              }

              return Column(
                children: buckets.map((bucket) {
                  final allocated = effectiveIncome * (bucket.percentage / 100);
                  final spent = spentPerBucket[bucket.id] ?? 0.0;

                  return BudgetProgressCard(
                    bucketName: bucket.name,
                    percentage: bucket.percentage,
                    spent: spent,
                    allocated: allocated,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BudgetTransactionsPage(
                            bucket: bucket,
                            month: budget.month,
                            year: budget.year,
                            allocatedAmount: allocated,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            }
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}