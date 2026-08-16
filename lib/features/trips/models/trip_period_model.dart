import 'dart:convert';

class TripPeriod {
  final DateTime start;
  final DateTime? end;

  TripPeriod({required this.start, this.end});

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
  };

  factory TripPeriod.fromJson(Map<String, dynamic> json) => TripPeriod(
    start: DateTime.parse(json['start']),
    end: json['end'] != null ? DateTime.parse(json['end']) : null,
  );

  static List<TripPeriod> parseList(String jsonString) {
    if (jsonString.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => TripPeriod.fromJson(e)).toList();
  }

  static String encodeList(List<TripPeriod> periods) {
    return jsonEncode(periods.map((e) => e.toJson()).toList());
  }
}
