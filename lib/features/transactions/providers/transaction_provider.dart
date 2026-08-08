// features/transactions/providers/transaction_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../services/transaction_service.dart';

final bucketsStreamProvider = StreamProvider<List<BudgetBucket>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.budgetBuckets).watch();
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionService(db);
});

final accountTransactionsProvider =
    StreamProvider.family<List<TransactionWithDetails>, String>((
      ref,
      accountId,
    ) {
      return ref
          .watch(transactionServiceProvider)
          .watchTransactionsForAccount(accountId);
    });

final allTransactionsProvider =
    StreamProvider.autoDispose<List<TransactionWithDetails>>((ref) {
      final service = ref.watch(transactionServiceProvider);
      return service.watchAllTransactions();
    });

class TransactionActionNotifier extends AsyncNotifier<void> {
  late TransactionService _service;

  @override
  FutureOr<void> build() {
    _service = ref.watch(transactionServiceProvider);
  }

  Future<bool> saveTransaction({
    String? existingId,
    required String type,
    required double amount,
    required DateTime date,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    String? categoryName, // <-- NEW
    int? categoryIcon, // <-- NEW
    String? subCategory,
    int? bucketId,
    String? bucketName,
    String? notes,
    bool isSpillover = false,
    bool isSettlementVerified = false,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (existingId == null) {
        await _service.logTransaction(
          type: type,
          amount: amount,
          date: date,
          accountId: accountId,
          toAccountId: toAccountId,
          categoryId: categoryId,
          categoryName: categoryName, // <-- PASSED
          categoryIcon: categoryIcon, // <-- PASSED
          subCategory: subCategory,
          bucketId: bucketId,
          bucketName: bucketName,
          notes: notes,
          isSpillover: isSpillover,
          isSettlementVerified: isSettlementVerified,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        await _service.updateTransaction(
          id: existingId,
          type: type,
          amount: amount,
          date: date,
          accountId: accountId,
          toAccountId: toAccountId,
          categoryId: categoryId,
          categoryName: categoryName, // <-- PASSED
          categoryIcon: categoryIcon, // <-- PASSED
          subCategory: subCategory,
          bucketId: bucketId,
          bucketName: bucketName,
          notes: notes,
          isSpillover: isSpillover,
          isSettlementVerified: isSettlementVerified,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
        );
      }
    });
    return !state.hasError;
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteTransaction(id));
  }

  Future<bool> splitTransaction({
    required String originalTxId,
    required double splitAmount,
    required String type,
    required DateTime date,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    String? categoryName, // <-- NEW
    int? categoryIcon, // <-- NEW
    String? subCategory,
    int? bucketId,
    String? bucketName,
    String? notes,
    bool isSpillover = false,
    bool isSettlementVerified = false,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.splitTransaction(
        originalTxId: originalTxId,
        splitAmount: splitAmount,
        type: type,
        date: date,
        accountId: accountId,
        toAccountId: toAccountId,
        categoryId: categoryId,
        categoryName: categoryName, // <-- PASSED
        categoryIcon: categoryIcon, // <-- PASSED
        subCategory: subCategory,
        bucketId: bucketId,
        bucketName: bucketName,
        notes: notes,
        isSpillover: isSpillover,
        isSettlementVerified: isSettlementVerified,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
      );
    });
    return !state.hasError;
  }

  // ... Keep toggleSpillover, verifySettlement, logLoanPayment identical ...
  Future<void> toggleSpillover(String id, bool isSpillover) async {
    await AsyncValue.guard(() => _service.toggleSpillover(id, isSpillover));
  }

  Future<void> verifySettlement(String id, bool isVerified) async {
    await AsyncValue.guard(() => _service.verifySettlement(id, isVerified));
  }

  Future<bool> logLoanPayment({
    required String accountId,
    required double principal,
    required double interest,
    required double tax,
    required double bankCharges,
    required DateTime date,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.logLoanPayment(
        accountId: accountId,
        principal: principal,
        interest: interest,
        tax: tax,
        bankCharges: bankCharges,
        date: date,
        notes: notes,
      );
    });
    return !state.hasError;
  }

  Future<bool> logLoanTransfer({
    required String fromAccountId,
    required String loanAccountId,
    required double principal,
    required double interest,
    required double tax,
    required double bankCharges,
    required DateTime date,
    required bool markAsExpense,
    int? bucketId,
    String? bucketName,
    String? notes,
    bool isSpillover = false,
    bool isSettlementVerified = false,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.logLoanTransfer(
        fromAccountId: fromAccountId,
        loanAccountId: loanAccountId,
        principal: principal,
        interest: interest,
        tax: tax,
        bankCharges: bankCharges,
        date: date,
        markAsExpense: markAsExpense,
        bucketId: bucketId,
        bucketName: bucketName,
        notes: notes,
        isSpillover: isSpillover,
        isSettlementVerified: isSettlementVerified,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
      );
    });
    return !state.hasError;
  }
}

final transactionActionProvider =
    AsyncNotifierProvider<TransactionActionNotifier, void>(
      () => TransactionActionNotifier(),
    );
