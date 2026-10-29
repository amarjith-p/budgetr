// lib/features/investments/providers/investment_provider.dart
import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../services/investment_service.dart';
import '../services/market_data_service.dart';
import '../models/market_data_models.dart';

final investmentServiceProvider = Provider<InvestmentService>((ref) {
  return InvestmentService(ref.watch(databaseProvider));
});

final marketDataServiceProvider = Provider<MarketDataService>((ref) {
  return MarketDataService();
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

final liveTrackerStreamProvider =
    StreamProvider.family<InvestmentLiveTracker?, String>((ref, investmentId) {
      return ref
          .watch(investmentServiceProvider)
          .watchLiveTracker(investmentId);
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

  // --- LIVE MARKET TRACKING ACTIONS ---
  Future<bool> saveLiveTracker({
    required String investmentId,
    required String symbol,
    required String name,
    required String assetType,
    required double quantity,
    double? lastPrice,
    double? changePercent,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(investmentServiceProvider).saveLiveTracker(
            investmentId: investmentId,
            symbol: symbol,
            name: name,
            assetType: assetType,
            quantity: quantity,
            lastPrice: lastPrice,
            changePercent: changePercent,
            lastFetchedAt: DateTime.now(),
          );
    });
    return !state.hasError;
  }

  Future<bool> deleteLiveTracker(String investmentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(investmentServiceProvider).deleteLiveTracker(investmentId);
    });
    return !state.hasError;
  }

  Future<MarketPriceQuote?> refreshLivePrice(String investmentId) async {
    final tracker = await ref
        .read(investmentServiceProvider)
        .getLiveTracker(investmentId);
    if (tracker == null) return null;

    final marketService = ref.read(marketDataServiceProvider);
    final quote = await marketService.getQuote(
      symbol: tracker.symbol,
      assetType: tracker.assetType,
    );

    if (quote != null) {
      await ref.read(investmentServiceProvider).updateCachedTrackerPrice(
            investmentId: investmentId,
            price: quote.price,
            changePercent: quote.changePercent,
            fetchedAt: quote.date,
          );
    }
    return quote;
  }

  Future<bool> applyLiveValueToInvestment({
    required String investmentId,
    required double liveValue,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(investmentServiceProvider).logInvestmentTransaction(
            investmentId: investmentId,
            type: 'Update',
            amount: liveValue,
            date: DateTime.now(),
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
