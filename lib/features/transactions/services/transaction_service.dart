import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class TransactionWithDetails {
  final TransactionRecord transaction;
  final Account account;
  final Account? toAccount;
  final TransactionCategory? category;
  final BudgetBucket? bucket;

  TransactionWithDetails({
    required this.transaction,
    required this.account,
    this.toAccount,
    this.category,
    this.bucket,
  });
}

class TransactionService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TransactionService(this._db);

  Stream<List<TransactionWithDetails>> watchTransactionsForAccount(String accountId) {
    final toAccountAlias = _db.alias(_db.accounts, 'to_account');

    final query = _db.select(_db.transactions).join([
      innerJoin(_db.accounts, _db.accounts.id.equalsExp(_db.transactions.accountId)),
      leftOuterJoin(toAccountAlias, toAccountAlias.id.equalsExp(_db.transactions.toAccountId)),
      leftOuterJoin(_db.transactionCategories, _db.transactionCategories.id.equalsExp(_db.transactions.categoryId)),
      leftOuterJoin(_db.budgetBuckets, _db.budgetBuckets.id.equalsExp(_db.transactions.bucketId)),
    ])
    ..where(_db.transactions.accountId.equals(accountId) | _db.transactions.toAccountId.equals(accountId))
    ..orderBy([OrderingTerm.desc(_db.transactions.date)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithDetails(
          transaction: row.readTable(_db.transactions),
          account: row.readTable(_db.accounts),
          toAccount: row.readTableOrNull(toAccountAlias),
          category: row.readTableOrNull(_db.transactionCategories),
          bucket: row.readTableOrNull(_db.budgetBuckets),
        );
      }).toList();
    });
  }

  Future<void> logTransaction({
    required String type,
    required double amount,
    required DateTime date,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    String? subCategory,
    int? bucketId,
    String? notes,
    bool isSpillover = false, 
    bool isSettlementVerified = false, // <-- NEW
  }) async {
    String dbAccountId = accountId;
    String? dbToAccountId = toAccountId;
    
    if (type == 'Transfer') {
      if (accountId == 'EXTERNAL') {
        dbAccountId = toAccountId!; 
        dbToAccountId = 'EXTERNAL_IN';
      } else if (toAccountId == 'EXTERNAL') {
        dbAccountId = accountId;
        dbToAccountId = 'EXTERNAL_OUT';
      } else if (accountId == toAccountId) {
        throw Exception("Cannot transfer to the same account.");
      }
    } else {
      dbToAccountId = null; 
    }

    await _db.transaction(() async {
      final sourceAcc = await (_db.select(_db.accounts)..where((a) => a.id.equals(dbAccountId))).getSingle();
      double newSourceBalance = sourceAcc.balance;
      
      if (type == 'Expense') newSourceBalance -= amount;
      if (type == 'Income') newSourceBalance += amount;
      if (type == 'Transfer') {
        if (dbToAccountId == 'EXTERNAL_IN') newSourceBalance += amount; 
        else if (dbToAccountId == 'EXTERNAL_OUT') newSourceBalance -= amount; 
        else newSourceBalance -= amount; 
      }

      await _db.update(_db.accounts).replace(sourceAcc.copyWith(balance: newSourceBalance));
      
      if (type == 'Transfer' && dbToAccountId != null && !dbToAccountId.startsWith('EXTERNAL')) {
        final destAcc = await (_db.select(_db.accounts)..where((a) => a.id.equals(dbToAccountId!))).getSingle();
        await _db.update(_db.accounts).replace(destAcc.copyWith(balance: destAcc.balance + amount));
      }

      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
         id: _uuid.v4(), type: type, amount: amount, date: date,
         accountId: dbAccountId, toAccountId: Value(dbToAccountId),
         categoryId: Value(categoryId), subCategory: Value(subCategory),
         bucketId: Value(bucketId), notes: Value(notes),
         isSpillover: Value(isSpillover), 
         isSettlementVerified: Value(isSettlementVerified), // <-- NEW
      ));
    });
  }

  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required DateTime date,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    String? subCategory,
    int? bucketId,
    String? notes,
    bool isSpillover = false, 
    bool isSettlementVerified = false, // <-- NEW
  }) async {
    String dbAccountId = accountId;
    String? dbToAccountId = toAccountId;
    
    if (type == 'Transfer') {
      if (accountId == 'EXTERNAL') {
        dbAccountId = toAccountId!; 
        dbToAccountId = 'EXTERNAL_IN';
      } else if (toAccountId == 'EXTERNAL') {
        dbAccountId = accountId;
        dbToAccountId = 'EXTERNAL_OUT';
      }
    } else {
      dbToAccountId = null; 
    }

    await _db.transaction(() async {
      final oldTx = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingle();
      var oldSourceAcc = await (_db.select(_db.accounts)..where((a) => a.id.equals(oldTx.accountId))).getSingle();
      double revSourceBalance = oldSourceAcc.balance;
      
      if (oldTx.type == 'Expense') revSourceBalance += oldTx.amount;
      if (oldTx.type == 'Income') revSourceBalance -= oldTx.amount;
      if (oldTx.type == 'Transfer') {
        if (oldTx.toAccountId == 'EXTERNAL_IN') revSourceBalance -= oldTx.amount;
        else if (oldTx.toAccountId == 'EXTERNAL_OUT') revSourceBalance += oldTx.amount;
        else revSourceBalance += oldTx.amount;
      }

      await _db.update(_db.accounts).replace(oldSourceAcc.copyWith(balance: revSourceBalance));

      if (oldTx.type == 'Transfer' && oldTx.toAccountId != null && !oldTx.toAccountId!.startsWith('EXTERNAL')) {
        var oldDestAcc = await (_db.select(_db.accounts)..where((a) => a.id.equals(oldTx.toAccountId!))).getSingle();
        await _db.update(_db.accounts).replace(oldDestAcc.copyWith(balance: oldDestAcc.balance - oldTx.amount));
      }

      var newSourceAcc = await (_db.select(_db.accounts)..where((a) => a.id.equals(dbAccountId))).getSingle();
      double newSourceBalance = newSourceAcc.balance;
      
      if (type == 'Expense') newSourceBalance -= amount;
      if (type == 'Income') newSourceBalance += amount;
      if (type == 'Transfer') {
        if (dbToAccountId == 'EXTERNAL_IN') newSourceBalance += amount;
        else if (dbToAccountId == 'EXTERNAL_OUT') newSourceBalance -= amount;
        else newSourceBalance -= amount;
      }

      await _db.update(_db.accounts).replace(newSourceAcc.copyWith(balance: newSourceBalance));

      if (type == 'Transfer' && dbToAccountId != null && !dbToAccountId.startsWith('EXTERNAL')) {
        var newDestAcc = await (_db.select(_db.accounts)..where((a) => a.id.equals(dbToAccountId!))).getSingle();
        await _db.update(_db.accounts).replace(newDestAcc.copyWith(balance: newDestAcc.balance + amount));
      }

      await _db.update(_db.transactions).replace(oldTx.copyWith(
        type: type, amount: amount, date: date, accountId: dbAccountId,
        toAccountId: Value(dbToAccountId), categoryId: Value(categoryId),
        subCategory: Value(subCategory), bucketId: Value(bucketId), notes: Value(notes),
        isSpillover: isSpillover, 
        isSettlementVerified: isSettlementVerified, // <-- NEW
      ));
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _db.transaction(() async {
      final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(transactionId))).getSingle();
      final sourceAcc = await (_db.select(_db.accounts)..where((a) => a.id.equals(tx.accountId))).getSingle();
      double revSourceBalance = sourceAcc.balance;
      
      if (tx.type == 'Expense') revSourceBalance += tx.amount;
      if (tx.type == 'Income') revSourceBalance -= tx.amount;
      if (tx.type == 'Transfer') {
        if (tx.toAccountId == 'EXTERNAL_IN') revSourceBalance -= tx.amount;
        else if (tx.toAccountId == 'EXTERNAL_OUT') revSourceBalance += tx.amount;
        else revSourceBalance += tx.amount;
      }

      await _db.update(_db.accounts).replace(sourceAcc.copyWith(balance: revSourceBalance));

      if (tx.type == 'Transfer' && tx.toAccountId != null && !tx.toAccountId!.startsWith('EXTERNAL')) {
        final destAcc = await (_db.select(_db.accounts)..where((a) => a.id.equals(tx.toAccountId!))).getSingle();
        await _db.update(_db.accounts).replace(destAcc.copyWith(balance: destAcc.balance - tx.amount));
      }

      await (_db.delete(_db.transactions)..where((t) => t.id.equals(transactionId))).go();
    });
  }

  Future<void> toggleSpillover(String transactionId, bool isSpillover) async {
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(transactionId))).getSingle();
    // Smart Logic: If pushed to next cycle, it can't be "Settled in current" anymore.
    await _db.update(_db.transactions).replace(
      tx.copyWith(
        isSpillover: isSpillover,
        isSettlementVerified: isSpillover ? false : tx.isSettlementVerified,
      )
    );
  }

  // --- NEW: Toggle the verified state ---
  Future<void> verifySettlement(String transactionId, bool isVerified) async {
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(transactionId))).getSingle();
    // Smart Logic: If verified to stay in current, it can't be a spillover.
    await _db.update(_db.transactions).replace(
      tx.copyWith(
        isSettlementVerified: isVerified,
        isSpillover: isVerified ? false : tx.isSpillover,
      )
    );
  }
}