import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VaultCryptoService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _hashKey = 'vault_master_hash';
  static const String _aesKey = 'vault_aes_key';
  static const String _biometricEnabledKey = 'vault_biometric_enabled';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> isVaultSetup() async {
    final hash = await _storage.read(key: _hashKey);
    return hash != null;
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<void> setupVault(String masterPassword, bool enableBiometric) async {
    final hash = _hashPassword(masterPassword);
    final aesKey = enc.Key.fromSecureRandom(32);

    await _storage.write(key: _hashKey, value: hash);
    await _storage.write(key: _aesKey, value: aesKey.base64);
    await _storage.write(
      key: _biometricEnabledKey,
      value: enableBiometric.toString(),
    );
  }

  Future<enc.Key?> unlockWithPassword(String password) async {
    final storedHash = await _storage.read(key: _hashKey);
    final inputHash = _hashPassword(password);

    if (storedHash == inputHash) {
      final base64Key = await _storage.read(key: _aesKey);
      return enc.Key.fromBase64(base64Key!);
    }
    return null;
  }

  Future<enc.Key?> unlockWithBiometric() async {
    final base64Key = await _storage.read(key: _aesKey);
    if (base64Key != null) {
      return enc.Key.fromBase64(base64Key);
    }
    return null;
  }

  String encryptPayload(String jsonPayload, enc.Key aesKey) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(jsonPayload, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String decryptPayload(String encryptedData, enc.Key aesKey) {
    final parts = encryptedData.split(':');
    final iv = enc.IV.fromBase64(parts[0]);
    final encrypted = enc.Encrypted.fromBase64(parts[1]);

    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.gcm));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // --- NEW: WIPE KEYSTORE ---
  Future<void> resetVault() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _aesKey);
    await _storage.delete(key: _biometricEnabledKey);
  }
}
