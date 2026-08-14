// lib/features/automation/providers/automation_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../transactions/services/transaction_service.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../notifications/providers/in_app_notification_provider.dart';

class ScheduleHelper {
  static DateTime calculateNextDate(
    DateTime current,
    String schedule,
    int interval,
    String? advancedSchedule,
  ) {
    DateTime baseNext;
    if (schedule == 'Daily') {
      baseNext = current.add(Duration(days: interval));
    } else if (schedule == 'Weekly') {
      baseNext = current.add(Duration(days: 7 * interval));
    } else if (schedule == 'Monthly') {
      int nextMonth = current.month + interval;
      int nextYear = current.year;
      while (nextMonth > 12) {
        nextMonth -= 12;
        nextYear++;
      }
      baseNext = DateTime(nextYear, nextMonth, 1, current.hour, current.minute);
    } else if (schedule == 'Yearly') {
      baseNext = DateTime(
        current.year + interval,
        current.month,
        1,
        current.hour,
        current.minute,
      );
    } else {
      baseNext = current.add(Duration(days: interval));
    }

    if ((schedule == 'Monthly' || schedule == 'Yearly') &&
        advancedSchedule != null &&
        advancedSchedule != 'Same Date') {
      final parts = advancedSchedule.split(' ');
      if (parts.length == 2) {
        final weekStr = parts[0];
        final dayStr = parts[1];
        final dayMap = {
          'Monday': 1,
          'Tuesday': 2,
          'Wednesday': 3,
          'Thursday': 4,
          'Friday': 5,
          'Saturday': 6,
          'Sunday': 7,
        };
        final targetDay = dayMap[dayStr] ?? 1;

        if (weekStr == 'Last') {
          int nextM = baseNext.month + 1;
          int nextY = baseNext.year;
          if (nextM > 12) {
            nextM = 1;
            nextY++;
          }
          DateTime firstOfNext = DateTime(nextY, nextM, 1);
          int diff = firstOfNext.weekday - targetDay;
          if (diff <= 0) diff += 7;
          return DateTime(nextY, nextM, 1 - diff, current.hour, current.minute);
        } else {
          int weekNum = int.parse(weekStr[0]);
          DateTime firstOfMonth = DateTime(baseNext.year, baseNext.month, 1);
          int diff = targetDay - firstOfMonth.weekday;
          if (diff < 0) diff += 7;
          int targetDate = 1 + diff + ((weekNum - 1) * 7);
          return DateTime(
            baseNext.year,
            baseNext.month,
            targetDate,
            current.hour,
            current.minute,
          );
        }
      }
    }

    if (schedule == 'Monthly' || schedule == 'Yearly') {
      int maxDays = DateTime(baseNext.year, baseNext.month + 1, 0).day;
      int safeDay = current.day > maxDays ? maxDays : current.day;
      return DateTime(
        baseNext.year,
        baseNext.month,
        safeDay,
        current.hour,
        current.minute,
      );
    }

    return baseNext;
  }
}

class AutomationEngine {
  final AppDatabase _db;
  final TransactionService _txService;
  final InAppNotificationService _notifService;
  final _uuid = const Uuid();

  AutomationEngine(this._db, this._txService, this._notifService);

  Future<void> runCatchUp() async {
    final rules = await _db.select(_db.recurringTransactionRules).get();
    final now = DateTime.now();

    for (var rule in rules) {
      if (!rule.isActive) continue;

      DateTime next = rule.nextExecutionDate;
      DateTime? lastExecuted = rule.lastExecutedDate;
      bool ruleUpdated = false;

      if (rule.isAutomatic && rule.amount != null) {
        while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
          await _txService.logTransaction(
            type: rule.transactionType,
            amount: rule.amount!,
            date: next,
            accountId: rule.accountId,
            toAccountId: rule.toAccountId,
            categoryId: rule.categoryId,
            categoryName: rule.categoryName,
            categoryIcon: rule.categoryIcon,
            subCategory: rule.subCategory,
            bucketId: rule.bucketId,
            bucketName: rule.bucketName,
            notes: 'Auto-logged by ${rule.name}',
          );

          await _notifService.saveNotification(
            id: 'auto_${rule.id}_${next.millisecondsSinceEpoch}',
            title: 'Automation Executed',
            body: '${rule.name} auto-logged successfully.',
            scheduledDate: next, // Use exact trigger time
          );
          lastExecuted = next;
          next = ScheduleHelper.calculateNextDate(
            next,
            rule.repetitionSchedule,
            rule.repetitionInterval,
            rule.advancedSchedule,
          );
          ruleUpdated = true;
        }
      } else {
        if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
          final payload = jsonEncode({
            "type": "manual_rule",
            "ruleId": rule.id,
            "expectedDate": next.toIso8601String(),
          });
          final notifId = 'manual_${rule.id}_${next.millisecondsSinceEpoch}';

          await _notifService.saveNotification(
            id: notifId,
            title: 'Action Required: ${rule.name}',
            body: rule.amount == null
                ? 'Variable transaction due. Tap to confirm amount.'
                : 'Scheduled transaction due for confirmation.',
            scheduledDate: next,
            payload: payload,
          );
        }
      }

