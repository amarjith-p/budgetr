// features/custom_budgets/models/custom_budget_details.dart

import '../../../core/database/app_database.dart';

class CustomBudgetWithDetails {
  final CustomBudget budget;
  final double spent;
  
  CustomBudgetWithDetails({
    required this.budget,
    required this.spent,
  });

  double get remaining => budget.amountLimit - spent;
  double get progress => budget.amountLimit == 0 ? 0.0 : (spent / budget.amountLimit).clamp(0.0, 1.0);
}