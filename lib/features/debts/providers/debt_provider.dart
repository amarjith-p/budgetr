import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/notification_service.dart';

final allDebtsProvider = StreamProvider.autoDispose<List<Debt>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.debts,
  )..orderBy([(t) => OrderingTerm.asc(t.dueDate)])).watch();
});

class DebtActionNotifier extends AsyncNotifier<void> {
  final _uuid = const Uuid();

  @override
  FutureOr<void> build() {}

  Future<bool> saveDebt({
    String? existingId,
    required String type,
    required String person,
    required String purpose,
    required double amount,
    required DateTime date,
    required DateTime dueDate,
    required bool isPushEnabled,
    int? priorDays,
    int? existingNotificationId,
  }) async {
    state = const AsyncLoading();
    final db = ref.read(databaseProvider);

    state = await AsyncValue.guard(() async {
      if (existingId != null && existingNotificationId != null) {
        await NotificationService.instance.cancelSpecific(
          existingNotificationId,
        );
        await NotificationService.instance.cancelSpecific(
          existingNotificationId + 1,
        );
      }

      final int newNotifId =
          existingNotificationId ?? DateTime.now().millisecond;

      if (isPushEnabled) {
        final title = type == 'Borrowed'
            ? 'Repayment Due: $person'
            : 'Collect Debt: $person';
        final body = 'Amount: ₹$amount | Purpose: $purpose';

        await NotificationService.instance.scheduleNotification(
          id: newNotifId,
          title: title,
          body: body,
          scheduledDate: dueDate,
        );

        if (priorDays != null && priorDays > 0) {
          final priorDate = dueDate.subtract(Duration(days: priorDays));
          if (priorDate.isAfter(DateTime.now())) {
            await NotificationService.instance.scheduleNotification(
              id: newNotifId + 1,
              title: 'Upcoming $title',
              body: body,
              scheduledDate: priorDate,
            );
          }
        }
      }

      if (existingId == null) {
        await db
            .into(db.debts)
            .insert(
              DebtsCompanion.insert(
                id: _uuid.v4(),
                type: type,
                person: person,
                purpose: purpose,
                amount: amount,
                date: date,
                dueDate: dueDate,
                isPushEnabled: Value(isPushEnabled),
                priorDays: Value(priorDays),
                notificationId: newNotifId,
              ),
            );
      } else {
        final existing = await (db.select(
          db.debts,
        )..where((t) => t.id.equals(existingId))).getSingle();
        await db
            .update(db.debts)
            .replace(
              existing.copyWith(
                type: type,
                person: person,
                purpose: purpose,
                amount: amount,
                date: date,
                dueDate: dueDate,
                isPushEnabled: isPushEnabled,
                priorDays: Value(priorDays),
                notificationId: newNotifId,
              ),
            );
      }
    });
    return !state.hasError;
  }

  // --- NEW: Accumulate Interest ---
  Future<void> addInterest(Debt debt, double interestAmount) async {
    final db = ref.read(databaseProvider);
    await db
        .update(db.debts)
        .replace(
          debt.copyWith(
            interestAccumulated: debt.interestAccumulated + interestAmount,
          ),
        );
  }

  // --- NEW: Partial & Full Settlement ---
  Future<void> recordSettlement(Debt debt, double amountPaid) async {
    final db = ref.read(databaseProvider);
    final newSettledAmount = debt.settledAmount + amountPaid;
    final isFullySettled = newSettledAmount >= debt.amount;

    if (isFullySettled) {
      await NotificationService.instance.cancelSpecific(debt.notificationId);
      await NotificationService.instance.cancelSpecific(
        debt.notificationId + 1,
      );
    }

    await db
        .update(db.debts)
        .replace(
          debt.copyWith(
            settledAmount: newSettledAmount,
            isSettled: isFullySettled,
            isPushEnabled: isFullySettled ? false : debt.isPushEnabled,
          ),
        );
  }

  Future<void> deleteDebt(Debt debt) async {
    final db = ref.read(databaseProvider);
    await NotificationService.instance.cancelSpecific(debt.notificationId);
    await NotificationService.instance.cancelSpecific(debt.notificationId + 1);
    await (db.delete(db.debts)..where((t) => t.id.equals(debt.id))).go();
  }
}

final debtActionProvider = AsyncNotifierProvider<DebtActionNotifier, void>(
  () => DebtActionNotifier(),
);
