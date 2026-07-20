import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Globally provides the active database connection.
/// Ensures the database is safely closed if the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});