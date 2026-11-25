import 'package:flutter_riverpod/legacy.dart';

enum HomeAccountViewMode {
  carousel, // Default 2-row horizontal sliding view
  grid, // All accounts displayed in a unified vertical grid
}

class HomeAccountViewModeNotifier extends StateNotifier<HomeAccountViewMode> {
  HomeAccountViewModeNotifier() : super(HomeAccountViewMode.carousel);

  void toggle() {
    state = state == HomeAccountViewMode.carousel
        ? HomeAccountViewMode.grid
        : HomeAccountViewMode.carousel;
  }

  void setMode(HomeAccountViewMode mode) {
    state = mode;
  }

  void reset() {
    state = HomeAccountViewMode.carousel;
  }
}

final homeAccountViewModeProvider = StateNotifierProvider.autoDispose<
    HomeAccountViewModeNotifier, HomeAccountViewMode>(
  (ref) => HomeAccountViewModeNotifier(),
);
