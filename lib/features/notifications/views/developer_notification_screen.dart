// features/notifications/views/developer_notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/services/notification_service.dart';

class DeveloperNotificationScreen extends StatefulWidget {
  const DeveloperNotificationScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperNotificationScreen> createState() =>
      _DeveloperNotificationScreenState();
}

class _DeveloperNotificationScreenState
    extends State<DeveloperNotificationScreen> {
  List<Map<String, dynamic>> _pendingNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    setState(() => _isLoading = true);

    final pending = await NotificationService.instance
        .getScheduledNotifications();
    pending.sort(
      (a, b) => DateTime.parse(
        a['scheduledDate'],
      ).compareTo(DateTime.parse(b['scheduledDate'])),
    );

    setState(() {
      _pendingNotifications = pending;
      _isLoading = false;
    });
  }

  Future<void> _cancelSpecific(int id) async {
    HapticFeedback.lightImpact();
    await NotificationService.instance.cancelSpecific(id);
    _loadPendingNotifications();
  }

  Future<void> _cancelAll() async {
    HapticFeedback.heavyImpact();
    await NotificationService.instance.cancelAllNotifications();
    _loadPendingNotifications();
  }

  // --- NEW: INSTANT TEST ALARM ---
  // --- REPLACE YOUR EXISTING _fireTestAlarm WITH THIS ---
  Future<void> _fireTestAlarm() async {
    HapticFeedback.selectionClick();

    // Fires instantly, bypassing the Android AlarmManager scheduler
    await NotificationService.instance.showInstantTestNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Instant notification triggered! Check your notification tray.',
          ),
        ),
      );
    }
  }

  void _openEditSheet(Map<String, dynamic> req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditNotificationSheet(
        id: req['id'],
        initialTitle: req['title'],
        initialBody: req['body'],
        initialDate: DateTime.parse(req['scheduledDate']),
        onSaved: () {
          _loadPendingNotifications();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Developer',
        subtitle: 'NOTIFICATION QUEUE',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingLg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Scheduled: ${_pendingNotifications.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          // --- TEST BUTTON ---
                          IconButton(
                            onPressed: _fireTestAlarm,
                            icon: Icon(
                              Icons.add_alert_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            tooltip: 'Schedule Test Alarm (5s)',
                          ),
                          if (_pendingNotifications.isNotEmpty)
                            IconButton(
                              onPressed: _cancelAll,
                              icon: Icon(
                                Icons.delete_sweep_rounded,
                                color: theme.colorScheme.error,
                              ),
                              tooltip: 'Clear All',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingLg,
                    vertical: 8,
                  ),
                  color: theme.colorScheme.error.withOpacity(0.1),
                  child: Text(
                    'Warning: Edits made here will be overwritten the next time the system recalculates automatic account schedules.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _pendingNotifications.isEmpty
                      ? Center(
                          child: Text(
                            'No notifications are currently scheduled.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(DesignTokens.spacingLg),
                          itemCount: _pendingNotifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final req = _pendingNotifications[index];
                            final DateTime date = DateTime.parse(
                              req['scheduledDate'],
                            );
                            final formattedDate = DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(date);

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'ID: ${req['id']}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _openEditSheet(req),
                                            icon: Icon(
                                              Icons.edit_rounded,
                                              size: 20,
                                              color: theme.colorScheme.primary,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _cancelSpecific(req['id']),
                                            icon: Icon(
                                              Icons.cancel_rounded,
                                              size: 20,
                                              color: theme.colorScheme.error
                                                  .withOpacity(0.7),
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    req['title'] ?? 'No Title',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    req['body'] ?? 'No Body',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// --- FULL EDIT SHEET FOR DEVELOPER OVERRIDE ---
class _EditNotificationSheet extends StatefulWidget {
  final int id;
  final String initialTitle;
  final String initialBody;
  final DateTime initialDate;
  final VoidCallback onSaved;

  const _EditNotificationSheet({
    required this.id,
    required this.initialTitle,
    required this.initialBody,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<_EditNotificationSheet> createState() => _EditNotificationSheetState();
}

class _EditNotificationSheetState extends State<_EditNotificationSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _bodyCtrl = TextEditingController(text: widget.initialBody);
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null && mounted) {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.selectionClick();

    await NotificationService.instance.cancelSpecific(widget.id);

    await NotificationService.instance.scheduleNotification(
      id: widget.id,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      scheduledDate: _selectedDate,
    );

    if (mounted) {
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(_selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
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
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Edit Notification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              ModernBoxyInput(
                controller: _titleCtrl,
                labelText: 'Title',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ModernBoxyInput(
                controller: _bodyCtrl,
                labelText: 'Body',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickDateTime,
                child: AbsorbPointer(
                  child: ModernBoxyInput(
                    controller: TextEditingController(text: formattedDate),
                    labelText: 'Trigger Date & Time',
                    suffixIcon: Icon(
                      Icons.edit_calendar_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ModernBoxyButton(
                      onPressed: () => Navigator.pop(context),
                      label: 'CANCEL',
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ModernBoxyButton(
                      onPressed: _save,
                      label: 'OVERWRITE ALARM',
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
