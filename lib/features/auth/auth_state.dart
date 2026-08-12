// lib/features/auth/auth_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'services/auth_service.dart';

enum AuthStatus { loading, setupRequired, unauthenticated, authenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  // Flag to track if the native biometric overlay is currently active
  bool _isBiometricPromptOpen = false;

  @override
  AuthStatus build() {
    initAuth();
    return AuthStatus.loading;
  }

  Future<void> initAuth() async {
    final authService = ref.read(authServiceProvider);

    final lockEnabled = await authService.isAppLockEnabled();
    final hasPin = await authService.hasRegisteredPin();

    if (!lockEnabled) {
      state = AuthStatus.authenticated;
      return;
    }

    if (!hasPin) {
      state = AuthStatus.setupRequired;
      return;
    }

    state = AuthStatus.unauthenticated;

    final useBio = await authService.isBiometricEnabled();
    if (useBio) {
      await attemptBiometricUnlock();
    }
  }

  Future<void> setupNewPin(String pin, bool enableBiometrics) async {
    final authService = ref.read(authServiceProvider);
    await authService.registerPin(pin, enableBiometrics);
    state = AuthStatus.authenticated;
  }

  Future<void> unlockWithPin(String pin) async {
    final authService = ref.read(authServiceProvider);
    final isValid = await authService.verifyPin(pin);

    if (isValid) {
      state = AuthStatus.authenticated;
    } else {
      throw Exception('Incorrect PIN entered. Please try again.');
    }
  }

  /// Instantly revokes access when the app goes to the background.
  Future<void> lockApp() async {
    final authService = ref.read(authServiceProvider);
    final lockEnabled = await authService.isAppLockEnabled();
    if (!lockEnabled) return;

    // DO NOT lock if the "pause" was just the biometric overlay popping up!
    if (state == AuthStatus.authenticated && !_isBiometricPromptOpen) {
      state = AuthStatus.unauthenticated;
    }
  }

  /// Triggers when the app is resumed from the background or manual button press.
  Future<void> attemptBiometricUnlock() async {
    final authService = ref.read(authServiceProvider);
    final lockEnabled = await authService.isAppLockEnabled();
    if (!lockEnabled) return;

    // Only attempt if locked AND the prompt isn't already open
    if (state == AuthStatus.unauthenticated && !_isBiometricPromptOpen) {
      final useBio = await authService.isBiometricEnabled();

      if (useBio) {
        _isBiometricPromptOpen = true; // Lock the lifecycle

        try {
          final success = await authService.authenticateWithBiometrics();
          if (success) {
            state = AuthStatus.authenticated;
          }
        } finally {
          // When the prompt closes, the OS fires a "resumed" event.
          // We wait 500ms before unlocking the flag so the lifecycle event
          // is safely ignored, dropping the user back to the PIN pad.
          await Future.delayed(const Duration(milliseconds: 500));
          _isBiometricPromptOpen = false;
        }
      }
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(
  () => AuthNotifier(),
);

// --- NEW: Security Settings Provider ---
class SecuritySettings {
  final bool appLockEnabled;
  final bool biometricsEnabled;
  SecuritySettings({
    required this.appLockEnabled,
    required this.biometricsEnabled,
  });
}

class SecuritySettingsNotifier extends StateNotifier<SecuritySettings> {
  final Ref ref;
  SecuritySettingsNotifier(this.ref)
    : super(SecuritySettings(appLockEnabled: true, biometricsEnabled: false)) {
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(authServiceProvider);
    final lock = await service.isAppLockEnabled();
    final bio = await service.isBiometricEnabled();
    state = SecuritySettings(appLockEnabled: lock, biometricsEnabled: bio);
  }

  Future<void> toggleAppLock(bool enable) async {
    final service = ref.read(authServiceProvider);
    await service.setAppLockEnabled(enable);
    state = SecuritySettings(
      appLockEnabled: enable,
      biometricsEnabled: state.biometricsEnabled,
    );

    if (!enable) {
      ref
          .read(authProvider.notifier)
          .initAuth(); // Instantly unlocks if disabled
    } else {
      final hasPin = await service.hasRegisteredPin();
      if (!hasPin) ref.read(authProvider.notifier).initAuth(); // Triggers setup
    }
  }

  Future<void> toggleBiometrics(bool enable) async {
    final service = ref.read(authServiceProvider);
    await service.setBiometricEnabled(enable);
    state = SecuritySettings(
      appLockEnabled: state.appLockEnabled,
      biometricsEnabled: enable,
    );
  }
}

final securitySettingsProvider =
    StateNotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
      (ref) => SecuritySettingsNotifier(ref),
    );
