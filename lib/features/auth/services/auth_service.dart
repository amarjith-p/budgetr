import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const String _pinKey = 'secure_user_pin';
  static const String _bioKey = 'use_biometrics';

  Future<bool> hasRegisteredPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _bioKey);
    return enabled == 'true';
  }

  Future<void> registerPin(String pin, bool enableBiometrics) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _bioKey, value: enableBiometrics.toString());
  }

  Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == enteredPin;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canCheck) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Unlock Budgetr to access your dashboard',
      );
    } catch (e) {
      return false; 
    }
  }
}