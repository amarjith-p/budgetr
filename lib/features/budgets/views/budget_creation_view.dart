import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/budget_provider.dart';

class BudgetCreationView extends ConsumerStatefulWidget {
  final DateTime date;
  const BudgetCreationView({Key? key, required this.date}) : super(key: key);

  @override
  ConsumerState<BudgetCreationView> createState() => _BudgetCreationViewState();
}

class _BudgetCreationViewState extends ConsumerState<BudgetCreationView> {
  final _salaryCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  final _deductionCtrl = TextEditingController();
  double _effectiveIncome = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _salaryCtrl.addListener(_calculateLive);
    _extraCtrl.addListener(_calculateLive);
    _deductionCtrl.addListener(_calculateLive);
  }

  @override
  void dispose() {
    _salaryCtrl.dispose(); _extraCtrl.dispose(); _deductionCtrl.dispose();
    super.dispose();
  }

  void _calculateLive() {
    final salary = double.tryParse(_salaryCtrl.text) ?? 0.0;
    final extra = double.tryParse(_extraCtrl.text) ?? 0.0;
    final ded = double.tryParse(_deductionCtrl.text) ?? 0.0;
    setState(() {
      _effectiveIncome = (salary + extra) - ded;
      if (_effectiveIncome < 0) _effectiveIncome = 0;
    });
  }

  Future<void> _submit() async {
    if (_effectiveIncome <= 0) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    
    await ref.read(budgetServiceProvider).saveBudget(
      month: widget.date.month,
      year: widget.date.year,
      salary: double.tryParse(_salaryCtrl.text) ?? 0.0,
      extra: double.tryParse(_extraCtrl.text) ?? 0.0,
      deductions: double.tryParse(_deductionCtrl.text) ?? 0.0,
    );
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bucketsAsync = ref.watch(bucketsStreamProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Establish Baseline', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          
          ModernBoxyInput(controller: _salaryCtrl, labelText: 'Salary Income (₹)', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ModernBoxyInput(controller: _extraCtrl, labelText: 'Extra Income (₹)', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: ModernBoxyInput(controller: _deductionCtrl, labelText: 'Deductions (₹)', keyboardType: TextInputType.number)),
            ],
          ),
          
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text('EFFECTIVE INCOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)),
                Text('₹${_effectiveIncome.toStringAsFixed(2)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: -1.0)),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Text('Live Allocations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          
          bucketsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
            data: (buckets) {
              if (buckets.isEmpty) return const Text('No buckets configured yet.');
              
              return Column(
                children: buckets.map((bucket) {
                  final allocatedAmount = _effectiveIncome * (bucket.percentage / 100);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                child: Text('${bucket.percentage.toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                              ),
                              const SizedBox(width: 12),
                              Text(bucket.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                            ],
                          ),
                          Text('₹${allocatedAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          
          const SizedBox(height: 24),
          ModernBoxyButton(
            onPressed: _effectiveIncome > 0 ? _submit : null, 
            label: 'CREATE BUDGET',
            isLoading: _isLoading,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}