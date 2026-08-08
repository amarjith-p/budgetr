// features/insights/models/insight_summary_model.dart

class InsightSummaryModel {
  final double totalIncome;
  final double totalExpense;

  InsightSummaryModel({required this.totalIncome, required this.totalExpense});

  double get netSavings => totalIncome - totalExpense;

  double get savingsRate {
    if (totalIncome <= 0) return 0.0;
    return (netSavings / totalIncome) * 100;
  }
}
