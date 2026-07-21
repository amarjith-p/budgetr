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