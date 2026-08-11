// lib/features/investments/providers/investment_provider.dart
import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../services/investment_service.dart';

final investmentServiceProvider = Provider<InvestmentService>((ref) {
  return InvestmentService(ref.watch(databaseProvider));
});

final investmentsStreamProvider = StreamProvider<List<Investment>>((ref) {
  return ref.watch(investmentServiceProvider).watchInvestments();
});

final investmentLogsStreamProvider =
    StreamProvider.family<List<InvestmentLog>, String>((ref, investmentId) {
      return ref
          .watch(investmentServiceProvider)
          .watchInvestmentLogs(investmentId);
    });

class InvestmentActionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  // --- REBUILT: Ledger-Driven Save Logic ---
  Future<bool> saveInvestment({
    required InvestmentsCompanion entry,
    required bool isEdit,
    double? initialDeposit,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(investmentServiceProvider);

      if (isEdit) {
        // Safe partial update: Only updates Form Details, ignores financial balances
        await service.updateInvestmentDetails(entry);
      } else {
        // NEW INVESTMENT:
        // Set root balances to 0, let the immediate deposit log mathematically correct them.
        final newEntry = entry.copyWith(
          initialAmount: const drift.Value(0.0),
          currentValue: const drift.Value(0.0),
        );
        await service.addInvestment(newEntry);

        // Instantly generate the Day 0 Deposit Log
        if (initialDeposit != null && initialDeposit > 0) {
          await service.logInvestmentTransaction(
            investmentId: entry.id.value,
            type: 'Deposit',
            amount: initialDeposit,
            date: entry.startDate.value,
          );
        }
      }
    });
    return !state.hasError;
  }

  Future<bool> deleteInvestment(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(investmentServiceProvider).deleteInvestment(id);
    });
    return !state.hasError;
  }

  Future<bool> logInvestmentActivity({
    required String investmentId,
    required String type,
    required double amount,
    required DateTime date,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(investmentServiceProvider)
          .logInvestmentTransaction(
            investmentId: investmentId,
            type: type,
            amount: amount,
            date: date,
          );
    });
    return !state.hasError;
  }

  Future<bool> editInvestmentActivity(InvestmentLog log) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(investmentServiceProvider).updateInvestmentLog(log);
    });
    return !state.hasError;
  }

  Future<bool> deleteInvestmentActivity(
    String logId,
    String investmentId,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(investmentServiceProvider)
          .deleteInvestmentLog(logId, investmentId);
    });
    return !state.hasError;
  }

  Future<bool> closeInvestment({
    required Investment investment,
    required double finalValue,
    required String reason,
    required DateTime date,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (investment.currentValue != finalValue) {
        await ref
            .read(investmentServiceProvider)
            .logInvestmentTransaction(
              investmentId: investment.id,
              type: 'Update',
              amount: finalValue,
              date: date,
            );
      }

      await ref
          .read(investmentServiceProvider)
          .updateInvestment(
            investment.copyWith(
              isClosed: true,
              closeReason: drift.Value(reason),
              currentValue: finalValue,
            ),
          );
    });
    return !state.hasError;
  }
}

final investmentActionProvider =
    AsyncNotifierProvider<InvestmentActionNotifier, void>(
      () => InvestmentActionNotifier(),
    );

final allInvestmentLogsStreamProvider = StreamProvider<List<InvestmentLog>>((
  ref,
) {
  return ref.watch(investmentServiceProvider).watchAllInvestmentLogs();
});
