// lib/features/smart_trackers/models/tracker_field_model.dart
enum TrackerFieldType {
  text,
  number,
  currency, // <-- NEW
  date,
  dropdown,
  toggle,
  radio,
  checkbox,
  serialNo, // <-- NEW
}

class TrackerField {
  final String id;
  final String name;
  final TrackerFieldType type;
  final List<String>? options; // For dropdowns, radios, checkboxes
  final String? prefix; // For Serial No
  final String? suffix; // For Serial No
  final String? currencySymbol; // For Currency

  TrackerField({
    required this.id,
    required this.name,
    required this.type,
    this.options,
    this.prefix,
    this.suffix,
    this.currencySymbol,
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
    );
  }
}
