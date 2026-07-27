import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../services/budget_service.dart';

// 1. Service Provider
final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService(ref.watch(databaseProvider));
});

// 2. State Provider for the actively viewed Month & Year
final budgetDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month); // Strip to just month/year
});

// 3. Stream Provider watching the DB for the selected month
final monthlyBudgetStreamProvider = StreamProvider.autoDispose<MonthlyBudget?>((ref) {
  final date = ref.watch(budgetDateProvider);
  return ref.watch(budgetServiceProvider).watchBudgetForMonth(date.month, date.year);
});