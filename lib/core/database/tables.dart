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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  BoolColumn get isSpillover => boolean().withDefault(const Constant(false))(); 
  // --- NEW: Tracks if the user confirmed it stays in the current bill ---
  BoolColumn get isSettlementVerified => boolean().withDefault(const Constant(false))(); 

  @override
  Set<Column> get primaryKey => {id};
}