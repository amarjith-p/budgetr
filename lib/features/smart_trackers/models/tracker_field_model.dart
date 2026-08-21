// lib/features/smart_trackers/models/tracker_field_model.dart
enum TrackerFieldType {
  text,
  number,
  currency,
  date,
  dropdown,
  toggle,
  radio,
  checkbox,
  serialNo,
  formula,
}

class FormulaConfig {
  final String type; // 'math' or 'logic'

  // --- ADVANCED MATH ---
  final String? mathExpression; // e.g., "([Field A] + [Field B]) * 100"

  // --- LEGACY MATH ---
  final String? field1Id;
  final String? mathOperator; // '+', '-', '*', '/'
  final String? field2Id;

  // --- LOGIC ---
  final String? logicFieldId;
  final String? logicOperator; // '==', '!=', '>', '<'
  final String? logicTargetValue;
  final String? trueResult; // Can be a static string, or another field ID
  final String? falseResult; // Can be a static string, or another field ID

  FormulaConfig({
    required this.type,
    this.mathExpression,
    this.field1Id,
    this.mathOperator,
    this.field2Id,
    this.logicFieldId,
    this.logicOperator,
    this.logicTargetValue,
    this.trueResult,
    this.falseResult,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'mathExpression': mathExpression,
      'field1Id': field1Id,
      'mathOperator': mathOperator,
      'field2Id': field2Id,
      'logicFieldId': logicFieldId,
      'logicOperator': logicOperator,
      'logicTargetValue': logicTargetValue,
      'trueResult': trueResult,
      'falseResult': falseResult,
    };
  }

  factory FormulaConfig.fromJson(Map<String, dynamic> json) {
    return FormulaConfig(
      type: json['type'] as String,
      mathExpression: json['mathExpression'] as String?,
      field1Id: json['field1Id'] as String?,
      mathOperator: json['mathOperator'] as String?,
      field2Id: json['field2Id'] as String?,
      logicFieldId: json['logicFieldId'] as String?,
      logicOperator: json['logicOperator'] as String?,
      logicTargetValue: json['logicTargetValue'] as String?,
      trueResult: json['trueResult'] as String?,
      falseResult: json['falseResult'] as String?,
    );
  }
}

class TrackerField {
  final String id;
  final String name;
  final TrackerFieldType type;
  final List<String>? options;
  final String? prefix;
  final String? suffix;
  final String? currencySymbol;
  final FormulaConfig? formulaConfig;
  final String? aggregate;
  final bool isMandatory; // <-- NEW

  TrackerField({
    required this.id,
    required this.name,
    required this.type,
    this.options,
    this.prefix,
    this.suffix,
    this.currencySymbol,
    this.formulaConfig,
    this.aggregate,
    this.isMandatory = true, // <-- NEW
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'options': options,
      'prefix': prefix,
      'suffix': suffix,
      'currencySymbol': currencySymbol,
      'formulaConfig': formulaConfig?.toJson(),
      'aggregate': aggregate,
      'isMandatory': isMandatory, // <-- NEW
    };
  }

  factory TrackerField.fromJson(Map<String, dynamic> json) {
    return TrackerField(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TrackerFieldType.values.firstWhere((e) => e.name == json['type']),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      prefix: json['prefix'] as String?,
      suffix: json['suffix'] as String?,
      currencySymbol: json['currencySymbol'] as String?,
      formulaConfig: json['formulaConfig'] != null
          ? FormulaConfig.fromJson(json['formulaConfig'])
          : null,
      aggregate: json['aggregate'] as String?,
      isMandatory: json['isMandatory'] as bool? ?? true, // <-- NEW
    );
  }
}
