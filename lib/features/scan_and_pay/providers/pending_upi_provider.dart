// lib/features/scan_and_pay/providers/pending_upi_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../models/upi_payment_models.dart';

class PendingUpiNotifier extends StateNotifier<List<PendingUpiPayment>> {
  final Ref ref;
  static const String _storageKey = 'pending_upi_payments_queue';

  PendingUpiNotifier(this.ref) : super([]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final list = decoded
            .map((item) => PendingUpiPayment.fromJson(item as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (e) {
      debugPrint('[PendingUpiNotifier] load error: $e');
    }
  }

  Future<void> _save(List<PendingUpiPayment> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(items.map((i) => i.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('[PendingUpiNotifier] save error: $e');
    }
  }

  /// Adds a newly initiated UPI payment to the pending queue.
  Future<void> addPendingPayment(PendingUpiPayment payment) async {
    final updated = [payment, ...state];
    await _save(updated);
    state = updated;
  }

  /// Confirms that the UPI payment was successful, writes the expense
  /// transaction to the local database, and removes it from the pending queue.
  Future<bool> confirmPayment(String id) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index == -1) return false;
    final payment = state[index];

    try {
      final txService = ref.read(transactionServiceProvider);
      await txService.logTransaction(
        type: 'Expense',
        amount: payment.amount,
        date: payment.createdAt,
        accountId: payment.accountId,
        categoryId: payment.categoryId,
        categoryName: payment.categoryName,
        categoryIcon: payment.categoryIcon,
        subCategory: payment.subCategory,
        bucketId: payment.bucketId,
        bucketName: payment.bucketName,
        notes: payment.note ?? 'UPI: ${payment.payeeName}',
        tags: payment.tags,
        locationName: payment.locationName,
        latitude: payment.latitude,
        longitude: payment.longitude,
      );

      final updated = List<PendingUpiPayment>.from(state)..removeAt(index);
      await _save(updated);
      state = updated;
      return true;
    } catch (e) {
      debugPrint('[PendingUpiNotifier] confirmPayment error: $e');
      return false;
    }
  }

  /// Discards a pending payment without logging it into the transactions.
  Future<void> discardPayment(String id) async {
    final updated = state.where((p) => p.id != id).toList();
    await _save(updated);
    state = updated;
  }

  /// Confirms all currently pending payments at once.
  Future<int> confirmAll() async {
    int count = 0;
    final toProcess = List<PendingUpiPayment>.from(state);
    final txService = ref.read(transactionServiceProvider);

    for (final payment in toProcess) {
      try {
        await txService.logTransaction(
          type: 'Expense',
          amount: payment.amount,
          date: payment.createdAt,
          accountId: payment.accountId,
          categoryId: payment.categoryId,
          categoryName: payment.categoryName,
          categoryIcon: payment.categoryIcon,
          subCategory: payment.subCategory,
          bucketId: payment.bucketId,
          bucketName: payment.bucketName,
          notes: payment.note ?? 'UPI: ${payment.payeeName}',
          tags: payment.tags,
          locationName: payment.locationName,
          latitude: payment.latitude,
          longitude: payment.longitude,
        );
        count++;
      } catch (e) {
        debugPrint('[PendingUpiNotifier] confirmAll item error: $e');
      }
    }

    await _save([]);
    state = [];
    return count;
  }

  /// Clears all pending payments.
  Future<void> clearAll() async {
    await _save([]);
    state = [];
  }
}

final pendingUpiPaymentsProvider =
    StateNotifierProvider<PendingUpiNotifier, List<PendingUpiPayment>>((ref) {
  return PendingUpiNotifier(ref);
});
