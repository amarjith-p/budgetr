// core/database/tables.dart

import 'package:drift/drift.dart';

class TransactionCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get subCategories => text()();
  IntColumn get iconCode => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetBucket')
class BudgetBuckets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get percentage => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Account')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get providerName => text()();
  TextColumn get type => text()();
  TextColumn get last4 => text().withLength(min: 4, max: 4)();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  RealColumn get creditLimit => real().nullable()();
  IntColumn get billDate => integer().nullable()();
  IntColumn get dueDate => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isCreditPayable => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionRecord')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get accountId => text()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get subCategory => text().nullable()();
  IntColumn get bucketId => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSpillover => boolean().withDefault(const Constant(false))();
  BoolColumn get isSettlementVerified => boolean().withDefault(const Constant(false))();
  TextColumn get bucketName => text().nullable()();
  TextColumn get locationName => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MonthlyBudget')
class MonthlyBudgets extends Table {
  TextColumn get id => text()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get salaryIncome => real().withDefault(const Constant(0.0))();
  RealColumn get extraIncome => real().withDefault(const Constant(0.0))();
  RealColumn get deductions => real().withDefault(const Constant(0.0))();
  TextColumn get bucketsSnapshot => text().nullable()();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();
  RealColumn get closedTotalSpent => real().nullable()();
  RealColumn get closedOutOfBucket => real().nullable()();
  RealColumn get closedRemaining => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ClosedBudgetSnapshot')
class ClosedBudgetSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text()();
  RealColumn get salaryIncome => real()();
  RealColumn get extraIncome => real()();
  RealColumn get deductions => real()();
  RealColumn get effectiveIncome => real()();
  RealColumn get totalSpent => real()();
  RealColumn get totalOutOfBucket => real()();
  RealColumn get totalRemaining => real()();
  RealColumn get budgetedRemaining => real()();
  TextColumn get bucketDetailsJson => text()();
  DateTimeColumn get closedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
@DataClassName('CustomBudget')
class CustomBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amountLimit => real()();
  TextColumn get timeFrame => text()(); 
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get subCategory => text().nullable()();
  IntColumn get bucketId => integer().nullable()();
  TextColumn get accountId => text().nullable()();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  
  // --- NEW: Freezes the exact spent amount upon settlement ---
  RealColumn get settledAmount => real().nullable()(); 
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}