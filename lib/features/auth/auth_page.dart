import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import '../../core/components/custom_bottom_sheets.dart';
import '../../core/theme/app_theme.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  String _enteredPin = '';
  String _firstPin = ''; 
  final int _pinLength = 4;

  void _onKeypadPressed(String value) {
    if (_enteredPin.length < _pinLength) {
      setState(() => _enteredPin += value);
      if (_enteredPin.length == _pinLength) {
        _processPinCompletion();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  Future<void> _processPinCompletion() async {
    final status = ref.read(authProvider);

    if (status == AuthStatus.setupRequired) {
      if (_firstPin.isEmpty) {
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
        });
      } else {
        if (_enteredPin == _firstPin) {
          final enableBio = await CustomBottomSheets.showBiometricOptIn(context) ?? false;
          ref.read(authProvider.notifier).setupNewPin(_enteredPin, enableBio);
        } else {
          CustomBottomSheets.showError(context, message: 'PINs do not match. Please try again.');
          setState(() {
            _firstPin = '';
            _enteredPin = '';
          });
        }
      }
    } else if (status == AuthStatus.unauthenticated) {
      try {
        await ref.read(authProvider.notifier).unlockWithPin(_enteredPin);
      } catch (e) {
        if (mounted) {
          CustomBottomSheets.showError(context, message: e.toString());
          setState(() => _enteredPin = '');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider);

    if (status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSetup = status == AuthStatus.setupRequired;
    final headerTitle = isSetup 
        ? (_firstPin.isEmpty ? 'Create PIN' : 'Confirm PIN') 
        : 'Welcome Back';
    final headerSubtitle = isSetup 
        ? (_firstPin.isEmpty ? 'Set a 4-digit security code' : 'Re-enter your code to confirm')
        : 'Enter your secure PIN to continue';

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Icon(isSetup ? Icons.security_rounded : Icons.lock_rounded, 
                     size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(headerTitle, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(headerSubtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.surfaceVariant,
                    border: isFilled 
                        ? null 
                        : Border.all(color: Theme.of(context).disabledColor.withOpacity(0.3), width: 2),
                  ),
                );
              }),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) {
                    if (status == AuthStatus.unauthenticated) {
                      return _buildKeypadButton(
                        child: const Icon(Icons.fingerprint_rounded, size: 32),
                        onPressed: () => ref.read(authProvider.notifier).attemptBiometricUnlock(),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  
                  if (index == 11) {
                    return _buildKeypadButton(
                      child: const Icon(Icons.backspace_rounded, size: 28),
                      onPressed: _onBackspace,
                    );
                  }
                  final number = index == 10 ? '0' : '${index + 1}';
                  return _buildKeypadButton(
                    child: Text(number, style: Theme.of(context).textTheme.headlineMedium),
                    onPressed: () => _onKeypadPressed(number),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton({required Widget child, required VoidCallback onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
      borderRadius: BorderRadius.circular(AppTokens.padRadius),
      elevation: isDark ? 0 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.padRadius),
        onTap: onPressed,
        child: Center(child: child),
      ),
    );
  }
}