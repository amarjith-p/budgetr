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
    r'\b(debited|paid|spent|sent|transferred|deducted)\b',
    caseSensitive: false,
  );

  static final RegExp _defaultIncomeKeywords = RegExp(
    r'\b(credited|received|deposited|added|refunded)\b',
    caseSensitive: false,
  );

  static final RegExp _accountRegex = RegExp(
    r'(?:a/c|acct|account|ac|card|ending|x+|\*+)\s*(?:no\.?|number|in|with)?\s*[-:]?\s*[\(\*]?\s*([0-9]{3,4})\)?',
    caseSensitive: false,
  );

  // --- FIX: Group 1 now captures the prefix. Added 'using' as a stopping boundary ---
  static final RegExp _merchantRegex = RegExp(
    r'(sent to|paid to|to|at|vpa|info|for|from)\s+([A-Za-z0-9\s&\-@]{3,25}?)(?:\s+on|\s+ref|\s+upi|\s+using|\s+avl|\s+by|\s+via|\s+in|\s+a/c|\s+acct|\s+card|\s+amount|\s+to|\s+from|\.|\,|$)',
    caseSensitive: false,
  );

  static final RegExp _refRegex = RegExp(
    r'(?:upi ref|ref no|utr|txn id|ref|imps ref)\s*[:#-]?\s*([A-Za-z0-9]{6,16})',
    caseSensitive: false,
  );

  // Synchronous memory lock to prevent duplicate async race conditions
  static final Set<String> _activeHashes = {};

  NotificationParserService(this._db);

  // Helper method to calculate text proximity
  int _getDistance(int start1, int end1, int start2, int end2) {
    if (end1 <= start2) return start2 - end1;
    if (end2 <= start1) return start1 - end2;
    return 0;
  }

  Future<ParsedNotificationResult?> testParseText(String fullText) async {
    if (fullText.trim().isEmpty) return null;

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

    final amountMatch = _amountRegex.firstMatch(fullText);
    if (amountMatch == null) return null;

    final rawAmount = amountMatch.group(1)?.replaceAll(',', '') ?? '';
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    final accMatch = _accountRegex.firstMatch(fullText);
    final refMatch = _refRegex.firstMatch(fullText);

    final last4 = accMatch?.group(1);
    final refNo = refMatch?.group(1);

    // --- FIX: DETERMINE INCOME/EXPENSE FIRST ---
    final expMatches = _defaultExpenseKeywords.allMatches(fullText);
    final incMatches = _defaultIncomeKeywords.allMatches(fullText);

    String finalType = 'Expense';
    String finalPattern = 'Universal Expense Pattern';

    if (expMatches.isNotEmpty && incMatches.isNotEmpty) {
      int minExpDist = 999999;
      for (var m in expMatches) {
        int dist = _getDistance(
          m.start,
          m.end,
          amountMatch.start,
          amountMatch.end,
        );
        if (dist < minExpDist) minExpDist = dist;
      }

      int minIncDist = 999999;
      for (var m in incMatches) {
        int dist = _getDistance(
          m.start,
          m.end,
          amountMatch.start,
          amountMatch.end,
        );
        if (dist < minIncDist) minIncDist = dist;
      }

      if (minIncDist < minExpDist) {
        finalType = 'Income';
        finalPattern = 'Universal Income Pattern (Proximity)';
      } else {
        finalType = 'Expense';
        finalPattern = 'Universal Expense Pattern (Proximity)';
      }
    } else if (incMatches.isNotEmpty) {
      finalType = 'Income';
      finalPattern = 'Universal Income Pattern';
    } else if (expMatches.isNotEmpty) {
      finalType = 'Expense';
      finalPattern = 'Universal Expense Pattern';
    } else {
      return null;
    }

    // --- NEW: CONTEXT-AWARE SMART MERCHANT FILTERING ---
    String? merchant;
    String? fallbackMerchant;
    final merchantMatches = _merchantRegex.allMatches(fullText);

    final expensePrefixes = ['to', 'at', 'paid to', 'sent to', 'vpa', 'for'];
    final incomePrefixes = ['from', 'by'];

    for (final m in merchantMatches) {
      final prefix = m.group(1)?.toLowerCase().trim() ?? '';
      final text = m.group(2)?.trim();

      if (text != null && text.isNotEmpty) {
        // Intelligently ignore matches that look like a masked account number
        final isMaskedAccount = RegExp(
          r'^(?:x+|\*+)?\d+$',
          caseSensitive: false,
        ).hasMatch(text);

        if (!isMaskedAccount) {
          if (finalType == 'Expense' && expensePrefixes.contains(prefix)) {
            merchant = text; // Perfect expense match found
            break;
          } else if (finalType == 'Income' && incomePrefixes.contains(prefix)) {
            merchant = text; // Perfect income match found
            break;
          } else {
            fallbackMerchant ??=
                text; // Save first valid match as fallback just in case
          }
        }
      }
    }

    // Apply the perfectly matched merchant, or the fallback if context failed
    merchant ??= fallbackMerchant;

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

    return ParsedNotificationResult(
      amount: amount,
      type: finalType,
      accountLast4: last4,
      merchantName: merchant,
      referenceNo: refNo,
      matchedPattern: finalPattern,
    );
  }

  Future<void> processNotification(ServiceNotificationEvent event) async {
    try {
      if (event.hasRemoved ?? false) {
        return;
      }

      final String title = event.title ?? '';
      final String content = event.content ?? '';
      final String fullText = '$title $content'.trim();
      final String packageName = event.packageName ?? 'unknown';

      if (packageName.contains('android.system') ||
          packageName.contains('whatsapp') ||
          packageName.contains('budgetr') ||
          packageName == 'com.example.budgetr') {
        return;
      }

      final String hashData = '$packageName|$fullText';
      final String txHash = sha256.convert(utf8.encode(hashData)).toString();

      if (_activeHashes.contains(txHash)) {
        debugPrint("Race condition blocked: Event already processing.");
        return;
      }

      _activeHashes.add(txHash);

      if (_activeHashes.length > 50) {
        _activeHashes.clear();
        _activeHashes.add(txHash);
      }

      try {
        final prefs = await SharedPreferences.getInstance();

        List<String> rawHashes =
            prefs.getStringList('smart_inbox_dedup_v3') ?? [];
        final now = DateTime.now();

        rawHashes.removeWhere((item) {
          final parts = item.split(':');
          if (parts.length != 2) return true;
          final timestamp = int.tryParse(parts[1]);
          if (timestamp == null) return true;
          final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
          return now.difference(time).inHours > 24;
        });

        bool isDuplicate = rawHashes.any((item) => item.startsWith('$txHash:'));

        if (isDuplicate) {
          debugPrint("Ghost notification interaction detected and dropped.");
          await prefs.setStringList('smart_inbox_dedup_v3', rawHashes);
          return;
        }

        final parsed = await testParseText(fullText);
        if (parsed == null) return;

        if (parsed.type == 'Ignore') {
          debugPrint("Notification deliberately omitted by custom rule.");
          return;
        }

        final timeWindow = now.subtract(const Duration(hours: 24));
        final recentStaged =
            await (_db.select(_db.stagedTransactions)
                  ..where((t) => t.isApproved.equals(false))
                  ..where((t) => t.date.isBiggerOrEqualValue(timeWindow)))
                .get();

        bool isSemanticDuplicate = false;
        for (var staged in recentStaged) {
          if (parsed.referenceNo != null &&
              parsed.referenceNo!.isNotEmpty &&
              staged.referenceNo == parsed.referenceNo) {
            isSemanticDuplicate = true;
            break;
          }

          final timeDiffMinutes = now.difference(staged.date).inMinutes.abs();
          final amountDifference = (staged.extractedAmount - parsed.amount)
              .abs();

          if (amountDifference < 0.01 &&
              staged.inferredType == parsed.type &&
              timeDiffMinutes <= 5) {
            isSemanticDuplicate = true;
            break;
          }
        }

        if (isSemanticDuplicate) {
          debugPrint(
            "Semantic duplicate dropped: Same amount and type logged within 5 mins, or matching Ref No.",
          );
          rawHashes.add('$txHash:${now.millisecondsSinceEpoch}');
          await prefs.setStringList('smart_inbox_dedup_v3', rawHashes);
          return;
        }

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

        final bool pushEnabled = prefs.getBool('smartInboxPushEnabled') ?? true;
        final bool masterEnabled = prefs.getBool('enableNotifications') ?? true;

        if (pushEnabled && masterEnabled) {
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
        } else {
          debugPrint("Smart Inbox Push disabled in settings. Skipping alert.");
        }
      } finally {
        _activeHashes.remove(txHash);
      }
    } catch (e) {
      debugPrint("Notification Parser Error: $e");
    }
  }
}
