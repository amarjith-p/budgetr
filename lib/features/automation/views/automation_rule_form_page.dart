import 'package:budgetr/core/models/transaction_category_model.dart';
import 'package:budgetr/features/transactions/providers/transaction_provider.dart';
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
import '../providers/automation_provider.dart';

class _BucketItem {
  final int id;
  final String name;
  _BucketItem(this.id, this.name);
}

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
  late TextEditingController _websiteCtrl;

  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedCategoryIcon;
  String? _selectedSubCategory;
  int? _selectedBucketId;
  String? _selectedBucketName;

  String _schedule = 'Monthly';
  String _advancedSchedule = 'Same Date';
  DateTime _startDate = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  bool _showCustomKeyboard = false;
  bool _showValidationErrors = false;

  String _expression = '';
  String _liveResult = '0.00';

  final List<String> _advancedOptions = [
    'Same Date',
    '1st Monday',
    '1st Tuesday',
    '1st Wednesday',
    '1st Thursday',
    '1st Friday',
    '1st Saturday',
    '1st Sunday',
    '2nd Monday',
    '2nd Tuesday',
    '2nd Wednesday',
    '2nd Thursday',
    '2nd Friday',
    '2nd Saturday',
    '2nd Sunday',
    '3rd Monday',
    '3rd Tuesday',
    '3rd Wednesday',
    '3rd Thursday',
    '3rd Friday',
    '3rd Saturday',
    '3rd Sunday',
    '4th Monday',
    '4th Tuesday',
    '4th Wednesday',
    '4th Thursday',
    '4th Friday',
    '4th Saturday',
    '4th Sunday',
    'Last Monday',
    'Last Tuesday',
    'Last Wednesday',
    'Last Thursday',
    'Last Friday',
    'Last Saturday',
    'Last Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _intervalCtrl = TextEditingController(text: '1');
    _websiteCtrl = TextEditingController();

    if (widget.existingRule != null) {
      final rule = widget.existingRule!;
      _nameCtrl.text = rule.name;
      _websiteCtrl.text = rule.serviceWebsite ?? '';
      _typeIndex = _types.indexOf(rule.transactionType);

      if (rule.amount == null) {
        _isVariableAmount = true;
        _isAutomatic = false;
      } else {
        _amountCtrl.text = rule.amount!.toStringAsFixed(2);
        _expression = _amountCtrl.text;
        _liveResult = _amountCtrl.text;
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
      _advancedSchedule = rule.advancedSchedule ?? 'Same Date';
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
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _onCalcKeyPress(String key) {
    setState(() {
      int cursorPosition = _amountCtrl.selection.baseOffset;
      if (cursorPosition < 0) cursorPosition = _amountCtrl.text.length;
      String currentText = _amountCtrl.text;

      if (key == 'C') {
        _amountCtrl.clear();
        _expression = '';
        _liveResult = '0.00';
      } else if (key == '⌫') {
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
        final isOperator = ['+', '-', '×', '÷'].contains(key);
        if (isOperator && cursorPosition > 0) {
          final prevChar = currentText[cursorPosition - 1];
          if (['+', '-', '×', '÷'].contains(prevChar)) {
            final newText =
                currentText.substring(0, cursorPosition - 1) +
                key +
                currentText.substring(cursorPosition);
            _amountCtrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursorPosition),
            );
          } else if (currentText.length < 25) {
            final newText =
                currentText.substring(0, cursorPosition) +
                key +
                currentText.substring(cursorPosition);
            _amountCtrl.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursorPosition + 1),
            );
          }
        } else if (currentText.length < 25) {
          final newText =
              currentText.substring(0, cursorPosition) +
              key +
              currentText.substring(cursorPosition);
          _amountCtrl.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorPosition + 1),
          );
        }
      }

      _expression = _amountCtrl.text;
      String rawResult = BodmasCalculator.evaluate(_expression);
      double? parsed = double.tryParse(rawResult);
      if (parsed != null) {
        if (parsed.isNaN || parsed.isInfinite) {
          _liveResult = '0.00';
        } else if (parsed >= 1000000000000) {
          _liveResult = '999999999999.99';
          if (key != '⌫') {
            _amountCtrl.text = '999999999999.99';
            _amountCtrl.selection = TextSelection.collapsed(
              offset: _amountCtrl.text.length,
            );
            _expression = _amountCtrl.text;
          }
        } else {
          _liveResult = parsed.toStringAsFixed(2);
        }
      } else {
        _liveResult = rawResult.isEmpty ? '0.00' : rawResult;
      }
    });
  }

  List<Widget> _buildAccountGroup(
    BuildContext ctx,
    List<Account> accounts,
    String title,
    IconData iconData,
    String? selectedId,
    ThemeData theme,
  ) {
    if (accounts.isEmpty) return [];
    List<Widget> children = [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    ];
    for (int i = 0; i < accounts.length; i++) {
      final acc = accounts[i];
      final isLast = i == accounts.length - 1;
      final isSelected = acc.id == selectedId;
      children.add(
        Column(
          children: [
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 0,
              ),
              leading: Icon(
                iconData,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                acc.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                acc.providerName,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    )
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx, acc.id);
              },
            ),
            if (!isLast)
              Divider(
                height: 1,
                color: theme.dividerColor.withOpacity(0.2),
                indent: 20,
                endIndent: 20,
              ),
          ],
        ),
      );
    }
    return children;
  }

  Future<void> _pickAccount(bool isToAccount, List<Account> rawAccounts) async {
    _closeKeyboard();
    final theme = Theme.of(context);
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

    final assets = availableAccounts
        .where((a) => a.type != 'Credit Cards' && a.type != 'Loan')
        .toList();
    final creditCards = availableAccounts
        .where((a) => a.type == 'Credit Cards')
        .toList();
    final loans = availableAccounts.where((a) => a.type == 'Loan').toList();
    final selectedId = isToAccount ? _selectedToAccountId : _selectedAccountId;

    bool showExternal = _typeIndex == 2;
    if (isToAccount && _selectedAccountId == 'EXTERNAL') showExternal = false;
    if (!isToAccount && _selectedToAccountId == 'EXTERNAL')
      showExternal = false;

    final selected = await GlobalSelectionSheet.show<String>(
      context: context,
      title: isToAccount ? 'Select Destination' : 'Select Account',
      builder: (ctx, scrollController) {
        return ListView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          children: [
            ..._buildAccountGroup(
              ctx,
              assets,
              'ASSETS',
              Icons.account_balance_wallet_rounded,
              selectedId,
              theme,
            ),
            if (assets.isNotEmpty &&
                (creditCards.isNotEmpty || loans.isNotEmpty || showExternal))
              Divider(
                height: 12,
                thickness: 4,
                color: theme.dividerColor.withOpacity(0.05),
              ),
            ..._buildAccountGroup(
              ctx,
              creditCards,
              'CREDIT CARDS',
              Icons.credit_card_rounded,
              selectedId,
              theme,
            ),
            if (creditCards.isNotEmpty && (loans.isNotEmpty || showExternal))
              Divider(
                height: 12,
                thickness: 4,
                color: theme.dividerColor.withOpacity(0.05),
              ),
            ..._buildAccountGroup(
              ctx,
              loans,
              'LOANS',
              Icons.account_balance_rounded,
              selectedId,
              theme,
            ),
            if (loans.isNotEmpty && showExternal)
              Divider(
                height: 12,
                thickness: 4,
                color: theme.dividerColor.withOpacity(0.05),
              ),
            if (showExternal) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'EXTERNAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                leading: Icon(
                  Icons.sync_alt_rounded,
                  size: 20,
                  color: selectedId == 'EXTERNAL'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  'External Account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selectedId == 'EXTERNAL'
                        ? FontWeight.w900
                        : FontWeight.w600,
                    color: selectedId == 'EXTERNAL'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Outside of FinStack 360',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: selectedId == 'EXTERNAL'
                    ? Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(ctx, 'EXTERNAL');
                },
              ),
            ],
          ],
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        if (isToAccount) {
          _selectedToAccountId = selected;
        } else {
          _selectedAccountId = selected;
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

  // --- FIXED: ADDED INTERVAL PICKER LOGIC ---
  Future<void> _pickInterval() async {
    _closeKeyboard();
    final items = List.generate(30, (index) => (index + 1).toString());
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Repetition Interval',
      items: items,
      selectedValue: _intervalCtrl.text,
    );
    if (selected != null && mounted) {
      setState(() => _intervalCtrl.text = selected);
    }
  }

  Future<void> _pickAdvancedSchedule() async {
    _closeKeyboard();
    final selected = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Specific Occurrence',
      items: _advancedOptions,
      selectedValue: _advancedSchedule,
    );
    if (selected != null && mounted)
      setState(() => _advancedSchedule = selected);
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
          serviceWebsite: _websiteCtrl.text.trim().isEmpty
              ? null
              : _websiteCtrl.text.trim(),
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
          advancedSchedule: _advancedSchedule,
          startDate: _startDate,
          occurrenceTime:
              '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
          isAutomatic: _isAutomatic,
        );

    if (success && mounted) Navigator.pop(context);
  }

  Widget _buildProjectedSchedule(ThemeData theme) {
    List<DateTime> projections = [];
    DateTime base = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _time.hour,
      _time.minute,
    );

    for (int i = 0; i < 3; i++) {
      base = ScheduleHelper.calculateNextDate(
        base,
        _schedule,
        int.tryParse(_intervalCtrl.text) ?? 1,
        _advancedSchedule,
      );
      projections.add(base);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'PROJECTED SCHEDULE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...projections.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy, HH:mm').format(e.value),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
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

    final displayAccName = _selectedAccountId == 'EXTERNAL'
        ? 'External Account'
        : selectedAccMatch?.name;
    final displayToAccName = _selectedToAccountId == 'EXTERNAL'
        ? 'External Account'
        : selectedToAccMatch?.name;

    final isTransfer = _typeIndex == 2;
    final isExpense = _typeIndex == 0;

    final amountVal = double.tryParse(_liveResult) ?? 0.0;
    final hasDanglingOperator =
        _expression.isNotEmpty &&
        ['+', '-', '×', '÷'].contains(_expression[_expression.length - 1]);
    final hasAmountError =
        _showValidationErrors &&
        (!_isVariableAmount && (amountVal <= 0 || hasDanglingOperator));
    final displayAmountColor = hasAmountError
        ? theme.colorScheme.error
        : txColor;

    List<Widget> cells = [
      _buildTableCell(
        'SCHEDULE',
        _schedule,
        Icons.update_rounded,
        _pickSchedule,
        false,
      ),
      // --- FIXED: ADDED _pickInterval to onTap ---
      _buildTableCell(
        'INTERVAL (COUNT)',
        _intervalCtrl.text,
        Icons.repeat_rounded,
        _pickInterval,
        false,
      ),
      if (_schedule == 'Monthly' || _schedule == 'Yearly')
        _buildTableCell(
          'OCCURRENCE RULE',
          _advancedSchedule,
          Icons.event_repeat_rounded,
          _pickAdvancedSchedule,
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
        'TRIGGER TIME',
        _time.format(context),
        Icons.access_time_rounded,
        _pickTime,
        false,
      ),
      _buildTableCell(
        isTransfer ? 'FROM ACCOUNT' : 'ACCOUNT',
        displayAccName,
        Icons.account_balance_wallet_rounded,
        () => _pickAccount(false, rawAccounts),
        _showValidationErrors && _selectedAccountId == null,
      ),
    ];

    if (isTransfer) {
      cells.add(
        _buildTableCell(
          'TO ACCOUNT',
          displayToAccName,
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
      resizeToAvoidBottomInset: false,
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
                        child: Column(
                          children: [
                            ModernBoxyInput(
                              controller: _nameCtrl,
                              labelText: 'Rule Name (e.g., Netflix Sub)',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            ModernBoxyInput(
                              controller: _websiteCtrl,
                              labelText: 'Service Website (Optional for Logo)',
                              hintText: 'netflix.com',
                            ),
                          ],
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
                                  if (val) _isAutomatic = false;
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
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

                    _buildProjectedSchedule(theme),
                    const SizedBox(height: 32),
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
              InlineCalculatorPad(
                controller: _amountCtrl,
                onSubmit: _closeKeyboard,
                onClose: _closeKeyboard,
              ),
          ],
        ),
      ),
    );
  }
}
