import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/services/transaction_service.dart';
import '../services/trip_service.dart';
import '../models/trip_period_model.dart';

final tripServiceProvider = Provider<TripService>((ref) {
  return TripService(ref.watch(databaseProvider));
});

final allTripsProvider = StreamProvider<List<Trip>>((ref) {
  return ref.watch(tripServiceProvider).watchAllTrips();
});

final tripTransactionsProvider =
    Provider.family<List<TransactionWithDetails>, Trip>((ref, trip) {
      final allTransactions =
          ref.watch(allTransactionsProvider).asData?.value ?? [];
      final periods = TripPeriod.parseList(trip.periodsJson);
      final List<dynamic> exclusions = jsonDecode(trip.excludedTxIdsJson);

      return allTransactions.where((txData) {
        final tx = txData.transaction;
        // 1. Check if excluded
        if (exclusions.contains(tx.id)) return false;

        // 2. Check if falls within ANY active trip period
        bool isInPeriod = false;
        for (var p in periods) {
          if ((tx.date.isAfter(p.start) || tx.date.isAtSameMomentAs(p.start)) &&
              (p.end == null ||
                  tx.date.isBefore(p.end!) ||
                  tx.date.isAtSameMomentAs(p.end!))) {
            isInPeriod = true;
            break;
          }
        }
        return isInPeriod;
      }).toList();
    });

class TripActionNotifier extends AsyncNotifier<void> {
  late TripService _service;

  @override
  FutureOr<void> build() {
    _service = ref.watch(tripServiceProvider);
  }

  Future<bool> createTrip(String name, double? budget, String? notes) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.createTrip(name, budget, notes),
    );
    return !state.hasError;
  }

  Future<void> updateTripStatus(Trip trip, String status) async {
    await AsyncValue.guard(() => _service.updateTripStatus(trip, status));
  }

  Future<void> toggleExclusion(Trip trip, String transactionId) async {
    await AsyncValue.guard(() => _service.toggleExclusion(trip, transactionId));
  }

  Future<void> deleteTrip(String id) async {
    await AsyncValue.guard(() => _service.deleteTrip(id));
  }
}

final tripActionProvider = AsyncNotifierProvider<TripActionNotifier, void>(
  () => TripActionNotifier(),
);
