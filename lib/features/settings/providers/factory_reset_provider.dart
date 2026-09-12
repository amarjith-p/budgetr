// lib/features/settings/providers/factory_reset_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';
import '../../../core/database/database_provider.dart';

final factoryResetProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return FactoryResetService(db);
});

class FactoryResetService {
  final dynamic _db;

  FactoryResetService(this._db);

  Future<void> performFactoryReset() async {
    // 1. Wipe all SQLite Data inside an atomic transaction
    await _db.transaction(() async {
      await _db.delete(_db.transactionCategories).go();
      await _db.delete(_db.budgetBuckets).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.monthlyBudgets).go();
      await _db.delete(_db.closedBudgetSnapshots).go();
      await _db.delete(_db.customBudgets).go();
      await _db.delete(_db.investments).go();
      await _db.delete(_db.investmentLogs).go();
      await _db.delete(_db.smartTrackerTemplates).go();
      await _db.delete(_db.smartTrackerRecords).go();
      await _db.delete(_db.appNotifications).go();
      await _db.delete(_db.recurringTransactionRules).go();
      await _db.delete(_db.trips).go();
      await _db.delete(_db.reminders).go();
      await _db.delete(_db.vaultRecords).go();
      await _db.delete(_db.stagedTransactions).go();
      await _db.delete(_db.parserRules).go();
      await _db.delete(_db.debts).go();
      await _db.delete(_db.netWorthRecords).go();
    });

    // 2. Wipe all User Preferences (Smart Inbox rules, location settings, themes, etc.)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 3. Wipe all Secure Storage (Biometrics, PIN, encrypted Vault payloads)
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();

    // 4. Force restart the app to clear memory and return to onboarding
    Restart.restartApp();
  }
}
