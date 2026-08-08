// features/transactions/services/transaction_service.dart
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

  Stream<List<TransactionWithDetails>> watchTransactionsForAccount(
    String accountId,
  ) {
    // ... Keep exact existing watchTransactionsForAccount logic ...
    final toAccountAlias = _db.alias(_db.accounts, 'to_account');
    final query =
        _db.select(_db.transactions).join([
            innerJoin(
              _db.accounts,
              _db.accounts.id.equalsExp(_db.transactions.accountId),
            ),
            leftOuterJoin(
              toAccountAlias,
              toAccountAlias.id.equalsExp(_db.transactions.toAccountId),
            ),
            leftOuterJoin(
              _db.transactionCategories,
              _db.transactionCategories.id.equalsExp(
                _db.transactions.categoryId,
              ),
            ),
            leftOuterJoin(
              _db.budgetBuckets,
              _db.budgetBuckets.id.equalsExp(_db.transactions.bucketId),
            ),
          ])
          ..where(
            _db.transactions.accountId.equals(accountId) |
                _db.transactions.toAccountId.equals(accountId),
          )
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

  Stream<List<TransactionWithDetails>> watchAllTransactions() {
    // ... Keep exact existing watchAllTransactions logic ...
    final toAccountAlias = _db.alias(_db.accounts, 'to_account');
    final query =
        _db.select(_db.transactions).join([
            innerJoin(
              _db.accounts,
              _db.accounts.id.equalsExp(_db.transactions.accountId),
            ),
            leftOuterJoin(
              toAccountAlias,
              toAccountAlias.id.equalsExp(_db.transactions.toAccountId),
            ),
            leftOuterJoin(
              _db.transactionCategories,
              _db.transactionCategories.id.equalsExp(
                _db.transactions.categoryId,
              ),
            ),
            leftOuterJoin(
              _db.budgetBuckets,
              _db.budgetBuckets.id.equalsExp(_db.transactions.bucketId),
            ),
          ])
          ..where(_db.accounts.type.isNotValue('Loan'))
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
    String? categoryName, // <-- NEW
    int? categoryIcon, // <-- NEW
    String? subCategory,
    int? bucketId,
    String? bucketName,
    String? notes,
    bool isSpillover = false,
    bool isSettlementVerified = false,
    String? locationName,
    double? latitude,
    double? longitude,
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
      final sourceAcc = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(dbAccountId))).getSingle();
      double newSourceBalance = sourceAcc.balance;

      bool isLoanFee =
          subCategory == 'Loan Interest' ||
          subCategory == 'Tax on Interest' ||
          subCategory == 'Bank Charges on Loan';

      if (type == 'Expense' && !isLoanFee) newSourceBalance -= amount;
      if (type == 'Income') newSourceBalance += amount;
      if (type == 'Transfer') {
        if (dbToAccountId == 'EXTERNAL_IN')
          newSourceBalance += amount;
        else if (dbToAccountId == 'EXTERNAL_OUT')
          newSourceBalance -= amount;
        else
          newSourceBalance -= amount;
      }

      await _db
          .update(_db.accounts)
          .replace(sourceAcc.copyWith(balance: newSourceBalance));

      if (type == 'Transfer' &&
          dbToAccountId != null &&
          !dbToAccountId.startsWith('EXTERNAL')) {
        final destAcc = await (_db.select(
          _db.accounts,
        )..where((a) => a.id.equals(dbToAccountId!))).getSingle();
        await _db
            .update(_db.accounts)
            .replace(destAcc.copyWith(balance: destAcc.balance + amount));
      }

      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: _uuid.v4(),
              type: type,
              amount: amount,
              date: date,
              accountId: dbAccountId,
              toAccountId: Value(dbToAccountId),
              categoryId: Value(categoryId),
              categoryName: Value(categoryName), // <-- SAVED
              categoryIcon: Value(categoryIcon), // <-- SAVED
              subCategory: Value(subCategory),
              bucketId: Value(bucketId),
              bucketName: Value(bucketName),
              notes: Value(notes),
              isSpillover: Value(isSpillover),
              isSettlementVerified: Value(isSettlementVerified),
              locationName: Value(locationName),
              latitude: Value(latitude),
              longitude: Value(longitude),
            ),
          );
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
    String? categoryName, // <-- NEW
    int? categoryIcon, // <-- NEW
    String? subCategory,
    int? bucketId,
    String? bucketName,
    String? notes,
    bool isSpillover = false,
    bool isSettlementVerified = false,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    // --- MULTI-LEG LOAN SYNCHRONIZATION ---
    if (id.startsWith('LOAN_TX_')) {
      final parts = id.split('_');
      final prefix = '${parts[0]}_${parts[1]}_${parts[2]}';
      final legType = parts[3];

      await _db.transaction(() async {
        final oldTx = await (_db.select(
          _db.transactions,
        )..where((t) => t.id.equals(id))).getSingle();
        final double diff = amount - oldTx.amount;

        await _db
            .update(_db.transactions)
            .replace(
              oldTx.copyWith(
                amount: amount,
                date: date,
                categoryId: Value(categoryId),
                categoryName: Value(categoryName), // <-- SAVED
                categoryIcon: Value(categoryIcon), // <-- SAVED
                subCategory: Value(subCategory),
                bucketId: Value(bucketId),
                bucketName: Value(bucketName),
                notes: Value(notes),
                locationName: Value(locationName),
                latitude: Value(latitude),
                longitude: Value(longitude),
              ),
            );

        // ... Keep existing exact loan sync logic ...
        final isSourceLeg = legType.startsWith('SOURCE');
        final isLoanLeg = legType.startsWith('LOAN');

        if (isSourceLeg) {
          final sourceAcc = await (_db.select(
            _db.accounts,
          )..where((a) => a.id.equals(oldTx.accountId))).getSingle();
          await _db
              .update(_db.accounts)
              .replace(sourceAcc.copyWith(balance: sourceAcc.balance - diff));
        } else if (legType == 'LOANPRIN') {
          final loanAcc = await (_db.select(
            _db.accounts,
          )..where((a) => a.id.equals(oldTx.accountId))).getSingle();
          await _db
              .update(_db.accounts)
              .replace(loanAcc.copyWith(balance: loanAcc.balance - diff));
        }

        String oppositeLegId = '';
        if (legType == 'SOURCEPRIN')
          oppositeLegId = '${prefix}_LOANPRIN';
        else if (legType == 'SOURCEINT')
          oppositeLegId = '${prefix}_LOANINT';
        else if (legType == 'SOURCETAX')
          oppositeLegId = '${prefix}_LOANTAX';
        else if (legType == 'SOURCEFEE')
          oppositeLegId = '${prefix}_LOANFEE';
        else if (legType == 'LOANPRIN')
          oppositeLegId = '${prefix}_SOURCEPRIN';
        else if (legType == 'LOANINT')
          oppositeLegId = '${prefix}_SOURCEINT';
        else if (legType == 'LOANTAX')
          oppositeLegId = '${prefix}_SOURCETAX';
        else if (legType == 'LOANFEE')
          oppositeLegId = '${prefix}_SOURCEFEE';

        if (isSourceLeg) {
          if (oppositeLegId.isNotEmpty) {
            final oppTx = await (_db.select(
              _db.transactions,
            )..where((t) => t.id.equals(oppositeLegId))).getSingleOrNull();
            if (oppTx != null) {
              await _db
                  .update(_db.transactions)
                  .replace(oppTx.copyWith(amount: oppTx.amount + diff));
              if (oppositeLegId == '${prefix}_LOANPRIN') {
                final oppAcc = await (_db.select(
                  _db.accounts,
                )..where((a) => a.id.equals(oppTx.accountId))).getSingle();
                await _db
                    .update(_db.accounts)
                    .replace(oppAcc.copyWith(balance: oppAcc.balance - diff));
              }
            }
          }
        } else if (isLoanLeg) {
          TransactionRecord? oppTx;
          if (oppositeLegId.isNotEmpty) {
            oppTx = await (_db.select(
              _db.transactions,
            )..where((t) => t.id.equals(oppositeLegId))).getSingleOrNull();
          }
          if (oppTx == null) {
            oppTx =
                await (_db.select(_db.transactions)
                      ..where((t) => t.id.equals('${prefix}_SOURCETRANSFER')))
                    .getSingleOrNull();
          }
          if (oppTx != null) {
            await _db
                .update(_db.transactions)
                .replace(oppTx.copyWith(amount: oppTx.amount + diff));
            final oppAcc = await (_db.select(
              _db.accounts,
            )..where((a) => a.id.equals(oppTx!.accountId))).getSingle();
            await _db
                .update(_db.accounts)
                .replace(oppAcc.copyWith(balance: oppAcc.balance - diff));
          }
        }
      });
      return;
    }

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
      final oldTx = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(id))).getSingle();
      var oldSourceAcc = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(oldTx.accountId))).getSingle();
      double revSourceBalance = oldSourceAcc.balance;

      bool isOldLoanFee =
          oldTx.subCategory == 'Loan Interest' ||
          oldTx.subCategory == 'Tax on Interest' ||
          oldTx.subCategory == 'Bank Charges on Loan';

      if (oldTx.type == 'Expense' && !isOldLoanFee)
        revSourceBalance += oldTx.amount;
      if (oldTx.type == 'Income') revSourceBalance -= oldTx.amount;
      if (oldTx.type == 'Transfer') {
        if (oldTx.toAccountId == 'EXTERNAL_IN')
          revSourceBalance -= oldTx.amount;
        else if (oldTx.toAccountId == 'EXTERNAL_OUT')
          revSourceBalance += oldTx.amount;
        else
          revSourceBalance += oldTx.amount;
      }

      await _db
          .update(_db.accounts)
          .replace(oldSourceAcc.copyWith(balance: revSourceBalance));

      if (oldTx.type == 'Transfer' &&
          oldTx.toAccountId != null &&
          !oldTx.toAccountId!.startsWith('EXTERNAL')) {
        var oldDestAcc = await (_db.select(
          _db.accounts,
        )..where((a) => a.id.equals(oldTx.toAccountId!))).getSingle();
        await _db
            .update(_db.accounts)
            .replace(
              oldDestAcc.copyWith(balance: oldDestAcc.balance - oldTx.amount),
            );
      }

      var newSourceAcc = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(dbAccountId))).getSingle();
      double newSourceBalance = newSourceAcc.balance;

      bool isNewLoanFee =
          subCategory == 'Loan Interest' ||
          subCategory == 'Tax on Interest' ||
          subCategory == 'Bank Charges on Loan';

      if (type == 'Expense' && !isNewLoanFee) newSourceBalance -= amount;
      if (type == 'Income') newSourceBalance += amount;
      if (type == 'Transfer') {
        if (dbToAccountId == 'EXTERNAL_IN')
          newSourceBalance += amount;
        else if (dbToAccountId == 'EXTERNAL_OUT')
          newSourceBalance -= amount;
        else
          newSourceBalance -= amount;
      }

      await _db
          .update(_db.accounts)
          .replace(newSourceAcc.copyWith(balance: newSourceBalance));

      if (type == 'Transfer' &&
          dbToAccountId != null &&
          !dbToAccountId.startsWith('EXTERNAL')) {
        var newDestAcc = await (_db.select(
          _db.accounts,
        )..where((a) => a.id.equals(dbToAccountId!))).getSingle();
        await _db
            .update(_db.accounts)
            .replace(newDestAcc.copyWith(balance: newDestAcc.balance + amount));
      }

      await _db
          .update(_db.transactions)
          .replace(
            oldTx.copyWith(
              type: type,
              amount: amount,
              date: date,
              accountId: dbAccountId,
              toAccountId: Value(dbToAccountId),
              categoryId: Value(categoryId),
              categoryName: Value(categoryName), // <-- SAVED
              categoryIcon: Value(categoryIcon), // <-- SAVED
              subCategory: Value(subCategory),
              bucketId: Value(bucketId),
              bucketName: Value(bucketName),
              notes: Value(notes),
              isSpillover: isSpillover,
              isSettlementVerified: isSettlementVerified,
              locationName: Value(locationName),
              latitude: Value(latitude),
              longitude: Value(longitude),
            ),
          );
    });
  }

  // ... Keep deleteTransaction exactly the same ...
  Future<void> deleteTransaction(String transactionId) async {
    if (transactionId.startsWith('LOAN_TX_')) {
      final parts = transactionId.split('_');
      final prefix = '${parts[0]}_${parts[1]}_${parts[2]}';
      await _db.transaction(() async {
        final allLegs = await (_db.select(
          _db.transactions,
        )..where((t) => t.id.like('$prefix%'))).get();
        for (final tx in allLegs) {
          final acc = await (_db.select(
            _db.accounts,
          )..where((a) => a.id.equals(tx.accountId))).getSingle();
          if (tx.id.endsWith('_SOURCETRANSFER'))
            await _db
                .update(_db.accounts)
                .replace(acc.copyWith(balance: acc.balance + tx.amount));
          else if (tx.id.contains('_SOURCE'))
            await _db
                .update(_db.accounts)
                .replace(acc.copyWith(balance: acc.balance + tx.amount));
          else if (tx.id.endsWith('_LOANPRIN'))
            await _db
                .update(_db.accounts)
                .replace(acc.copyWith(balance: acc.balance + tx.amount));
          await (_db.delete(
            _db.transactions,
          )..where((t) => t.id.equals(tx.id))).go();
        }
      });
      return;
    }
    await _db.transaction(() async {
      final tx = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).getSingle();
      final sourceAcc = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(tx.accountId))).getSingle();
      double revSourceBalance = sourceAcc.balance;
      bool isLoanFee =
          tx.subCategory == 'Loan Interest' ||
          tx.subCategory == 'Tax on Interest' ||
          tx.subCategory == 'Bank Charges on Loan';
      if (tx.type == 'Expense' && !isLoanFee) revSourceBalance += tx.amount;
      if (tx.type == 'Income') revSourceBalance -= tx.amount;
      if (tx.type == 'Transfer') {
        if (tx.toAccountId == 'EXTERNAL_IN')
          revSourceBalance -= tx.amount;
        else if (tx.toAccountId == 'EXTERNAL_OUT')
          revSourceBalance += tx.amount;
        else
          revSourceBalance += tx.amount;
      }
      await _db
          .update(_db.accounts)
          .replace(sourceAcc.copyWith(balance: revSourceBalance));
      if (tx.type == 'Transfer' &&
          tx.toAccountId != null &&
          !tx.toAccountId!.startsWith('EXTERNAL')) {
        final destAcc = await (_db.select(
          _db.accounts,
        )..where((a) => a.id.equals(tx.toAccountId!))).getSingle();
        await _db
            .update(_db.accounts)
            .replace(destAcc.copyWith(balance: destAcc.balance - tx.amount));
      }
      await (_db.delete(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).go();
    });
  }

  Future<void> splitTransaction({
    required String originalTxId,
    required double splitAmount,
    required String type,
    required DateTime date,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    String? categoryName, // <-- NEW
    int? categoryIcon, // <-- NEW
    String? subCategory,
    int? bucketId,
    String? bucketName,
    String? notes,
    bool isSpillover = false,
    bool isSettlementVerified = false,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    await _db.transaction(() async {
      final origTx = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(originalTxId))).getSingle();
      final newOrigAmount = origTx.amount - splitAmount;

      if (newOrigAmount <= 0)
        throw Exception(
          "Split amount must be strictly less than the original amount.",
        );

      await updateTransaction(
        id: origTx.id,
        type: origTx.type,
        amount: newOrigAmount,
        date: origTx.date,
        accountId: origTx.accountId,
        toAccountId: origTx.toAccountId,
        categoryId: origTx.categoryId,
        categoryName: origTx.categoryName, // Retain original
        categoryIcon: origTx.categoryIcon, // Retain original
        subCategory: origTx.subCategory,
        bucketId: origTx.bucketId,
        bucketName: origTx.bucketName,
        notes: origTx.notes,
        isSpillover: origTx.isSpillover,
        isSettlementVerified: origTx.isSettlementVerified,
        locationName: origTx.locationName,
        latitude: origTx.latitude,
        longitude: origTx.longitude,
      );

      await logTransaction(
        type: type,
        amount: splitAmount,
        date: date,
        accountId: accountId,
        toAccountId: toAccountId,
        categoryId: categoryId,
        categoryName: categoryName, // Pass newly selected
        categoryIcon: categoryIcon, // Pass newly selected
        subCategory: subCategory,
        bucketId: bucketId,
        bucketName: bucketName,
        notes: notes,
        isSpillover: isSpillover,
        isSettlementVerified: isSettlementVerified,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
      );
    });
  }

  // ... Keep verifySettlement, toggleSpillover, logLoanPayment exact logic ...
  Future<void> toggleSpillover(String transactionId, bool isSpillover) async {
    final tx = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingle();
    await _db
        .update(_db.transactions)
        .replace(
          tx.copyWith(
            isSpillover: isSpillover,
            isSettlementVerified: isSpillover ? false : tx.isSettlementVerified,
          ),
        );
  }

  Future<void> verifySettlement(String transactionId, bool isVerified) async {
    final tx = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingle();
    await _db
        .update(_db.transactions)
        .replace(
          tx.copyWith(
            isSettlementVerified: isVerified,
            isSpillover: isVerified ? false : tx.isSpillover,
          ),
        );
  }

  Future<void> logLoanPayment({
    required String accountId,
    required double principal,
    required double interest,
    required double tax,
    required double bankCharges,
    required DateTime date,
    String? notes,
  }) async {
    await _db.transaction(() async {
      final loanAcc = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(accountId))).getSingle();
      if (principal > 0) {
        await _db
            .update(_db.accounts)
            .replace(loanAcc.copyWith(balance: loanAcc.balance - principal));
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: _uuid.v4(),
                type: 'Expense',
                amount: principal,
                date: date,
                accountId: accountId,
                subCategory: const Value('Loan Principal'),
                notes: Value(notes != null && notes.isNotEmpty ? notes : null),
              ),
            );
      }
      if (interest > 0)
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: _uuid.v4(),
                type: 'Expense',
                amount: interest,
                date: date,
                accountId: accountId,
                subCategory: const Value('Loan Interest'),
                notes: Value(notes != null && notes.isNotEmpty ? notes : null),
              ),
            );
      if (tax > 0)
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: _uuid.v4(),
                type: 'Expense',
                amount: tax,
                date: date,
                accountId: accountId,
                subCategory: const Value('Tax on Interest'),
                notes: Value(notes != null && notes.isNotEmpty ? notes : null),
              ),
            );
      if (bankCharges > 0)
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: _uuid.v4(),
                type: 'Expense',
                amount: bankCharges,
                date: date,
                accountId: accountId,
                subCategory: const Value('Bank Charges on Loan'),
                notes: Value(notes != null && notes.isNotEmpty ? notes : null),
              ),
            );
    });
  }

  // --- MULTI-LEG LOAN TRANSFER ---
  Future<void> logLoanTransfer({
    required String fromAccountId,
    required String loanAccountId,
    required double principal,
    required double interest,
    required double tax,
    required double bankCharges,
    required DateTime date,
    required bool markAsExpense,
    int? bucketId,
    String? bucketName,
    String? notes,
    bool isSpillover = false,
    bool isSettlementVerified = false,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    await _db.transaction(() async {
      final fromAcc = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(fromAccountId))).getSingle();
      final loanAcc = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(loanAccountId))).getSingle();

      final totalAmount = principal + interest + tax + bankCharges;
      final groupId = _uuid.v4();

      await _db
          .update(_db.accounts)
          .replace(fromAcc.copyWith(balance: fromAcc.balance - totalAmount));

      if (markAsExpense) {
        final bfCat =
            await (_db.select(_db.transactionCategories)
                  ..where((c) => c.name.equals('Banking & Financial')))
                .getSingleOrNull();
        final taxCat =
            await (_db.select(_db.transactionCategories)
                  ..where((c) => c.name.equals('Taxes & Gov. Charges')))
                .getSingleOrNull();

        Future<void> insertFromTx(
          double amt,
          String idSuffix,
          String? catId,
          String? catName,
          int? catIcon,
          String subCat,
        ) async {
          if (amt > 0) {
            await _db
                .into(_db.transactions)
                .insert(
                  TransactionsCompanion.insert(
                    id: 'LOAN_TX_${groupId}_$idSuffix',
                    type: 'Expense',
                    amount: amt,
                    date: date,
                    accountId: fromAccountId,
                    categoryId: Value(catId),
                    categoryName: Value(catName), // <-- SAVED SNAPSHOT
                    categoryIcon: Value(catIcon), // <-- SAVED SNAPSHOT
                    subCategory: Value(subCat),
                    bucketId: Value(bucketId),
                    bucketName: Value(bucketName),
                    notes: Value(notes),
                    isSpillover: Value(isSpillover),
                    isSettlementVerified: Value(isSettlementVerified),
                    locationName: Value(locationName),
                    latitude: Value(latitude),
                    longitude: Value(longitude),
                  ),
                );
          }
        }

        await insertFromTx(
          principal,
          'SOURCEPRIN',
          bfCat?.id,
          bfCat?.name,
          bfCat?.iconCode,
          'Loan EMIs',
        );
        await insertFromTx(
          interest,
          'SOURCEINT',
          bfCat?.id,
          bfCat?.name,
          bfCat?.iconCode,
          'Interest Charges',
        );
        await insertFromTx(
          tax,
          'SOURCETAX',
          taxCat?.id,
          taxCat?.name,
          taxCat?.iconCode,
          'GST',
        );
        await insertFromTx(
          bankCharges,
          'SOURCEFEE',
          bfCat?.id,
          bfCat?.name,
          bfCat?.iconCode,
          'Processing Fees',
        );
      } else {
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'LOAN_TX_${groupId}_SOURCETRANSFER',
                type: 'Transfer',
                amount: totalAmount,
                date: date,
                accountId: fromAccountId,
                toAccountId: Value(loanAccountId),
                notes: Value(notes),
                isSpillover: Value(isSpillover),
                isSettlementVerified: Value(isSettlementVerified),
                locationName: Value(locationName),
                latitude: Value(latitude),
                longitude: Value(longitude),
              ),
            );
      }

      Future<void> insertLoanTx(
        double amt,
        String idSuffix,
        String subCat,
      ) async {
        if (amt > 0) {
          await _db
              .into(_db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  id: 'LOAN_TX_${groupId}_$idSuffix',
                  type: 'Expense',
                  amount: amt,
                  date: date,
                  accountId: loanAccountId,
                  subCategory: Value(subCat),
                  notes: Value(notes),
                  locationName: Value(locationName),
                  latitude: Value(latitude),
                  longitude: Value(longitude),
                ),
              );
        }
      }

      if (principal > 0) {
        await _db
            .update(_db.accounts)
            .replace(loanAcc.copyWith(balance: loanAcc.balance - principal));
        await insertLoanTx(principal, 'LOANPRIN', 'Loan Principal');
      }
      await insertLoanTx(interest, 'LOANINT', 'Loan Interest');
      await insertLoanTx(tax, 'LOANTAX', 'Tax on Interest');
      await insertLoanTx(bankCharges, 'LOANFEE', 'Bank Charges on Loan');
    });
  }
}
