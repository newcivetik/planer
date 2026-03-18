enum Priority { low, medium, high }

enum RecurrenceType { daily, weekly, monthly, yearly }

class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime? date;
  final int? timeHour;
  final int? timeMinute;
  final Priority priority;
  final int? categoryId;
  final List<String> tags;
  final int progressPercent;
  final bool isCompleted;
  final RecurrenceType? recurrenceType;
  final int? recurrenceInterval;
  final List<int>? recurrenceDaysOfWeek;
  final DateTime? recurrenceEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    this.id,
    required this.title,
    this.description,
    this.date,
    this.timeHour,
    this.timeMinute,
    this.priority = Priority.medium,
    this.categoryId,
    this.tags = const [],
    this.progressPercent = 0,
    this.isCompleted = false,
    this.recurrenceType,
    this.recurrenceInterval,
    this.recurrenceDaysOfWeek,
    this.recurrenceEndDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    int? timeHour,
    int? timeMinute,
    Priority? priority,
    int? categoryId,
    List<String>? tags,
    int? progressPercent,
    bool? isCompleted,
    RecurrenceType? recurrenceType,
    int? recurrenceInterval,
    List<int>? recurrenceDaysOfWeek,
    DateTime? recurrenceEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      timeHour: timeHour ?? this.timeHour,
      timeMinute: timeMinute ?? this.timeMinute,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      progressPercent: progressPercent ?? this.progressPercent,
      isCompleted: isCompleted ?? this.isCompleted,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek ?? this.recurrenceDaysOfWeek,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get timeFormatted {
    if (timeHour == null || timeMinute == null) return '';
    return '${timeHour!.toString().padLeft(2, '0')}:${timeMinute!.toString().padLeft(2, '0')}';
  }

  String get priorityLabel {
    switch (priority) {
      case Priority.low:
        return 'Низкий';
      case Priority.medium:
        return 'Средний';
      case Priority.high:
        return 'Высокий';
    }
  }
}
