import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class ReminderService {
  final AppDatabase _db;

  ReminderService(this._db);

  Stream<List<Reminder>> watchAllReminders() {
    return (_db.select(_db.reminders)..orderBy([
          (t) =>
              OrderingTerm.asc(t.targetDate), // Ascending to show closest first
        ]))
        .watch();
  }

  Future<void> saveReminder({
    required String id,
    required String title,
    String? notes,
    required DateTime targetDate,
    required bool isPushEnabled,
    int? priorDays,
    required int notificationId,
  }) async {
    await _db
        .into(_db.reminders)
        .insert(
          RemindersCompanion.insert(
            id: id,
            title: title,
            notes: Value(notes),
            targetDate: targetDate,
            isPushEnabled: Value(isPushEnabled),
            priorDays: Value(priorDays),
            notificationId: notificationId,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> deleteReminder(String id) async {
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();
  }
}
