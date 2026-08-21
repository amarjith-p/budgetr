// lib/features/investments/components/passive_income_action_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/components/docked_calculator_pad.dart';
import '../../../core/utils/bodmas_calculator.dart';
import '../providers/investment_provider.dart';

class PassiveIncomeActionBottomSheet extends ConsumerStatefulWidget {
  final Investment investment;
  final bool isUpdateMode;
  final InvestmentLog? existingLog;

  const PassiveIncomeActionBottomSheet({
    Key? key,
    required this.investment,
    required this.isUpdateMode,
    this.existingLog,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required Investment investment,
    required bool isUpdateMode,
    InvestmentLog? existingLog,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PassiveIncomeActionBottomSheet(
        investment: investment,
        isUpdateMode: isUpdateMode,
        existingLog: existingLog,
      ),
    );
  }

  @override
  ConsumerState<PassiveIncomeActionBottomSheet> createState() =>
      _PassiveIncomeActionBottomSheetState();
}

class _PassiveIncomeActionBottomSheetState
    extends ConsumerState<PassiveIncomeActionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  DateTime _selectedDate = DateTime.now();
  int _typeIndex = 0; // 0 = Dividend, 1 = Interest

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      _amountCtrl.text = widget.existingLog!.amount.toStringAsFixed(2);
      _selectedDate = widget.existingLog!.date;
      _typeIndex = widget.existingLog!.type == 'Dividend' ? 0 : 1;
    }
    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus)
        SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onCalcKeyPress(String key) {
    setState(() {
      int cursorPosition = _amountCtrl.selection.baseOffset;
      if (cursorPosition < 0) cursorPosition = _amountCtrl.text.length;
      String currentText = _amountCtrl.text;

      // --- FIXED: Explicitly catch '⌫' and other backspace variations ---
      if (key.toUpperCase() == 'C') {
        _amountCtrl.clear();
      } else if (key == '⌫' ||
          key.toLowerCase() == 'backspace' ||
          key == '<' ||
          key == ' ') {
        if (cursorPosition > 0) {
          final newText =
              currentText.substring(0, cursorPosition - 1) +
              currentText.substring(cursorPosition);
          _amountCtrl.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorPosition - 1),
          );
        }
      } else if (key == '=') {
        String rawResult = BodmasCalculator.evaluate(_amountCtrl.text);
        double? parsed = double.tryParse(rawResult);
        if (parsed != null && !parsed.isNaN && !parsed.isInfinite) {
          _amountCtrl.text = parsed.toStringAsFixed(2);
          _amountCtrl.selection = TextSelection.collapsed(
            offset: _amountCtrl.text.length,
          );
        }
      } else {
        if (currentText.length < 25) {
          final newText =
              currentText.substring(0, cursorPosition) +
              key +
              currentText.substring(cursorPosition);
          _amountCtrl.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: cursorPosition + key.length,
            ),
          );
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
    _amountFocus.requestFocus();
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty) return;
    final amount =
        double.tryParse(BodmasCalculator.evaluate(_amountCtrl.text)) ?? 0.0;
    if (amount <= 0) return;

    HapticFeedback.heavyImpact();
    final type = _typeIndex == 0 ? 'Dividend' : 'Interest';
    bool success;

    if (widget.existingLog != null) {
      success = await ref
          .read(investmentActionProvider.notifier)
          .editInvestmentActivity(
            widget.existingLog!.copyWith(
              amount: amount,
              date: _selectedDate,
              type: type,
            ),
          );
    } else {
      success = await ref
          .read(investmentActionProvider.notifier)
          .logInvestmentActivity(
            investmentId: widget.investment.id,
            type: type,
            amount: amount,
            date: _selectedDate,
          );
    }
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionState = ref.watch(investmentActionProvider);
    final Color activeColor = Colors.amber.shade600;
    final double calcHeight = MediaQuery.of(context).size.height * 0.35;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spacingLg,
                  DesignTokens.spacingLg,
                  DesignTokens.spacingLg,
                  12,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(
                            bottom: DesignTokens.spacingLg,
                          ),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      ModernBoxyToggle(
                        labels: const ['Dividend', 'Interest'],
                        selectedIndex: _typeIndex,
                        onSelected: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _typeIndex = i);
                          _amountFocus.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: activeColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: activeColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _typeIndex == 0
                                      ? Icons.pie_chart_rounded
                                      : Icons.percent_rounded,
                                  color: activeColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isUpdateMode
                                      ? 'EDIT ${_typeIndex == 0 ? "DIVIDEND" : "INTEREST"}'
                                      : 'RECORD ${_typeIndex == 0 ? "DIVIDEND" : "INTEREST"}',
                                  style: TextStyle(
                                    color: activeColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            IntrinsicWidth(
                              child: TextField(
                                controller: _amountCtrl,
                                focusNode: _amountFocus,
                                readOnly: true,
                                showCursor: true,
                                cursorColor: activeColor,
                                textAlign: TextAlign.center,
                                onTap: () {
                                  if (!_amountFocus.hasFocus)
                                    _amountFocus.requestFocus();
                                  SystemChannels.textInput.invokeMethod(
                                    'TextInput.hide',
                                  );
                                },
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -1.0,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.6),
                                  ),
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Received Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: calcHeight,
              child: DockedCalculatorPad(
                backgroundColor: Colors.transparent,
                actionColor: activeColor,
                onKeyPress: _onCalcKeyPress,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                8,
                DesignTokens.spacingLg,
                DesignTokens.spacingLg,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: ModernBoxyButton(
                        onPressed: () => Navigator.pop(context),
                        label: 'Cancel',
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ModernBoxyButton(
                        onPressed: _submit,
                        label: widget.existingLog != null
                            ? 'Save Changes'
                            : 'Save Record',
                        backgroundColor: activeColor,
                        foregroundColor: Colors.black,
                        isLoading: actionState.isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
