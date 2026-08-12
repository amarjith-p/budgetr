// lib/features/smart_trackers/utils/tracker_formula_evaluator.dart
import '../models/tracker_field_model.dart';

class TrackerFormulaEvaluator {
  static String evaluate(
    FormulaConfig config,
    Map<String, dynamic> rowData,
    List<TrackerField> fields,
  ) {
    try {
      if (config.type == 'math') {
        // --- MATH OPERATION ---
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

        // Return clean integer if no decimals, else 2 decimal places
        return result == result.toInt()
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
      } else if (config.type == 'logic') {
        // --- LOGIC CONDITION ---
        String actualValue =
            rowData[config.logicFieldId]?.toString().trim() ?? '';
        String targetValue = config.logicTargetValue?.trim() ?? '';

        bool isTrue = false;

        // Handle Numeric Comparisons safely
        if (config.logicOperator == '>' ||
            config.logicOperator == '<' ||
            config.logicOperator == '>=' ||
            config.logicOperator == '<=') {
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
          // Handle String Equality
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

        // Check if the result is actually referencing another Field ID
        if (fields.any((f) => f.id == rawResult)) {
          return rowData[rawResult]?.toString() ?? '';
        }

        // Otherwise, it's just static text returned by the user
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
