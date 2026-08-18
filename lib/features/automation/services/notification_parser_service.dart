// lib/features/automation/services/notification_parser_service.dart
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:notification_listener_service/notification_event.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/services/notification_service.dart';

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
      final String title = event.title ?? '';
      final String content = event.content ?? '';
      final String fullText = '$title $content'.trim();
      final String packageName = event.packageName ?? 'unknown';

      if (packageName.contains('android.system') ||
          packageName.contains('whatsapp'))
        return;

      final parsed = await testParseText(fullText);
      if (parsed == null) return;

      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(minutes: 3));

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

      // --- FETCH LOCATION IN BACKGROUND ---
      String? locName;
      double? lat;
      double? lng;

      try {
        // 5-second timeout ensures the background parser doesn't hang if GPS is weak
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
              locationName: Value(locName), // Fully captured in background
              latitude: Value(lat),
              longitude: Value(lng),
            ),
          );

      // Trigger user prompt
      final String sign = parsed.type == 'Expense' ? '-' : '+';
      final String alertTitle = 'New Transaction Detected';
      final String bodyText =
          '$sign ₹${parsed.amount} via $sourceName. Tap to review and approve.';

      // Using your existing centralized notification service
      NotificationService.instance.scheduleNotification(
        id: DateTime.now().millisecond,
        title: alertTitle,
        body: bodyText,
        scheduledDate: now.add(const Duration(seconds: 1)),
      );
    } catch (e) {
      debugPrint("Notification Parser Error: $e");
    }
  }
}
