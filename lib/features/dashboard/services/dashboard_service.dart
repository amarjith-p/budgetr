import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/models/financial_record_model.dart';

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
    // Delete Budget Record
    final financeRef = _db
        .collection(FirebaseConstants.financialRecords)
        .doc(id);
    batch.delete(financeRef);
    // Delete Settlement Record (Linked data)
    final settlementRef = _db.collection(FirebaseConstants.settlements).doc(id);
    batch.delete(settlementRef);
    await batch.commit();
  }
}
