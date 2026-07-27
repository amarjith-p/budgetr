import 'dart:convert';
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
    final existing = await (_db.select(_db.monthlyBudgets)
          ..where((t) => t.month.equals(month) & t.year.equals(year)))
        .getSingleOrNull();

    if (existing != null) {
      // RULE: If editing an existing budget, ONLY update values. 
      // Do NOT overwrite the historical bucketsSnapshot.
      await _db.update(_db.monthlyBudgets).replace(
        existing.copyWith(
          salaryIncome: salary, 
          extraIncome: extra, 
          deductions: deductions
        ),
      );
    } else {
      // RULE: If creating a fresh budget, take a hard JSON snapshot of the current global buckets.
      final currentBuckets = await _db.select(_db.budgetBuckets).get();
      
      final snapshotList = currentBuckets.map((b) => {
        'id': b.id,
        'name': b.name,
        'percentage': b.percentage,
        // FIX: Removed the non-existent iconCode reference
      }).toList();
      
      final snapshotJson = jsonEncode(snapshotList);

      await _db.into(_db.monthlyBudgets).insert(MonthlyBudgetsCompanion.insert(
        id: _uuid.v4(),
        month: month,
        year: year,
        salaryIncome: Value(salary),
        extraIncome: Value(extra),
        deductions: Value(deductions),
        bucketsSnapshot: Value(snapshotJson),
      ));
    }
  }
}