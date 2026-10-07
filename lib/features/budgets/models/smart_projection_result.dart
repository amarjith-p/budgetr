// lib/features/budgets/models/smart_projection_result.dart

/// The result produced by the SmartProjectionEngine.
class SmartProjectionResult {
  /// Sum of all transactions classified as Fixed (EMI, rent, etc.)
  final double fixedTotal;

  /// Sum of all transactions classified as One-off (travel, medical, etc.)
  final double oneoffTotal;

  /// Sum of all transactions classified as Variable (food, fuel, etc.)
  final double variableTotal;

  /// Projected variable spend extrapolated to end of month
  final double projectedVariable;

  /// Total smart projection = fixedTotal + oneoffTotal + projectedVariable
  final double smartProjection;

  /// Linear projection (unchanged, for comparison)
  final double linearProjection;

  /// Recommended daily budget for remaining days (excluding fixed + oneoff)
  final double adjustedDailyTarget;

  /// Variable-only daily average (the real "controllable" rate)
  final double variableDailyAvg;

  /// Budget health score 0–100
  final int healthScore;

  /// Human-readable insight message
  final String insightMessage;

  /// True if smart projection goes over budget
  final bool isSmartOverBudget;

  const SmartProjectionResult({
    required this.fixedTotal,
    required this.oneoffTotal,
    required this.variableTotal,
    required this.projectedVariable,
    required this.smartProjection,
    required this.linearProjection,
    required this.adjustedDailyTarget,
    required this.variableDailyAvg,
    required this.healthScore,
    required this.insightMessage,
    required this.isSmartOverBudget,
  });
}
