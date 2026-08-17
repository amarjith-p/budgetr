import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../services/vault_crypto_service.dart';
import '../models/vault_models.dart';

enum VaultStateStatus { initializing, setupRequired, locked, unlocked }

class VaultState {
  final VaultStateStatus status;
  final enc.Key? activeKey;

  VaultState({required this.status, this.activeKey});
}

final vaultCryptoProvider = Provider((ref) => VaultCryptoService());

class VaultNotifier extends AsyncNotifier<VaultState> {
  late VaultCryptoService _cryptoService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  Future<VaultState> build() async {
    _cryptoService = ref.watch(vaultCryptoProvider);
    final isSetup = await _cryptoService.isVaultSetup();
    return VaultState(
      status: isSetup
          ? VaultStateStatus.locked
          : VaultStateStatus.setupRequired,
    );
  }

  Future<bool> setupVault(String password, bool enableBiometric) async {
    await _cryptoService.setupVault(password, enableBiometric);
    final key = await _cryptoService.unlockWithPassword(password);
    state = AsyncData(
      VaultState(status: VaultStateStatus.unlocked, activeKey: key),
    );
    return true;
  }

  Future<bool> unlockWithPassword(String password) async {
    final key = await _cryptoService.unlockWithPassword(password);
    if (key != null) {
      state = AsyncData(
        VaultState(status: VaultStateStatus.unlocked, activeKey: key),
      );
      return true;
    }
    return false;
  }

  Future<bool> unlockWithBiometric() async {
    final isBiometricEnabled = await _cryptoService.isBiometricEnabled();
    if (!isBiometricEnabled) return false;

    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    if (!canCheckBiometrics) return false;

    final authenticated = await _localAuth.authenticate(
      localizedReason: 'Authenticate to unlock Secure Vault',
    );

    if (authenticated) {
      final key = await _cryptoService.unlockWithBiometric();
      if (key != null) {
        state = AsyncData(
          VaultState(status: VaultStateStatus.unlocked, activeKey: key),
        );
        return true;
      }
    }
    return false;
  }

  void lockVault() {
    state = AsyncData(
      VaultState(status: VaultStateStatus.locked, activeKey: null),
    );
  }

  Future<bool> saveRecord({
    required String recordType,
    required String recordName,
    required VaultPayload payload,
  }) async {
    try {
      final currentState = state.value;
      if (currentState == null ||
          currentState.status != VaultStateStatus.unlocked ||
          currentState.activeKey == null) {
        throw Exception("Vault is locked or key is missing.");
      }

      final db = ref.read(databaseProvider);
      final jsonString = jsonEncode(payload.toJson());
      final encryptedData = _cryptoService.encryptPayload(
        jsonString,
        currentState.activeKey!,
      );

      await db
          .into(db.vaultRecords)
          .insert(
            VaultRecordsCompanion.insert(
              id: const Uuid().v4(),
              recordType: recordType,
              recordName: recordName,
              encryptedPayload: encryptedData,
              createdAt: DateTime.now(),
            ),
          );
      return true;
    } catch (e) {
      throw Exception("Encryption failed: $e");
    }
  }

  Future<bool> updateRecord({
    required String id,
    required String recordType,
    required String recordName,
    required VaultPayload payload,
  }) async {
    try {
      final currentState = state.value;
      if (currentState == null ||
          currentState.status != VaultStateStatus.unlocked ||
          currentState.activeKey == null) {
        throw Exception("Vault is locked or key is missing.");
      }

      final db = ref.read(databaseProvider);
      final jsonString = jsonEncode(payload.toJson());
      final encryptedData = _cryptoService.encryptPayload(
        jsonString,
        currentState.activeKey!,
      );

      final oldRecord = await (db.select(
        db.vaultRecords,
      )..where((t) => t.id.equals(id))).getSingle();

      await db
          .update(db.vaultRecords)
          .replace(
            oldRecord.copyWith(
              recordType: recordType,
              recordName: recordName,
              encryptedPayload: encryptedData,
            ),
          );
      return true;
    } catch (e) {
      throw Exception("Update encryption failed: $e");
    }
  }

  Future<void> deleteRecord(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.vaultRecords)..where((t) => t.id.equals(id))).go();
  }

  // --- NEW: FACTORY RESET VAULT ---
  Future<void> resetVault() async {
    final db = ref.read(databaseProvider);
    // 1. Wipe database records
    await db.delete(db.vaultRecords).go();
    // 2. Wipe cryptographic keys
    await _cryptoService.resetVault();
    // 3. Reset state
    state = AsyncData(
      VaultState(status: VaultStateStatus.setupRequired, activeKey: null),
    );
    ref.invalidate(vaultRecordsProvider);
  }
}

final vaultProvider = AsyncNotifierProvider<VaultNotifier, VaultState>(
  () => VaultNotifier(),
);

final vaultRecordsProvider =
    FutureProvider.autoDispose<List<DecryptedVaultRecord>>((ref) async {
      final vaultState = ref.watch(vaultProvider).value;
      if (vaultState == null ||
          vaultState.status != VaultStateStatus.unlocked ||
          vaultState.activeKey == null) {
        return [];
      }

      final db = ref.watch(databaseProvider);
      final crypto = ref.watch(vaultCryptoProvider);
      final records = await db.select(db.vaultRecords).get();

      return records.map((row) {
        final decryptedJsonStr = crypto.decryptPayload(
          row.encryptedPayload,
          vaultState.activeKey!,
        );
        final jsonMap = jsonDecode(decryptedJsonStr);

        VaultPayload payload;
        if (row.recordType == 'Credential') {
          payload = CredentialPayload.fromJson(jsonMap);
        } else {
          payload = CardPayload.fromJson(jsonMap);
        }

        return DecryptedVaultRecord(
          id: row.id,
          recordType: row.recordType,
          recordName: row.recordName,
          payload: payload,
          createdAt: row.createdAt,
        );
      }).toList();
    });
