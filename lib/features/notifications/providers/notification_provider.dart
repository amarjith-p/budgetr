// lib/features/notifications/providers/notification_provider.dart
import 'package:budgetr/features/automation/providers/automation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/notification_service.dart';
import '../../accounts/providers/account_provider.dart';
import 'in_app_notification_provider.dart';

// --- ADDED BACKUP REMINDER IMPORT ---
import '../../backup/providers/backup_reminder_provider.dart';

class NotificationSettings {
  final bool enableNotifications;
  final bool backupReminderEnabled;
  final bool smartInboxPushEnabled; // <-- NEW

  // Credit Card Settings
  final int ccAlertHour;
  final int ccAlertMinute;
  final bool notifyOnBillDate;
  final bool notifyOnDueDate;
  final bool notify1DayBefore;
  final bool notify3DaysBefore;
  final bool notify5DaysBefore;

  // Loan EMI Settings
  final int loanAlertHour;
  final int loanAlertMinute;
  final bool notifyOnEmiDate;
  final bool notifyLoan1DayBefore;
  final bool notifyLoan3DaysBefore;
  final bool notifyLoan5DaysBefore;

  NotificationSettings({
    this.enableNotifications = true,
    this.backupReminderEnabled = true,
    this.smartInboxPushEnabled = true, // <-- NEW
    this.ccAlertHour = 9,
    this.ccAlertMinute = 0,
    this.notifyOnBillDate = true,
    this.notifyOnDueDate = true,
    this.notify1DayBefore = true,
    this.notify3DaysBefore = false,
    this.notify5DaysBefore = false,
    this.loanAlertHour = 10,
    this.loanAlertMinute = 0,
    this.notifyOnEmiDate = true,
    this.notifyLoan1DayBefore = true,
    this.notifyLoan3DaysBefore = false,
    this.notifyLoan5DaysBefore = false,
  });

