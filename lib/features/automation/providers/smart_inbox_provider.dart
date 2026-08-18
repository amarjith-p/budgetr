// lib/features/automation/providers/smart_inbox_provider.dart
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../services/notification_parser_service.dart';

final notificationParserServiceProvider = Provider<NotificationParserService>((
  ref,
) {
  return NotificationParserService(ref.watch(databaseProvider));
});

final stagedTransactionsProvider =
    StreamProvider.autoDispose<List<StagedTransaction>>((ref) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.stagedTransactions)
            ..where((t) => t.isApproved.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();
    });

final parserRulesProvider = StreamProvider.autoDispose<List<ParserRule>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.parserRules).watch();
});

class SmartInboxActionNotifier extends AsyncNotifier<void> {
  StreamSubscription? _subscription;
  final _uuid = const Uuid();

  @override
  FutureOr<void> build() {}

  Future<bool> checkPermission() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  Future<void> requestPermissionsAndListen() async {
    final bool isGranted =
        await NotificationListenerService.isPermissionGranted();
    if (!isGranted) {
      await NotificationListenerService.requestPermission();
    }

    _subscription?.cancel();
    _subscription = NotificationListenerService.notificationsStream.listen((
      event,
    ) {
      ref.read(notificationParserServiceProvider).processNotification(event);
    });
  }

  Future<bool> approveStagedTransaction({
    required StagedTransaction stagedTx,
    required String accountId,
    required String? categoryId,
    required String? categoryName,
    required int? categoryIcon,
    String? subCategory,
    int? bucketId,
    String? bucketName,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final db = ref.read(databaseProvider);

    final success = await ref
        .read(transactionActionProvider.notifier)
        .saveTransaction(
          type: stagedTx.inferredType,
          amount: stagedTx.extractedAmount,
          date: stagedTx.date,
          accountId: accountId,
          categoryId: categoryId,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          subCategory: subCategory,
          bucketId: bucketId,
          bucketName: bucketName,
          notes:
              notes ?? stagedTx.merchantName ?? 'Auto-logged via Smart Inbox',
        );

    if (success) {
      await db
          .update(db.stagedTransactions)
          .replace(stagedTx.copyWith(isApproved: true));
      // Clean up approved item from staging table
      await (db.delete(
        db.stagedTransactions,
      )..where((t) => t.id.equals(stagedTx.id))).go();
    }

    state = const AsyncData(null);
    return success;
  }

  Future<void> deleteStaged(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(
      db.stagedTransactions,
    )..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAllStaged() async {
    final db = ref.read(databaseProvider);
    await (db.delete(
      db.stagedTransactions,
    )..where((t) => t.isApproved.equals(false))).go();
  }

  Future<void> addCustomRule({
    required String name,
    required String regexPattern,
    required String targetType,
  }) async {
    final db = ref.read(databaseProvider);
    await db
        .into(db.parserRules)
        .insert(
          ParserRulesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            regexPattern: regexPattern,
            targetType: targetType,
            isActive: const Value(true),
            isCustom: const Value(true),
          ),
        );
  }

  Future<void> toggleRule(String id, bool isActive) async {
    final db = ref.read(databaseProvider);
    final rule = await (db.select(
      db.parserRules,
    )..where((r) => r.id.equals(id))).getSingle();
    await db.update(db.parserRules).replace(rule.copyWith(isActive: isActive));
  }

  Future<void> deleteRule(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.parserRules)..where((r) => r.id.equals(id))).go();
  }
}

final smartInboxActionProvider =
    AsyncNotifierProvider<SmartInboxActionNotifier, void>(
      () => SmartInboxActionNotifier(),
    );
