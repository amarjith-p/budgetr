// lib/features/investments/services/investment_service.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class InvestmentService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  InvestmentService(this._db);

  Stream<List<Investment>> watchInvestments() {
    return (_db.select(_db.investments)..orderBy([
          (t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
          (t) => OrderingTerm(
            expression: t.name,
            mode: OrderingMode.asc,
          ), // Fallback
        ]))
        .watch();
  }

  Future<void> addInvestment(InvestmentsCompanion entry) async {
    // REMOVED the auto-uuid override so the Provider can strictly assign the ID
    await _db.into(_db.investments).insert(entry);
  }

  // --- NEW: Safe Partial Update ---
  // Only updates fields explicitly passed in the companion (leaving balances untouched)
  Future<void> updateInvestmentDetails(InvestmentsCompanion entry) async {
    await (_db.update(
      _db.investments,
    )..where((t) => t.id.equals(entry.id.value))).write(entry);
  }

  Future<void> updateInvestment(Investment investment) async {
    await _db.update(_db.investments).replace(investment);
  }

  Future<void> deleteInvestment(String id) async {
    await (_db.delete(_db.investments)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<InvestmentLog>> watchInvestmentLogs(String investmentId) {
    return (_db.select(_db.investmentLogs)
          ..where((t) => t.investmentId.equals(investmentId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  // --- THE MASTER RECALCULATION ENGINE ---
  Future<void> _recalculateAndSave(
    String investmentId,
    Future<void> Function() dbMutation,
  ) async {
    await _db.transaction(() async {
      final inv = await (_db.select(
        _db.investments,
      )..where((t) => t.id.equals(investmentId))).getSingle();

      final oldLogs = await (_db.select(
        _db.investmentLogs,
      )..where((t) => t.investmentId.equals(investmentId))).get();

      // 1. Safely Reverse-Engineer the true Day 0 starting principal
      double baseInvested = inv.initialAmount;
      for (final l in oldLogs) {
        if (l.type == 'Deposit') baseInvested -= l.amount;
        if (l.type == 'Withdrawal') baseInvested += l.amount;
      }

      // 2. Perform the Mutation (Insert, Update, or Delete)
      await dbMutation();

      // 3. Fetch the new timeline chronologically
      // 3. Fetch the new timeline chronologically
      final newLogs =
          await (_db.select(_db.investmentLogs)
                ..where((t) => t.investmentId.equals(investmentId))
                ..orderBy([
                  (t) =>
                      OrderingTerm(expression: t.date, mode: OrderingMode.asc),
                  // FIX: Fallback to ID so chronological processing is strictly deterministic
                  (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
                ]))
              .get();

      // 4. Replay the Timeline Forward
      double runningInvested = baseInvested;
      double runningCurrent = baseInvested;

      for (final l in newLogs) {
        if (l.type == 'Deposit') {
          runningInvested += l.amount;
          runningCurrent += l.amount;
        } else if (l.type == 'Withdrawal') {
          runningInvested -= l.amount;
          runningCurrent -= l.amount;
        } else if (l.type == 'Update') {
          runningCurrent = l.amount;
        }
      }

      // 5. Save the mathematically perfect state
      await _db
          .update(_db.investments)
          .replace(
            inv.copyWith(
              initialAmount: runningInvested,
              currentValue: runningCurrent,
            ),
          );
    });
  }

  Future<void> logInvestmentTransaction({
    required String investmentId,
    required String type,
    required double amount,
    required DateTime date,
  }) async {
    await _recalculateAndSave(investmentId, () async {
      await _db
          .into(_db.investmentLogs)
          .insert(
            InvestmentLogsCompanion.insert(
              id: _uuid.v4(),
              investmentId: investmentId,
              type: type,
              amount: amount,
              date: date,
            ),
          );
    });
  }

  Future<void> updateInvestmentLog(InvestmentLog log) async {
    await _recalculateAndSave(log.investmentId, () async {
      await _db.update(_db.investmentLogs).replace(log);
    });
  }

  Future<void> deleteInvestmentLog(String logId, String investmentId) async {
    await _recalculateAndSave(investmentId, () async {
      await (_db.delete(
        _db.investmentLogs,
      )..where((t) => t.id.equals(logId))).go();
    });
  }

  Stream<List<InvestmentLog>> watchAllInvestmentLogs() {
    return (_db.select(_db.investmentLogs)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch();
  }
}
