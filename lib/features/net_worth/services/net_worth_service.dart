import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class NetWorthService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  NetWorthService(this._db);

  Stream<List<NetWorthRecord>> watchNetWorthRecords() {
    return (_db.select(_db.netWorthRecords)..orderBy([
          (t) =>
              OrderingTerm(expression: t.recordedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<void> addNetWorthRecord(NetWorthRecordsCompanion entry) async {
    // Inject UUID and current timestamp
    final finalEntry = entry.copyWith(
      id: Value(_uuid.v4()),
      recordedAt: Value(DateTime.now()),
    );
    await _db.into(_db.netWorthRecords).insert(finalEntry);
  }

  Future<void> deleteNetWorthRecord(String id) async {
    await (_db.delete(_db.netWorthRecords)..where((t) => t.id.equals(id))).go();
  }
}
