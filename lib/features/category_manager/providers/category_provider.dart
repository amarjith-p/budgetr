import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/services/category_service.dart';
import '../../../core/models/transaction_category_model.dart';

// 1. Create a provider for the AppDatabase (Dependency Injection)
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase(); 
});

// 2. Inject the database into the CategoryService
final categoryServiceProvider = Provider<CategoryService>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryService(db);
});

// 3. StreamProvider to reactively listen to Category DB changes
final categoriesStreamProvider = StreamProvider<List<TransactionCategoryModel>>((ref) {
  final service = ref.watch(categoryServiceProvider);
  return service.getCategories();
});

// 4. AsyncNotifier to handle business logic operations (Add/Edit/Delete/Reset)
class CategoryActionNotifier extends AsyncNotifier<void> {
  late CategoryService _service;

  @override
  FutureOr<void> build() {
    _service = ref.watch(categoryServiceProvider);
  }

  Future<void> resetToDefaults() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.resetToDefaults());
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteCategory(id));
  }

  Future<bool> saveCategory({
    required String? id,
    required String name,
    required String type,
    required List<String> subs,
    required int iconCode,
  }) async {
    state = const AsyncLoading();
    
    // Check duplicates before saving
    final isDuplicate = await _service.checkDuplicate(name, type, excludeId: id);
    if (isDuplicate) {
      state = AsyncError(Exception('Category name already exists.'), StackTrace.current);
      return false;
    }

    state = await AsyncValue.guard(() async {
      if (id == null) {
        await _service.addCategory(name, type, subs, iconCode);
      } else {
        final updated = TransactionCategoryModel(
          id: id, name: name, type: type, subCategories: subs, iconCode: iconCode
        );
        await _service.updateCategory(updated);
      }
    });

    return !state.hasError;
  }
}

// 5. Expose the Action Notifier
final categoryActionProvider = AsyncNotifierProvider<CategoryActionNotifier, void>(
  () => CategoryActionNotifier(),
);