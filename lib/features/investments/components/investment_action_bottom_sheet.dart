// lib/features/investments/components/investment_action_bottom_sheet.dart
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

class InvestmentActionBottomSheet extends ConsumerStatefulWidget {
  final Investment investment;
  final bool isUpdateMode;
  final InvestmentLog? existingLog; // --- NEW: Supports Editing ---

  const InvestmentActionBottomSheet({
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
      builder: (ctx) => InvestmentActionBottomSheet(
        investment: investment,
        isUpdateMode: isUpdateMode,
        existingLog: existingLog,
      ),
    );
  }

  @override
  ConsumerState<InvestmentActionBottomSheet> createState() =>
      _InvestmentActionBottomSheetState();
}

class _InvestmentActionBottomSheetState
    extends ConsumerState<InvestmentActionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  int _typeIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Pre-fill if editing
    if (widget.existingLog != null) {
      _amountCtrl.text = widget.existingLog!.amount.toStringAsFixed(2);
      _selectedDate = widget.existingLog!.date;
      _typeIndex = widget.existingLog!.type == 'Deposit' ? 0 : 1;
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
      _errorMessage = null;
      int cursorPosition = _amountCtrl.selection.baseOffset;
      if (cursorPosition < 0) cursorPosition = _amountCtrl.text.length;
      String currentText = _amountCtrl.text;

      if (key == 'C') {
        _amountCtrl.clear();
      } else if (key == '⌫' || key == 'Backspace' || key == '<') {
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

    if (!widget.isUpdateMode && _typeIndex == 1 && widget.existingLog == null) {
      if (amount > widget.investment.currentValue) {
        HapticFeedback.vibrate();
        setState(
          () => _errorMessage =
              'Withdrawal cannot exceed Current Value (₹${widget.investment.currentValue.toStringAsFixed(2)})',
        );
        return;
      }
    }

    HapticFeedback.heavyImpact();
    final type = widget.isUpdateMode
        ? 'Update'
        : (_typeIndex == 0 ? 'Deposit' : 'Withdrawal');

    bool success;
    if (widget.existingLog != null) {
      // Execute Edit
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
      // Execute Add
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

    final Color activeColor = widget.isUpdateMode
        ? theme.colorScheme.primary
        : (_typeIndex == 0 ? Colors.green : theme.colorScheme.error);

    final String actionLabel = widget.isUpdateMode
        ? (widget.existingLog != null
              ? 'Edit Value Update'
              : 'Update Market Value')
        : (widget.existingLog != null
              ? 'Edit Transaction'
              : (_typeIndex == 0 ? 'Add Deposit' : 'Record Withdrawal'));

    final IconData actionIcon = widget.isUpdateMode
        ? Icons.sync_rounded
        : (_typeIndex == 0
              ? Icons.south_west_rounded
              : Icons.north_east_rounded);

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

                      if (!widget.isUpdateMode) ...[
                        ModernBoxyToggle(
                          labels: const ['Deposit', 'Withdrawal'],
                          selectedIndex: _typeIndex,
                          onSelected: (i) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _typeIndex = i;
                              _errorMessage = null;
                            });
                            _amountFocus.requestFocus();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

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
                                Icon(actionIcon, color: activeColor, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  actionLabel.toUpperCase(),
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
                                    'Effective Date',
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

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: theme.colorScheme.error,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
              decoration: const BoxDecoration(color: Colors.transparent),
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
                        foregroundColor: Colors.white,
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
