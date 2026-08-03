// features/custom_budgets/services/custom_budget_service.dart

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../models/custom_budget_details.dart';

class CustomBudgetService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CustomBudgetService(this._db);

  Stream<List<CustomBudgetWithDetails>> watchBudgets(bool isSettled) {
    return (_db.select(_db.customBudgets)
          ..where((t) => t.isSettled.equals(isSettled))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .asyncMap((budgets) async {
      List<CustomBudgetWithDetails> result = [];
      for (var b in budgets) {
        double spent = await _calculateSpentAmount(b);
        result.add(CustomBudgetWithDetails(budget: b, spent: spent));
      }
      return result;
    });
  }

  Future<double> _calculateSpentAmount(CustomBudget b) async {
    // If it's settled, return the frozen snapshot amount immediately
    if (b.isSettled && b.settledAmount != null) {
      return b.settledAmount!;
    }

    final query = _db.select(_db.transactions)..where((t) => t.type.equals('Expense'));
    query.where((t) => t.date.isBetweenValues(b.startDate, b.endDate));

    if (b.categoryId != null) query.where((t) => t.categoryId.equals(b.categoryId!));
    if (b.subCategory != null) query.where((t) => t.subCategory.equals(b.subCategory!));
    if (b.bucketId != null) query.where((t) => t.bucketId.equals(b.bucketId!));
    if (b.accountId != null) query.where((t) => t.accountId.equals(b.accountId!));

    final txs = await query.get();
    
    double total = 0.0;
    for (var tx in txs) {
      total += tx.amount;
    }
    return total;
  }

  Future<void> saveCustomBudget({
    String? existingId,
    required String name,
    required double amountLimit,
    required String timeFrame,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? subCategory,
    int? bucketId,
    String? accountId,
  }) async {
    final companion = CustomBudgetsCompanion(
      name: Value(name),
      amountLimit: Value(amountLimit),
      timeFrame: Value(timeFrame),
      startDate: Value(startDate),
      endDate: Value(endDate),
      categoryId: Value(categoryId),
      subCategory: Value(subCategory),
      bucketId: Value(bucketId),
      accountId: Value(accountId),
    );

    if (existingId == null) {
      await _db.into(_db.customBudgets).insert(
            companion.copyWith(id: Value(_uuid.v4())),
          );
    } else {
      await (_db.update(_db.customBudgets)..where((t) => t.id.equals(existingId))).write(companion);
    }
  }

  Future<void> settleBudget(String id) async {
    final existing = await (_db.select(_db.customBudgets)..where((t) => t.id.equals(id))).getSingle();
    final spent = await _calculateSpentAmount(existing);
    
    final now = DateTime.now();
    final frozenEndDate = now.isBefore(existing.endDate) ? now : existing.endDate;

    await (_db.update(_db.customBudgets)..where((t) => t.id.equals(id)))
        .write(CustomBudgetsCompanion(
          isSettled: const Value(true),
          endDate: Value(frozenEndDate),
          settledAmount: Value(spent),
        ));
  }

  Future<void> deleteBudget(String id) async {
    await (_db.delete(_db.customBudgets)..where((t) => t.id.equals(id))).go();
  }
}