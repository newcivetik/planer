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

  /// Колбэк при нажатии на уведомление — передаёт ID задачи.
  static void Function(int taskId)? onTaskTapped;

  /// Уникальный ID для ежедневной сводки.
  static const int _dailySummaryId = 999999;

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
    debugPrint('Notification tapped: ${response.payload}');
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final taskId = int.tryParse(payload);
      if (taskId != null && onTaskTapped != null) {
        onTaskTapped!(taskId);
      }
    }
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

  /// Проверяет, включены ли уведомления на устройстве.
  Future<bool> areNotificationsEnabled() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? false;
    }

    // На iOS считаем, что разрешения были запрошены через requestPermissions.
    // Если платформа не Android — возвращаем true по умолчанию.
    return true;
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

  /// Планирует ежедневную сводку в указанное время.
  /// Показывает «У вас X задач на сегодня» каждый день.
  Future<void> scheduleDailySummary({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Если время уже прошло сегодня — переносим на завтра.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailySummaryId,
      'Ежедневная сводка',
      'У вас есть задачи на сегодня',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Ежедневная сводка',
          channelDescription: 'Ежедневное напоминание о задачах на день',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_summary',
    );
  }

  /// Отменяет ежедневную сводку.
  Future<void> cancelDailySummary() async {
    await _plugin.cancel(_dailySummaryId);
  }

  /// Планирует повторяющееся уведомление для задачи.
  ///
  /// [firstOccurrence] — время первого уведомления.
  /// [interval] — интервал повторения (день, неделя и т.д.).
  Future<void> scheduleRecurring({
    required int taskId,
    required String title,
    required DateTime firstOccurrence,
    required Duration interval,
  }) async {
    if (kIsWeb) return;

    final tzTime = tz.TZDateTime.from(firstOccurrence, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    // Определяем подходящий DateTimeComponents по интервалу.
    DateTimeComponents? matchComponents;
    if (interval.inDays == 7) {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    } else if (interval.inDays == 1) {
      matchComponents = DateTimeComponents.time;
    } else if (interval.inDays >= 28 && interval.inDays <= 31) {
      matchComponents = DateTimeComponents.dayOfMonthAndTime;
    }

    if (matchComponents != null) {
      // Используем zonedSchedule с matchDateTimeComponents для точного повторения.
      await _plugin.zonedSchedule(
        taskId,
        title,
        'Повторяющаяся задача',
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
        matchDateTimeComponents: matchComponents,
        payload: taskId.toString(),
      );
    } else {
      // Для нестандартных интервалов используем periodicallyShow.
      RepeatInterval repeatInterval;
      if (interval.inHours >= 1 && interval.inHours < 24) {
        repeatInterval = RepeatInterval.hourly;
      } else {
        repeatInterval = RepeatInterval.daily;
      }

      await _plugin.periodicallyShow(
        taskId,
        title,
        'Повторяющаяся задача',
        repeatInterval,
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
        payload: taskId.toString(),
      );
    }
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

  /// Возвращает список всех запланированных уведомлений.
  /// Полезно для повторного планирования после перезагрузки устройства.
  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((request) {
      return {
        'id': request.id,
        'title': request.title,
        'body': request.body,
        'payload': request.payload,
      };
    }).toList();
  }
}
