import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/auth_service.dart';

enum AuthStatus { loading, setupRequired, unauthenticated, authenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  // Flag to track if the native biometric overlay is currently active
  bool _isBiometricPromptOpen = false;

  @override
  AuthStatus build() {
    _initAuth();
    return AuthStatus.loading;
  }

  Future<void> _initAuth() async {
    final authService = ref.read(authServiceProvider);
    final hasPin = await authService.hasRegisteredPin();
    
    if (!hasPin) {
      state = AuthStatus.setupRequired;
      return;
    }
    
    // FIX: Immediately transition out of 'loading' to 'unauthenticated'.
    // This renders the PIN pad in the background and satisfies the 
    // safety check inside attemptBiometricUnlock().
    state = AuthStatus.unauthenticated;

    final useBio = await authService.isBiometricEnabled();
    if (useBio) {
      // Now this will successfully trigger because the state is unauthenticated.
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
  void lockApp() {
    // DO NOT lock if the "pause" was just the biometric overlay popping up!
    if (state == AuthStatus.authenticated && !_isBiometricPromptOpen) {
      state = AuthStatus.unauthenticated;
    }
  }

  /// Triggers when the app is resumed from the background or manual button press.
  Future<void> attemptBiometricUnlock() async {
    // Only attempt if locked AND the prompt isn't already open
    if (state == AuthStatus.unauthenticated && !_isBiometricPromptOpen) {
      final authService = ref.read(authServiceProvider);
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

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(() => AuthNotifier());