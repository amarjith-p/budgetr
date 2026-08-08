// features/insights/providers/insight_filter_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

class InsightFilterState {
  final String timeFrame; // e.g., 'This Month', 'Last Month', 'Custom Range'
  final DateTimeRange? customRange;
  final String? accountId; // null means 'All Accounts'

  InsightFilterState({
    this.timeFrame = 'This Month',
    this.customRange,
    this.accountId,
  });

  InsightFilterState copyWith({
    String? timeFrame,
    DateTimeRange? customRange,
    String? accountId,
    bool clearAccount = false,
  }) {
    return InsightFilterState(
      timeFrame: timeFrame ?? this.timeFrame,
      customRange: customRange ?? this.customRange,
      accountId: clearAccount ? null : (accountId ?? this.accountId),
    );
  }
}

final insightFilterProvider = StateProvider<InsightFilterState>((ref) {
  return InsightFilterState();
});
