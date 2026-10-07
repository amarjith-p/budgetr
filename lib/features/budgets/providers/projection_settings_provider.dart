// lib/features/budgets/providers/projection_settings_provider.dart
//
// SharedPreferences-backed Riverpod provider that stores the user's chosen
// budget projection mode (linear vs smart).

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProjectionMode { linear, smart }

class ProjectionSettingsNotifier extends StateNotifier<ProjectionMode> {
  static const _prefKey = 'budget_projection_mode';

  ProjectionSettingsNotifier() : super(ProjectionMode.linear) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored != null) {
      state = ProjectionMode.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => ProjectionMode.linear,
      );
    }
  }

  Future<void> setMode(ProjectionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
    state = mode;
  }
}

final projectionSettingsProvider =
    StateNotifierProvider<ProjectionSettingsNotifier, ProjectionMode>(
      (ref) => ProjectionSettingsNotifier(),
    );
