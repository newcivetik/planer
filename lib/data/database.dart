import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime().nullable()();
  IntColumn get timeHour => integer().nullable()();
  IntColumn get timeMinute => integer().nullable()();
  IntColumn get priority => intEnum<TaskPriority>()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get tags => text().withDefault(const Constant(''))();
  IntColumn get progressPercent => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get recurrenceType => intEnum<TaskRecurrenceType>().nullable()();
  IntColumn get recurrenceInterval => integer().nullable()();
  TextColumn get recurrenceDaysOfWeek => text().nullable()();
  DateTimeColumn get recurrenceEndDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id)();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get colorValue => integer()();
  TextColumn get iconName => text().nullable()();
}

class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id)();
  TextColumn get filePath => text()();
  TextColumn get displayName => text().nullable()();
  IntColumn get attachmentType => intEnum<AttachmentType>()();
  DateTimeColumn get createdAt => dateTime()();
}

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id)();
  IntColumn get offsetMinutes => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

enum TaskPriority { low, medium, high }

enum TaskRecurrenceType { daily, weekly, monthly, yearly }

enum AttachmentType { image, file, link }

@DriftDatabase(tables: [Tasks, Subtasks, Categories, Attachments, Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'planer_db');
  }

  // === Tasks ===

  Future<List<Task>> getAllTasks() => select(tasks).get();

  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.timeHour), (t) => OrderingTerm(expression: t.timeMinute)]))
        .watch();
  }

  Stream<List<Task>> watchTodayTasks() {
    return watchTasksForDate(DateTime.now());
  }

  Future<Task> getTaskById(int id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);

  Future<int> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> toggleTaskCompletion(int id, bool isCompleted) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // === Subtasks ===

  Stream<List<Subtask>> watchSubtasksForTask(int taskId) {
    return (select(subtasks)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([(s) => OrderingTerm(expression: s.sortOrder)]))
        .watch();
  }

  Future<int> insertSubtask(SubtasksCompanion subtask) => into(subtasks).insert(subtask);

  Future<void> toggleSubtask(int id, bool isCompleted) {
    return (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(isCompleted: Value(isCompleted)),
    );
  }

  Future<int> deleteSubtask(int id) {
    return (delete(subtasks)..where((s) => s.id.equals(id))).go();
  }

  // === Categories ===

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<List<Category>> getAllCategories() => select(categories).get();

  Future<int> insertCategory(CategoriesCompanion category) => into(categories).insert(category);

  Future<bool> updateCategory(CategoriesCompanion category) => update(categories).replace(category);

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  // === Attachments ===

  Stream<List<Attachment>> watchAttachmentsForTask(int taskId) {
    return (select(attachments)..where((a) => a.taskId.equals(taskId))).watch();
  }

  Future<int> insertAttachment(AttachmentsCompanion attachment) => into(attachments).insert(attachment);

  Future<int> deleteAttachment(int id) {
    return (delete(attachments)..where((a) => a.id.equals(id))).go();
  }

  Future<List<Attachment>> getAttachmentsForTask(int taskId) {
    return (select(attachments)..where((a) => a.taskId.equals(taskId))).get();
  }

  // === Reminders ===

  Stream<List<Reminder>> watchRemindersForTask(int taskId) {
    return (select(reminders)..where((r) => r.taskId.equals(taskId))).watch();
  }

  Future<int> insertReminder(RemindersCompanion reminder) => into(reminders).insert(reminder);

  Future<int> deleteReminder(int id) {
    return (delete(reminders)..where((r) => r.id.equals(id))).go();
  }

  Future<void> deleteRemindersForTask(int taskId) {
    return (delete(reminders)..where((r) => r.taskId.equals(taskId))).go();
  }

  // === Sync Export ===

  Future<Map<String, dynamic>> exportAllData() async {
    final allTasks = await select(tasks).get();
    final allSubtasks = await select(subtasks).get();
    final allCategories = await select(categories).get();
    final allAttachments = await select(attachments).get();
    final allReminders = await select(reminders).get();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': allTasks.map((t) => {
            'id': t.id,
            'title': t.title,
            'description': t.description,
            'date': t.date?.toIso8601String(),
            'timeHour': t.timeHour,
            'timeMinute': t.timeMinute,
            'priority': t.priority.index,
            'categoryId': t.categoryId,
            'tags': t.tags,
            'progressPercent': t.progressPercent,
            'isCompleted': t.isCompleted,
            'recurrenceType': t.recurrenceType?.index,
            'recurrenceInterval': t.recurrenceInterval,
            'createdAt': t.createdAt.toIso8601String(),
            'updatedAt': t.updatedAt.toIso8601String(),
          }).toList(),
      'subtasks': allSubtasks.map((s) => {
            'id': s.id,
            'taskId': s.taskId,
            'title': s.title,
            'isCompleted': s.isCompleted,
            'sortOrder': s.sortOrder,
          }).toList(),
      'categories': allCategories.map((c) => {
            'id': c.id,
            'name': c.name,
            'colorValue': c.colorValue,
            'iconName': c.iconName,
          }).toList(),
      'attachments': allAttachments.map((a) => {
            'id': a.id,
            'taskId': a.taskId,
            'filePath': a.filePath,
            'displayName': a.displayName,
            'attachmentType': a.attachmentType.index,
            'createdAt': a.createdAt.toIso8601String(),
          }).toList(),
      'reminders': allReminders.map((r) => {
            'id': r.id,
            'taskId': r.taskId,
            'offsetMinutes': r.offsetMinutes,
            'isActive': r.isActive,
          }).toList(),
    };
  }
}
