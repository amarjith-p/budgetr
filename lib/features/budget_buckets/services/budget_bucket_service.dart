import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../models/bucket_draft_model.dart';

class BudgetBucketService {
  final AppDatabase _db;

  BudgetBucketService(this._db);

  /// Intelligently Updates, Inserts, or Deletes buckets to perfectly 
  /// preserve the primary integer IDs for historical transaction integrity.
  Future<void> replaceAllBuckets(List<BucketDraft> drafts) async {
    await _db.transaction(() async {
      final existingBuckets = await _db.select(_db.budgetBuckets).get();

      // BucketDraft uses a UUID for brand new items, but parses to an INT for existing ones.
      final draftIds = drafts.map((d) => int.tryParse(d.id)).whereType<int>().toSet();

      // 1. Delete buckets that were removed by the user
      final toDelete = existingBuckets.where((b) => !draftIds.contains(b.id)).toList();
      for (var b in toDelete) {
        await (_db.delete(_db.budgetBuckets)..where((t) => t.id.equals(b.id))).go();
      }

      // 2. Update existing buckets (Preserves IDs) or Insert new ones
      for (var draft in drafts) {
        final parsedId = int.tryParse(draft.id);
        
        if (parsedId != null && existingBuckets.any((b) => b.id == parsedId)) {
          // UPDATE: Protects the historical link to past transactions
          await (_db.update(_db.budgetBuckets)..where((t) => t.id.equals(parsedId)))
              .write(BudgetBucketsCompanion(
                name: Value(draft.name),
                percentage: Value(draft.percentage),
              ));
        } else {
          // INSERT: Let SQLite assign a brand new auto-increment ID
          await _db.into(_db.budgetBuckets).insert(BudgetBucketsCompanion.insert(
            name: draft.name,
            percentage: draft.percentage,
          ));
        }
      }
    });
  }

  Stream<List<BucketDraft>> watchBuckets() {
    return _db.select(_db.budgetBuckets).watch().map((rows) {
      return rows.map((row) => BucketDraft(
        id: row.id.toString(), // Converts the SQLite int to string for the UI Draft model
        name: row.name,
        percentage: row.percentage,
      )).toList();
    });
  }
}