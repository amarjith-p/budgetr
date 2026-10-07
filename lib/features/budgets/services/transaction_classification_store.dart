// lib/features/budgets/services/transaction_classification_store.dart
//
// Persists user-confirmed transaction classifications using SharedPreferences.
// Key per month: "tx_clf_<month>_<year>"
// Value: JSON map { "<txId>": "fixed" | "variable" | "oneoff" }

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_classification.dart';

class TransactionClassificationStore {
  static String _prefKey(int month, int year) => 'tx_clf_${month}_$year';

  /// Load all classifications for a given budget month.
  static Future<Map<String, TransactionClassification>> load(
    int month,
    int year,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey(month, year));
    if (raw == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((txId, value) {
        final clf = TransactionClassification.values.firstWhere(
          (e) => e.name == value,
          orElse: () => TransactionClassification.variable,
        );
        return MapEntry(txId, clf);
      });
    } catch (_) {
      return {};
    }
  }

  /// Save a single transaction's classification.
  static Future<void> save(
    int month,
    int year,
    String txId,
    TransactionClassification classification,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await load(month, year);
    existing[txId] = classification;
    await prefs.setString(_prefKey(month, year), jsonEncode(
      existing.map((k, v) => MapEntry(k, v.name)),
    ));
  }

  /// Bulk-save all classifications for a month at once.
  static Future<void> saveAll(
    int month,
    int year,
    Map<String, TransactionClassification> classifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey(month, year),
      jsonEncode(classifications.map((k, v) => MapEntry(k, v.name))),
    );
  }

  /// Clear all classifications for a month (e.g. on budget reset).
  static Future<void> clear(int month, int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey(month, year));
  }
}
