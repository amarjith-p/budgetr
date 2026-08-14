// lib/features/notifications/providers/in_app_notification_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';

// ============================================================================
// --- SERVICE ---
// ============================================================================
class InAppNotificationService {
  final AppDatabase _db;

  InAppNotificationService(this._db);

  Stream<List<AppNotification>> watchAllNotifications() {
    return (_db.select(
      _db.appNotifications,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<void> saveNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _db
        .into(_db.appNotifications)
        .insertOnConflictUpdate(
          AppNotificationsCompanion.insert(
            id: id,
            title: title,
            body: body,
            payload: Value(payload),
            createdAt: scheduledDate,
            isRead: const Value(false),
          ),
        );
  }

  Future<void> markAsRead(String id) async {
    final notif = await (_db.select(
      _db.appNotifications,
    )..where((t) => t.id.equals(id))).getSingle();
    await _db
        .update(_db.appNotifications)
        .replace(notif.copyWith(isRead: true));
  }

  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    await (_db.update(_db.appNotifications)
          ..where((t) => t.createdAt.isSmallerOrEqualValue(now)))
        .write(const AppNotificationsCompanion(isRead: Value(true)));
  }

  Future<void> deleteNotification(String id) async {
    await (_db.delete(
      _db.appNotifications,
    )..where((t) => t.id.equals(id))).go();
  }

  // Clear past notifications (Triggered by user in UI)
  Future<void> clearPastNotifications() async {
    final now = DateTime.now();
    await (_db.delete(
      _db.appNotifications,
    )..where((t) => t.createdAt.isSmallerOrEqualValue(now))).go();
  }

  // Clear future scheduled notifications (Triggered by the scheduler to prevent duplicates)
  Future<void> clearFutureNotifications() async {
    final now = DateTime.now();
    await (_db.delete(
      _db.appNotifications,
    )..where((t) => t.createdAt.isBiggerThanValue(now))).go();
  }
}

// ============================================================================
// --- PROVIDERS ---
// ============================================================================

final inAppNotificationServiceProvider = Provider<InAppNotificationService>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return InAppNotificationService(db);
});

// --- ROCK SOLID TIMER STATE NOTIFIER ---
// This safely watches all DB notifications and pushes them to the UI *only*
// when their scheduled time has passed, without breaking the Riverpod state tree.
class InAppNotificationStateNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final InAppNotificationService _service;
  Timer? _timer;
  StreamSubscription? _sub;
  List<AppNotification> _allNotifications = [];

  InAppNotificationStateNotifier(this._service) : super(const AsyncLoading()) {
    _init();
  }

  void _init() {
    // 1. Subscribe to the database securely
    _sub = _service.watchAllNotifications().listen(
      (data) {
        _allNotifications = data;
        _refreshFilteredState();
      },
      onError: (e, st) {
        state = AsyncError(e, st);
      },
    );

    // 2. Tick every 3 seconds to pop scheduled notifications into the UI seamlessly
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshFilteredState(),
    );
  }

  void _refreshFilteredState() {
    final now = DateTime.now();

    // Only show notifications where the scheduled time has arrived or passed
    final triggered = _allNotifications.where((n) {
      return n.createdAt.isBefore(now) || n.createdAt.isAtSameMomentAs(now);
    }).toList();

    state = AsyncData(triggered);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

final notificationsStreamProvider =
    StateNotifierProvider.autoDispose<
      InAppNotificationStateNotifier,
      AsyncValue<List<AppNotification>>
    >((ref) {
      final service = ref.watch(inAppNotificationServiceProvider);
      return InAppNotificationStateNotifier(service);
    });

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(notificationsStreamProvider);
  return state.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// ============================================================================
// --- ACTION NOTIFIER (Mark Read / Delete) ---
// ============================================================================

class InAppNotificationActionNotifier extends AsyncNotifier<void> {
  late InAppNotificationService _service;

  @override
  FutureOr<void> build() {
    _service = ref.watch(inAppNotificationServiceProvider);
  }

  Future<bool> markAsRead(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.markAsRead(id));
    return !state.hasError;
  }

  Future<bool> markAllAsRead() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.markAllAsRead());
    return !state.hasError;
  }

  Future<bool> deleteNotification(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteNotification(id));
    return !state.hasError;
  }

  Future<bool> clearPastNotifications() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.clearPastNotifications());
    return !state.hasError;
  }
}

final inAppNotificationActionProvider =
    AsyncNotifierProvider<InAppNotificationActionNotifier, void>(
      () => InAppNotificationActionNotifier(),
    );
