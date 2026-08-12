// lib/features/smart_trackers/providers/smart_tracker_provider.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../models/tracker_field_model.dart';
import '../utils/tracker_formula_evaluator.dart';

final smartTrackerTemplatesProvider =
    StreamProvider<List<SmartTrackerTemplate>>((ref) {
      final db = ref.watch(databaseProvider);
      return db.select(db.smartTrackerTemplates).watch();
    });

// --- NEW: Watch a specific template for instant schema updates ---
final singleSmartTrackerTemplateProvider =
    StreamProvider.family<SmartTrackerTemplate, String>((ref, id) {
      final db = ref.watch(databaseProvider);
      return (db.select(
        db.smartTrackerTemplates,
      )..where((t) => t.id.equals(id))).watchSingle();
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
      await (_db.delete(
        _db.smartTrackerRecords,
      )..where((r) => r.templateId.equals(id))).go();
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

  Future<bool> addFormulaColumn(
    SmartTrackerTemplate template,
    TrackerField formulaField,
  ) async {
    try {
      final List<dynamic> decoded = jsonDecode(template.schemaJson);
      List<TrackerField> fields = decoded
          .map((e) => TrackerField.fromJson(e))
          .toList();
      fields.add(formulaField);

      await saveTrackerTemplate(
        existingId: template.id,
        name: template.name,
        fields: fields,
      );
      await _recalculateAllRecords(template.id, fields);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateColumnAggregate(
    SmartTrackerTemplate template,
    String fieldId,
    String aggregateType,
  ) async {
    try {
      final List<dynamic> decoded = jsonDecode(template.schemaJson);
      List<TrackerField> fields = decoded
          .map((e) => TrackerField.fromJson(e))
          .toList();
      final index = fields.indexWhere((f) => f.id == fieldId);

      if (index != -1) {
        final oldField = fields[index];
        fields[index] = TrackerField(
          id: oldField.id,
          name: oldField.name,
          type: oldField.type,
          options: oldField.options,
          prefix: oldField.prefix,
          suffix: oldField.suffix,
          currencySymbol: oldField.currencySymbol,
          formulaConfig: oldField.formulaConfig,
          aggregate: aggregateType,
        );
        await saveTrackerTemplate(
          existingId: template.id,
          name: template.name,
          fields: fields,
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _recalculateAllRecords(
    String templateId,
    List<TrackerField> fields,
  ) async {
    final records = await (_db.select(
      _db.smartTrackerRecords,
    )..where((r) => r.templateId.equals(templateId))).get();
    for (var record in records) {
      Map<String, dynamic> dataMap = jsonDecode(record.dataJson);
      bool changed = false;

      for (var field in fields) {
        if (field.type == TrackerFieldType.formula &&
            field.formulaConfig != null) {
          final newValue = TrackerFormulaEvaluator.evaluate(
            field.formulaConfig!,
            dataMap,
            fields,
          );
          if (dataMap[field.id] != newValue) {
            dataMap[field.id] = newValue;
            changed = true;
          }
        }
      }
      if (changed) {
        await _db
            .update(_db.smartTrackerRecords)
            .replace(record.copyWith(dataJson: jsonEncode(dataMap)));
      }
    }
  }
}

final smartTrackerActionProvider =
    NotifierProvider<SmartTrackerActionNotifier, void>(
      () => SmartTrackerActionNotifier(),
    );
