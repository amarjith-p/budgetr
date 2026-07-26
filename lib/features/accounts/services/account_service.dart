import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class AccountService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  AccountService(this._db);

  Stream<List<Account>> watchAccounts() {
    return (_db.select(_db.accounts)
          // --- UPDATED: Primary sort by custom order, secondary sort by newest ---
          ..orderBy([
            (t) => OrderingTerm(expression: t.displayOrder, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<void> addAccount({
    required String name,
    required String providerName,
    required String type,
    required String last4,
    required double balance,
    double? creditLimit,
    int? billDate,
    int? dueDate,
  }) async {
    await _db.into(_db.accounts).insert(AccountsCompanion.insert(
      id: _uuid.v4(),
      name: name,
      providerName: providerName,
      type: type,
      last4: last4,
      balance: const Value.absent(), 
    ).copyWith(
      balance: Value(balance),
      creditLimit: Value(creditLimit),
      billDate: Value(billDate),
      dueDate: Value(dueDate),
      // New accounts automatically default to displayOrder: 0
    ));
  }

  Future<void> updateAccount(Account account) async {
    await _db.update(_db.accounts).replace(account);
  }

  Future<void> deleteAccount(String id) async {
    await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
  }

  // --- NEW: Lightning Fast Batch Reorder ---
  Future<void> reorderAccounts(List<Account> accounts) async {
    await _db.batch((batch) {
      for (final acc in accounts) {
        batch.replace(_db.accounts, acc);
      }
    });
  }
}