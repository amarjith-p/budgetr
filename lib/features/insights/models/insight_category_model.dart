// features/insights/models/insight_category_model.dart
import '../../transactions/services/transaction_service.dart';
import 'insight_subcategory_model.dart'; // <-- NEW

class InsightCategoryModel {
  final String name;
  final int? iconCode;
  final double totalAmount;
  final double previousAmount;
  final double percentage;
  final List<InsightSubcategoryModel> subcategories; // <-- NEW
  final List<TransactionWithDetails> transactions;

  InsightCategoryModel({
    required this.name,
    this.iconCode,
    required this.totalAmount,
    required this.previousAmount,
    required this.percentage,
    required this.subcategories,
    required this.transactions,
  });

  double get trendPercentage {
    if (previousAmount == 0 && totalAmount == 0) return 0.0;
    if (previousAmount == 0) return 100.0;
    return ((totalAmount - previousAmount) / previousAmount) * 100;
  }
}
