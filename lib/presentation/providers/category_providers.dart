import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import 'database_provider.dart';

final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCategories();
});

final categoryActionsProvider = Provider<CategoryActions>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryActions(db);
});

class CategoryActions {
  final AppDatabase _db;

  CategoryActions(this._db);

  Future<int> createCategory({
    required String name,
    required int colorValue,
    String? iconName,
  }) {
    return _db.insertCategory(CategoriesCompanion(
      name: Value(name),
      colorValue: Value(colorValue),
      iconName: Value(iconName),
    ));
  }

  Future<void> deleteCategory(int id) {
    return _db.deleteCategory(id);
  }
}
