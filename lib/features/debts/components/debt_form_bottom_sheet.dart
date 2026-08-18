import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/debt_provider.dart';

class DebtFormBottomSheet extends ConsumerStatefulWidget {
  final Debt? existingDebt;

  const DebtFormBottomSheet({Key? key, this.existingDebt}) : super(key: key);

  static void show(BuildContext context, {Debt? existingDebt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => DebtFormBottomSheet(existingDebt: existingDebt),
    );
  }

  @override
  ConsumerState<DebtFormBottomSheet> createState() =>
      _DebtFormBottomSheetState();
}

class _DebtFormBottomSheetState extends ConsumerState<DebtFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  int _typeIndex = 0;
  final List<String> _types = ['Borrowed', 'Lent'];

  late TextEditingController _personCtrl;
  late TextEditingController _purposeCtrl;
  late TextEditingController _amountCtrl;

  DateTime _date = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _dueTime = const TimeOfDay(hour: 9, minute: 0);

  late bool _isPushEnabled;
  late int _priorDays;

  @override
  void initState() {
    super.initState();
    _personCtrl = TextEditingController(
      text: widget.existingDebt?.person ?? '',
    );
    _purposeCtrl = TextEditingController(
      text: widget.existingDebt?.purpose ?? '',
    );
    _amountCtrl = TextEditingController(
      text: widget.existingDebt?.amount != null
          ? widget.existingDebt!.amount.toStringAsFixed(2)
          : '',
    );

    if (widget.existingDebt != null) {
      final d = widget.existingDebt!;
      _typeIndex = _types.indexOf(d.type);
      _date = d.date;
      _dueDate = d.dueDate;
      _dueTime = TimeOfDay.fromDateTime(d.dueDate);
      _isPushEnabled = d.isPushEnabled;
      _priorDays = d.priorDays ?? 0;
    } else {
      _isPushEnabled = true;
      _priorDays = 0;
    }
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _purposeCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDue) async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final initial = isDue ? _dueDate : _date;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      setState(() {
        if (isDue) {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            _dueTime.hour,
            _dueTime.minute,
          );
        } else {
          _date = date;
        }
      });
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    final t = await showTimePicker(context: context, initialTime: _dueTime);
    if (t != null && mounted) {
      setState(() {
        _dueTime = t;
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          t.hour,
          t.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.selectionClick();
    final success = await ref
        .read(debtActionProvider.notifier)
        .saveDebt(
          existingId: widget.existingDebt?.id,
          type: _types[_typeIndex],
          person: _personCtrl.text.trim(),
          purpose: _purposeCtrl.text.trim(),
          amount: double.parse(_amountCtrl.text.trim()),
          date: _date,
          dueDate: _dueDate,
          isPushEnabled: _isPushEnabled,
          priorDays: _isPushEnabled ? _priorDays : null,
          existingNotificationId: widget.existingDebt?.notificationId,
        );

    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actionState = ref.watch(debtActionProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + DesignTokens.spacingLg,
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: DesignTokens.spacingSm,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.existingDebt != null ? 'Edit Debt' : 'Add Debt',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),

              ModernBoxyToggle(
                labels: _types,
                selectedIndex: _typeIndex,
                onSelected: (idx) => setState(() => _typeIndex = idx),
              ),
              const SizedBox(height: DesignTokens.spacingLg),

              ModernBoxyInput(
                controller: _personCtrl,
                labelText: _typeIndex == 0
                    ? 'Who did you borrow from?'
                    : 'Who did you lend to?',
                prefixIcon: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: DesignTokens.spacingMd),

              ModernBoxyInput(
                controller: _amountCtrl,
                labelText: 'Amount',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Invalid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: DesignTokens.spacingMd),

              ModernBoxyInput(
                controller: _purposeCtrl,
                labelText: 'Purpose / Notes',
                prefixIcon: Icon(
                  Icons.notes_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: DesignTokens.spacingMd),

              // --- CUSTOM DATE SELECTORS ---
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(false),
                      child: _buildDateSelector(
                        'Issue Date',
                        DateFormat('dd MMM yyyy').format(_date),
                        Icons.calendar_today_rounded,
                        theme,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(true),
                      child: _buildDateSelector(
                        'Due Date',
                        DateFormat('dd MMM yyyy').format(_dueDate),
                        Icons.event_rounded,
                        theme,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingMd),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    isDark ? 0.3 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Push Notification Alert',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _isPushEnabled,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              HapticFeedback.lightImpact();
                              setState(() => _isPushEnabled = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_isPushEnabled) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Exact Due Time:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Text(
                              _dueTime.format(context),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remind me earlier:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          DropdownButton<int>(
                            value: _priorDays,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            items: [0, 1, 2, 3, 4, 5].map((days) {
                              return DropdownMenuItem(
                                value: days,
                                child: Text(
                                  days == 0
                                      ? 'Exact Time'
                                      : '$days Days Before',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              if (val != null) setState(() => _priorDays = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: ModernBoxyButton(
                      onPressed: () => Navigator.pop(context),
                      label: 'Cancel',
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    flex: 2,
                    child: ModernBoxyButton(
                      onPressed: _submit,
                      label: widget.existingDebt != null ? 'Update' : 'Save',
                      isLoading: actionState.isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to completely prevent icon and text overlapping
  Widget _buildDateSelector(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}
