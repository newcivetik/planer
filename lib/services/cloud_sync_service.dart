import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';
import 'sync_service.dart';

/// Статус облачной синхронизации
enum SyncStatus {
  /// Синхронизация никогда не выполнялась
  never,

  /// Синхронизация завершена успешно
  synced,

  /// Ошибка при последней синхронизации
  error,

  /// Синхронизация в процессе
  inProgress,
}

/// Cloud sync service that manages backup/restore to platform-specific cloud storage.
///
/// On iOS: Uses iCloud Documents (via file copy to iCloud container)
/// On Android: Uses local backup with option to share via system share sheet
///
/// Strategy: JSON snapshots with last-write-wins merge by `updatedAt` field.
/// Supports subtask/reminder/attachment merge and soft-delete via `deletedAt`.
class CloudSyncService {
  static const _lastCloudSyncKey = 'lastCloudSyncTime';
  static const _backupFileName = 'planer_cloud_backup.json';
  static const _autoSyncEnabledKey = 'cloudAutoSyncEnabled';
  static const _syncStatusKey = 'cloudSyncStatus';
  static const _syncErrorKey = 'cloudSyncLastError';
  static const _syncStatsKey = 'cloudSyncStats';
  static const _autoSyncIntervalHours = 1;

  static bool _isSyncing = false;

