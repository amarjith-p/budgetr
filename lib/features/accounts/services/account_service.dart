import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class AccountService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  AccountService(this._db);

  Stream<List<Account>> watchAccounts() {
    return (_db.select(_db.accounts)..orderBy([
          (t) =>
              OrderingTerm(expression: t.displayOrder, mode: OrderingMode.asc),
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
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
    double? totalInterestPayable,
    double? totalTaxPayable,
    double? bankCharges, // <-- THIS WAS MISSING
  }) async {
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
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
            totalInterestPayable: Value(totalInterestPayable),
            totalTaxPayable: Value(totalTaxPayable),
            bankCharges: Value(bankCharges), // <-- MAPS TO YOUR NEW DB FIELD
          ),
        );
  }

  Future<void> updateAccount(Account account) async {
    await _db.update(_db.accounts).replace(account);
  }

  Future<void> deleteAccount(String id) async {
    await _db.transaction(() async {
      // 1. Fetch all transactions where this account is either the source or destination
      final relatedTxs = await (_db.select(
        _db.transactions,
      )..where((t) => t.accountId.equals(id) | t.toAccountId.equals(id))).get();

      for (final tx in relatedTxs) {
        if (tx.accountId == id &&
            tx.toAccountId != null &&
            !tx.toAccountId!.startsWith('EXTERNAL')) {
          // Scenario A: Transfer FROM the deleted account TO a surviving account
          // Action: Convert it into an 'EXTERNAL_IN' for the surviving account
          await _db
              .update(_db.transactions)
              .replace(
                tx.copyWith(
                  accountId: tx.toAccountId,
                  toAccountId: const Value('EXTERNAL_IN'),
                ),
              );
        } else if (tx.toAccountId == id && tx.accountId != id) {
          // Scenario B: Transfer FROM a surviving account TO the deleted account
          // Action: Convert it into an 'EXTERNAL_OUT' for the surviving account
          await _db
              .update(_db.transactions)
              .replace(tx.copyWith(toAccountId: const Value('EXTERNAL_OUT')));
        } else {
          // Scenario C: Standard Income/Expense or an already-external transfer
          // Action: Safe to delete completely
          await (_db.delete(
            _db.transactions,
          )..where((t) => t.id.equals(tx.id))).go();
        }
      }

      // 2. Finally, safely delete the account itself
      await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> reorderAccounts(List<Account> accounts) async {
    await _db.batch((batch) {
      for (final acc in accounts) {
        batch.replace(_db.accounts, acc);
      }
    });
  }

  // --- SETTLE LOAN ACTION ---
  Future<bool> settleLoan(String accountId) async {
    try {
      await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
          .write(const AccountsCompanion(isClosed: Value(true)));
      return true;
    } catch (e) {
      return false;
    }
  }
}
