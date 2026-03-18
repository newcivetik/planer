import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../services/widget_service.dart';
import 'database_provider.dart';

final allTasksProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTasks();
});

final todayTasksProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTodayTasks();
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final tasksForSelectedDateProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.watchTasksForDate(date);
});

final taskActionsProvider = Provider<TaskActions>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskActions(db);
});

class TaskActions {
  final AppDatabase _db;

  TaskActions(this._db);

  Future<int> createTask({
    required String title,
    String? description,
    DateTime? date,
    int? timeHour,
    int? timeMinute,
    TaskPriority priority = TaskPriority.medium,
    int? categoryId,
    String tags = '',
  }) async {
    final now = DateTime.now();
    final id = await _db.insertTask(TasksCompanion(
      title: Value(title),
      description: Value(description),
      date: Value(date),
      timeHour: Value(timeHour),
      timeMinute: Value(timeMinute),
      priority: Value(priority),
      categoryId: Value(categoryId),
      tags: Value(tags),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    _updateWidgets();
    return id;
  }

  Future<void> updateTask({
    required int id,
    required String title,
    String? description,
    DateTime? date,
    int? timeHour,
    int? timeMinute,
    TaskPriority priority = TaskPriority.medium,
    int? categoryId,
    String tags = '',
    int progressPercent = 0,
    bool isCompleted = false,
  }) async {
    final existing = await _db.getTaskById(id);
    await _db.updateTask(TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      date: Value(date),
      timeHour: Value(timeHour),
      timeMinute: Value(timeMinute),
      priority: Value(priority),
      categoryId: Value(categoryId),
      tags: Value(tags),
      progressPercent: Value(progressPercent),
      isCompleted: Value(isCompleted),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> toggleCompletion(int id, bool isCompleted) async {
    await _db.toggleTaskCompletion(id, isCompleted);
    _updateWidgets();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    _updateWidgets();
  }

  void _updateWidgets() {
    if (!kIsWeb) {
      WidgetService.updateWidgetData();
    }
  }
}
