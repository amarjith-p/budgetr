import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../models/bucket_draft_model.dart';

class BudgetBucketService {
  final AppDatabase _db;

  BudgetBucketService(this._db);

  /// Atomically deletes all existing buckets and inserts the new allocation.
  Future<void> replaceAllBuckets(List<BucketDraft> drafts) async {
    await _db.transaction(() async {
      // 1. Wipe the current table clean
      await _db.delete(_db.budgetBuckets).go();

      // 2. Batch insert the new draft list
      await _db.batch((batch) {
        batch.insertAll(
          _db.budgetBuckets,
          drafts.map((draft) => BudgetBucketsCompanion.insert(
            name: draft.name,
            percentage: draft.percentage,
          )).toList(),
        );
      });
    });
  }
  Stream<List<BucketDraft>> watchBuckets() {
  return _db.select(_db.budgetBuckets).watch().map((rows) {
    return rows.map((row) => BucketDraft(
      // Ensure the id mapping matches your Drift schema (usually an auto-incrementing int)
      id: row.id.toString(), 
      name: row.name,
      percentage: row.percentage,
    )).toList();
  });
}
}