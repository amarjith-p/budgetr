import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/models/financial_record_model.dart';
import '../../credit_tracker/models/credit_models.dart';

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<FinancialRecord>> getFinancialRecords() {
    return _db
        .collection(FirebaseConstants.financialRecords)
        .orderBy('id', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FinancialRecord.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<Map<String, double>> getMonthlyBucketSpending(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    return _db
        .collection(FirebaseConstants.creditTransactions)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
          final Map<String, double> spending = {};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['type'] == 'Expense') {
              final bucket = data['bucket'] as String? ?? 'Unallocated';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              spending[bucket] = (spending[bucket] ?? 0.0) + amount;
            }
          }
          return spending;
        });
  }

  Stream<List<CreditTransactionModel>> getBucketTransactions(
    int year,
    int month,
    String bucketName,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    return _db
        .collection(FirebaseConstants.creditTransactions)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CreditTransactionModel.fromFirestore(doc))
              .where((txn) => txn.bucket == bucketName && txn.type == 'Expense')
              .toList();
        });
  }

  /// NEW: Fetch ALL Expense Transactions for the month (For Monthly Overview)
  Stream<List<CreditTransactionModel>> getMonthlyTransactions(
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    return _db
        .collection(FirebaseConstants.creditTransactions)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          // Return all expenses, regardless of bucket
          return snapshot.docs
              .map((doc) => CreditTransactionModel.fromFirestore(doc))
              .where((txn) => txn.type == 'Expense')
              .toList();
        });
  }

  Future<FinancialRecord?> getRecordForMonth(int year, int month) async {
    final snapshot = await _db
        .collection(FirebaseConstants.financialRecords)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return FinancialRecord.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<void> setFinancialRecord(FinancialRecord record) {
    return _db
        .collection(FirebaseConstants.financialRecords)
        .doc(record.id)
        .set(record.toMap());
  }

  Future<FinancialRecord> getRecordById(String id) async {
    final doc = await _db
        .collection(FirebaseConstants.financialRecords)
        .doc(id)
        .get();
    return FinancialRecord.fromFirestore(doc);
  }

  Future<void> deleteFinancialRecord(String id) async {
    final batch = _db.batch();
    final financeRef = _db
        .collection(FirebaseConstants.financialRecords)
        .doc(id);
    batch.delete(financeRef);
    final settlementRef = _db.collection(FirebaseConstants.settlements).doc(id);
    batch.delete(settlementRef);
    await batch.commit();
  }
}
