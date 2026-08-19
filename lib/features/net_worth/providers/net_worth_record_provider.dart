import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../services/net_worth_service.dart';

final netWorthServiceProvider = Provider<NetWorthService>((ref) {
  return NetWorthService(ref.watch(databaseProvider));
});

final netWorthRecordsStreamProvider = StreamProvider<List<NetWorthRecord>>((
  ref,
) {
  return ref.watch(netWorthServiceProvider).watchNetWorthRecords();
});

class NetWorthRecordActionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> saveRecord(NetWorthRecordsCompanion entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(netWorthServiceProvider).addNetWorthRecord(entry);
    });
    return !state.hasError;
  }

  Future<bool> deleteRecord(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(netWorthServiceProvider).deleteNetWorthRecord(id);
    });
    return !state.hasError;
  }
}

final netWorthRecordActionProvider =
    AsyncNotifierProvider<NetWorthRecordActionNotifier, void>(
      () => NetWorthRecordActionNotifier(),
    );
