// lib/features/budgets/services/smart_projection_engine.dart
//
// The Smart Projection Engine.
// Uses user-confirmed transaction classifications to compute an accurate
// budget projection that correctly handles fixed costs and one-off spends.

import 'dart:math';
import '../../../core/database/app_database.dart';
import '../models/transaction_classification.dart';
import '../models/smart_projection_result.dart';

class SmartProjectionEngine {
  /// Computes a [SmartProjectionResult] from the given inputs.
  ///
  /// [transactions] — all expense transactions for the budget month.
  /// [classifications] — user-confirmed classification per txId.
  /// [allocatedBudget] — the effective income / budget limit.
  /// [daysInMonth] — total days in the current month.
  /// [daysElapsed] — how many days have passed so far.
  static SmartProjectionResult compute({
    required List<TransactionRecord> transactions,
    required Map<String, TransactionClassification> classifications,
    required double allocatedBudget,
    required int daysInMonth,
    required int daysElapsed,
  }) {
    double fixedTotal = 0.0;
    double oneoffTotal = 0.0;
    double variableTotal = 0.0;

    for (final tx in transactions) {
      final clf = classifications[tx.id] ?? TransactionClassification.variable;
      switch (clf) {
        case TransactionClassification.fixed:
          fixedTotal += tx.amount;
          break;
        case TransactionClassification.oneoff:
          oneoffTotal += tx.amount;
          break;
        case TransactionClassification.variable:
          variableTotal += tx.amount;
          break;
      }
    }

    // Variable daily average (the only part that gets extrapolated)
    final variableDailyAvg =
        daysElapsed > 0 ? variableTotal / daysElapsed : 0.0;

    // Project variable spending to end of month
    final projectedVariable = variableDailyAvg * daysInMonth;

    // Smart total projection
    final smartProjection = fixedTotal + oneoffTotal + projectedVariable;

    // Linear projection (for reference comparison)
    final totalSpend = fixedTotal + oneoffTotal + variableTotal;
    final linearDailyAvg = daysElapsed > 0 ? totalSpend / daysElapsed : 0.0;
    final linearProjection = linearDailyAvg * daysInMonth;

    // Adjusted daily target (what can I spend per day for remaining days?)
    final daysRemaining = daysInMonth - daysElapsed;
    final controllableBudget = allocatedBudget - fixedTotal - oneoffTotal;
    final adjustedDailyTarget = daysRemaining > 0
        ? max(0.0, (controllableBudget - variableTotal) / daysRemaining)
        : 0.0;

    // Health score (0–100)
    final healthScore = _computeHealthScore(
      smartProjection: smartProjection,
      allocatedBudget: allocatedBudget,
      variableDailyAvg: variableDailyAvg,
      controllableBudget: controllableBudget,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
    );

    // Insight message
    final insightMessage = _buildInsight(
      fixedTotal: fixedTotal,
      oneoffTotal: oneoffTotal,
      variableTotal: variableTotal,
      smartProjection: smartProjection,
      linearProjection: linearProjection,
      allocatedBudget: allocatedBudget,
      adjustedDailyTarget: adjustedDailyTarget,
      healthScore: healthScore,
    );

    return SmartProjectionResult(
      fixedTotal: fixedTotal,
      oneoffTotal: oneoffTotal,
      variableTotal: variableTotal,
      projectedVariable: projectedVariable,
      smartProjection: smartProjection,
      linearProjection: linearProjection,
      adjustedDailyTarget: adjustedDailyTarget,
      variableDailyAvg: variableDailyAvg,
      healthScore: healthScore,
      insightMessage: insightMessage,
      isSmartOverBudget: smartProjection > allocatedBudget,
    );
  }

  static int _computeHealthScore({
    required double smartProjection,
    required double allocatedBudget,
    required double variableDailyAvg,
    required double controllableBudget,
    required int daysElapsed,
    required int daysInMonth,
  }) {
    if (allocatedBudget <= 0) return 50;

    // Factor 1: How well is variable spending pacing vs controllable budget?
    final targetVariableDailyAvg = daysElapsed > 0
        ? controllableBudget / daysInMonth
        : 0.0;
    final variablePaceRatio = targetVariableDailyAvg > 0
        ? (variableDailyAvg / targetVariableDailyAvg).clamp(0.0, 2.0)
        : 0.0;
    final pacingScore = ((1.0 - variablePaceRatio) * 50 + 50).clamp(0.0, 100.0);

    // Factor 2: Overall projection vs budget ratio
    final projRatio = (smartProjection / allocatedBudget).clamp(0.0, 2.0);
    final projectionScore = ((1.0 - projRatio) * 50 + 50).clamp(0.0, 100.0);

    // Weighted average: pace is more actionable
    return ((pacingScore * 0.6) + (projectionScore * 0.4)).round().clamp(0, 100);
  }

  static String _buildInsight({
    required double fixedTotal,
    required double oneoffTotal,
    required double variableTotal,
    required double smartProjection,
    required double linearProjection,
    required double allocatedBudget,
    required double adjustedDailyTarget,
    required int healthScore,
  }) {
    final savedFromLinear = linearProjection - smartProjection;
    final hasFixed = fixedTotal > 0;
    final hasOneoff = oneoffTotal > 0;

    if (healthScore >= 80) {
      if (hasFixed || hasOneoff) {
        return 'Isolated costs accounted for. Your day-to-day spending is well within control.';
      }
      return 'Great pace! You are on track to finish well under budget.';
    } else if (healthScore >= 60) {
      if ((hasFixed || hasOneoff) && savedFromLinear > 0) {
        if (hasFixed && hasOneoff) {
          return 'Fixed & one-off costs (₹${_fmt(fixedTotal + oneoffTotal)}) are isolated. Actual variable pace is healthy.';
        } else if (hasFixed) {
          return 'Fixed costs (₹${_fmt(fixedTotal)}) are isolated. Actual variable pace is healthy.';
        } else {
          return 'One-off spends (₹${_fmt(oneoffTotal)}) are isolated. Actual variable pace is healthy.';
        }
      }
      return 'Spending is moderate. Keep an eye on daily variable costs.';
    } else if (healthScore >= 40) {
      if (hasFixed || hasOneoff) {
        if (hasFixed && hasOneoff) {
          return 'Fixed + one-off costs total ₹${_fmt(fixedTotal + oneoffTotal)}. Reduce daily variable spending to stay safe.';
        } else if (hasFixed) {
          return 'Fixed costs total ₹${_fmt(fixedTotal)}. Reduce daily variable spending to stay safe.';
        } else {
          return 'One-off spends total ₹${_fmt(oneoffTotal)}. Reduce daily variable spending to stay safe.';
        }
      }
      return 'Variable spending is running high. Aim for ₹${_fmt(adjustedDailyTarget)}/day to recover.';
    } else {
      return 'High variable spending rate detected. Target ₹${_fmt(adjustedDailyTarget)}/day to avoid overrun.';
    }
  }

  static String _fmt(double val) {
    return val.toStringAsFixed(2);
  }
}