      if (ruleUpdated) {
        await _db
            .update(_db.recurringTransactionRules)
            .replace(
              rule.copyWith(
                nextExecutionDate: next,
                lastExecutedDate: Value(lastExecuted),
              ),
            );
      }
      await _notifService.clearFutureNotifications(prefix: 'auto_${rule.id}');
      await _notifService.clearFutureNotifications(prefix: 'manual_${rule.id}');

      // --- NEW FIX: PRE-SAVE THE NOTIFICATION FOR THE FUTURE ---
      // This guarantees the notification pops into the UI exactly when 'now' crosses 'next'
      if (next.isAfter(now)) {
        final isAuto = rule.isAutomatic && rule.amount != null;
        final title = isAuto
            ? 'Automation Executed'
            : 'Action Required: ${rule.name}';
        final body = isAuto
            ? '${rule.name} was auto-logged.'
            : 'Tap to confirm your recurring transaction.';

        NotificationService.instance.scheduleNotification(
          id: rule.id.hashCode,
          title: title,
          body: body,
          scheduledDate: next,
        );

        final payload = isAuto
            ? null
            : jsonEncode({
                "type": "manual_rule",
                "ruleId": rule.id,
                "expectedDate": next.toIso8601String(),
              });

        final notifId = isAuto
            ? 'auto_${rule.id}_${next.millisecondsSinceEpoch}'
            : 'manual_${rule.id}_${next.millisecondsSinceEpoch}';

        await _notifService.saveNotification(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: next,
          payload: payload,
        );
      }
    }
  }

  Stream<RecurringTransactionRule> watchRule(String id) {
    return (_db.select(
      _db.recurringTransactionRules,
    )..where((t) => t.id.equals(id))).watchSingle();
  }
}

// --- PROVIDERS ---
final automationEngineProvider = Provider<AutomationEngine>((ref) {
  final db = ref.watch(databaseProvider);
  final txService = ref.watch(transactionServiceProvider);
  final notifService = ref.watch(inAppNotificationServiceProvider);
  return AutomationEngine(db, txService, notifService);
});

final singleRecurringRuleProvider =
    StreamProvider.family<RecurringTransactionRule, String>((ref, id) {
      return ref.watch(automationEngineProvider).watchRule(id);
    });

final allRecurringRulesProvider =
    StreamProvider.autoDispose<List<RecurringTransactionRule>>((ref) {
      final db = ref.watch(databaseProvider);
      return (db.select(
        db.recurringTransactionRules,
      )..orderBy([(t) => OrderingTerm.desc(t.nextExecutionDate)])).watch();
    });

class AutomationActionNotifier extends AsyncNotifier<void> {
  late AppDatabase _db;
  final _uuid = const Uuid();

  @override
  FutureOr<void> build() {
    _db = ref.watch(databaseProvider);
  }

