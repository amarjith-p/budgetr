// lib/features/smart_trackers/utils/summary_formula_engine.dart
import 'dart:convert';
import '../../../core/database/app_database.dart';
import '../../../core/utils/bodmas_calculator.dart';
import '../models/tracker_field_model.dart';

class SummaryFormulaEngine {
  static final RegExp _aggRegex = RegExp(
    r'(SUM|AVG|MAX|MIN|COUNT)\(\[([^\]]+)\]\)',
  );
  static final RegExp _edgeRegex = RegExp(r'(FIRST|LAST)\(\[([^\]]+)\]\)');
  static final RegExp _cellRegex = RegExp(r'CELL\((\d+),\s*\[([^\]]+)\]\)');

  // Helper to nicely format raw text, dates, toggles, and lists
  static String _formatFieldValue(TrackerField field, dynamic rawValue) {
    if (rawValue == null || rawValue.toString().isEmpty) return '-';

    if (field.type == TrackerFieldType.checkbox) {
      if (rawValue is List) return rawValue.join(', ');
      if (rawValue is String) {
        try {
          final List parsed = jsonDecode(rawValue);
          return parsed.join(', ');
        } catch (_) {}
      }
    }
    if (field.type == TrackerFieldType.date) {
      try {
        final d = DateTime.parse(rawValue.toString());
        return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
      } catch (_) {}
    }
    if (field.type == TrackerFieldType.toggle) {
      return (rawValue == true || rawValue == 'true') ? 'Yes' : 'No';
    }
    return rawValue.toString();
  }

  static String evaluate(
    String formula,
    String formatAs, // <-- NEW: Engine now knows the target format
    List<SmartTrackerRecord> records,
    List<TrackerField> fields,
  ) {
    try {
      if (formula.trim().isEmpty || records.isEmpty) return '-';
      String expr = formula;

      // 1. Resolve Specific CELL(rowIndex, [Field])
      final cellMatches = _cellRegex.allMatches(expr).toList();
      for (var match in cellMatches) {
        final fullMatch = match.group(0)!;
        final rowIndex = int.parse(match.group(1)!);
        final fieldName = match.group(2)!;

        final field = fields.where((f) => f.name == fieldName).firstOrNull;
        if (field == null || rowIndex < 1 || rowIndex > records.length) {
          expr = expr.replaceAll(fullMatch, '-');
          continue;
        }
        final targetRecord = records[records.length - rowIndex];
        final rawVal = jsonDecode(targetRecord.dataJson)[field.id];
        expr = expr.replaceAll(fullMatch, _formatFieldValue(field, rawVal));
      }

      // 2. Resolve FIRST() and LAST()
      final edgeMatches = _edgeRegex.allMatches(expr).toList();
      for (var match in edgeMatches) {
        final fullMatch = match.group(0)!;
        final operation = match.group(1)!;
        final fieldName = match.group(2)!;

        final field = fields.where((f) => f.name == fieldName).firstOrNull;
        if (field == null) {
          expr = expr.replaceAll(fullMatch, '-');
          continue;
        }

        SmartTrackerRecord targetRecord = operation == 'LAST'
            ? records.first
            : records.last;
        final rawVal = jsonDecode(targetRecord.dataJson)[field.id];
        expr = expr.replaceAll(fullMatch, _formatFieldValue(field, rawVal));
      }

      // 3. Resolve Column Aggregates (SUM, AVG, etc. remain numeric)
      final aggMatches = _aggRegex.allMatches(expr).toList();
      for (var match in aggMatches) {
        final fullMatch = match.group(0)!;
        final operation = match.group(1)!;
        final fieldName = match.group(2)!;

        final field = fields.where((f) => f.name == fieldName).firstOrNull;
        if (field == null) {
          expr = expr.replaceAll(fullMatch, '0');
          continue;
        }

        double sum = 0,
            minVal = double.infinity,
            maxVal = double.negativeInfinity;
        int numericCount = 0;
        int textCount =
            0; // NEW: Tracks all filled cells, regardless of data type

        for (var record in records) {
          final rawVal =
              jsonDecode(record.dataJson)[field.id]?.toString() ?? '';

          if (rawVal.trim().isNotEmpty) {
            textCount++; // Count every cell that isn't completely empty

            final val = double.tryParse(rawVal);
            if (val != null) {
              sum += val;
              numericCount++;
              if (val < minVal) minVal = val;
              if (val > maxVal) maxVal = val;
            }
          }
        }

        double res = 0.0;
        if (operation == 'COUNT') {
          // COUNT applies to anything (Text, Dates, Numbers)
          res = textCount.toDouble();
        } else if (numericCount > 0) {
          // SUM, AVG, MAX, MIN strictly require numeric values
          if (operation == 'SUM') res = sum;
          if (operation == 'AVG') res = sum / numericCount;
          if (operation == 'MAX') res = maxVal;
          if (operation == 'MIN') res = minVal;
        }
        expr = expr.replaceAll(fullMatch, res.toString());
      }

      // --- THE FIX ---
      // If the user set the format to "text", BYPASS the Bodmas calculator entirely
      // and return the exact string we just extracted!
      if (formatAs == 'text') {
        return expr;
      }

      // 4. Otherwise, evaluate Mathematical Expression for numbers
      String rawResult = BodmasCalculator.evaluate(expr);
      double finalResult = double.tryParse(rawResult) ?? 0.0;
      return finalResult.toStringAsFixed(2);
    } catch (e) {
      return 'Err';
    }
  }
}
