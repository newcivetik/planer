import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Task ID is stored in payload — can be used for navigation
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> requestPermissions() async {
    // iOS
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    // Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required DateTime scheduledTime,
    String? body,
  }) async {
    if (kIsWeb) return; // No notifications on web

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      taskId,
      title,
      body ?? 'Пора выполнить задачу',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Напоминания о задачах',
          channelDescription: 'Уведомления о предстоящих задачах',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: taskId.toString(),
    );
  }

  Future<void> scheduleWithOffset({
    required int taskId,
    required String title,
    required DateTime taskTime,
    required Duration offsetBefore,
  }) async {
    final reminderTime = taskTime.subtract(offsetBefore);
    final offsetLabel = _offsetLabel(offsetBefore);

    await scheduleTaskReminder(
      taskId: taskId + offsetBefore.inMinutes * 1000, // unique ID
      title: title,
      scheduledTime: reminderTime,
      body: '$offsetLabel до задачи',
    );
  }

  String _offsetLabel(Duration offset) {
    if (offset.inDays > 0) return 'Через ${offset.inDays} д.';
    if (offset.inHours > 0) return 'Через ${offset.inHours} ч.';
    return 'Через ${offset.inMinutes} мин.';
  }

  Future<void> cancelTaskReminders(int taskId) async {
    await _plugin.cancel(taskId);
    // Cancel offset reminders too
    for (final offset in [5, 15, 30, 60, 1440]) {
      await _plugin.cancel(taskId + offset * 1000);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
