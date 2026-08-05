import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../services/account_service.dart';

final accountServiceProvider = Provider<AccountService>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountService(db);
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountServiceProvider).watchAccounts();
});

class AccountActionNotifier extends AsyncNotifier<void> {
  late AccountService _service;

  @override
  FutureOr<void> build() {
    _service = ref.watch(accountServiceProvider);
  }

  Future<bool> saveAccount({
    String? existingId,
    required String name,
    required String providerName,
    required String type,
    required String last4,
    required double balance,
    double? creditLimit,
    int? billDate,
    int? dueDate,
    String? loanPurpose,
    double? loanPrincipal,
    double? interestRate,
    int? tenureMonths,
    DateTime? emiDate,
    DateTime? loanStartDate,
    DateTime? loanEndDate,
    double? totalInterestPayable,
    double? totalTaxPayable,
    double? bankCharges, // <-- ADDED HERE
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      if (existingId == null) {
        await _service.addAccount(
          name: name,
          providerName: providerName,
          type: type,
          last4: last4,
          balance: balance,
          creditLimit: creditLimit,
          billDate: billDate,
          dueDate: dueDate,
          loanPurpose: loanPurpose,
          loanPrincipal: loanPrincipal,
          interestRate: interestRate,
          tenureMonths: tenureMonths,
          emiDate: emiDate,
          loanStartDate: loanStartDate,
          loanEndDate: loanEndDate,
          totalInterestPayable: totalInterestPayable,
          totalTaxPayable: totalTaxPayable,
          bankCharges: bankCharges, // <-- PASSED TO SERVICE
        );
      } else {
        final db = ref.read(databaseProvider);
        final existing = await (db.select(
          db.accounts,
        )..where((t) => t.id.equals(existingId))).getSingle();

        final updated = existing.copyWith(
          name: name,
          providerName: providerName,
          type: type,
          last4: Value(last4),
          balance: balance,
          creditLimit: Value(creditLimit),
          billDate: Value(billDate),
          dueDate: Value(dueDate),
          loanPurpose: Value(loanPurpose),
          loanPrincipal: Value(loanPrincipal),
          interestRate: Value(interestRate),
          tenureMonths: Value(tenureMonths),
          emiDate: Value(emiDate),
          loanStartDate: Value(loanStartDate),
          loanEndDate: Value(loanEndDate),
          totalInterestPayable: Value(totalInterestPayable),
          totalTaxPayable: Value(totalTaxPayable),
          bankCharges: Value(bankCharges), // <-- UPDATED VIA COPYWITH
        );
        await _service.updateAccount(updated);
      }
    });
    return !state.hasError;
  }

  Future<void> deleteAccount(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteAccount(id));
  }

  Future<void> reorderAccounts(List<Account> orderedList) async {
    final updatedAccounts = <Account>[];
    for (int i = 0; i < orderedList.length; i++) {
      updatedAccounts.add(orderedList[i].copyWith(displayOrder: Value(i)));
    }
    await AsyncValue.guard(() => _service.reorderAccounts(updatedAccounts));
  }

  Future<void> updateAccountPreferences(List<Account> modifiedList) async {
    final updatedAccounts = <Account>[];
    for (int i = 0; i < modifiedList.length; i++) {
      updatedAccounts.add(modifiedList[i].copyWith(displayOrder: Value(i)));
    }
    await AsyncValue.guard(() => _service.reorderAccounts(updatedAccounts));
  }

  Future<bool> settleLoan(String accountId) async {
    state = const AsyncLoading();
    try {
      final success = await _service.settleLoan(accountId);
      state = const AsyncData(null);
      return success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final accountActionProvider =
    AsyncNotifierProvider<AccountActionNotifier, void>(
      () => AccountActionNotifier(),
    );
