import 'package:budgetr/core/models/transaction_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/inline_calculator_pad.dart';
import '../../../core/utils/bodmas_calculator.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../accounts/providers/account_provider.dart';
import '../../category_manager/providers/category_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/automation_provider.dart';

class AutomationRuleFormPage extends ConsumerStatefulWidget {
  final RecurringTransactionRule? existingRule;

  const AutomationRuleFormPage({super.key, this.existingRule});

  @override
  ConsumerState<AutomationRuleFormPage> createState() =>
      _AutomationRuleFormPageState();
}

class _AutomationRuleFormPageState
    extends ConsumerState<AutomationRuleFormPage> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _types = ['Expense', 'Income', 'Transfer'];
  final List<String> _schedules = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  int _typeIndex = 0;
  bool _isVariableAmount = false;
  bool _isAutomatic = true;

  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _intervalCtrl;

  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedCategoryIcon;
  String? _selectedSubCategory;
  int? _selectedBucketId;
  String? _selectedBucketName;

  String _schedule = 'Monthly';
  DateTime _startDate = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  bool _showCustomKeyboard = false;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _intervalCtrl = TextEditingController(text: '1');

    if (widget.existingRule != null) {
      final rule = widget.existingRule!;
      _nameCtrl.text = rule.name;
      _typeIndex = _types.indexOf(rule.transactionType);

      if (rule.amount == null) {
        _isVariableAmount = true;
        _isAutomatic = false;
      } else {
        _amountCtrl.text = rule.amount!.toStringAsFixed(2);
      }

      _selectedAccountId = rule.accountId;
      _selectedToAccountId = rule.toAccountId;
      _selectedCategoryId = rule.categoryId;
      _selectedCategoryName = rule.categoryName;
      _selectedCategoryIcon = rule.categoryIcon;
      _selectedSubCategory = rule.subCategory;
      _selectedBucketId = rule.bucketId;
      _selectedBucketName = rule.bucketName;

      _schedule = rule.repetitionSchedule;
      _intervalCtrl.text = rule.repetitionInterval.toString();
      _startDate = rule.startDate;

      final tParts = rule.occurrenceTime.split(':');
      if (tParts.length == 2) {
        _time = TimeOfDay(
          hour: int.parse(tParts[0]),
          minute: int.parse(tParts[1]),
        );
      }

      _isAutomatic = rule.isAutomatic;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAccount(bool isToAccount, List<Account> rawAccounts) async {
    _closeKeyboard();
    List<Account> availableAccounts = List.from(rawAccounts);

    if (isToAccount) {
      if (_selectedAccountId != null && _selectedAccountId != 'EXTERNAL') {
        availableAccounts = availableAccounts
            .where((a) => a.id != _selectedAccountId)
            .toList();
      }
    } else {
      if (_typeIndex == 2 &&
          _selectedToAccountId != null &&
          _selectedToAccountId != 'EXTERNAL') {
        availableAccounts = availableAccounts
            .where((a) => a.id != _selectedToAccountId)
            .toList();
      }
    }

    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: isToAccount ? 'Select Destination' : 'Select Account',
      items: availableAccounts.map((a) => a.name).toList(),
      selectedValue: isToAccount
          ? availableAccounts
                    .where((a) => a.id == _selectedToAccountId)
                    .firstOrNull
                    ?.name ??
                ''
          : availableAccounts
                    .where((a) => a.id == _selectedAccountId)
                    .firstOrNull
                    ?.name ??
                '',
    );

    if (selected != null && mounted) {
      setState(() {
        final id = availableAccounts.firstWhere((a) => a.name == selected).id;
        if (isToAccount) {
          _selectedToAccountId = id;
        } else {
          _selectedAccountId = id;
        }
      });
    }
  }

  Future<void> _pickCategory(
    List<TransactionCategoryModel> activeCategories,
  ) async {
    _closeKeyboard();
    final items = activeCategories.map((c) => c.name).toList();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Category',
      items: items,
      selectedValue: _selectedCategoryName ?? '',
    );

    if (selected != null && mounted) {
      final cat = activeCategories.firstWhere((c) => c.name == selected);
      setState(() {
        _selectedCategoryId = cat.id;
        _selectedCategoryName = cat.name;
        _selectedCategoryIcon = cat.iconCode;
        _selectedSubCategory = null;
      });
    }
  }

  Future<void> _pickSubCategory(List<String> activeSubCategories) async {
    _closeKeyboard();
    if (activeSubCategories.isEmpty) return;
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Subcategory',
      items: activeSubCategories,
      selectedValue: _selectedSubCategory ?? '',
    );

    if (selected != null && mounted)
      setState(() => _selectedSubCategory = selected);
  }

  Future<void> _pickBucket(List<BudgetBucket> buckets) async {
    _closeKeyboard();
    final items = buckets.map((b) => b.name).toList();
    items.add('Out of Bucket');
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Budget Bucket',
      items: items,
      selectedValue: _selectedBucketName ?? '',
    );

    if (selected != null && mounted) {
      setState(() {
        if (selected == 'Out of Bucket') {
          _selectedBucketId = -1;
          _selectedBucketName = 'Out of Bucket';
        } else {
          final b = buckets.firstWhere((b) => b.name == selected);
          _selectedBucketId = b.id;
          _selectedBucketName = b.name;
        }
      });
    }
  }

  Future<void> _pickSchedule() async {
    _closeKeyboard();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Repetition Schedule',
      items: _schedules,
      selectedValue: _schedule,
    );
    if (selected != null && mounted) setState(() => _schedule = selected);
  }

  Future<void> _pickDate() async {
    _closeKeyboard();
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _startDate = date);
  }

  Future<void> _pickTime() async {
    _closeKeyboard();
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null && mounted) setState(() => _time = t);
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
    setState(() => _showCustomKeyboard = false);
  }

  Future<void> _submit() async {
    _closeKeyboard();
    if (!_formKey.currentState!.validate()) return;

    final amountVal = double.tryParse(
      BodmasCalculator.evaluate(_amountCtrl.text),
    );
    final intervalVal = int.tryParse(_intervalCtrl.text) ?? 1;

    final isTransfer = _typeIndex == 2;
    final isExpense = _typeIndex == 0;

    // Strict Rule Validation
    if (intervalVal <= 0 ||
        (!_isVariableAmount && (amountVal == null || amountVal <= 0)) ||
        _selectedAccountId == null ||
        (isTransfer && _selectedToAccountId == null) ||
        (!isTransfer && _selectedCategoryId == null) ||
        (isExpense && _selectedBucketId == null)) {
      setState(() => _showValidationErrors = true);
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.selectionClick();

    final success = await ref
        .read(automationActionProvider.notifier)
        .saveRule(
          existingId: widget.existingRule?.id,
          name: _nameCtrl.text.trim(),
          amount: _isVariableAmount ? null : amountVal,
          transactionType: _types[_typeIndex],
          accountId: _selectedAccountId!,
          toAccountId: _selectedToAccountId,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          categoryIcon: _selectedCategoryIcon,
          subCategory: _selectedSubCategory,
          bucketId: _selectedBucketId == -1 ? null : _selectedBucketId,
          bucketName: _selectedBucketName,
          repetitionSchedule: _schedule,
          repetitionInterval: intervalVal,
          startDate: _startDate,
          occurrenceTime:
              '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
          isAutomatic: _isAutomatic,
        );

    if (success && mounted) Navigator.pop(context);
  }

  Widget _buildTableCell(
    String label,
    String? value,
    IconData icon,
    VoidCallback? onTap,
    bool isError,
  ) {
    final theme = Theme.of(context);
    final hasValue = value != null && value.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isError
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasValue ? value : (onTap != null ? 'Select' : ''),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasValue ? FontWeight.w800 : FontWeight.w500,
                  color: isError
                      ? theme.colorScheme.error
                      : (hasValue
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.5,
                              )),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txColor = TransactionColors.getTypeColor(_types[_typeIndex], theme);

    final rawAccounts = ref.watch(accountsStreamProvider).asData?.value ?? [];
    final rawCategories =
        ref.watch(categoriesStreamProvider).asData?.value ?? [];
    final rawBuckets = ref.watch(bucketsStreamProvider).asData?.value ?? [];

    final activeCategories = rawCategories
        .where((c) => c.type == _types[_typeIndex])
        .toList();
    final selectedCatMatch = rawCategories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;
    final activeSubCategories = selectedCatMatch?.subCategories ?? [];

    final selectedAccMatch = rawAccounts
        .where((a) => a.id == _selectedAccountId)
        .firstOrNull;
    final selectedToAccMatch = rawAccounts
        .where((a) => a.id == _selectedToAccountId)
        .firstOrNull;

    final isTransfer = _typeIndex == 2;
    final isExpense = _typeIndex == 0;

    List<Widget> cells = [
      _buildTableCell(
        'SCHEDULE',
        _schedule,
        Icons.update_rounded,
        _pickSchedule,
        false,
      ),
      _buildTableCell(
        'INTERVAL (COUNT)',
        _intervalCtrl.text,
        Icons.repeat_rounded,
        null,
        false,
      ),
      _buildTableCell(
        'START DATE',
        DateFormat('dd MMM yyyy').format(_startDate),
        Icons.calendar_today_rounded,
        _pickDate,
        false,
      ),
      _buildTableCell(
        'OCCURRENCE TIME',
        _time.format(context),
        Icons.access_time_rounded,
        _pickTime,
        false,
      ),
      _buildTableCell(
        isTransfer ? 'FROM ACCOUNT' : 'ACCOUNT',
        selectedAccMatch?.name,
        Icons.account_balance_wallet_rounded,
        () => _pickAccount(false, rawAccounts),
        _showValidationErrors && _selectedAccountId == null,
      ),
    ];

    if (isTransfer) {
      cells.add(
        _buildTableCell(
          'TO ACCOUNT',
          selectedToAccMatch?.name,
          Icons.sync_alt_rounded,
          () => _pickAccount(true, rawAccounts),
          _showValidationErrors && _selectedToAccountId == null,
        ),
      );
    } else {
      cells.add(
        _buildTableCell(
          'CATEGORY',
          _selectedCategoryName,
          Icons.category_rounded,
          () => _pickCategory(activeCategories),
          _showValidationErrors && _selectedCategoryId == null,
        ),
      );
      if (activeSubCategories.isNotEmpty || _selectedSubCategory != null) {
        cells.add(
          _buildTableCell(
            'SUBCATEGORY',
            _selectedSubCategory,
            Icons.subdirectory_arrow_right_rounded,
            () => _pickSubCategory(activeSubCategories),
            false,
          ),
        );
      }
      if (isExpense) {
        cells.add(
          _buildTableCell(
            'BUDGET BUCKET',
            _selectedBucketName,
            Icons.donut_small_rounded,
            () => _pickBucket(rawBuckets),
            _showValidationErrors && _selectedBucketId == null,
          ),
        );
      }
    }
    if (cells.length % 2 != 0) cells.add(const SizedBox.shrink());

    List<TableRow> tableRows = [];
    for (int i = 0; i < cells.length; i += 2) {
      tableRows.add(TableRow(children: [cells[i], cells[i + 1]]));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: widget.existingRule != null ? 'Edit Rule' : 'New Automation',
        subtitle: 'RECURRING TRANSACTION',
        leadingIcon: Icons.close_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 60,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ModernBoxyToggle(
                        labels: _types,
                        selectedIndex: _typeIndex,
                        onSelected: (index) => setState(() {
                          _typeIndex = index;
                          _selectedCategoryId = null;
                          _selectedCategoryName = null;
                          _selectedSubCategory = null;
                        }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _formKey,
                        child: ModernBoxyInput(
                          controller: _nameCtrl,
                          labelText: 'Rule Name (e.g., Netflix Sub)',
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: const Text(
                                'Variable Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              value: _isVariableAmount,
                              activeColor: theme.colorScheme.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _isVariableAmount = val;
                                  if (val)
                                    _isAutomatic =
                                        false; // Variables must be manual
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text(
                                'Auto Execute',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              value: _isAutomatic,
                              activeColor: theme.colorScheme.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: _isVariableAmount
                                  ? null
                                  : (val) {
                                      HapticFeedback.lightImpact();
                                      setState(() => _isAutomatic = val);
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isVariableAmount)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: ModernBoxyInput(
                          controller: _amountCtrl,
                          labelText: 'Fixed Amount',
                          readOnly: true,
                          onTap: () {
                            SystemChannels.textInput.invokeMethod(
                              'TextInput.hide',
                            );
                            setState(() => _showCustomKeyboard = true);
                          },
                          prefixIcon: Icon(
                            Icons.currency_rupee_rounded,
                            color: txColor,
                            size: 18,
                          ),
                        ),
                      ),
                    if (_showValidationErrors &&
                        (!_isVariableAmount &&
                            (double.tryParse(
                                      BodmasCalculator.evaluate(
                                        _amountCtrl.text,
                                      ),
                                    ) ==
                                    null ||
                                double.parse(
                                      BodmasCalculator.evaluate(
                                        _amountCtrl.text,
                                      ),
                                    ) <=
                                    0)))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Amount is required for fixed rules',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Table(
                        border: TableBorder.symmetric(
                          inside: BorderSide(
                            color: theme.dividerColor,
                            width: 1.0,
                          ),
                        ),
                        children: tableRows,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_showCustomKeyboard)
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ModernBoxyButton(
                        onPressed: () => Navigator.pop(context),
                        label: 'CANCEL',
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      flex: 2,
                      child: ModernBoxyButton(
                        onPressed: _submit,
                        label: 'SAVE RULE',
                      ),
                    ),
                  ],
                ),
              ),
            if (_showCustomKeyboard)
              Expanded(
                flex: 40,
                child: InlineCalculatorPad(
                  controller: _amountCtrl,
                  onSubmit: _closeKeyboard,
                  onClose: _closeKeyboard,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
