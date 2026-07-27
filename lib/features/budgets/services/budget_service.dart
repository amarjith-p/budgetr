import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class BudgetService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  BudgetService(this._db);

  Stream<MonthlyBudget?> watchBudgetForMonth(int month, int year) {
    return (_db.select(_db.monthlyBudgets)
          ..where((t) => t.month.equals(month) & t.year.equals(year)))
        .watchSingleOrNull();
  }

  Future<void> saveBudget({
    required int month,
    required int year,
    required double salary,
    required double extra,
    required double deductions,
  }) async {
    // Check if one exists to overwrite, otherwise insert new
    final existing = await (_db.select(_db.monthlyBudgets)
          ..where((t) => t.month.equals(month) & t.year.equals(year)))
        .getSingleOrNull();

    if (existing != null) {
      await _db.update(_db.monthlyBudgets).replace(
        existing.copyWith(salaryIncome: salary, extraIncome: extra, deductions: deductions),
      );
    } else {
      await _db.into(_db.monthlyBudgets).insert(MonthlyBudgetsCompanion.insert(
        id: _uuid.v4(),
        month: month,
        year: year,
        salaryIncome: Value(salary),
        extraIncome: Value(extra),
        deductions: Value(deductions),
      ));
    }
  }
}