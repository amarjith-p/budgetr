import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationPreference { current, map, ask }

class LocationSettingsNotifier extends StateNotifier<LocationPreference> {
  LocationSettingsNotifier() : super(LocationPreference.ask) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('location_pref');
    if (stored != null) {
      state = LocationPreference.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => LocationPreference.ask,
      );
    }
  }

  Future<void> updatePreference(LocationPreference pref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location_pref', pref.name);
    state = pref;
  }
}

final locationSettingsProvider =
    StateNotifierProvider<LocationSettingsNotifier, LocationPreference>((ref) {
      return LocationSettingsNotifier();
    });
