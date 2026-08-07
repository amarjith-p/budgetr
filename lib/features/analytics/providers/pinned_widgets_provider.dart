import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinnedWidgetsNotifier extends StateNotifier<List<String>> {
  PinnedWidgetsNotifier() : super([]) {
    _loadFromStorage();
  }

  static const _storageKey = 'budgetr_pinned_widgets';

  // Automatically fetch the saved selection when the app opens
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWidgets = prefs.getStringList(_storageKey);
    if (savedWidgets != null) {
      state = savedWidgets;
    }
  }

  // Update the UI state and permanently save to the device
  Future<void> updatePinnedWidgets(List<String> newSelection) async {
    state = newSelection;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, newSelection);
  }
}

// The upgraded provider
final pinnedWidgetsProvider =
    StateNotifierProvider<PinnedWidgetsNotifier, List<String>>((ref) {
      return PinnedWidgetsNotifier();
    });
