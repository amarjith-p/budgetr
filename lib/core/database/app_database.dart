import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  TransactionCategories, 
  BudgetBuckets,
  Accounts,
  Transactions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // --- VERSION BUMP TO 4 ---
  @override
  int get schemaVersion => 4;

  // --- MIGRATION STRATEGY ---
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        await m.addColumn(transactions, transactions.isSpillover);
      }
      if (from < 4) {
        await m.addColumn(transactions, transactions.isSettlementVerified);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budgetr_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}