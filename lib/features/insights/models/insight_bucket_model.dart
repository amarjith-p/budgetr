// features/insights/models/insight_bucket_model.dart
import '../../transactions/services/transaction_service.dart';
import 'insight_category_model.dart'; // <-- NEW

class InsightBucketModel {
  final String name;
  final double totalAmount;
  final double previousAmount;
  final double percentage;
  final List<InsightCategoryModel> categories; // <-- NEW
  final List<TransactionWithDetails> transactions;

  InsightBucketModel({
    required this.name,
    required this.totalAmount,
    required this.previousAmount,
    required this.percentage,
    required this.categories,
    required this.transactions,
  });

  double get trendPercentage {
    if (previousAmount == 0 && totalAmount == 0) return 0.0;
    if (previousAmount == 0) return 100.0;
    return ((totalAmount - previousAmount) / previousAmount) * 100;
  }
}
