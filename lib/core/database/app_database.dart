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
  MonthlyBudgets, // <-- NEW TABLE ADDED
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 10; 

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) await m.addColumn(transactions, transactions.isSpillover);
      if (from < 4) await m.addColumn(transactions, transactions.isSettlementVerified);
      if (from < 5) await m.addColumn(accounts, accounts.displayOrder);
      if (from < 6) await m.createTable(monthlyBudgets);
      if (from < 7) await m.addColumn(monthlyBudgets, monthlyBudgets.bucketsSnapshot);
      if (from < 8) await m.addColumn(monthlyBudgets, monthlyBudgets.isClosed);
      if (from < 9) {
        await m.addColumn(monthlyBudgets, monthlyBudgets.closedTotalSpent);
        await m.addColumn(monthlyBudgets, monthlyBudgets.closedOutOfBucket);
        await m.addColumn(monthlyBudgets, monthlyBudgets.closedRemaining);
      }
      if (from < 10) {
        // --- RULE 7: MIGRATION FOR FROZEN BUCKET NAME ---
        await m.addColumn(transactions, transactions.bucketName);
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