  /// Export data to cloud-accessible location
  static Future<String> syncToCloud() async {
    if (_isSyncing) {
      throw Exception('Синхронизация уже выполняется');
    }
    _isSyncing = true;
    await _setSyncStatus(SyncStatus.inProgress);

    try {
      final json = await SyncService.exportToJson();
      final path = await _getCloudPath();
      final file = File('$path/$_backupFileName');
      await file.writeAsString(json);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastCloudSyncKey, DateTime.now().toIso8601String());

      // Сохраняем статистику
      final data = jsonDecode(json) as Map<String, dynamic>;
      await _saveSyncStats(data);

      await _setSyncStatus(SyncStatus.synced);
      await _clearSyncError();

      debugPrint('Cloud sync: exported to ${file.path}');
      return file.path;
    } catch (e) {
      await _setSyncStatus(SyncStatus.error);
      await _setSyncError('Ошибка экспорта: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Restore data from cloud backup
  static Future<bool> syncFromCloud() async {
    if (_isSyncing) {
      throw Exception('Синхронизация уже выполняется');
    }
    _isSyncing = true;
    await _setSyncStatus(SyncStatus.inProgress);

    try {
      final path = await _getCloudPath();
      final file = File('$path/$_backupFileName');

      if (!await file.exists()) {
        debugPrint('Cloud sync: no backup found at ${file.path}');
        await _setSyncStatus(SyncStatus.synced);
        return false;
      }

      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;

      if (data['version'] != 1) {
        throw Exception('Неподдерживаемая версия бэкапа');
      }

      final db = AppDatabase.instance;
      final existingTasks = await db.getAllTasks();
      final existingMap = {for (final t in existingTasks) t.id: t};

      final remoteTasks = data['tasks'] as List<dynamic>? ?? [];
      final remoteSubtasks = data['subtasks'] as List<dynamic>? ?? [];
      final remoteReminders = data['reminders'] as List<dynamic>? ?? [];
      final remoteAttachments = data['attachments'] as List<dynamic>? ?? [];

      // Группируем подзадачи, напоминания, вложения по taskId
      final remoteSubtasksByTask = _groupByTaskId(remoteSubtasks);
      final remoteRemindersByTask = _groupByTaskId(remoteReminders);
      final remoteAttachmentsByTask = _groupByTaskId(remoteAttachments);

      for (final rt in remoteTasks) {
        final remoteId = rt['id'] as int;

        // Мягкое удаление: если есть deletedAt, пропускаем задачу
        if (rt['deletedAt'] != null &&
            (rt['deletedAt'] as String).isNotEmpty) {
          // Если задача существует локально — удаляем
          if (existingMap.containsKey(remoteId)) {
            try {
              await db.deleteTask(remoteId);
            } catch (_) {}
          }
          debugPrint(
              'Cloud sync: пропущена удалённая задача id=$remoteId');
          continue;
        }

        final remoteUpdatedAt =
            DateTime.parse(rt['updatedAt'] as String);

        if (existingMap.containsKey(remoteId)) {
          final local = existingMap[remoteId]!;
          // Обновляем только если удалённая версия новее
          if (remoteUpdatedAt.isAfter(local.updatedAt)) {
            await _importSingleTask(db, rt);

            // Мержим подзадачи
            await _mergeSubtasks(
                db, remoteId, remoteSubtasksByTask[remoteId] ?? []);

            // Мержим напоминания
            await _mergeReminders(
                db, remoteId, remoteRemindersByTask[remoteId] ?? []);

            // Мержим метаданные вложений
            await _mergeAttachments(
                db, remoteId, remoteAttachmentsByTask[remoteId] ?? []);
          }
        } else {
          await _importSingleTask(db, rt);

          // Импортируем связанные данные для новой задачи
          await _importSubtasksForTask(
              db, remoteSubtasksByTask[remoteId] ?? []);
          await _importRemindersForTask(
              db, remoteRemindersByTask[remoteId] ?? []);
          await _importAttachmentsForTask(
              db, remoteAttachmentsByTask[remoteId] ?? []);
        }
      }

      // Import categories that don't exist locally
      final existingCategories = await db.getAllCategories();
      final existingCatIds = existingCategories.map((c) => c.id).toSet();
      final remoteCategories =
          data['categories'] as List<dynamic>? ?? [];

      for (final rc in remoteCategories) {
        if (!existingCatIds.contains(rc['id'] as int)) {
          await SyncService.importFromFile(await _writeTemp(json));
          break; // importFromFile handles all data
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastCloudSyncKey, DateTime.now().toIso8601String());

      await _saveSyncStats(data);
      await _setSyncStatus(SyncStatus.synced);
      await _clearSyncError();

      debugPrint('Cloud sync: restored from ${file.path}');
      return true;
    } catch (e) {
      await _setSyncStatus(SyncStatus.error);
      await _setSyncError('Ошибка импорта: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  // === Auto-sync ===

  /// Автоматическая синхронизация, если прошло больше часа с последней
  static Future<void> autoSyncIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoSyncEnabledKey) ?? false;
    if (!enabled) {
      debugPrint('Cloud sync: авто-синхронизация отключена');
      return;
    }

    final lastSync = prefs.getString(_lastCloudSyncKey);
    if (lastSync != null) {
      final lastSyncTime = DateTime.parse(lastSync);
      final diff = DateTime.now().difference(lastSyncTime);
      if (diff.inHours < _autoSyncIntervalHours) {
        debugPrint(
            'Cloud sync: авто-синхронизация не нужна (прошло ${diff.inMinutes} мин)');
        return;
      }
    }

    debugPrint('Cloud sync: запуск авто-синхронизации...');
    try {
      // Сначала загружаем из облака, потом выгружаем
      await syncFromCloud();
      await syncToCloud();
      debugPrint('Cloud sync: авто-синхронизация завершена');
    } catch (e) {
      debugPrint('Cloud sync: ошибка авто-синхронизации: $e');
    }
  }

  /// Включить/выключить автоматическую синхронизацию
  static Future<void> enableAutoSync(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncEnabledKey, enabled);
    debugPrint(
        'Cloud sync: авто-синхронизация ${enabled ? "включена" : "выключена"}');
  }

  /// Проверить, включена ли авто-синхронизация
  static Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncEnabledKey) ?? false;
  }

  // === Sync status tracking ===

  /// Получить текущий статус синхронизации
  static Future<SyncStatus> getSyncStatus() async {
    if (_isSyncing) return SyncStatus.inProgress;
    final prefs = await SharedPreferences.getInstance();
    final statusIndex = prefs.getInt(_syncStatusKey);
    if (statusIndex == null) return SyncStatus.never;
    if (statusIndex >= 0 && statusIndex < SyncStatus.values.length) {
      return SyncStatus.values[statusIndex];
    }
    return SyncStatus.never;
  }

  /// Получить сообщение последней ошибки синхронизации
  static Future<String?> getLastSyncError() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_syncErrorKey);
  }

  /// Получить статистику последней синхронизации
  static Future<Map<String, int>> getSyncStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_syncStatsKey);
    if (statsJson == null) {
      return {
        'tasks': 0,
        'subtasks': 0,
        'categories': 0,
        'attachments': 0,
        'reminders': 0,
      };
    }
    final decoded = jsonDecode(statsJson) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }

  // === Existing public methods ===

  /// Get last cloud sync time
  static Future<String?> getLastCloudSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCloudSyncKey);
  }

  /// Check if cloud backup exists
  static Future<bool> hasCloudBackup() async {
    try {
      final path = await _getCloudPath();
      final file = File('$path/$_backupFileName');
      return file.exists();
    } catch (_) {
      return false;
    }
  }

  // === Private helpers: merge logic ===

  static Map<int, List<Map<String, dynamic>>> _groupByTaskId(
      List<dynamic> items) {
    final result = <int, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final taskId = item['taskId'] as int;
      result.putIfAbsent(taskId, () => []);
      result[taskId]!.add(item as Map<String, dynamic>);
    }
    return result;
  }

  /// Мержим подзадачи: по совпадению taskId + title
  static Future<void> _mergeSubtasks(AppDatabase db, int taskId,
      List<Map<String, dynamic>> remoteSubtasks) async {
    if (remoteSubtasks.isEmpty) return;

    // Получаем локальные подзадачи через экспорт всех данных
    final allData = await db.exportAllData();
    final localSubtasks = (allData['subtasks'] as List<dynamic>)
        .where((s) => s['taskId'] == taskId)
        .toList();

    final localByKey = <String, Map<String, dynamic>>{};
    for (final s in localSubtasks) {
      final key = '${s['taskId']}_${s['title']}';
      localByKey[key] = s as Map<String, dynamic>;
    }

    for (final rs in remoteSubtasks) {
      final key = '${rs['taskId']}_${rs['title']}';
      if (localByKey.containsKey(key)) {
        // Подзадача существует — обновляем статус завершения
        final localSub = localByKey[key]!;
        if (rs['isCompleted'] == true && localSub['isCompleted'] != true) {
          try {
            await db.deleteSubtask(localSub['id'] as int);
          } catch (_) {}
          await _importSingleSubtask(db, rs);
        }
      } else {
        // Новая подзадача — импортируем
        await _importSingleSubtask(db, rs);
      }
    }
  }

  /// Мержим напоминания: по taskId + offsetMinutes
  static Future<void> _mergeReminders(AppDatabase db, int taskId,
      List<Map<String, dynamic>> remoteReminders) async {
    if (remoteReminders.isEmpty) return;

    final allData = await db.exportAllData();
    final localReminders = (allData['reminders'] as List<dynamic>)
        .where((r) => r['taskId'] == taskId)
        .toList();

    final localByKey = <String, Map<String, dynamic>>{};
    for (final r in localReminders) {
      final key = '${r['taskId']}_${r['offsetMinutes']}';
      localByKey[key] = r as Map<String, dynamic>;
    }

    for (final rr in remoteReminders) {
      final key = '${rr['taskId']}_${rr['offsetMinutes']}';
      if (!localByKey.containsKey(key)) {
        // Новое напоминание — импортируем
        await _importSingleReminder(db, rr);
      }
      // Если напоминание уже есть — оставляем локальную версию
    }
  }

  /// Мержим метаданные вложений: по taskId + displayName
  static Future<void> _mergeAttachments(AppDatabase db, int taskId,
      List<Map<String, dynamic>> remoteAttachments) async {
    if (remoteAttachments.isEmpty) return;

    final localAttachments = await db.getAttachmentsForTask(taskId);
    final localByKey = <String, dynamic>{};
    for (final a in localAttachments) {
      final key = '${a.taskId}_${a.displayName ?? a.filePath}';
      localByKey[key] = a;
    }

    for (final ra in remoteAttachments) {
      final key =
          '${ra['taskId']}_${ra['displayName'] ?? ra['filePath']}';
      if (!localByKey.containsKey(key)) {
        // Новое вложение (только метаданные) — импортируем
        await _importSingleAttachment(db, ra);
      }
    }
  }

  // === Private helpers: import individual items ===

  static Future<void> _importSingleTask(
      AppDatabase db, Map<String, dynamic> t) async {
    try {
      await db.deleteTask(t['id'] as int);
    } catch (_) {
      // Task doesn't exist yet
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_single_import.json');
    final singleData = {
      'version': 1,
      'tasks': [t],
      'subtasks': [],
      'categories': [],
      'attachments': [],
      'reminders': [],
    };
    await tempFile.writeAsString(jsonEncode(singleData));
    await SyncService.importFromFile(tempFile.path);
    await tempFile.delete();
  }

  static Future<void> _importSubtasksForTask(
      AppDatabase db, List<Map<String, dynamic>> subtasks) async {
    for (final s in subtasks) {
      await _importSingleSubtask(db, s);
    }
  }

  static Future<void> _importRemindersForTask(
      AppDatabase db, List<Map<String, dynamic>> reminders) async {
    for (final r in reminders) {
      await _importSingleReminder(db, r);
    }
  }

  static Future<void> _importAttachmentsForTask(
      AppDatabase db, List<Map<String, dynamic>> attachments) async {
    for (final a in attachments) {
      await _importSingleAttachment(db, a);
    }
  }

  static Future<void> _importSingleSubtask(
      AppDatabase db, Map<String, dynamic> s) async {
    try {
      await db.insertSubtask(SubtasksCompanion(
        id: Value(s['id'] as int),
        taskId: Value(s['taskId'] as int),
        title: Value(s['title'] as String),
        isCompleted: Value(s['isCompleted'] as bool? ?? false),
        sortOrder: Value(s['sortOrder'] as int? ?? 0),
      ));
    } catch (e) {
      debugPrint('Cloud sync: ошибка импорта подзадачи: $e');
    }
  }

  static Future<void> _importSingleReminder(
      AppDatabase db, Map<String, dynamic> r) async {
    try {
      await db.insertReminder(RemindersCompanion(
        id: Value(r['id'] as int),
        taskId: Value(r['taskId'] as int),
        offsetMinutes: Value(r['offsetMinutes'] as int),
        isActive: Value(r['isActive'] as bool? ?? true),
      ));
    } catch (e) {
      debugPrint('Cloud sync: ошибка импорта напоминания: $e');
    }
  }

  static Future<void> _importSingleAttachment(
      AppDatabase db, Map<String, dynamic> a) async {
    try {
      await db.insertAttachment(AttachmentsCompanion(
        id: Value(a['id'] as int),
        taskId: Value(a['taskId'] as int),
        filePath: Value(a['filePath'] as String),
        displayName: Value(a['displayName'] as String?),
        attachmentType:
            Value(AttachmentType.values[a['attachmentType'] as int]),
        createdAt: Value(DateTime.parse(a['createdAt'] as String)),
      ));
    } catch (e) {
      debugPrint('Cloud sync: ошибка импорта вложения: $e');
    }
  }

  // === Private helpers: status & stats ===

  static Future<void> _setSyncStatus(SyncStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncStatusKey, status.index);
  }

  static Future<void> _setSyncError(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncErrorKey, message);
    debugPrint('Cloud sync error: $message');
  }

  static Future<void> _clearSyncError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncErrorKey);
  }

  static Future<void> _saveSyncStats(Map<String, dynamic> data) async {
    final stats = {
      'tasks': (data['tasks'] as List<dynamic>?)?.length ?? 0,
      'subtasks': (data['subtasks'] as List<dynamic>?)?.length ?? 0,
      'categories': (data['categories'] as List<dynamic>?)?.length ?? 0,
      'attachments':
          (data['attachments'] as List<dynamic>?)?.length ?? 0,
      'reminders': (data['reminders'] as List<dynamic>?)?.length ?? 0,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncStatsKey, jsonEncode(stats));
  }

  static Future<String> _writeTemp(String json) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/cloud_sync_temp.json');
    await file.writeAsString(json);
    return file.path;
  }

  /// Get platform-specific cloud storage path
  static Future<String> _getCloudPath() async {
    if (Platform.isIOS) {
      // На iOS пробуем найти iCloud контейнер
      try {
        final dir = await getApplicationDocumentsDirectory();

        // Вариант 1: NSUbiquitousKeyValueStore путь
        // ~/Library/Mobile Documents/iCloud~com~planer~planer/Documents/
        final basePath = dir.path.replaceAll('/Documents', '');
        final ubiquitousPath =
            '$basePath/Mobile Documents/iCloud~com~planer~planer';
        final ubiquitousDir = Directory('$ubiquitousPath/Documents');
        if (await ubiquitousDir.exists()) {
          debugPrint(
              'Cloud sync: используется iCloud путь (NSUbiquitous): ${ubiquitousDir.path}');
          return ubiquitousDir.path;
        }

        // Вариант 2: Стандартный iCloud Documents путь
        final icloudPath = basePath.replaceAll(
            'Application', 'Mobile Documents/iCloud~com~planer~planer');
        final icloudDir = Directory('$icloudPath/Documents');
        if (await icloudDir.exists()) {
          debugPrint(
              'Cloud sync: используется iCloud путь (стандартный): ${icloudDir.path}');
          return icloudDir.path;
        }

        debugPrint('Cloud sync: iCloud контейнер не найден, '
            'используется локальная директория');
      } catch (e) {
        debugPrint('Cloud sync: ошибка определения iCloud пути: $e');
      }
    }

    // По умолчанию: директория документов приложения
    final dir = await getApplicationDocumentsDirectory();
    debugPrint(
        'Cloud sync: используется локальный путь: ${dir.path}');
    return dir.path;
  }
}
