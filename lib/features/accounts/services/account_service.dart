import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class AccountService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  AccountService(this._db);

  Stream<List<Account>> watchAccounts() {
    return (_db.select(_db.accounts)
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
    String? loanPurpose,
    double? loanPrincipal,
    double? interestRate,
    int? tenureMonths,
    DateTime? emiDate,
    DateTime? loanStartDate,
    DateTime? loanEndDate,
    // --- NEW PERSISTENT LOAN METRICS ---
    double? totalInterestPayable,
    double? totalTaxPayable,
  }) async {
    await _db.into(_db.accounts).insert(AccountsCompanion.insert(
      id: _uuid.v4(),
      name: name,
      providerName: providerName,
      type: type,
      balance: balance,
      last4: Value(last4),
      creditLimit: Value(creditLimit),
      billDate: Value(billDate),
      dueDate: Value(dueDate),
      loanPurpose: Value(loanPurpose),
      loanPrincipal: Value(loanPrincipal),
      interestRate: Value(interestRate),
      tenureMonths: Value(tenureMonths),
      emiDate: Value(emiDate),
      loanStartDate: Value(loanStartDate),
      loanEndDate: Value(loanEndDate),
      // --- MAP TO DB ---
      totalInterestPayable: Value(totalInterestPayable),
      totalTaxPayable: Value(totalTaxPayable),
    ));
  }

  Future<void> updateAccount(Account account) async {
    await _db.update(_db.accounts).replace(account);
  }

  Future<void> deleteAccount(String id) async {
    await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reorderAccounts(List<Account> accounts) async {
    await _db.batch((batch) {
      for (final acc in accounts) {
        batch.replace(_db.accounts, acc);
      }
    });
  }

  // --- NEW: SETTLE LOAN ACTION ---
  Future<bool> settleLoan(String accountId) async {
    try {
      await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
          .write(AccountsCompanion(isClosed: const Value(true)));
      return true;
    } catch (e) {
      return false;
    }
  }
}