  NotificationSettings copyWith({
    bool? enableNotifications,
    bool? backupReminderEnabled,
    bool? smartInboxPushEnabled, // <-- NEW
    int? ccAlertHour,
    int? ccAlertMinute,
    bool? notifyOnBillDate,
    bool? notifyOnDueDate,
    bool? notify1DayBefore,
    bool? notify3DaysBefore,
    bool? notify5DaysBefore,
    int? loanAlertHour,
    int? loanAlertMinute,
    bool? notifyOnEmiDate,
    bool? notifyLoan1DayBefore,
    bool? notifyLoan3DaysBefore,
    bool? notifyLoan5DaysBefore,
  }) {
    return NotificationSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      backupReminderEnabled:
          backupReminderEnabled ?? this.backupReminderEnabled,
      smartInboxPushEnabled:
          smartInboxPushEnabled ?? this.smartInboxPushEnabled, // <-- NEW
      ccAlertHour: ccAlertHour ?? this.ccAlertHour,
      ccAlertMinute: ccAlertMinute ?? this.ccAlertMinute,
      notifyOnBillDate: notifyOnBillDate ?? this.notifyOnBillDate,
      notifyOnDueDate: notifyOnDueDate ?? this.notifyOnDueDate,
      notify1DayBefore: notify1DayBefore ?? this.notify1DayBefore,
      notify3DaysBefore: notify3DaysBefore ?? this.notify3DaysBefore,
      notify5DaysBefore: notify5DaysBefore ?? this.notify5DaysBefore,
      loanAlertHour: loanAlertHour ?? this.loanAlertHour,
      loanAlertMinute: loanAlertMinute ?? this.loanAlertMinute,
      notifyOnEmiDate: notifyOnEmiDate ?? this.notifyOnEmiDate,
      notifyLoan1DayBefore: notifyLoan1DayBefore ?? this.notifyLoan1DayBefore,
      notifyLoan3DaysBefore:
          notifyLoan3DaysBefore ?? this.notifyLoan3DaysBefore,
      notifyLoan5DaysBefore:
          notifyLoan5DaysBefore ?? this.notifyLoan5DaysBefore,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enableNotifications: prefs.getBool('enableNotifications') ?? true,
      backupReminderEnabled: prefs.getBool('backupReminderEnabled') ?? true,
      smartInboxPushEnabled:
          prefs.getBool('smartInboxPushEnabled') ?? true, // <-- NEW
      ccAlertHour: prefs.getInt('ccAlertHour') ?? 9,
      ccAlertMinute: prefs.getInt('ccAlertMinute') ?? 0,
      notifyOnBillDate: prefs.getBool('notifyOnBillDate') ?? true,
      notifyOnDueDate: prefs.getBool('notifyOnDueDate') ?? true,
      notify1DayBefore: prefs.getBool('notify1DayBefore') ?? true,
      notify3DaysBefore: prefs.getBool('notify3DaysBefore') ?? false,
      notify5DaysBefore: prefs.getBool('notify5DaysBefore') ?? false,
      loanAlertHour: prefs.getInt('loanAlertHour') ?? 10,
      loanAlertMinute: prefs.getInt('loanAlertMinute') ?? 0,
      notifyOnEmiDate: prefs.getBool('notifyOnEmiDate') ?? true,
      notifyLoan1DayBefore: prefs.getBool('notifyLoan1DayBefore') ?? true,
      notifyLoan3DaysBefore: prefs.getBool('notifyLoan3DaysBefore') ?? false,
      notifyLoan5DaysBefore: prefs.getBool('notifyLoan5DaysBefore') ?? false,
    );
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    state = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableNotifications', newSettings.enableNotifications);
    await prefs.setBool(
      'backupReminderEnabled',
      newSettings.backupReminderEnabled,
    );
    await prefs.setBool(
      'smartInboxPushEnabled',
      newSettings.smartInboxPushEnabled,
    ); // <-- NEW
    await prefs.setInt('ccAlertHour', newSettings.ccAlertHour);
    await prefs.setInt('ccAlertMinute', newSettings.ccAlertMinute);
    await prefs.setBool('notifyOnBillDate', newSettings.notifyOnBillDate);
    await prefs.setBool('notifyOnDueDate', newSettings.notifyOnDueDate);
    await prefs.setBool('notify1DayBefore', newSettings.notify1DayBefore);
    await prefs.setBool('notify3DaysBefore', newSettings.notify3DaysBefore);
    await prefs.setBool('notify5DaysBefore', newSettings.notify5DaysBefore);

    await prefs.setInt('loanAlertHour', newSettings.loanAlertHour);
    await prefs.setInt('loanAlertMinute', newSettings.loanAlertMinute);
    await prefs.setBool('notifyOnEmiDate', newSettings.notifyOnEmiDate);
    await prefs.setBool(
      'notifyLoan1DayBefore',
      newSettings.notifyLoan1DayBefore,
    );
    await prefs.setBool(
      'notifyLoan3DaysBefore',
      newSettings.notifyLoan3DaysBefore,
    );
    await prefs.setBool(
      'notifyLoan5DaysBefore',
      newSettings.notifyLoan5DaysBefore,
    );
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      (ref) => NotificationSettingsNotifier(),
    );

void initializeNotificationScheduler(WidgetRef ref) {
  ref.listen<AsyncValue<List<Account>>>(accountsStreamProvider, (
    previous,
    next,
  ) {
    final accounts = next.asData?.value ?? [];
    final settings = ref.read(notificationSettingsProvider);
    _scheduleNotificationsForAccounts(accounts, settings, ref);
  });

  ref.listen<NotificationSettings>(notificationSettingsProvider, (
    previous,
    next,
  ) {
    final accounts = ref.read(accountsStreamProvider).asData?.value ?? [];
    _scheduleNotificationsForAccounts(accounts, next, ref);

    // --- NEW: Recalculate backup timer immediately if settings are toggled ---
    ref.read(backupReminderProvider.notifier).scheduleNextReminder();
  });
}

