// lib/features/reminders/providers/reminder_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/notification_service.dart';
import '../../notifications/providers/in_app_notification_provider.dart';
import '../services/reminder_service.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(ref.watch(databaseProvider));
});

final allRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderServiceProvider).watchAllReminders();
});

class ReminderActionNotifier extends AsyncNotifier<void> {
  late ReminderService _service;
  final _uuid = const Uuid();

  @override
  FutureOr<void> build() {
    _service = ref.watch(reminderServiceProvider);
  }

  Future<bool> saveReminder({
    String? existingId,
    int? existingNotificationId,
    required String title,
    String? notes,
    required DateTime targetDate,
    required bool isPushEnabled,
    int? priorDays,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // --- FIX: DETERMINISTIC HASH ID ---
      final id = existingId ?? _uuid.v4();
      final notificationId =
          existingNotificationId ?? (id.hashCode.abs() % 80000);

      if (existingId != null && existingNotificationId != null) {
        await NotificationService.instance.cancelSpecific(
          existingNotificationId,
        );
        await ref
            .read(inAppNotificationServiceProvider)
            .deleteNotification('rem_$existingNotificationId');

        ref.read(dismissedRemindersProvider.notifier).undismiss(existingId);
      }

      if (isPushEnabled) {
        final triggerDate = targetDate.subtract(Duration(days: priorDays ?? 0));

        if (triggerDate.isAfter(DateTime.now())) {
          final bodyText = notes?.isNotEmpty == true
              ? notes!
              : 'You have a scheduled reminder pending!';

          await NotificationService.instance.scheduleNotification(
            id: notificationId,
            title: title,
            body: bodyText,
            scheduledDate: triggerDate,
          );

          await ref
              .read(inAppNotificationServiceProvider)
              .saveNotification(
                id: 'rem_$notificationId',
                title: title,
                body: bodyText,
                scheduledDate: triggerDate,
                payload: jsonEncode({'type': 'reminder', 'reminderId': id}),
              );
        }
      }

      await _service.saveReminder(
        id: id,
        title: title,
        notes: notes,
        targetDate: targetDate,
        isPushEnabled: isPushEnabled,
        priorDays: priorDays,
        notificationId: notificationId,
      );
    });
    return !state.hasError;
  }

  Future<void> deleteReminder(Reminder reminder) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (reminder.isPushEnabled) {
        await NotificationService.instance.cancelSpecific(
          reminder.notificationId,
        );
        await ref
            .read(inAppNotificationServiceProvider)
            .deleteNotification('rem_${reminder.notificationId}');
      }
      await _service.deleteReminder(reminder.id);
    });
  }
}

final reminderActionProvider =
    AsyncNotifierProvider<ReminderActionNotifier, void>(
      () => ReminderActionNotifier(),
    );

class DismissedRemindersNotifier extends StateNotifier<Set<String>> {
  DismissedRemindersNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('dismissed_dashboard_reminders') ?? [];
    state = list.toSet();
  }

  Future<void> dismiss(String id) async {
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_dashboard_reminders', state.toList());
  }

  Future<void> undismiss(String id) async {
    if (state.contains(id)) {
      final newState = Set<String>.from(state)..remove(id);
      state = newState;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'dismissed_dashboard_reminders',
        state.toList(),
      );
    }
  }
}

final dismissedRemindersProvider =
    StateNotifierProvider<DismissedRemindersNotifier, Set<String>>(
      (ref) => DismissedRemindersNotifier(),
    );
