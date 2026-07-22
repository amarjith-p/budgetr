import 'package:drift/drift.dart';

class TransactionCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'Expense' or 'Income'
  TextColumn get subCategories => text()(); // Stored as JSON string list
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
  TextColumn get type => text()(); // 'Savings Account', 'Credit Cards', etc.
  TextColumn get last4 => text().withLength(min: 4, max: 4)();
  RealColumn get balance => real().withDefault(const Constant(0.0))(); 
  RealColumn get creditLimit => real().nullable()(); // Null if not Credit Card
  IntColumn get billDate => integer().nullable()(); // 1-31
  IntColumn get dueDate => integer().nullable()(); // 1-31
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}