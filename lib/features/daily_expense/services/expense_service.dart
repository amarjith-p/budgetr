import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../credit_tracker/services/credit_service.dart';
import '../models/expense_models.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ACCOUNTS ---
  Stream<List<ExpenseAccountModel>> getAccounts() {
    return _db
        .collection(FirebaseConstants.expenseAccounts)
        .orderBy('dashboardOrder', descending: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ExpenseAccountModel.fromFirestore(d)).toList());
  }

  Stream<List<ExpenseAccountModel>> getDashboardAccounts() {
    return _db
        .collection(FirebaseConstants.expenseAccounts)
        .orderBy('dashboardOrder', descending: false)
        .limit(6)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ExpenseAccountModel.fromFirestore(d)).toList());
  }

  Future<void> updateAccountOrder(List<ExpenseAccountModel> accounts) async {
    final batch = _db.batch();
    for (int i = 0; i < accounts.length; i++) {
      final account = accounts[i];
      if (account.dashboardOrder != i) {
        final ref =
            _db.collection(FirebaseConstants.expenseAccounts).doc(account.id);
        batch.update(ref, {'dashboardOrder': i});
      }
    }
    await batch.commit();
  }

  Future<void> addAccount(ExpenseAccountModel account) async {
    final snapshot =
        await _db.collection(FirebaseConstants.expenseAccounts).count().get();
    final count = snapshot.count ?? 0;
    final newAccount = account.copyWith(dashboardOrder: count);
    return _db
        .collection(FirebaseConstants.expenseAccounts)
        .doc(newAccount.id)
        .set(newAccount.toMap());
  }

  Future<void> updateAccount(ExpenseAccountModel account) async {
    await _db
        .collection(FirebaseConstants.expenseAccounts)
        .doc(account.id)
        .update(account.toMap());
  }

  Future<void> deleteAccount(String accountId) async {
    final batch = _db.batch();
    final accRef =
        _db.collection(FirebaseConstants.expenseAccounts).doc(accountId);
    batch.delete(accRef);
    final txnsSnapshot = await _db
        .collection(FirebaseConstants.expenseTransactions)
        .where('accountId', isEqualTo: accountId)
        .get();
    for (final doc in txnsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- TRANSACTIONS ---

  Stream<List<ExpenseTransactionModel>> getTransactionsForAccount(
      String accountId) {
    return _db
        .collection(FirebaseConstants.expenseTransactions)
        .where('accountId', isEqualTo: accountId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ExpenseTransactionModel.fromFirestore(d))
            .toList());
  }

  Future<void> addTransaction(ExpenseTransactionModel txn) async {
    final batch = _db.batch();
    final docId = txn.id.isNotEmpty
        ? txn.id
        : _db.collection(FirebaseConstants.expenseTransactions).doc().id;
    final txnRef =
        _db.collection(FirebaseConstants.expenseTransactions).doc(docId);

    final txnToSave = ExpenseTransactionModel(
      id: docId,
      accountId: txn.accountId,
      amount: txn.amount,
      date: txn.date,
      bucket: txn.bucket,
      type: txn.type,
      category: txn.category,
      subCategory: txn.subCategory,
      notes: txn.notes,
      transferAccountId: txn.transferAccountId,
      transferAccountName: txn.transferAccountName,
      transferAccountBankName: txn.transferAccountBankName,
      linkedCreditCardId: txn.linkedCreditCardId,
    );

    batch.set(txnRef, txnToSave.toMap());

    final accRef =
        _db.collection(FirebaseConstants.expenseAccounts).doc(txn.accountId);
    double delta = 0.0;
    if (txn.type == 'Expense' || txn.type == 'Transfer Out') {
      delta = -txn.amount;
    } else if (txn.type == 'Income' || txn.type == 'Transfer In') {
      delta = txn.amount;
    }
    batch.update(accRef, {'currentBalance': FieldValue.increment(delta)});
    await batch.commit();
  }

  // Standard Delete (UI Triggered)
  Future<void> deleteTransaction(ExpenseTransactionModel txn) async {
    // 1. Delete this transaction
    await _db
        .collection(FirebaseConstants.expenseTransactions)
        .doc(txn.id)
        .delete();

    // 2. Revert Balance
    await _updateAccountBalance(txn.accountId, txn.amount, txn.type,
        isAdding: false);

    // 3. Delete Transfer Partner (e.g. Pool Account entry)
    if (txn.type == 'Transfer Out' || txn.type == 'Transfer In') {
      final linkedTxn = await findLinkedTransfer(txn);
      if (linkedTxn != null) {
        await _db
            .collection(FirebaseConstants.expenseTransactions)
            .doc(linkedTxn.id)
            .delete();
        await _updateAccountBalance(
            linkedTxn.accountId, linkedTxn.amount, linkedTxn.type,
            isAdding: false);
      }
    }

    // 4. BI-DIRECTIONAL SYNC: Delete linked Credit Tracker Transaction
    // If this was a Bank Transfer -> Credit Card, delete the Credit side.
    await CreditService().deleteTransactionFromExpense(txn.id);
  }

  // Standard Update (UI Triggered)
  Future<void> updateTransaction(ExpenseTransactionModel newTxn) async {
    await _db.runTransaction((transaction) async {
      final txnRef =
          _db.collection(FirebaseConstants.expenseTransactions).doc(newTxn.id);
      final accRef = _db
          .collection(FirebaseConstants.expenseAccounts)
          .doc(newTxn.accountId);

      final docSnapshot = await transaction.get(txnRef);
      if (!docSnapshot.exists) throw Exception("Transaction does not exist!");

      final oldTxn = ExpenseTransactionModel.fromFirestore(docSnapshot);

      double oldEffect = 0.0;
      if (oldTxn.type == 'Expense' || oldTxn.type == 'Transfer Out') {
        oldEffect = -oldTxn.amount;
      } else {
        oldEffect = oldTxn.amount;
      }

      double newEffect = 0.0;
      if (newTxn.type == 'Expense' || newTxn.type == 'Transfer Out') {
        newEffect = -newTxn.amount;
      } else {
        newEffect = newTxn.amount;
      }

      double netChange = newEffect - oldEffect;
      transaction
          .update(accRef, {'currentBalance': FieldValue.increment(netChange)});
      transaction.update(txnRef, newTxn.toMap());
    });

    // BI-DIRECTIONAL SYNC: Update linked Credit Tracker Transaction
    await CreditService()
        .updateTransactionFromExpense(newTxn.id, newTxn.amount, newTxn.date);
  }

  // --- INTERNAL / SYNC HELPERS (Called by CreditService) ---

  // Called when CreditService needs to update a Bank Transaction (to avoid infinite loops)
  Future<void> updateTransactionFromCredit(
      String txnId, double newAmount, Timestamp newDate) async {
    final txnRef =
        _db.collection(FirebaseConstants.expenseTransactions).doc(txnId);
    final doc = await txnRef.get();

    if (doc.exists) {
      final oldTxn = ExpenseTransactionModel.fromFirestore(doc);

      // Perform local update only
      await _db.runTransaction((transaction) async {
        final accRef = _db
            .collection(FirebaseConstants.expenseAccounts)
            .doc(oldTxn.accountId);

        double oldEffect = 0.0;
        if (oldTxn.type == 'Expense' || oldTxn.type == 'Transfer Out') {
          oldEffect = -oldTxn.amount;
        } else {
          oldEffect = oldTxn.amount;
        }

        double newEffect = 0.0;
        if (oldTxn.type == 'Expense' || oldTxn.type == 'Transfer Out') {
          newEffect = -newAmount;
        } else {
          newEffect = newAmount;
        }

        double netChange = newEffect - oldEffect;

        transaction.update(
            accRef, {'currentBalance': FieldValue.increment(netChange)});
        transaction.update(txnRef, {
          'amount': newAmount,
          'date': newDate,
        });
      });
    }
  }

  // Called when CreditService needs to delete a Bank Transaction
  Future<void> deleteTransactionFromCredit(String txnId) async {
    final doc = await _db
        .collection(FirebaseConstants.expenseTransactions)
        .doc(txnId)
        .get();
    if (doc.exists) {
      final txn = ExpenseTransactionModel.fromFirestore(doc);
      await deleteTransactionSingle(txn);
    }
  }

  Future<void> deleteTransactionSingle(ExpenseTransactionModel txn) async {
    await _db
        .collection(FirebaseConstants.expenseTransactions)
        .doc(txn.id)
        .delete();

    await _updateAccountBalance(txn.accountId, txn.amount, txn.type,
        isAdding: false);
  }

  Future<ExpenseTransactionModel?> findLinkedTransfer(
      ExpenseTransactionModel txn) async {
    if (txn.transferAccountId == null) return null;

    final linkedType =
        txn.type == 'Transfer Out' ? 'Transfer In' : 'Transfer Out';

    final snapshot = await _db
        .collection(FirebaseConstants.expenseTransactions)
        .where('accountId', isEqualTo: txn.transferAccountId)
        .where('transferAccountId', isEqualTo: txn.accountId)
        .where('amount', isEqualTo: txn.amount)
        .where('date', isEqualTo: txn.date)
        .where('type', isEqualTo: linkedType)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ExpenseTransactionModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // --- UTILS ---

  Future<void> _updateAccountBalance(
      String accountId, double amount, String type,
      {required bool isAdding}) async {
    double change = 0.0;
    if (type == 'Expense' || type == 'Transfer Out') {
      change = -amount;
    } else if (type == 'Income' || type == 'Transfer In') {
      change = amount;
    }
    if (!isAdding) change = -change;

    await _db
        .collection(FirebaseConstants.expenseAccounts)
        .doc(accountId)
        .update({'currentBalance': FieldValue.increment(change)});
  }

  Stream<List<ExpenseTransactionModel>> getAllRecentTransactions(
      {int limit = 20}) {
    return _db
        .collection(FirebaseConstants.expenseTransactions)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ExpenseTransactionModel.fromFirestore(d))
            .toList());
  }
}