Future<void> _scheduleNotificationsForAccounts(
  List<Account> accounts,
  NotificationSettings settings,
  WidgetRef ref,
) async {
  final service = NotificationService.instance;

  // --- FIX 1: Use targeted cancellation instead of a global wipe ---
  await service.cancelAccountNotifications();

  // Clear future in-app notifications to prevent duplicates
  await ref
      .read(inAppNotificationServiceProvider)
      .clearFutureNotifications(prefix: 'alert_');

  if (!settings.enableNotifications) return;

  final creditCards = accounts
      .where((a) => a.type == 'Credit Cards' && !a.isClosed)
      .toList();
  final activeLoans = accounts
      .where((a) => a.type == 'Loan' && !a.isClosed)
      .toList();

  if (creditCards.isEmpty && activeLoans.isEmpty) return;

  DateTime getNextTargetDate(int targetDay, int hour, int minute) {
    final now = DateTime.now();
    int maxDays = DateTime(now.year, now.month + 1, 0).day;
    int safeDay = targetDay > maxDays ? maxDays : targetDay;

    DateTime target = DateTime(now.year, now.month, safeDay, hour, minute);

    if (target.isBefore(now)) {
      int nextMonth = now.month + 1;
      int nextYear = now.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      int maxDaysNext = DateTime(nextYear, nextMonth + 1, 0).day;
      int safeDayNext = targetDay > maxDaysNext ? maxDaysNext : targetDay;
      target = DateTime(nextYear, nextMonth, safeDayNext, hour, minute);
    }
    return target;
  }

  Map<String, List<String>> groupedEvents = {};

  void addEvent(DateTime triggerDate, String eventType, Account account) {
    if (triggerDate.isBefore(DateTime.now())) return;

    final formattedName = "${account.name} - ${account.providerName}";

    String dateKey =
        "${triggerDate.year}-${triggerDate.month.toString().padLeft(2, '0')}-${triggerDate.day.toString().padLeft(2, '0')} ${triggerDate.hour.toString().padLeft(2, '0')}:${triggerDate.minute.toString().padLeft(2, '0')}";
    String groupKey = "$dateKey|$eventType";
    groupedEvents.putIfAbsent(groupKey, () => []).add(formattedName);
  }

  for (var card in creditCards) {
    final bDay = card.billDate ?? 15;
    final dDay = card.dueDate ?? 5;

    final nextBillDate = getNextTargetDate(
      bDay,
      settings.ccAlertHour,
      settings.ccAlertMinute,
    );
    final nextDueDate = getNextTargetDate(
      dDay,
      settings.ccAlertHour,
      settings.ccAlertMinute,
    );

    if (settings.notifyOnBillDate) addEvent(nextBillDate, 'bill', card);
    if (settings.notifyOnDueDate) addEvent(nextDueDate, 'due0', card);
    if (settings.notify1DayBefore)
      addEvent(nextDueDate.subtract(const Duration(days: 1)), 'due1', card);
    if (settings.notify3DaysBefore)
      addEvent(nextDueDate.subtract(const Duration(days: 3)), 'due3', card);
    if (settings.notify5DaysBefore)
      addEvent(nextDueDate.subtract(const Duration(days: 5)), 'due5', card);
  }

  for (var loan in activeLoans) {
    if (loan.emiDate == null) continue;

    final eDay = loan.emiDate!.day;
    final nextEmiDate = getNextTargetDate(
      eDay,
      settings.loanAlertHour,
      settings.loanAlertMinute,
    );

    if (settings.notifyOnEmiDate) addEvent(nextEmiDate, 'emi0', loan);
    if (settings.notifyLoan1DayBefore)
      addEvent(nextEmiDate.subtract(const Duration(days: 1)), 'emi1', loan);
    if (settings.notifyLoan3DaysBefore)
      addEvent(nextEmiDate.subtract(const Duration(days: 3)), 'emi3', loan);
    if (settings.notifyLoan5DaysBefore)
      addEvent(nextEmiDate.subtract(const Duration(days: 5)), 'emi5', loan);
  }

  // --- FIX 2: Shift starting ID to 100000 to prevent collisions ---
  int notificationId = 100000;
  int delaySeconds = 0;
  final uuid = const Uuid();

  // --- FIX 2: Use deterministic hash IDs and remove shifting delay timestamps ---
  for (var entry in groupedEvents.entries) {
    final groupKey = entry.key;
    final parts = groupKey.split('|');
    final dateTimeStr = parts[0];
    final eventType = parts[1];
    final accountNames = entry.value;

    final dtParts = dateTimeStr.split(' ');
    final dateParts = dtParts[0].split('-');
    final timeParts = dtParts[1].split(':');

    // We no longer add arbitrary seconds to this date.
    // Keeping it exactly on the minute ensures OS-level alarm overwrites work perfectly.
    final scheduledDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    // Create a 100% deterministic, repeatable ID based on the exact time and event type.
    // This bounds the ID between 100000 and 189999 safely.
    final int notificationId = 100000 + (groupKey.hashCode.abs() % 90000);

    String title = '';
    String body = '';

    bool isPlural = accountNames.length > 1;
    String bulletedList = accountNames.map((name) => '• $name').join('\n');

    switch (eventType) {
      case 'bill':
        title = isPlural
            ? '${accountNames.length} Credit Card Bills Generated'
            : 'Credit Card Bill Generated';
        body = isPlural
            ? 'Credit Card Bills have been generated for:\n$bulletedList'
            : 'Credit Card Bill generated for:\n$bulletedList';
        break;
      case 'due0':
        title = isPlural
            ? '${accountNames.length} Payments Due Today!'
            : 'Payment Due Today!';
        body = isPlural
            ? 'Bills are due today for:\n$bulletedList'
            : 'Bill is due today for:\n$bulletedList';
        break;
      case 'due1':
        title = isPlural
            ? '${accountNames.length} Payments Due Tomorrow'
            : 'Payment Due Tomorrow';
        body = 'Due tomorrow for:\n$bulletedList';
        break;
      case 'due3':
        title = isPlural
            ? '${accountNames.length} Upcoming Payments'
            : 'Upcoming Payment';
        body = 'Due in 3 days for:\n$bulletedList';
        break;
      case 'due5':
        title = isPlural
            ? '${accountNames.length} Upcoming Payments'
            : 'Upcoming Payment';
        body = 'Due in 5 days for:\n$bulletedList';
        break;
      case 'emi0':
        title = isPlural
            ? '${accountNames.length} EMIs Due Today!'
            : 'EMI Due Today!';
        body = isPlural
            ? 'EMI payments are due today for:\n$bulletedList'
            : 'EMI payment is due today for:\n$bulletedList';
        break;
      case 'emi1':
        title = isPlural
            ? '${accountNames.length} EMIs Due Tomorrow'
            : 'EMI Due Tomorrow';
        body = 'Due tomorrow for:\n$bulletedList';
        break;
      case 'emi3':
        title = isPlural
            ? '${accountNames.length} Upcoming EMIs'
            : 'Upcoming EMI';
        body = 'Due in 3 days for:\n$bulletedList';
        break;
      case 'emi5':
        title = isPlural
            ? '${accountNames.length} Upcoming EMIs'
            : 'Upcoming EMI';
        body = 'Due in 5 days for:\n$bulletedList';
        break;
    }

    await service.scheduleNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );

    await ref
        .read(inAppNotificationServiceProvider)
        .saveNotification(
          id: 'alert_$notificationId',
          title: title,
          body: body,
          scheduledDate: scheduledDate,
        );
  }

  ref.read(automationEngineProvider).runCatchUp();
}
