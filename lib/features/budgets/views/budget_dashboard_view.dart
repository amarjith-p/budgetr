import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../transactions/providers/transaction_provider.dart';

import '../services/budget_service.dart';
import '../components/budget_summary_card.dart';
import '../components/budget_progress_card.dart';
import '../components/close_budget_confirmation_sheet.dart'; // <-- POM COMPONENT IMPORT
import 'budget_transactions_page.dart';
import 'monthly_budget_transactions_page.dart';

class BudgetDashboardView extends ConsumerWidget {
  final MonthlyBudget budget;
  
  const BudgetDashboardView({Key? key, required this.budget}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final effectiveIncome = (budget.salaryIncome + budget.extraIncome) - budget.deductions;

    final List<BudgetBucket> snapshotBuckets = [];
    if (budget.bucketsSnapshot != null) {
      try {
        final List<dynamic> decoded = jsonDecode(budget.bucketsSnapshot!);
        for (var b in decoded) {
          snapshotBuckets.add(BudgetBucket(
            id: b['id'] as int,
            name: b['name'] as String,
            percentage: (b['percentage'] as num).toDouble(),
            createdAt: DateTime.now(), 
          ));
        }
      } catch (e) {
        // Fallback
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BudgetSummaryCard(
            salaryIncome: budget.salaryIncome,
            extraIncome: budget.extraIncome,
            deductions: budget.deductions,
            isClosed: budget.isClosed, 
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyBudgetTransactionsPage(month: budget.month, year: budget.year, effectiveIncome: effectiveIncome)));
            },
            onEdit: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: DesignTokens.bottomSheetShape,
                builder: (ctx) => _BudgetEditSheet(budget: budget),
              );
            },
            onDelete: () async {
              HapticFeedback.heavyImpact();
              final confirm = await ConfirmationBottomSheet.show(
                context,
                title: 'Delete Budget?',
                description: 'This budget will be permanently removed. Your logged transactions will remain entirely safe and mathematically intact with their historical bucket assignments.',
                confirmText: 'DELETE BUDGET',
                cancelText: 'CANCEL',
                isDestructive: true,
                onConfirm: () {},
              );
              
              if (confirm == true) {
                final db = ref.read(databaseProvider);
                final budgetService = BudgetService(db);
                await budgetService.deleteBudget(budget.id);
              }
            },
            onClose: () async {
              HapticFeedback.heavyImpact();
              
              final txs = transactionsAsync.asData?.value ?? [];
              final monthlyExpenses = txs.where((data) => data.transaction.type == 'Expense' && data.transaction.date.month == budget.month && data.transaction.date.year == budget.year).toList();
              
              double totalSpent = 0.0;
              double outOfBucket = 0.0;
              Map<int, double> bucketSpends = {};

              for(var e in monthlyExpenses) {
                totalSpent += e.transaction.amount;
                final bId = e.transaction.bucketId;
                if(bId == null || bId == -1) {
                  outOfBucket += e.transaction.amount;
                } else {
                  bucketSpends[bId] = (bucketSpends[bId] ?? 0.0) + e.transaction.amount;
                }
              }
              
              final totalRemaining = effectiveIncome - totalSpent;
              final budgetedSpends = totalSpent - outOfBucket;
              final budgetedRemaining = effectiveIncome - budgetedSpends;

              List<Map<String, dynamic>> bucketDetailsList = [];
              for (var b in snapshotBuckets) {
                final allocated = effectiveIncome * (b.percentage / 100);
                final spent = bucketSpends[b.id] ?? 0.0;
                final remaining = allocated - spent;
                bucketDetailsList.add({
                  'name': b.name,
                  'allocated': allocated,
                  'spent': spent,
                  'remaining': remaining,
                });
              }
              final bucketDetailsJson = jsonEncode(bucketDetailsList);

              // --- POM INVOCATION: Use the new globally extracted sheet ---
              final confirm = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: DesignTokens.bottomSheetShape,
                builder: (ctx) => CloseBudgetConfirmationSheet(
                  salaryIncome: budget.salaryIncome,
                  extraIncome: budget.extraIncome,
                  deductions: budget.deductions,
                  effectiveIncome: effectiveIncome,
                  totalSpent: totalSpent,
                  outOfBucket: outOfBucket,
                  totalRemaining: totalRemaining,
                  budgetedRemaining: budgetedRemaining,
                  bucketDetails: bucketDetailsList,
                ),
              );
              
              if (confirm == true) {
                final db = ref.read(databaseProvider);
                final budgetService = BudgetService(db);
                await budgetService.closeBudget(
                  budgetId: budget.id,
                  salaryIncome: budget.salaryIncome,
                  extraIncome: budget.extraIncome,
                  deductions: budget.deductions,
                  effectiveIncome: effectiveIncome,
                  totalSpent: totalSpent,
                  outOfBucket: outOfBucket,
                  totalRemaining: totalRemaining,
                  budgetedRemaining: budgetedRemaining,
                  bucketDetailsJson: bucketDetailsJson,
                );
              }
            },
          ),
          
          const SizedBox(height: 32),
          Text('Bucket Allocations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          const SizedBox(height: 16),

          if (snapshotBuckets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No bucket allocations found in this budget\'s history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                final txs = transactionsAsync.asData?.value ?? [];
                final monthlyExpenses = txs.where((data) => data.transaction.type == 'Expense' && data.transaction.date.month == budget.month && data.transaction.date.year == budget.year).toList();

                Map<int, double> spentPerBucket = {};
                for (var txData in monthlyExpenses) {
                  final bId = txData.transaction.bucketId ?? -1;
                  spentPerBucket[bId] = (spentPerBucket[bId] ?? 0.0) + txData.transaction.amount;
                }

                return Column(
                  children: snapshotBuckets.map((bucket) {
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

// --- EDIT BUDGET BOTTOM SHEET ---
class _BudgetEditSheet extends ConsumerStatefulWidget {
  final MonthlyBudget budget;
  const _BudgetEditSheet({required this.budget});

  @override
  ConsumerState<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<_BudgetEditSheet> {
  late TextEditingController _salaryCtrl;
  late TextEditingController _extraCtrl;
  late TextEditingController _deductionCtrl;

  @override
  void initState() {
    super.initState();
    _salaryCtrl = TextEditingController(text: widget.budget.salaryIncome.toString());
    _extraCtrl = TextEditingController(text: widget.budget.extraIncome.toString());
    _deductionCtrl = TextEditingController(text: widget.budget.deductions.toString());
  }

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _extraCtrl.dispose();
    _deductionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final db = ref.read(databaseProvider);
    final budgetService = BudgetService(db);

    await budgetService.saveBudget(
      month: widget.budget.month,
      year: widget.budget.year,
      salary: double.tryParse(_salaryCtrl.text) ?? 0.0,
      extra: double.tryParse(_extraCtrl.text) ?? 0.0,
      deductions: double.tryParse(_deductionCtrl.text) ?? 0.0,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + DesignTokens.spacingLg,
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: DesignTokens.spacingSm,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Edit Budget', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: DesignTokens.spacingLg),
            
            ModernBoxyInput(controller: _salaryCtrl, labelText: 'Salary Income (₹)', keyboardType: TextInputType.number),
            const SizedBox(height: DesignTokens.spacingMd),
            Row(
              children: [
                Expanded(child: ModernBoxyInput(controller: _extraCtrl, labelText: 'Extra Income (₹)', keyboardType: TextInputType.number)),
                const SizedBox(width: DesignTokens.spacingMd),
                Expanded(child: ModernBoxyInput(controller: _deductionCtrl, labelText: 'Deductions (₹)', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            
            ModernBoxyButton(
              onPressed: _submit,
              label: 'SAVE CHANGES',
            ),
          ],
        ),
      ),
    );
  }
}