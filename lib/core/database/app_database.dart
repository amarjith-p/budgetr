// lib/core/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TransactionCategories,
    BudgetBuckets,
    Accounts,
    Transactions,
    MonthlyBudgets,
    ClosedBudgetSnapshots,
    CustomBudgets,
    Investments,
    InvestmentLogs,
    SmartTrackerTemplates,
    SmartTrackerRecords,
    AppNotifications,
    RecurringTransactionRules,
    Trips,
    Reminders,
    VaultRecords,
    StagedTransactions,
    ParserRules,
    Debts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // --- BUMPED TO VERSION 25 ---
  @override
  int get schemaVersion => 36;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) await m.addColumn(transactions, transactions.isSpillover);
      if (from < 4)
        await m.addColumn(transactions, transactions.isSettlementVerified);
      if (from < 5) await m.addColumn(accounts, accounts.displayOrder);
      if (from < 6) await m.createTable(monthlyBudgets);
      if (from < 7)
        await m.addColumn(monthlyBudgets, monthlyBudgets.bucketsSnapshot);
      if (from < 8) await m.addColumn(monthlyBudgets, monthlyBudgets.isClosed);
      if (from < 9) {
        await m.addColumn(monthlyBudgets, monthlyBudgets.closedTotalSpent);
        await m.addColumn(monthlyBudgets, monthlyBudgets.closedOutOfBucket);
        await m.addColumn(monthlyBudgets, monthlyBudgets.closedRemaining);
      }
      if (from < 10) await m.addColumn(transactions, transactions.bucketName);
      if (from < 11) await m.createTable(closedBudgetSnapshots);
      if (from < 12) {
        await m.addColumn(transactions, transactions.locationName);
        await m.addColumn(transactions, transactions.latitude);
        await m.addColumn(transactions, transactions.longitude);
      }
      if (from < 13) await m.addColumn(accounts, accounts.isHidden);
      if (from < 14) await m.addColumn(accounts, accounts.isCreditPayable);
      if (from < 15) await m.createTable(customBudgets);
      if (from < 16)
        await m.addColumn(customBudgets, customBudgets.settledAmount);
      if (from < 17) {
        await m.addColumn(accounts, accounts.loanPurpose);
        await m.addColumn(accounts, accounts.loanPrincipal);
        await m.addColumn(accounts, accounts.interestRate);
        await m.addColumn(accounts, accounts.tenureMonths);
        await m.addColumn(accounts, accounts.emiDate);
        await m.addColumn(accounts, accounts.loanStartDate);
        await m.addColumn(accounts, accounts.loanEndDate);
      }
      if (from < 18) {
        await m.addColumn(accounts, accounts.totalInterestPayable);
        await m.addColumn(accounts, accounts.totalTaxPayable);
      }
      if (from < 19) await m.addColumn(accounts, accounts.isClosed);
      if (from < 20) await m.addColumn(accounts, accounts.bankCharges);
      if (from < 21) {
        await m.addColumn(transactions, transactions.categoryName);
        await m.addColumn(transactions, transactions.categoryIcon);
      }
      if (from < 23) {
        await m.createTable(investments);
      }
      if (from < 24) {
        await m.createTable(investmentLogs);
      }
      if (from < 25) {
        // --- NEW MIGRATION: INVESTMENT CLOSURE ---
        await m.addColumn(investments, investments.isClosed);
        await m.addColumn(investments, investments.closeReason);
      }
      if (from < 26) {
        await m.createTable(smartTrackerTemplates);
      }
      if (from < 27) {
        await m.createTable(smartTrackerRecords);
      }
      if (from < 28) {
        await m.createTable(appNotifications);
      }
      if (from < 29) {
        await m.createTable(recurringTransactionRules);
      }
      if (from < 30) {
        await m.addColumn(
          recurringTransactionRules,
          recurringTransactionRules.serviceWebsite,
        );
        await m.addColumn(
          recurringTransactionRules,
          recurringTransactionRules.advancedSchedule,
        );
      }
      if (from < 31) {
        await m.createTable(trips);
      }
      if (from < 32) {
        await m.createTable(reminders);
      }
      if (from < 33) {
        await m.createTable(vaultRecords);
      }
      if (from < 35) {
        await m.createTable(stagedTransactions);
        await m.createTable(parserRules);
      }
      if (from < 36) {
        await m.createTable(debts); // <-- NEW
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
