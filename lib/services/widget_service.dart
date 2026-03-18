import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../data/database.dart';

class WidgetService {
  static const _appGroupId = 'group.com.planer.planer';
  static const _iOSWidgetName = 'PlanerWidgets';
  static const _androidWidgetName = 'PlanerWidgetProvider';

  static Future<void> init() async {
    if (kIsWeb) return;
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidgetData() async {
    if (kIsWeb) return;

    try {
      final db = AppDatabase.instance;
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      // Get today's tasks
      final allTasks = await db.getAllTasks();
      final todayTasks = allTasks
          .where((t) =>
              t.date != null &&
              t.date!.isAfter(start.subtract(const Duration(seconds: 1))) &&
              t.date!.isBefore(end))
          .toList();

      final completed = todayTasks.where((t) => t.isCompleted).length;
      final total = todayTasks.length;
      final progress = total > 0 ? (completed / total * 100).round() : 0;

      // Serialize tasks for widget (max 5)
      final taskListJson = todayTasks
          .where((t) => !t.isCompleted)
          .take(5)
          .map((t) => {
                'title': t.title,
                'time': t.timeHour != null
                    ? '${t.timeHour!.toString().padLeft(2, '0')}:${t.timeMinute?.toString().padLeft(2, '0') ?? '00'}'
                    : '',
                'priority': t.priority.index,
              })
          .toList();

      // Save data for widget
      await HomeWidget.saveWidgetData('progress', progress);
      await HomeWidget.saveWidgetData('completed', completed);
      await HomeWidget.saveWidgetData('total', total);
      await HomeWidget.saveWidgetData('tasks', jsonEncode(taskListJson));
      await HomeWidget.saveWidgetData('date', '${now.day}.${now.month}.${now.year}');

      // Trigger widget update
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('Widget update error: $e');
    }
  }
}
