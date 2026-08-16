// lib/features/reminders/components/create_reminder_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../providers/reminder_provider.dart';

class CreateReminderBottomSheet extends ConsumerStatefulWidget {
  final Reminder? existingReminder;

  const CreateReminderBottomSheet({Key? key, this.existingReminder})
    : super(key: key);

  static void show(BuildContext context, {Reminder? existingReminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) =>
          CreateReminderBottomSheet(existingReminder: existingReminder),
    );
  }

  @override
  ConsumerState<CreateReminderBottomSheet> createState() =>
      _CreateReminderBottomSheetState();
}

class _CreateReminderBottomSheetState
    extends ConsumerState<CreateReminderBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _notesCtrl;

  late DateTime _selectedDate;
  late bool _isPushEnabled;
  late int _priorDays;

  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(
      text: widget.existingReminder?.title ?? '',
    );
    _notesCtrl = TextEditingController(
      text: widget.existingReminder?.notes ?? '',
    );

    _selectedDate =
        widget.existingReminder?.targetDate ??
        DateTime.now().add(const Duration(minutes: 5));
    _isPushEnabled = widget.existingReminder?.isPushEnabled ?? true;
    _priorDays = widget.existingReminder?.priorDays ?? 0;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.lightImpact();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time must be in the future.")),
      );
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.selectionClick();
    final success = await ref
        .read(reminderActionProvider.notifier)
        .saveReminder(
          existingId: widget.existingReminder?.id,
          existingNotificationId: widget.existingReminder?.notificationId,
          title: _titleCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
          targetDate: _selectedDate,
          isPushEnabled: _isPushEnabled,
          priorDays: _isPushEnabled ? _priorDays : null,
        );

    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actionState = ref.watch(reminderActionProvider);

    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(_selectedDate);

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
                widget.existingReminder != null
                    ? 'Edit Reminder'
                    : 'New Reminder',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),

              ModernBoxyInput(
                controller: _titleCtrl,
                labelText: 'Reminder Title',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: DesignTokens.spacingMd),

              ModernBoxyInput(
                controller: _notesCtrl,
                labelText: 'Additional Notes (Optional)',
              ),
              const SizedBox(height: DesignTokens.spacingMd),

              GestureDetector(
                onTap: _pickDateTime,
                child: AbsorbPointer(
                  child: ModernBoxyInput(
                    controller: TextEditingController(text: formattedDate),
                    labelText: 'Target Date & Time',
                    suffixIcon: Icon(
                      Icons.edit_calendar_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
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
                      label: widget.existingReminder != null
                          ? 'Update'
                          : 'Save',
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
}
