import 'package:flutter/material.dart';

class CustomBottomSheets {
  static void showError(BuildContext context, {required String message}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security_update_warning_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('Authentication Failed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  static Future<bool?> showBiometricOptIn(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint_rounded, color: Theme.of(context).colorScheme.primary, size: 56),
            const SizedBox(height: 16),
            Text('Enable Fingerprint Login?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Would you like to use your fingerprint or face to unlock Budgetr faster in the future?', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Enable Biometrics'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}