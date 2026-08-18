// lib/features/automation/services/notification_parser_service.dart
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:notification_listener_service/notification_event.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/location_helper.dart';

class ParsedNotificationResult {
  final double amount;
  final String type; // 'Expense' or 'Income'
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

  // 1. Independent Amount Extractor (Matches Rs 500, INR 500, ₹500)
  static final RegExp _amountRegex = RegExp(
    r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // 2. Independent Keyword Extractors
  static final RegExp _defaultExpenseKeywords = RegExp(
    r'\b(debited|paid|spent|sent|transferred|deducted|vpa)\b',
    caseSensitive: false,
  );
  static final RegExp _defaultIncomeKeywords = RegExp(
    r'\b(credited|received|deposited|added|refunded)\b',
    caseSensitive: false,
  );

  // 3. Metadata Extractors
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

  /// Test parsing raw text against both custom DB rules and universal defaults
  Future<ParsedNotificationResult?> testParseText(String fullText) async {
    if (fullText.trim().isEmpty) return null;

    // STEP 1: Find the Amount first. If no amount, it's not a transaction.
    final amountMatch = _amountRegex.firstMatch(fullText);
    if (amountMatch == null) return null;

    final rawAmount = amountMatch.group(1)?.replaceAll(',', '') ?? '';
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    // Extract optional metadata
    final accMatch = _accountRegex.firstMatch(fullText);
    final merchantMatch = _merchantRegex.firstMatch(fullText);
    final refMatch = _refRegex.firstMatch(fullText);

    final last4 = accMatch?.group(1);
    final merchant = merchantMatch?.group(1)?.trim();
    final refNo = refMatch?.group(1);

    // STEP 2: Check custom active rules in database
    final customRules = await (_db.select(
      _db.parserRules,
    )..where((r) => r.isActive.equals(true))).get();

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

    // STEP 3: Universal Heuristic Check
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

  /// Background stream processor for intercepted system notifications
  Future<void> processNotification(ServiceNotificationEvent event) async {
    try {
      final String title = event.title ?? '';
      final String content = event.content ?? '';
      final String fullText = '$title $content'.trim();
      final String packageName = event.packageName ?? 'unknown';

      // Ignore system logs or messaging noise early
      if (packageName.contains('android.system') ||
          packageName.contains('whatsapp'))
        return;

      final parsed = await testParseText(fullText);
      if (parsed == null) return;

      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(minutes: 3));

      // Smart Deduplication: Avoid duplicate logs if UPI push and SMS arrive together
      final existingMatches =
          await (_db.select(_db.stagedTransactions)..where(
                (t) =>
                    t.extractedAmount.equals(parsed.amount) &
                    t.isApproved.equals(false) &
                    t.date.isBiggerThanValue(windowStart),
              ))
              .get();

      if (existingMatches.isNotEmpty) {
        final existing = existingMatches.first;
        if (existing.accountLast4 == null && parsed.accountLast4 != null) {
          await _db
              .update(_db.stagedTransactions)
              .replace(
                existing.copyWith(accountLast4: Value(parsed.accountLast4)),
              );
        }
        return;
      }

      final sourceName = title.isNotEmpty && title.length < 20
          ? title
          : packageName.split('.').last.toUpperCase();

      // --- NEW: FETCH LOCATION IN BACKGROUND ---
      String? locName;
      double? lat;
      double? lng;

      try {
        // Wrap in a 5-second timeout so a bad GPS signal doesn't crash or stall the background service
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
        // We continue silently without location so the transaction still logs
      }

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
              date: now,
              locationName: Value(locName), // <-- Saved to Staging
              latitude: Value(lat), // <-- Saved to Staging
              longitude: Value(lng), // <-- Saved to Staging
            ),
          );
    } catch (e) {
      debugPrint("Notification Parser Error: $e");
    }
  }
}
