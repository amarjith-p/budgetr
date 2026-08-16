import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../models/trip_period_model.dart';

class TripService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TripService(this._db);

  Stream<List<Trip>> watchAllTrips() {
    return (_db.select(_db.trips)..orderBy([
          (t) => OrderingTerm.desc(
            t.status,
          ), // <-- Wrap it in a function like this
        ]))
        .watch();
  }

  Future<void> createTrip(String name, double? budget, String? notes) async {
    final period = TripPeriod(start: DateTime.now());
    await _db
        .into(_db.trips)
        .insert(
          TripsCompanion.insert(
            id: _uuid.v4(),
            name: name,
            budget: Value(budget),
            notes: Value(notes),
            status: 'ACTIVE',
            periodsJson: TripPeriod.encodeList([period]),
            excludedTxIdsJson: '[]',
          ),
        );
  }

  Future<void> updateTripStatus(Trip trip, String newStatus) async {
    final periods = TripPeriod.parseList(trip.periodsJson);

    if (newStatus == 'PAUSED' || newStatus == 'COMPLETED') {
      // Close the current active period
      if (periods.isNotEmpty && periods.last.end == null) {
        periods[periods.length - 1] = TripPeriod(
          start: periods.last.start,
          end: DateTime.now(),
        );
      }
    } else if (newStatus == 'ACTIVE') {
      // Start a new active period
      periods.add(TripPeriod(start: DateTime.now()));
    }

    await _db
        .update(_db.trips)
        .replace(
          trip.copyWith(
            status: newStatus,
            periodsJson: TripPeriod.encodeList(periods),
          ),
        );
  }

  Future<void> toggleExclusion(Trip trip, String transactionId) async {
    List<dynamic> exclusions = jsonDecode(trip.excludedTxIdsJson);
    if (exclusions.contains(transactionId)) {
      exclusions.remove(transactionId);
    } else {
      exclusions.add(transactionId);
    }

    await _db
        .update(_db.trips)
        .replace(trip.copyWith(excludedTxIdsJson: jsonEncode(exclusions)));
  }

  Future<void> deleteTrip(String id) async {
    await (_db.delete(_db.trips)..where((t) => t.id.equals(id))).go();
  }
}
