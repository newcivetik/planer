class Subtask {
  final int? id;
  final int taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;

  const Subtask({
    this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.sortOrder = 0,
  });

  Subtask copyWith({
    int? id,
    int? taskId,
    String? title,
    bool? isCompleted,
    int? sortOrder,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
