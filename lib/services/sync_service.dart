import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';

class SyncService {
  static const _lastSyncKey = 'lastSyncTime';

  static Future<String> exportToJson() async {
    final db = AppDatabase.instance;
    final data = await db.exportAllData();
    return jsonEncode(data);
  }

  static Future<String> exportToFile() async {
    final json = await exportToJson();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/planer_backup_$timestamp.json');
    await file.writeAsString(json);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

    return file.path;
  }

  static Future<void> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Файл не найден');
    }

    final json = await file.readAsString();
    final data = jsonDecode(json) as Map<String, dynamic>;

    if (data['version'] != 1) {
      throw Exception('Неподдерживаемая версия бэкапа');
    }

    final db = AppDatabase.instance;

    // Import categories first (tasks reference them)
    final categoriesList = data['categories'] as List<dynamic>? ?? [];
    for (final c in categoriesList) {
      await db.insertCategory(CategoriesCompanion(
        id: Value(c['id'] as int),
        name: Value(c['name'] as String),
        colorValue: Value(c['colorValue'] as int),
        iconName: Value(c['iconName'] as String?),
      ));
    }

    // Import tasks
    final tasksList = data['tasks'] as List<dynamic>? ?? [];
    for (final t in tasksList) {
      await db.insertTask(TasksCompanion(
        id: Value(t['id'] as int),
        title: Value(t['title'] as String),
        description: Value(t['description'] as String?),
        date: Value(t['date'] != null ? DateTime.parse(t['date'] as String) : null),
        timeHour: Value(t['timeHour'] as int?),
        timeMinute: Value(t['timeMinute'] as int?),
        priority: Value(TaskPriority.values[t['priority'] as int? ?? 1]),
        categoryId: Value(t['categoryId'] as int?),
        tags: Value(t['tags'] as String? ?? ''),
        progressPercent: Value(t['progressPercent'] as int? ?? 0),
        isCompleted: Value(t['isCompleted'] as bool? ?? false),
        recurrenceType: Value(t['recurrenceType'] != null
            ? TaskRecurrenceType.values[t['recurrenceType'] as int]
            : null),
        recurrenceInterval: Value(t['recurrenceInterval'] as int?),
        createdAt: Value(DateTime.parse(t['createdAt'] as String)),
        updatedAt: Value(DateTime.parse(t['updatedAt'] as String)),
      ));
    }

    // Import subtasks
    final subtasksList = data['subtasks'] as List<dynamic>? ?? [];
    for (final s in subtasksList) {
      await db.insertSubtask(SubtasksCompanion(
        id: Value(s['id'] as int),
        taskId: Value(s['taskId'] as int),
        title: Value(s['title'] as String),
        isCompleted: Value(s['isCompleted'] as bool? ?? false),
        sortOrder: Value(s['sortOrder'] as int? ?? 0),
      ));
    }

    // Import attachments
    final attachmentsList = data['attachments'] as List<dynamic>? ?? [];
    for (final a in attachmentsList) {
      await db.insertAttachment(AttachmentsCompanion(
        id: Value(a['id'] as int),
        taskId: Value(a['taskId'] as int),
        filePath: Value(a['filePath'] as String),
        displayName: Value(a['displayName'] as String?),
        attachmentType: Value(AttachmentType.values[a['attachmentType'] as int]),
        createdAt: Value(DateTime.parse(a['createdAt'] as String)),
      ));
    }

    // Import reminders
    final remindersList = data['reminders'] as List<dynamic>? ?? [];
    for (final r in remindersList) {
      await db.insertReminder(RemindersCompanion(
        id: Value(r['id'] as int),
        taskId: Value(r['taskId'] as int),
        offsetMinutes: Value(r['offsetMinutes'] as int),
        isActive: Value(r['isActive'] as bool? ?? true),
      ));
    }

    debugPrint('Import complete: ${tasksList.length} tasks, '
        '${categoriesList.length} categories, '
        '${subtasksList.length} subtasks, '
        '${attachmentsList.length} attachments, '
        '${remindersList.length} reminders');
  }

  static Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }
}
