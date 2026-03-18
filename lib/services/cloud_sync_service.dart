import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';
import 'sync_service.dart';

/// Cloud sync service that manages backup/restore to platform-specific cloud storage.
///
/// On iOS: Uses iCloud Documents (via file copy to iCloud container)
/// On Android: Uses local backup with option to share via system share sheet
///
/// Strategy: JSON snapshots with last-write-wins merge by `updatedAt` field.
class CloudSyncService {
  static const _lastCloudSyncKey = 'lastCloudSyncTime';
  static const _backupFileName = 'planer_cloud_backup.json';

  /// Export data to cloud-accessible location
  static Future<String> syncToCloud() async {
    final json = await SyncService.exportToJson();
    final path = await _getCloudPath();
    final file = File('$path/$_backupFileName');
    await file.writeAsString(json);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCloudSyncKey, DateTime.now().toIso8601String());

    debugPrint('Cloud sync: exported to ${file.path}');
    return file.path;
  }

  /// Restore data from cloud backup
  static Future<bool> syncFromCloud() async {
    final path = await _getCloudPath();
    final file = File('$path/$_backupFileName');

    if (!await file.exists()) {
      debugPrint('Cloud sync: no backup found at ${file.path}');
      return false;
    }

    final json = await file.readAsString();
    final data = jsonDecode(json) as Map<String, dynamic>;

    if (data['version'] != 1) {
      throw Exception('Неподдерживаемая версия бэкапа');
    }

    // Merge strategy: compare updatedAt timestamps
    final db = AppDatabase.instance;
    final existingTasks = await db.getAllTasks();
    final existingMap = {for (final t in existingTasks) t.id: t};

    final remoteTasks = data['tasks'] as List<dynamic>? ?? [];

    for (final rt in remoteTasks) {
      final remoteId = rt['id'] as int;
      final remoteUpdatedAt = DateTime.parse(rt['updatedAt'] as String);

      if (existingMap.containsKey(remoteId)) {
        final local = existingMap[remoteId]!;
        // Only overwrite if remote is newer
        if (remoteUpdatedAt.isAfter(local.updatedAt)) {
          await _importSingleTask(db, rt);
        }
      } else {
        await _importSingleTask(db, rt);
      }
    }

    // Import categories that don't exist locally
    final existingCategories = await db.getAllCategories();
    final existingCatIds = existingCategories.map((c) => c.id).toSet();
    final remoteCategories = data['categories'] as List<dynamic>? ?? [];

    for (final rc in remoteCategories) {
      if (!existingCatIds.contains(rc['id'] as int)) {
        await SyncService.importFromFile(await _writeTemp(json));
        break; // importFromFile handles all data
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCloudSyncKey, DateTime.now().toIso8601String());

    debugPrint('Cloud sync: restored from ${file.path}');
    return true;
  }

  static Future<void> _importSingleTask(AppDatabase db, Map<String, dynamic> t) async {
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

  static Future<String> _writeTemp(String json) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/cloud_sync_temp.json');
    await file.writeAsString(json);
    return file.path;
  }

  /// Get platform-specific cloud storage path
  static Future<String> _getCloudPath() async {
    if (Platform.isIOS) {
      // On iOS, use the iCloud Documents container if available
      // Falls back to app documents directory
      try {
        final dir = await getApplicationDocumentsDirectory();
        // iCloud container path: ~/Library/Mobile Documents/iCloud~com~planer~planer/Documents/
        final icloudPath = dir.path
            .replaceAll('/Documents', '')
            .replaceAll('Application', 'Mobile Documents/iCloud~com~planer~planer');
        final icloudDir = Directory('$icloudPath/Documents');
        if (await icloudDir.exists()) {
          return icloudDir.path;
        }
      } catch (e) {
        debugPrint('iCloud path not available: $e');
      }
    }

    // Default: app documents directory
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

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
}
