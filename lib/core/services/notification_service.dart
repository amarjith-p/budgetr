// lib/core/services/notification_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

    // The working small icon configuration
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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

  // --- NEW: Helper method to extract the asset and save it locally ---
  // This bypasses Android's drawable/mipmap system entirely.
  Future<String> _getAssetFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/notification_avatar.png';
    final file = File(filePath);

    // Only write the file if it doesn't already exist to save processing time
    if (!await file.exists()) {
      final byteData = await rootBundle.load(
        'assets/icon/fs360_transparent.png',
      );
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
    }
    return filePath;
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

    // Load the file path directly from storage
    final String largeIconPath = await _getAssetFilePath();

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'budgetr_cc_reminders_final', // Fresh channel ID
          'Credit Card Reminders',
          channelDescription:
              'Notifications for Credit Card Bills and Due Dates',
          importance: Importance.max,
          priority: Priority.high,

          // The working small right-side badge icon
          // icon: '@mipmap/launcher_icon',

          // The large left-side avatar loaded directly from device storage
          largeIcon: FilePathAndroidBitmap(largeIconPath),

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
    // Load the file path directly from storage
    final String largeIconPath = await _getAssetFilePath();

    final androidDetails = AndroidNotificationDetails(
      'budgetr_cc_reminders_final',
      'Credit Card Reminders',
      channelDescription: 'Notifications for Credit Card Bills and Due Dates',
      importance: Importance.max,
      priority: Priority.high,

      // The working small right-side badge icon
      // icon: '@mipmap/launcher_icon',

      // The large left-side avatar loaded directly from device storage
      largeIcon: FilePathAndroidBitmap(largeIconPath),

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
