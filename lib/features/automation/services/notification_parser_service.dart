// lib/features/automation/services/notification_parser_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:notification_listener_service/notification_event.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/services/notification_service.dart';

class ParsedNotificationResult {
  final double amount;
  final String type; // 'Expense', 'Income', or 'Ignore'
  final String? accountLast4;
  final String? merchantName;
  final String? referenceNo;
  final String matchedPattern;

  ParsedNotificationResult({
    required this.amount,
    required this.type,
    this.accountLast4,
    this.merchantName,
    this.referenceNo,
    required this.matchedPattern,
  });
}

class NotificationParserService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  static final RegExp _amountRegex = RegExp(
    r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _defaultExpenseKeywords = RegExp(
    r'\b(debited|paid|spent|sent|transferred|deducted|vpa)\b',
    caseSensitive: false,
  );

  static final RegExp _defaultIncomeKeywords = RegExp(
    r'\b(credited|received|deposited|added|refunded)\b',
    caseSensitive: false,
  );

  static final RegExp _accountRegex = RegExp(
    r'(?:a/c|acct|card|ending with|ending in|xx|x)\s*([0-9]{3,4})',
    caseSensitive: false,
  );

  static final RegExp _merchantRegex = RegExp(
    r'(?:to|at|vpa|info|for)\s+([A-Za-z0-9\s&.\-@]{3,25})(?:\s+on|\s+ref|\s+upi|\s+avl|\.|$)',
    caseSensitive: false,
  );

  static final RegExp _refRegex = RegExp(
    r'(?:upi ref|ref no|utr|txn id|ref)\s*[:]?\s*([0-9]{6,12})',
    caseSensitive: false,
  );

  NotificationParserService(this._db);

  Future<ParsedNotificationResult?> testParseText(String fullText) async {
    if (fullText.trim().isEmpty) return null;

    // =========================================================================
    // 1. ISOLATED CODE BLOCK: OMIT / IGNORE RULES
    // Checked first, before anything else, so promotional texts without amounts
    // are correctly caught and omitted by the system.
    // =========================================================================
    final ignoreRules =
        await (_db.select(_db.parserRules)..where(
              (r) => r.isActive.equals(true) & r.targetType.equals('Ignore'),
            ))
            .get();

    for (var rule in ignoreRules) {
      try {
        final keywordRegex = RegExp(rule.regexPattern, caseSensitive: false);
        if (keywordRegex.hasMatch(fullText)) {
          return ParsedNotificationResult(
            amount: 0.0,
            type: 'Ignore',
            matchedPattern: 'Omit Rule: ${rule.name}',
          );
        }
      } catch (_) {}
    }
    // =========================================================================

    // 2. EXTRACT AMOUNT
    final amountMatch = _amountRegex.firstMatch(fullText);
    if (amountMatch == null) return null;

    final rawAmount = amountMatch.group(1)?.replaceAll(',', '') ?? '';
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    final accMatch = _accountRegex.firstMatch(fullText);
    final merchantMatch = _merchantRegex.firstMatch(fullText);
    final refMatch = _refRegex.firstMatch(fullText);

    final last4 = accMatch?.group(1);
    final merchant = merchantMatch?.group(1)?.trim();
    final refNo = refMatch?.group(1);

    // 3. CHECK ACTIVE CUSTOM RULES (Priority over Default Universal Rules)
    final customRules =
        await (_db.select(_db.parserRules)..where(
              (r) =>
                  r.isActive.equals(true) & r.targetType.isNotValue('Ignore'),
            ))
            .get();

    for (var rule in customRules) {
      try {
        final keywordRegex = RegExp(rule.regexPattern, caseSensitive: false);
        if (keywordRegex.hasMatch(fullText)) {
          return ParsedNotificationResult(
            amount: amount,
            type: rule.targetType,
            accountLast4: last4,
            merchantName: merchant,
            referenceNo: refNo,
            matchedPattern: 'Custom Rule: ${rule.name}',
          );
        }
      } catch (_) {}
    }

    // 4. FALLBACK TO UNIVERSAL DEFAULT RULES
    if (_defaultExpenseKeywords.hasMatch(fullText)) {
      return ParsedNotificationResult(
        amount: amount,
        type: 'Expense',
        accountLast4: last4,
        merchantName: merchant,
        referenceNo: refNo,
        matchedPattern: 'Universal Expense Pattern',
      );
    } else if (_defaultIncomeKeywords.hasMatch(fullText)) {
      return ParsedNotificationResult(
        amount: amount,
        type: 'Income',
        accountLast4: last4,
        merchantName: merchant,
        referenceNo: refNo,
        matchedPattern: 'Universal Income Pattern',
      );
    }

    return null;
  }

  Future<void> processNotification(ServiceNotificationEvent event) async {
    try {
      // 1. IGNORE DISMISSALS: Stops ghost triggers when user clears their phone's notification tray
      if (event.hasRemoved ?? false) {
        return;
      }

      final String title = event.title ?? '';
      final String content = event.content ?? '';
      final String fullText = '$title $content'.trim();
      final String packageName = event.packageName ?? 'unknown';

      if (packageName.contains('android.system') ||
          packageName.contains('whatsapp')) {
        return;
      }

      // 2. BULLETPROOF HASH: Includes the OS-level event.id.
      // This ensures that interacting with the SAME notification is blocked as a duplicate,
      // but receiving a NEW notification with the EXACT SAME text is allowed through.
      final String hashData = '${event.id}|$packageName|$fullText';
      final String txHash = sha256.convert(utf8.encode(hashData)).toString();

      final prefs = await SharedPreferences.getInstance();

      // 3. SLIDING WINDOW: Track hashes with a timestamp
      List<String> rawHashes =
          prefs.getStringList('smart_inbox_dedup_v3') ?? [];
      final now = DateTime.now();

      // Clean up hashes older than 48 hours to keep the app lightweight
      rawHashes.removeWhere((item) {
        final parts = item.split(':');
        if (parts.length != 2) return true;
        final timestamp = int.tryParse(parts[1]);
        if (timestamp == null) return true;
        final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return now.difference(time).inHours > 48;
      });

      // If we already have this exact Android Notification ID + Text combo, drop it.
      bool isDuplicate = rawHashes.any((item) => item.startsWith('$txHash:'));

      if (isDuplicate) {
        debugPrint("Ghost notification interaction detected and dropped.");
        await prefs.setStringList('smart_inbox_dedup_v3', rawHashes);
        return;
      }

      final parsed = await testParseText(fullText);
      if (parsed == null) return;

      // --- ABORT IF IT TRIGGERED THE OMIT/IGNORE RULE ---
      if (parsed.type == 'Ignore') {
        debugPrint("Notification deliberately omitted by custom rule.");
        return;
      }

      // Add the new unique hash to our tracking list
      rawHashes.add('$txHash:${now.millisecondsSinceEpoch}');
      await prefs.setStringList('smart_inbox_dedup_v3', rawHashes);

      final txDate = DateTime.now();

      String? locName;
      double? lat;
      double? lng;

      final bool isFreshNotification =
          DateTime.now().difference(txDate).inMinutes < 5;

      if (isFreshNotification) {
        try {
          final locData = await LocationHelper.fetchCurrentLocation().timeout(
            const Duration(seconds: 5),
          );
          if (locData != null) {
            locName = locData['name'];
            lat = locData['latitude'];
            lng = locData['longitude'];
          }
        } catch (e) {
          debugPrint("Background location fetch failed or timed out: $e");
        }
      }

      final sourceName = title.isNotEmpty && title.length < 20
          ? title
          : packageName.split('.').last.toUpperCase();

      await _db
          .into(_db.stagedTransactions)
          .insert(
            StagedTransactionsCompanion.insert(
              id: _uuid.v4(),
              rawText: fullText,
              sourceName: sourceName,
              packageName: packageName,
              extractedAmount: parsed.amount,
              inferredType: parsed.type,
              accountLast4: Value(parsed.accountLast4),
              merchantName: Value(parsed.merchantName),
              referenceNo: Value(parsed.referenceNo),
              date: txDate,
              locationName: Value(locName),
              latitude: Value(lat),
              longitude: Value(lng),
            ),
          );

      final String sign = parsed.type == 'Expense' ? '-' : '+';
      final String alertTitle = 'New Transaction Detected';
      final String bodyText =
          '$sign ₹${parsed.amount} via $sourceName. Tap to review and approve.';

      NotificationService.instance.scheduleNotification(
        id: DateTime.now().millisecond,
        title: alertTitle,
        body: bodyText,
        scheduledDate: DateTime.now().add(const Duration(seconds: 1)),
      );
    } catch (e) {
      debugPrint("Notification Parser Error: $e");
    }
  }
}
