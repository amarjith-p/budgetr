// lib/features/smart_trackers/providers/smart_tracker_provider.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../models/tracker_field_model.dart';

final smartTrackerTemplatesProvider =
    StreamProvider<List<SmartTrackerTemplate>>((ref) {
      final db = ref.watch(databaseProvider);
      return db.select(db.smartTrackerTemplates).watch();
    });

final smartTrackerRecordsProvider =
    StreamProvider.family<List<SmartTrackerRecord>, String>((ref, templateId) {
      final db = ref.watch(databaseProvider);
      final query = db.select(db.smartTrackerRecords)
        ..where((t) => t.templateId.equals(templateId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
      return query.watch();
    });

class SmartTrackerActionNotifier extends Notifier<void> {
  late AppDatabase _db;
  final _uuid = const Uuid();

  @override
  void build() {
    _db = ref.watch(databaseProvider);
  }

  Future<bool> saveTrackerTemplate({
    String? existingId,
    required String name,
    required List<TrackerField> fields,
  }) async {
    try {
      final schemaJson = jsonEncode(fields.map((f) => f.toJson()).toList());

      if (existingId == null) {
        // Create New
        await _db
            .into(_db.smartTrackerTemplates)
            .insert(
              SmartTrackerTemplatesCompanion.insert(
                id: _uuid.v4(),
                name: name,
                schemaJson: schemaJson,
                createdAt: DateTime.now(),
              ),
            );
      } else {
        // Update Existing
        final template = await (_db.select(
          _db.smartTrackerTemplates,
        )..where((t) => t.id.equals(existingId))).getSingle();
        await _db
            .update(_db.smartTrackerTemplates)
            .replace(template.copyWith(name: name, schemaJson: schemaJson));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteTrackerTemplate(String id) async {
    await _db.transaction(() async {
      // Delete all cascading records first
      await (_db.delete(
        _db.smartTrackerRecords,
      )..where((r) => r.templateId.equals(id))).go();
      // Delete the template
      await (_db.delete(
        _db.smartTrackerTemplates,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  Future<bool> saveTrackerRecord(
    String templateId,
    Map<String, dynamic> formData,
  ) async {
    try {
      await _db
          .into(_db.smartTrackerRecords)
          .insert(
            SmartTrackerRecordsCompanion.insert(
              id: _uuid.v4(),
              templateId: templateId,
              dataJson: jsonEncode(formData),
              createdAt: DateTime.now(),
            ),
          );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final smartTrackerActionProvider =
    NotifierProvider<SmartTrackerActionNotifier, void>(
      () => SmartTrackerActionNotifier(),
    );
