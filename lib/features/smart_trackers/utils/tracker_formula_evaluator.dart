// lib/features/smart_trackers/utils/tracker_formula_evaluator.dart
import '../models/tracker_field_model.dart';
import '../../../core/utils/bodmas_calculator.dart';

class TrackerFormulaEvaluator {
  static String evaluate(
    FormulaConfig config,
    Map<String, dynamic> rowData,
    List<TrackerField> fields,
  ) {
    try {
      if (config.type == 'math') {
        // --- 1. ADVANCED FREEFORM MATH ---
        if (config.mathExpression != null &&
            config.mathExpression!.trim().isNotEmpty) {
          String expr = config.mathExpression!;

          // Inject raw data into [Field] placeholders
          for (var f in fields) {
            final token = '[${f.name}]';
            if (expr.contains(token)) {
              double val = _parseDouble(rowData[f.id]);
              expr = expr.replaceAll(token, val.toString());
            }
          }

          // Evaluate standard math
          String rawResult = BodmasCalculator.evaluate(expr);
          double result = double.tryParse(rawResult) ?? 0.0;
          return result == result.toInt()
              ? result.toInt().toString()
              : result.toStringAsFixed(2);
        }
        // --- 2. LEGACY MATH (Backward compatibility) ---
        else {
          double val1 = _parseDouble(rowData[config.field1Id]);
          double val2 = _parseDouble(rowData[config.field2Id]);
          double result = 0;

          switch (config.mathOperator) {
            case '+':
              result = val1 + val2;
              break;
            case '-':
              result = val1 - val2;
              break;
            case '*':
              result = val1 * val2;
              break;
            case '/':
              result = val2 == 0 ? 0 : val1 / val2;
              break;
          }

          return result == result.toInt()
              ? result.toInt().toString()
              : result.toStringAsFixed(2);
        }
      } else if (config.type == 'logic') {
        // --- LOGIC CONDITION ---
        String actualValue =
            rowData[config.logicFieldId]?.toString().trim() ?? '';
        String targetValue = config.logicTargetValue?.trim() ?? '';
        bool isTrue = false;

        if (['>', '<', '>=', '<='].contains(config.logicOperator)) {
          double numActual = _parseDouble(actualValue);
          double numTarget = _parseDouble(targetValue);
          switch (config.logicOperator) {
            case '>':
              isTrue = numActual > numTarget;
              break;
            case '<':
              isTrue = numActual < numTarget;
              break;
            case '>=':
              isTrue = numActual >= numTarget;
              break;
            case '<=':
              isTrue = numActual <= numTarget;
              break;
          }
        } else {
          switch (config.logicOperator) {
            case '==':
              isTrue = actualValue.toLowerCase() == targetValue.toLowerCase();
              break;
            case '!=':
              isTrue = actualValue.toLowerCase() != targetValue.toLowerCase();
              break;
          }
        }

        String rawResult = isTrue
            ? (config.trueResult ?? '')
            : (config.falseResult ?? '');

        if (fields.any((f) => f.id == rawResult)) {
          return rowData[rawResult]?.toString() ?? '';
        }
        return rawResult;
      }
      return '-';
    } catch (e) {
      return 'Error';
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(
          value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
        ) ??
        0.0;
  }
}
