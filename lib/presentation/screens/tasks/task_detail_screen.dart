import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database.dart';
import '../../providers/task_providers.dart';
import '../../providers/database_provider.dart';
import '../../widgets/task/subtask_list.dart';
import '../../widgets/task/attachment_list.dart';

final taskDetailProvider = FutureProvider.family<Task, int>((ref, id) async {
  final db = ref.watch(databaseProvider);
  return db.getTaskById(id);
});

class TaskDetailScreen extends ConsumerWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  static const _accentColor = Color(0xFF4A90D9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));
    final dateFormat = DateFormat('d MMMM yyyy, EEEE', 'ru');

    return taskAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _accentColor),
        ),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Ошибка: $err',
            style: const TextStyle(color: Color(0xFF888888)),
          ),
        ),
      ),
      data: (task) {
        Color priorityColor;
        String priorityLabel;
        switch (task.priority) {
          case TaskPriority.low:
            priorityColor = AppColors.priorityLow;
            priorityLabel = 'Низкий';
          case TaskPriority.medium:
            priorityColor = AppColors.priorityMedium;
            priorityLabel = 'Средний';
          case TaskPriority.high:
            priorityColor = AppColors.priorityHigh;
            priorityLabel = 'Высокий';
        }

        final tags = task.tags.isNotEmpty ? task.tags.split(',') : <String>[];

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Задача',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 22),
                onPressed: () => context.push('/task/edit/${task.id}'),
                tooltip: 'Редактировать',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22, color: Color(0xFFE74C3C)),
                onPressed: () => _confirmDelete(context, ref, task),
                tooltip: 'Удалить',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Title card
              _buildCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(taskActionsProvider).toggleCompletion(task.id, !task.isCompleted);
                        ref.invalidate(taskDetailProvider(taskId));
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: task.isCompleted ? _accentColor : priorityColor,
                            width: 2.5,
                          ),
                          color: task.isCompleted ? _accentColor : Colors.transparent,
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted
                                  ? const Color(0xFFAAAAAA)
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: priorityColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                priorityLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: priorityColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Description
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(icon: Icons.notes, title: 'Описание'),
                      const SizedBox(height: 8),
                      Text(
                        task.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Meta info
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    if (task.date != null)
                      _MetaRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Дата',
                        value: dateFormat.format(task.date!),
                      ),
                    if (task.timeHour != null && task.timeMinute != null) ...[
                      if (task.date != null) const _ThinDivider(),
                      _MetaRow(
                        icon: Icons.access_time_outlined,
                        label: 'Время',
                        value: '${task.timeHour!.toString().padLeft(2, '0')}:${task.timeMinute!.toString().padLeft(2, '0')}',
                      ),
                    ],
                    const _ThinDivider(),
                    _MetaRow(
                      icon: Icons.flag_outlined,
                      label: 'Приоритет',
                      value: priorityLabel,
                      valueColor: priorityColor,
                    ),
                    if (task.recurrenceType != null) ...[
                      const _ThinDivider(),
                      _MetaRow(
                        icon: Icons.repeat,
                        label: 'Повтор',
                        value: _recurrenceLabel(task.recurrenceType!),
                      ),
                    ],
                  ],
                ),
              ),

              // Tags
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(icon: Icons.label_outline, title: 'Теги'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag.trim(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: _accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Progress
              if (task.progressPercent > 0) ...[
                const SizedBox(height: 10),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _SectionHeader(icon: Icons.trending_up, title: 'Прогресс'),
                          const Spacer(),
                          Text(
                            '${task.progressPercent}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.progressPercent / 100,
                          backgroundColor: const Color(0xFFEEEEEE),
                          color: _accentColor,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Subtasks
              const SizedBox(height: 10),
              _buildCard(
                child: SubtaskList(
                  taskId: taskId,
                  onProgressChanged: (progress) {
                    final percent = (progress * 100).toInt();
                    if (percent != task.progressPercent) {
                      ref.read(taskActionsProvider).updateTask(
                        id: task.id,
                        title: task.title,
                        description: task.description,
                        date: task.date,
                        timeHour: task.timeHour,
                        timeMinute: task.timeMinute,
                        priority: task.priority,
                        categoryId: task.categoryId,
                        tags: task.tags,
                        progressPercent: percent,
                        isCompleted: task.isCompleted,
                      );
                    }
                  },
                ),
              ),

              // Attachments
              const SizedBox(height: 10),
              _buildCard(
                child: AttachmentList(taskId: taskId),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Удалить задачу?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Это действие нельзя отменить.',
          style: TextStyle(fontSize: 14, color: Color(0xFF777777)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(taskActionsProvider).deleteTask(task.id);
      if (context.mounted) context.pop();
    }
  }

  String _recurrenceLabel(TaskRecurrenceType type) {
    switch (type) {
      case TaskRecurrenceType.daily:
        return 'Ежедневно';
      case TaskRecurrenceType.weekly:
        return 'Еженедельно';
      case TaskRecurrenceType.monthly:
        return 'Ежемесячно';
      case TaskRecurrenceType.yearly:
        return 'Ежегодно';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF999999)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF999999),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF999999)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF777777),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xFFEEEEEE),
    );
  }
}
