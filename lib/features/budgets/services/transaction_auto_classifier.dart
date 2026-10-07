// lib/features/budgets/services/transaction_auto_classifier.dart
//
// Heuristic auto-classifier that assigns a best-guess TransactionClassification
// to a transaction using category name, sub-category, notes, bucket name, and
// amount relative to the daily budget.
//
// This is intentionally a pure Dart class — no async, no DB access — so it
// can run synchronously inside the build/compute pipeline.

import '../../../core/database/app_database.dart';
import '../models/transaction_classification.dart';

class TransactionAutoClassifier {
  // ---------------------------------------------------------------------------
  // Fixed-cost keyword sets
  // ---------------------------------------------------------------------------
  static const _fixedCategoryKeywords = [
    'emi', 'loan', 'rent', 'mortgage', 'insurance', 'premium',
    'subscription', 'netflix', 'amazon prime', 'hotstar', 'spotify',
    'youtube', 'icloud', 'google one', 'phone bill', 'electricity',
    'water bill', 'gas bill', 'broadband', 'internet', 'recharge',
    'maintenance', 'society', 'tax', 'sip', 'recurring',
  ];

  static const _fixedSubcategoryKeywords = [
    'emi', 'loan', 'rent', 'subscription', 'bill', 'recharge',
    'insurance', 'maintenance', 'tax', 'premium',
  ];

  // ---------------------------------------------------------------------------
  // One-off keyword sets
  // ---------------------------------------------------------------------------
  static const _oneoffCategoryKeywords = [
    'travel', 'trip', 'vacation', 'flight', 'hotel', 'tour',
    'medical', 'hospital', 'doctor', 'medicine', 'emergency',
    'gift', 'wedding', 'birthday', 'celebration', 'donation',
    'repair', 'appliance', 'furniture', 'electronics', 'gadget',
    'investment', 'property', 'vehicle', 'car', 'bike',
  ];

  static const _oneoffSubcategoryKeywords = [
    'travel', 'medical', 'gift', 'wedding', 'repair', 'emergency',
  ];

  // ---------------------------------------------------------------------------
  // Main classify method
  // ---------------------------------------------------------------------------

  /// Classify a single transaction heuristically.
  /// Returns a [TransactionClassification] with a confidence score (0.0–1.0).
  static ClassificationGuess classify(
    TransactionRecord tx, {
    double? dailyBudget, // if provided, helps detect lump sums
  }) {
    final catName = (tx.categoryName ?? '').toLowerCase().trim();
    final subCat = (tx.subCategory ?? '').toLowerCase().trim();
    final notes = (tx.notes ?? '').toLowerCase().trim();
    final bucketName = (tx.bucketName ?? '').toLowerCase().trim();

    // Combine all text for broad matching
    final combined = '$catName $subCat $notes $bucketName';

    // --- Check FIXED ---
    int fixedScore = 0;
    for (final kw in _fixedCategoryKeywords) {
      if (catName.contains(kw)) fixedScore += 3;
      if (combined.contains(kw)) fixedScore += 1;
    }
    for (final kw in _fixedSubcategoryKeywords) {
      if (subCat.contains(kw)) fixedScore += 2;
    }

    // --- Check ONE-OFF ---
    int oneoffScore = 0;
    for (final kw in _oneoffCategoryKeywords) {
      if (catName.contains(kw)) oneoffScore += 3;
      if (combined.contains(kw)) oneoffScore += 1;
    }
    for (final kw in _oneoffSubcategoryKeywords) {
      if (subCat.contains(kw)) oneoffScore += 2;
    }

    // Lump-sum heuristic: if the amount is > 5× daily budget, likely one-off
    if (dailyBudget != null && dailyBudget > 0 && tx.amount > dailyBudget * 5) {
      oneoffScore += 2;
    }

    // --- Decide ---
    if (fixedScore == 0 && oneoffScore == 0) {
      // Default: variable with low confidence
      return ClassificationGuess(TransactionClassification.variable, 0.4);
    }

    if (fixedScore > oneoffScore) {
      final confidence = (fixedScore / (fixedScore + oneoffScore + 2)).clamp(0.5, 0.95);
      return ClassificationGuess(TransactionClassification.fixed, confidence);
    } else if (oneoffScore > fixedScore) {
      final confidence = (oneoffScore / (fixedScore + oneoffScore + 2)).clamp(0.5, 0.95);
      return ClassificationGuess(TransactionClassification.oneoff, confidence);
    } else {
      // Tie — lean towards variable
      return ClassificationGuess(TransactionClassification.variable, 0.45);
    }
  }

  /// Classify a list and return a map of txId → guess.
  static Map<String, ClassificationGuess> classifyAll(
    List<TransactionRecord> transactions, {
    double? dailyBudget,
  }) {
    return {
      for (final tx in transactions)
        tx.id: classify(tx, dailyBudget: dailyBudget),
    };
  }
}

/// Result of an auto-classification — includes the suggested classification
/// and a confidence level so the UI can show it appropriately.
class ClassificationGuess {
  final TransactionClassification classification;

  /// 0.0 = no idea, 1.0 = very confident
  final double confidence;

  const ClassificationGuess(this.classification, this.confidence);

  bool get isHighConfidence => confidence >= 0.7;

  String get confidenceLabel {
    if (confidence >= 0.85) return 'HIGH';
    if (confidence >= 0.65) return 'MEDIUM';
    return 'LOW';
  }
}
