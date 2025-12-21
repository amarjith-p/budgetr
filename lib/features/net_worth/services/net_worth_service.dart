import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/models/net_worth_model.dart';
import '../../../core/models/net_worth_split_model.dart';

class NetWorthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Total Net Worth ---
  Stream<List<NetWorthRecord>> getNetWorthRecords() {
    return _db
        .collection(FirebaseConstants.netWorth)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NetWorthRecord.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addNetWorthRecord(NetWorthRecord record) {
    return _db.collection(FirebaseConstants.netWorth).add(record.toMap());
  }

  Future<void> deleteNetWorthRecord(String id) {
    return _db.collection(FirebaseConstants.netWorth).doc(id).delete();
  }

  // --- Net Worth Splits ---
  Stream<List<NetWorthSplit>> getNetWorthSplits() {
    return _db
        .collection(FirebaseConstants.netWorthSplits)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NetWorthSplit.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addNetWorthSplit(NetWorthSplit split) {
    return _db.collection(FirebaseConstants.netWorthSplits).add(split.toMap());
  }

  Future<void> deleteNetWorthSplit(String id) {
    return _db.collection(FirebaseConstants.netWorthSplits).doc(id).delete();
  }
}
