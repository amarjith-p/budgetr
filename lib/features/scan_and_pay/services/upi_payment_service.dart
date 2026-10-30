// lib/features/scan_and_pay/services/upi_payment_service.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiPaymentService {
  /// Builds a fully standard, NPCI-compliant UPI payment intent URI.
  static String buildUpiUri({
    required String pa,
    required String pn,
    required double amount,
    String? note,
    String? tr,
    String? mc,
  }) {
    final queryParams = <String, String>{
      'pa': pa.trim(),
      'pn': pn.trim(),
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
    };

    if (note != null && note.trim().isNotEmpty) {
      queryParams['tn'] = note.trim();
    }
    if (mc != null && mc.trim().isNotEmpty) {
      queryParams['mc'] = mc.trim();
    }
    if (tr != null && tr.trim().isNotEmpty) {
      queryParams['tr'] = tr.trim();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'upi://pay?$queryString';
  }

  /// Launches the external UPI app (Google Pay, PhonePe, Paytm, etc.).
  ///
  /// Uses [LaunchMode.externalApplication] so that the UPI app runs in the
  /// foreground in its own native task. This allows the user to see the
  /// green payment success checkmark screen and keep it visible for the
  /// merchant as long as they need, before switching back to Budgetr.
  static Future<bool> launchUpi({
    required String upiUri,
  }) async {
    try {
      final uri = Uri.parse(upiUri);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback: Try with externalNonBrowserApplication
        return await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      }
      return launched;
    } catch (e) {
      debugPrint('[UpiPaymentService] launchUpi failed: $e');
      return false;
    }
  }
}