  Future<bool> executeManualRule({
    required RecurringTransactionRule rule,
    required double finalAmount,
    required DateTime executionDate,
    required String? notificationId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final currentRule = await (_db.select(
        _db.recurringTransactionRules,
      )..where((t) => t.id.equals(rule.id))).getSingle();

      if (currentRule.nextExecutionDate.isAfter(executionDate)) {
        if (notificationId != null) {
          await ref
              .read(inAppNotificationActionProvider.notifier)
              .markAsRead(notificationId);
        }
        throw Exception('This transaction has already been executed.');
      }

      final txService = ref.read(transactionServiceProvider);
      await txService.logTransaction(
        type: currentRule.transactionType,
        amount: finalAmount,
        date: executionDate,
        accountId: currentRule.accountId,
        toAccountId: currentRule.toAccountId,
        categoryId: currentRule.categoryId,
        categoryName: currentRule.categoryName,
        categoryIcon: currentRule.categoryIcon,
        subCategory: currentRule.subCategory,
        bucketId: currentRule.bucketId,
        bucketName: currentRule.bucketName,
        notes: 'Manually confirmed from ${currentRule.name}',
      );

      final nextDate = ScheduleHelper.calculateNextDate(
        currentRule.nextExecutionDate,
        currentRule.repetitionSchedule,
        currentRule.repetitionInterval,
        currentRule.advancedSchedule,
      );

      await _db
          .update(_db.recurringTransactionRules)
          .replace(
            currentRule.copyWith(
              lastExecutedDate: Value(executionDate),
              nextExecutionDate: nextDate,
            ),
          );

      if (notificationId != null) {
        await ref
            .read(inAppNotificationActionProvider.notifier)
            .markAsRead(notificationId);
      }

      ref.read(automationEngineProvider).runCatchUp();
    });
    return !state.hasError;
  }

  Future<bool> saveRule({
    String? existingId,
    required String name,
    String? serviceWebsite,
    double? amount,
    required String transactionType,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    String? categoryName,
    int? categoryIcon,
    String? subCategory,
    int? bucketId,
    String? bucketName,
    required String repetitionSchedule,
    required int repetitionInterval,
    String? advancedSchedule,
    required DateTime startDate,
    required String occurrenceTime,
    required bool isAutomatic,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final timeParts = occurrenceTime.split(':');
      final initialNextExecution = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      if (existingId == null) {
        await _db
            .into(_db.recurringTransactionRules)
            .insert(
              RecurringTransactionRulesCompanion.insert(
                id: _uuid.v4(),
                name: name,
                serviceWebsite: Value(serviceWebsite),
                amount: Value(amount),
                transactionType: transactionType,
                accountId: accountId,
                toAccountId: Value(toAccountId),
                categoryId: Value(categoryId),
                categoryName: Value(categoryName),
                categoryIcon: Value(categoryIcon),
                subCategory: Value(subCategory),
                bucketId: Value(bucketId),
                bucketName: Value(bucketName),
                repetitionSchedule: repetitionSchedule,
                repetitionInterval: repetitionInterval,
                advancedSchedule: Value(advancedSchedule),
                startDate: startDate,
                occurrenceTime: occurrenceTime,
                isAutomatic: isAutomatic,
                nextExecutionDate: initialNextExecution,
              ),
            );
      } else {
        final existing = await (_db.select(
          _db.recurringTransactionRules,
        )..where((t) => t.id.equals(existingId))).getSingle();
        await _db
            .update(_db.recurringTransactionRules)
            .replace(
              existing.copyWith(
                name: name,
                serviceWebsite: Value(serviceWebsite),
                amount: Value(amount),
                transactionType: transactionType,
                accountId: accountId,
                toAccountId: Value(toAccountId),
                categoryId: Value(categoryId),
                categoryName: Value(categoryName),
                categoryIcon: Value(categoryIcon),
                subCategory: Value(subCategory),
                bucketId: Value(bucketId),
                bucketName: Value(bucketName),
                repetitionSchedule: repetitionSchedule,
                repetitionInterval: repetitionInterval,
                advancedSchedule: Value(advancedSchedule),
                startDate: startDate,
                occurrenceTime: occurrenceTime,
                isAutomatic: isAutomatic,
                nextExecutionDate: initialNextExecution,
              ),
            );
      }
      ref.read(automationEngineProvider).runCatchUp();
    });
    return !state.hasError;
  }

  Future<bool> deleteRule(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await (_db.delete(
        _db.recurringTransactionRules,
      )..where((t) => t.id.equals(id))).go();

      // --- FIX 4: Ensure deleted rules don't leave orphaned future notifications ---
      final notifService = ref.read(inAppNotificationServiceProvider);
      await notifService.clearFutureNotifications(prefix: 'auto_$id');
      await notifService.clearFutureNotifications(prefix: 'manual_$id');
    });
    return !state.hasError;
  }
}

final automationActionProvider =
    AsyncNotifierProvider<AutomationActionNotifier, void>(
      () => AutomationActionNotifier(),
    );
