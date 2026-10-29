// lib/features/settings/providers/investment_settings_provider.dart
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveMarketValuationSettingsNotifier extends StateNotifier<bool> {
  LiveMarketValuationSettingsNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool('live_market_valuation_enabled');
    if (stored != null) {
      state = stored;
    }
  }

  Future<void> toggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('live_market_valuation_enabled', enabled);
    state = enabled;
  }
}

final liveMarketValuationSettingsProvider =
    StateNotifierProvider<LiveMarketValuationSettingsNotifier, bool>((ref) {
      return LiveMarketValuationSettingsNotifier();
    });
