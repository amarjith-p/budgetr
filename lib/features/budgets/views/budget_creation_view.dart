import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/inline_calculator_pad.dart';
import '../../../core/utils/bodmas_calculator.dart';
import '../../../core/constants/date_time_constants.dart';
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
  
  final _salaryFocus = FocusNode();
  final _extraFocus = FocusNode();
  final _deductionFocus = FocusNode();

  TextEditingController? _activeCalcController;
  
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
    _salaryCtrl.dispose();
    _extraCtrl.dispose();
    _deductionCtrl.dispose();
    _salaryFocus.dispose();
    _extraFocus.dispose();
    _deductionFocus.dispose();
    super.dispose();
  }

  void _calculateLive() {
    double parseSafe(String val) {
      if (val.trim().isEmpty) return 0.0;
      final eval = BodmasCalculator.evaluate(val);
      return double.tryParse(eval) ?? 0.0;
    }

    final salary = parseSafe(_salaryCtrl.text);
    final extra = parseSafe(_extraCtrl.text);
    final ded = parseSafe(_deductionCtrl.text);
    
    setState(() {
      _effectiveIncome = (salary + extra) - ded;
      if (_effectiveIncome < 0) _effectiveIncome = 0;
    });
  }

  // --- CALCULATOR INTEGRATION WITH SMART AUTO-SCROLL ---
  void _openCalculatorFor(TextEditingController controller, FocusNode focusNode) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    if (_activeCalcController != null && _activeCalcController != controller) {
      _closeCalculatorSafely(reopen: true);
    }
    
    setState(() => _activeCalcController = controller);
    if (!focusNode.hasFocus) focusNode.requestFocus();

    // SMOOTH SCROLL FIX: Ensures the active input is always perfectly visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.context != null && mounted) {
        Scrollable.ensureVisible(
          focusNode.context!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          // 0.5 centers the input in the visible area above the calculator
          alignment: 0.5, 
        );
      }
    });
  }

  void _closeCalculatorSafely({bool reopen = false}) {
    if (_activeCalcController != null) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty ? '' : BodmasCalculator.evaluate(text);
      if (!reopen) {
        setState(() => _activeCalcController = null);
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _handleCalcNext() {
    if (_activeCalcController == _salaryCtrl) _openCalculatorFor(_extraCtrl, _extraFocus);
    else if (_activeCalcController == _extraCtrl) _openCalculatorFor(_deductionCtrl, _deductionFocus);
  }

  void _handleCalcPrev() {
    if (_activeCalcController == _deductionCtrl) _openCalculatorFor(_extraCtrl, _extraFocus);
    else if (_activeCalcController == _extraCtrl) _openCalculatorFor(_salaryCtrl, _salaryFocus);
  }

  Future<void> _submit() async {
    _closeCalculatorSafely();
    if (_effectiveIncome <= 0) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    
    await ref.read(budgetServiceProvider).saveBudget(
      month: widget.date.month,
      year: widget.date.year,
      salary: double.tryParse(BodmasCalculator.evaluate(_salaryCtrl.text)) ?? 0.0,
      extra: double.tryParse(BodmasCalculator.evaluate(_extraCtrl.text)) ?? 0.0,
      deductions: double.tryParse(BodmasCalculator.evaluate(_deductionCtrl.text)) ?? 0.0,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bucketsAsync = ref.watch(bucketsStreamProvider);
    final monthName = DateTimeConstants.fullMonths[widget.date.month - 1];
    final showCalculator = _activeCalcController != null;

    return Column(
      children: [
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: DesignTokens.spacingLg,
              right: DesignTokens.spacingLg,
              top: DesignTokens.spacingMd,
              bottom: showCalculator ? DesignTokens.spacingLg : DesignTokens.spacingXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HERO: EFFECTIVE INCOME ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.2 : 0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'EFFECTIVE INCOME', 
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1.5, 
                          color: theme.colorScheme.primary
                        )
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CurrencyText(
                          amount: _effectiveIncome,
                          sign: '₹',
                          amountStyle: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.w900, 
                            color: theme.colorScheme.primary, 
                            letterSpacing: -1.0
                          ),
                          symbolStyle: TextStyle(
                            fontSize: 18, 
                            color: theme.colorScheme.primary.withOpacity(0.8)
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'For $monthName ${widget.date.year}', 
                          style: TextStyle(
                            fontSize: 11, 
                            fontWeight: FontWeight.w800, 
                            color: theme.colorScheme.primary
                          )
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // --- STEP 1: INPUTS ---
                Row(
                  children: [
                    Icon(Icons.calculate_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'ESTABLISH BASELINE', 
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 1.0, 
                        color: theme.colorScheme.primary
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ModernBoxyInput(
                  controller: _salaryCtrl, 
                  focusNode: _salaryFocus,
                  labelText: 'Salary Income (₹)', 
                  readOnly: true, 
                  onTap: () => _openCalculatorFor(_salaryCtrl, _salaryFocus),
                  prefixIcon: Icon(Icons.work_outline_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ModernBoxyInput(
                        controller: _extraCtrl, 
                        focusNode: _extraFocus,
                        labelText: 'Extra Income (₹)', 
                        readOnly: true,
                        onTap: () => _openCalculatorFor(_extraCtrl, _extraFocus),
                        prefixIcon: Icon(Icons.add_card_rounded, color: Colors.blueAccent.shade400),
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModernBoxyInput(
                        controller: _deductionCtrl, 
                        focusNode: _deductionFocus,
                        labelText: 'Deductions (₹)', 
                        readOnly: true,
                        onTap: () => _openCalculatorFor(_deductionCtrl, _deductionFocus),
                        prefixIcon: Icon(Icons.remove_circle_outline_rounded, color: theme.colorScheme.error),
                      )
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // --- STEP 2: PROJECTIONS ---
                Row(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'PROJECTED ALLOCATIONS', 
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 1.0, 
                        color: theme.colorScheme.primary
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                bucketsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => Text('Error: $e'),
                  data: (buckets) {
                    if (buckets.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: theme.colorScheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No buckets configured. Please set up your global buckets first.', 
                                style: TextStyle(
                                  color: theme.colorScheme.error, 
                                  fontWeight: FontWeight.w700, 
                                  fontSize: 13
                                )
                              )
                            ),
                          ]
                        )
                      );
                    }
                    
                    return Column(
                      children: buckets.map((bucket) {
                        final allocatedAmount = _effectiveIncome * (bucket.percentage / 100);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${bucket.percentage.toInt()}%', 
                                        style: TextStyle(
                                          fontSize: 10, 
                                          fontWeight: FontWeight.w900, 
                                          color: theme.colorScheme.primary
                                        )
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    bucket.name.toUpperCase(), 
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800, 
                                      fontSize: 13, 
                                      letterSpacing: 0.5
                                    )
                                  ),
                                ],
                              ),
                              CurrencyText(
                                amount: allocatedAmount,
                                sign: '₹',
                                amountStyle: TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 16, 
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                                symbolStyle: TextStyle(
                                  fontSize: 11, 
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                ModernBoxyButton(
                  onPressed: _effectiveIncome > 0 ? _submit : null, 
                  label: 'CONFIRM & CREATE BUDGET',
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                ),
                if (!showCalculator) const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        
        if (showCalculator)
          InlineCalculatorPad(
            key: ValueKey(_activeCalcController.hashCode), 
            controller: _activeCalcController!, 
            onNext: _activeCalcController != _deductionCtrl ? _handleCalcNext : null,
            onPrevious: _activeCalcController != _salaryCtrl ? _handleCalcPrev : null,
            onSubmit: _closeCalculatorSafely,
            onClose: _closeCalculatorSafely,
          ),
      ],
    );
  }
}