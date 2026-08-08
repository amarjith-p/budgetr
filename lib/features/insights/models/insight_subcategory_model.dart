// features/insights/models/insight_subcategory_model.dart
import '../../transactions/services/transaction_service.dart';

class InsightSubcategoryModel {
  final String name;
  final double totalAmount;
  final double previousAmount;
  final double percentage;
  final List<TransactionWithDetails> transactions;

  InsightSubcategoryModel({
    required this.name,
    required this.totalAmount,
    required this.previousAmount,
    required this.percentage,
    required this.transactions,
  });

  double get trendPercentage {
    if (previousAmount == 0 && totalAmount == 0) return 0.0;
    if (previousAmount == 0) return 100.0;
    return ((totalAmount - previousAmount) / previousAmount) * 100;
  }
}
