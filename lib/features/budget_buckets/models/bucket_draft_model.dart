import 'package:uuid/uuid.dart';

class BucketDraft {
  final String id;
  final String name;
  final double percentage;

  BucketDraft({String? id, this.name = '', this.percentage = 0.0}) 
    : id = id ?? const Uuid().v4();

  BucketDraft copyWith({String? name, double? percentage}) {
    return BucketDraft(
      id: id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
    );
  }
}