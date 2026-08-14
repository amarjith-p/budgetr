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

class AutomationEngine {
  final AppDatabase _db;
  final TransactionService _txService;
  final InAppNotificationService _notifService;
  final _uuid = const Uuid();

  AutomationEngine(this._db, this._txService, this._notifService);

  DateTime _calculateNextDate(DateTime current, String schedule, int interval) {
    if (schedule == 'Daily') {
      return current.add(Duration(days: interval));
    } else if (schedule == 'Weekly') {
      return current.add(Duration(days: 7 * interval));
    } else if (schedule == 'Monthly') {
      int nextMonth = current.month + interval;
      int nextYear = current.year;
      while (nextMonth > 12) {
        nextMonth -= 12;
        nextYear++;
      }
      int maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
      int safeDay = current.day > maxDays ? maxDays : current.day;
      return DateTime(
        nextYear,
        nextMonth,
        safeDay,
        current.hour,
        current.minute,
      );
    } else if (schedule == 'Yearly') {
      return DateTime(
        current.year + interval,
        current.month,
        current.day,
        current.hour,
        current.minute,
      );
    }
    return current.add(Duration(days: interval));
  }

  Future<void> runCatchUp() async {
    final rules = await _db.select(_db.recurringTransactionRules).get();
    final now = DateTime.now();

    for (var rule in rules) {
      if (!rule.isActive) continue;

      DateTime next = rule.nextExecutionDate;
      DateTime? lastExecuted = rule.lastExecutedDate;
      bool ruleUpdated = false;

      while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
        if (rule.isAutomatic && rule.amount != null) {
          // 1. SILENT AUTO-LOG
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
            id: _uuid.v4(),
            title: 'Automation Executed',
            body: '${rule.name} auto-logged successfully.',
            scheduledDate: now,
          );
        } else {
          // 2. MANUAL CONFIRMATION / VARIABLE AMOUNT
          final payload = jsonEncode({
            "type": "manual_rule",
            "ruleId": rule.id,
            "expectedDate": next.toIso8601String(),
          });

          await _notifService.saveNotification(
            id: 'manual_${rule.id}_${next.millisecondsSinceEpoch}',
            title: 'Action Required: ${rule.name}',
            body: rule.amount == null
                ? 'Variable transaction due. Tap to confirm amount.'
                : 'Scheduled transaction due for confirmation.',
            scheduledDate: now,
            payload: payload,
          );
        }

        lastExecuted = next;
        next = _calculateNextDate(
          next,
          rule.repetitionSchedule,
          rule.repetitionInterval,
        );
        ruleUpdated = true;
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

      if (next.isAfter(now)) {
        NotificationService.instance.scheduleNotification(
          id: rule.id.hashCode,
          title: rule.isAutomatic && rule.amount != null
              ? 'Automation Executed'
              : 'Action Required: ${rule.name}',
          body: rule.isAutomatic && rule.amount != null
              ? '${rule.name} was auto-logged.'
              : 'Tap to confirm your recurring transaction.',
          scheduledDate: next,
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

// ============================================================================
// --- PROVIDERS (Properly placed outside classes) ---
// ============================================================================

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

// --- FIXED: Moved OUTSIDE the ActionNotifier class so the UI can access it ---
final allRecurringRulesProvider =
    StreamProvider.autoDispose<List<RecurringTransactionRule>>((ref) {
      final db = ref.watch(databaseProvider);
      return (db.select(
        db.recurringTransactionRules,
      )..orderBy([(t) => OrderingTerm.desc(t.nextExecutionDate)])).watch();
    });

// ============================================================================
// --- ACTION NOTIFIER ---
// ============================================================================

class AutomationActionNotifier extends AsyncNotifier<void> {
  late AppDatabase _db;
  final _uuid = const Uuid();

  @override
  FutureOr<void> build() {
    _db = ref.watch(databaseProvider);
  }

  Future<bool> saveRule({
    String? existingId,
    required String name,
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
                startDate: startDate,
                occurrenceTime: occurrenceTime,
                isAutomatic: isAutomatic,
                nextExecutionDate: initialNextExecution,
              ),
            );
      }

      // Trigger the engine to catch up if the date is already in the past
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
    });
    return !state.hasError;
  }
}

final automationActionProvider =
    AsyncNotifierProvider<AutomationActionNotifier, void>(
      () => AutomationActionNotifier(),
    );
