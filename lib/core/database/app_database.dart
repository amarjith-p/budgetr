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
  MonthlyBudgets, 
  ClosedBudgetSnapshots, // <-- NEW TABLE ADDED
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // --- BUMP TO VERSION 11 ---
  @override
  int get schemaVersion => 14; 

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
      if (from < 10) await m.addColumn(transactions, transactions.bucketName);
      if (from < 11) {
        // --- NEW: MIGRATION FOR DETAILED CLOSING SNAPSHOTS ---
        await m.createTable(closedBudgetSnapshots);
      }
      if (from < 12) {
        await m.addColumn(transactions, transactions.locationName);
        await m.addColumn(transactions, transactions.latitude);
        await m.addColumn(transactions, transactions.longitude);
      }
      if (from < 13) {
        await m.addColumn(accounts, accounts.isHidden);
       }
       if (from < 14) {
        // --- NEW MIGRATION FOR PAYABLE ACCOUNTS ---
        await m.addColumn(accounts, accounts.isCreditPayable);
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