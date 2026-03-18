import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database.dart';
import '../../providers/task_providers.dart';
import '../../providers/category_providers.dart';
import '../../providers/database_provider.dart';
import '../../widgets/task/tag_input.dart';
import '../../widgets/reminder/reminder_picker.dart';
import '../../../services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;

class TaskFormScreen extends ConsumerStatefulWidget {
  final int? taskId;

  const TaskFormScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskPriority _priority = TaskPriority.medium;
  int? _categoryId;
  List<String> _tags = [];
  List<Duration> _reminderOffsets = [];
  TaskRecurrenceType? _recurrenceType;
  bool _isLoading = false;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadTask();
    }
  }

  Future<void> _loadTask() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final task = await db.getTaskById(widget.taskId!);
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedDate = task.date;
      if (task.timeHour != null && task.timeMinute != null) {
        _selectedTime = TimeOfDay(hour: task.timeHour!, minute: task.timeMinute!);
      }
      _priority = task.priority;
      _categoryId = task.categoryId;
      _tags = task.tags.isNotEmpty ? task.tags.split(',') : [];
      _recurrenceType = task.recurrenceType;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ru'),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final actions = ref.read(taskActionsProvider);
    final tagsStr = _tags.join(',');

    int savedTaskId;
    if (_isEditing) {
      await actions.updateTask(
        id: widget.taskId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
        timeHour: _selectedTime?.hour,
        timeMinute: _selectedTime?.minute,
        priority: _priority,
        categoryId: _categoryId,
        tags: tagsStr,
      );
      savedTaskId = widget.taskId!;
    } else {
      savedTaskId = await actions.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
        timeHour: _selectedTime?.hour,
        timeMinute: _selectedTime?.minute,
        priority: _priority,
        categoryId: _categoryId,
        tags: tagsStr,
      );
    }

    // Save reminders to database
    final db = ref.read(databaseProvider);
    await db.deleteRemindersForTask(savedTaskId);

    for (final offset in _reminderOffsets) {
      await db.insertReminder(RemindersCompanion(
        taskId: Value(savedTaskId),
        offsetMinutes: Value(offset.inMinutes),
        isActive: const Value(true),
      ));
    }

    // Schedule push notifications
    if (!kIsWeb && _selectedDate != null && _selectedTime != null && _reminderOffsets.isNotEmpty) {
      final taskTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final title = _titleController.text.trim();

      await NotificationService.instance.cancelTaskReminders(savedTaskId);
      for (final offset in _reminderOffsets) {
        await NotificationService.instance.scheduleWithOffset(
          taskId: savedTaskId,
          title: title,
          taskTime: taskTime,
          offsetBefore: offset,
        );
      }
    }

    if (mounted) context.pop();
  }

  String _recurrenceLabel(TaskRecurrenceType? type) {
    switch (type) {
      case TaskRecurrenceType.daily:
        return 'Ежедневно';
      case TaskRecurrenceType.weekly:
        return 'Еженедельно';
      case TaskRecurrenceType.monthly:
        return 'Ежемесячно';
      case TaskRecurrenceType.yearly:
        return 'Ежегодно';
      case null:
        return 'Не повторяется';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(allCategoriesProvider);
    final dateFormat = DateFormat('d MMMM yyyy', 'ru');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editTask : AppStrings.newTask),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(AppStrings.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: AppStrings.taskTitle,
                hintText: 'Что нужно сделать?',
              ),
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название задачи';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Описание
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: AppStrings.taskDescription,
                hintText: 'Добавьте описание...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Дата
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_selectedDate != null
                  ? dateFormat.format(_selectedDate!)
                  : 'Выберите дату'),
              trailing: _selectedDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedDate = null),
                    )
                  : null,
              onTap: _pickDate,
            ),

            // Время
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(_selectedTime != null
                  ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                  : 'Выберите время'),
              trailing: _selectedTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedTime = null),
                    )
                  : null,
              onTap: _pickTime,
            ),

            // Повтор
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: Text(_recurrenceLabel(_recurrenceType)),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Не повторяется'),
                          leading: const Icon(Icons.block),
                          onTap: () {
                            setState(() => _recurrenceType = null);
                            Navigator.pop(ctx);
                          },
                        ),
                        ...TaskRecurrenceType.values.map((type) => ListTile(
                              title: Text(_recurrenceLabel(type)),
                              leading: const Icon(Icons.repeat),
                              onTap: () {
                                setState(() => _recurrenceType = type);
                                Navigator.pop(ctx);
                              },
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 32),

            // Приоритет
            Text(AppStrings.taskPriority, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: [
                ButtonSegment(
                  value: TaskPriority.low,
                  label: const Text('Низкий'),
                  icon: Icon(Icons.arrow_downward, color: AppColors.priorityLow, size: 18),
                ),
                ButtonSegment(
                  value: TaskPriority.medium,
                  label: const Text('Средний'),
                  icon: Icon(Icons.remove, color: AppColors.priorityMedium, size: 18),
                ),
                ButtonSegment(
                  value: TaskPriority.high,
                  label: const Text('Высокий'),
                  icon: Icon(Icons.arrow_upward, color: AppColors.priorityHigh, size: 18),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (value) {
                setState(() => _priority = value.first);
              },
            ),

            const SizedBox(height: 24),

            // Напоминания
            ReminderPicker(
              selectedOffsets: _reminderOffsets,
              onChanged: (offsets) => _reminderOffsets = offsets,
            ),

            const SizedBox(height: 24),

            // Теги
            TagInput(
              tags: _tags,
              onChanged: (tags) => _tags = tags,
            ),

            const SizedBox(height: 24),

            // Категория
            categories.when(
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
              data: (cats) {
                if (cats.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.taskCategory, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Без категории'),
                          selected: _categoryId == null,
                          onSelected: (_) => setState(() => _categoryId = null),
                        ),
                        ...cats.map((cat) => ChoiceChip(
                              label: Text(cat.name),
                              selected: _categoryId == cat.id,
                              onSelected: (_) => setState(() => _categoryId = cat.id),
                              avatar: CircleAvatar(
                                backgroundColor: Color(cat.colorValue),
                                radius: 8,
                              ),
                            )),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
