import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final accountTransactionsProvider = StreamProvider.family<List<TransactionWithDetails>, String>((ref, accountId) {
  return ref.watch(transactionServiceProvider).watchTransactionsForAccount(accountId);
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
    String? subCategory,
    int? bucketId,
    String? notes,
    bool isSpillover = false, 
    bool isSettlementVerified = false, // <-- NEW
  }) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      if (existingId == null) {
        await _service.logTransaction(
          type: type, amount: amount, date: date, accountId: accountId,
          toAccountId: toAccountId, categoryId: categoryId, subCategory: subCategory,
          bucketId: bucketId, notes: notes, isSpillover: isSpillover, isSettlementVerified: isSettlementVerified,
        );
      } else {
        await _service.updateTransaction(
          id: existingId, type: type, amount: amount, date: date, accountId: accountId,
          toAccountId: toAccountId, categoryId: categoryId, subCategory: subCategory,
          bucketId: bucketId, notes: notes, isSpillover: isSpillover, isSettlementVerified: isSettlementVerified,
        );
      }
    });

    return !state.hasError;
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteTransaction(id));
  }

  Future<void> toggleSpillover(String id, bool isSpillover) async {
    await AsyncValue.guard(() => _service.toggleSpillover(id, isSpillover));
  }

  // --- NEW ---
  Future<void> verifySettlement(String id, bool isVerified) async {
    await AsyncValue.guard(() => _service.verifySettlement(id, isVerified));
  }
}

final transactionActionProvider = AsyncNotifierProvider<TransactionActionNotifier, void>(
  () => TransactionActionNotifier(),
);