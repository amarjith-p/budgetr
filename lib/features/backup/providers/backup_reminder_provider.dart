// lib/features/backup/providers/backup_reminder_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/providers/in_app_notification_provider.dart';
import '../../../core/services/notification_service.dart';

class BackupReminderNotifier extends StateNotifier<bool> {
  final Ref ref;
  Timer? _timer;
  DateTime? _lastBackup;

  BackupReminderNotifier(this.ref) : super(false) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString('last_backup_time');
    if (lastStr != null) {
      _lastBackup = DateTime.parse(lastStr);
    }
    _checkDue();
    // Re-check periodically while the app is active
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkDue());
  }

  void _checkDue() {
    if (_lastBackup == null) {
      if (state != true) state = true;
      return;
    }
    // Flag as due if 24 hours have passed
    final due = DateTime.now().difference(_lastBackup!).inHours >= 24;
    if (state != due) state = due;
  }

  Future<void> recordBackup() async {
    final now = DateTime.now();
    _lastBackup = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_backup_time', now.toIso8601String());
    _checkDue();
    await scheduleNextReminder();
  }

  Future<void> scheduleNextReminder() async {
    // 1. Wipe previous backup schedules to avoid duplicates
    // We use ID 99999 to distinct it from CCs/Loans (which are 100k+)
    await NotificationService.instance.cancelSpecific(99999);
    await ref
        .read(inAppNotificationServiceProvider)
        .clearFutureNotifications(prefix: 'alert_99999');

    final settings = ref.read(notificationSettingsProvider);
    if (!settings.enableNotifications || !settings.backupReminderEnabled)
      return;

    // 2. Target exact 24 hours from the last backup
    final targetTime = (_lastBackup ?? DateTime.now()).add(
      const Duration(hours: 24),
    );

    if (targetTime.isAfter(DateTime.now())) {
      const title = 'Data Backup Overdue';
      const body =
          'It has been 24 hours since your last backup. Secure your FinStack 360 ledger now.';

      // Push to OS via Local Notifications (Appears in Developer Queue automatically)
      await NotificationService.instance.scheduleNotification(
        id: 99999,
        title: title,
        body: body,
        scheduledDate: targetTime,
      );

      // Queue in In-App Notification Center
      await ref
          .read(inAppNotificationServiceProvider)
          .saveNotification(
            id: 'alert_99999',
            title: title,
            body: body,
            scheduledDate: targetTime,
          );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final backupReminderProvider =
    StateNotifierProvider<BackupReminderNotifier, bool>((ref) {
      return BackupReminderNotifier(ref);
    });
