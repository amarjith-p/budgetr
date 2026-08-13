// core/services/notification_service.dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _registryKey = 'dev_notification_registry';

  Future<void> initialize() async {
    tz.initializeTimeZones();

    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: initializationSettingsAndroid,
      ),
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    bool hasExactAlarmPermission = false;
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      hasExactAlarmPermission =
          await androidImplementation?.canScheduleExactNotifications() ?? false;
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body, // Collapsed view (automatically truncated by Android)
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'budgetr_cc_reminders',
          'Credit Card Reminders',
          channelDescription:
              'Notifications for Credit Card Bills and Due Dates',
          importance: Importance.max,
          priority: Priority.high,
          // --- NEW: Allows the notification to be expanded for multi-line lists ---
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            htmlFormatBigText: false,
          ),
        ),
      ),
      androidScheduleMode: hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );

    await _saveToRegistry(id, title, body, scheduledDate);
  }

  Future<void> cancelSpecific(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);

    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_registryKey) ?? [];
    list.removeWhere((item) => jsonDecode(item)['id'] == id);
    await prefs.setStringList(_registryKey, list);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_registryKey);
  }

  Future<void> _saveToRegistry(
    int id,
    String title,
    String body,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_registryKey) ?? [];
    final map = {
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': date.toIso8601String(),
    };

    list.removeWhere((item) => jsonDecode(item)['id'] == id);
    list.add(jsonEncode(map));
    await prefs.setStringList(_registryKey, list);
  }

  Future<List<Map<String, dynamic>>> getScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_registryKey) ?? [];
    return list
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  Future<void> showInstantTestNotification() async {
    // Also updating the test notification to support Big Text just in case
    final androidDetails = AndroidNotificationDetails(
      'budgetr_cc_reminders',
      'Credit Card Reminders',
      channelDescription: 'Notifications for Credit Card Bills and Due Dates',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: const BigTextStyleInformation(
        'Line 1: Your app permissions are working.\nLine 2: Expandable text works perfectly!\nLine 3: You are ready to go.',
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 88888,
      title: 'Instant Test Successful! 🎉',
      body: 'Expand this notification to see more...',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }
}
