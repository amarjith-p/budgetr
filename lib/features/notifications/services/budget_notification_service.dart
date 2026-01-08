import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/models/financial_record_model.dart';
import '../../daily_expense/models/expense_models.dart';
import '../../credit_tracker/models/credit_models.dart'; // Imported Credit Models
import '../managers/budget_guardian_manager.dart';

class BudgetNotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call this from your UI immediately after a successful transaction add.
  Future<void> checkAndTriggerNotification(
      ExpenseTransactionModel newTxn) async {
    // 1. Basic Validation
    if (newTxn.type != 'Expense') return;
    await _analyzeBudgetHealth(newTxn.bucket);
  }

  /// Call this from your Credit Tracker UI immediately after a successful credit transaction add.
  Future<void> checkAndTriggerCreditNotification(
      CreditTransactionModel newTxn) async {
    // 1. Basic Validation
    if (newTxn.type != 'Expense') return;
    await _analyzeBudgetHealth(newTxn.bucket);
  }

  /// Core logic to calculate budget health including both Cash and Credit expenses
  Future<void> _analyzeBudgetHealth(String bucketName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notif_budget_enabled') ?? false;

      if (!isEnabled) {
        print("🔕 [Budget Service] Budget Guardian is disabled in settings.");
        return;
      }

      print("🔍 [Budget Service] Analyzing budget health for: $bucketName...");

      // 2. Define Time Window (Current Month)
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // 3. Fetch Financial Record for the Current Month
      // Instead of calculating from Income * Percentage, we fetch the fixed record.
      final recordQuery = await _db
          .collection(FirebaseConstants.financialRecords)
          .where('year', isEqualTo: now.year)
          .where('month', isEqualTo: now.month)
          .limit(1)
          .get();

      if (recordQuery.docs.isEmpty) {
        print(
            "⚠️ [Budget Service] No financial record found for ${now.month}/${now.year}. Cannot determine budget limits.");
        return;
      }

      final financialRecord =
          FinancialRecord.fromFirestore(recordQuery.docs.first);

      // 4. Get Allocated Budget for the Bucket
      final double limitAmount = financialRecord.allocations[bucketName] ?? 0.0;

      if (limitAmount <= 0) {
        print(
            "ℹ️ [Budget Service] No budget allocated for bucket: $bucketName in this month's record.");
        return;
      }

      // 5. Fetch Current Spending in this Bucket (Standard Expenses)
      final expenseQuery = await _db
          .collection(FirebaseConstants.expenseTransactions)
          .where('type', isEqualTo: 'Expense')
          .where('bucket', isEqualTo: bucketName)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double currentSpent = 0.0;
      for (var doc in expenseQuery.docs) {
        currentSpent += (doc.data()['amount'] ?? 0.0) as double;
      }

      // 6. Fetch Current Spending in this Bucket (Credit Transactions)
      final creditQuery = await _db
          .collection(FirebaseConstants.creditTransactions)
          .where('type', isEqualTo: 'Expense')
          .where('bucket', isEqualTo: bucketName)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      for (var doc in creditQuery.docs) {
        currentSpent += (doc.data()['amount'] ?? 0.0) as double;
      }

      print(
          "📊 [Budget Service] $bucketName: Spent $currentSpent / Limit $limitAmount (Includes Credit & Cash)");

      // 7. Trigger Notification Manager
      await BudgetGuardianManager().checkBudgetHealth(
        bucketName: bucketName,
        currentSpent: currentSpent,
        totalAllocated: limitAmount,
        isEnabled: true,
      );
    } catch (e) {
      print("❌ [Budget Service] Error executing check: $e");
    }
  }
}
