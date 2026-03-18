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

  // ── UI helpers ──────────────────────────────────────────────

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bgColor =>
      _isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF5F5F5);

  Color get _cardColor =>
      _isDark ? Theme.of(context).cardColor : Colors.white;

  Color get _fieldFill =>
      _isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : const Color(0xFFF5F5F5);

  Color get _accent => Theme.of(context).colorScheme.primary;

  List<BoxShadow> get _cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: _isDark ? 0.2 : 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: _accent,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.3),
      ),
      filled: true,
      fillColor: _fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    VoidCallback? onClear,
    bool hasValue = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: hasValue
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thinDivider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 52,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
    );
  }

  // ── Priority cards ──────────────────────────────────────────

  static const _priorityColors = {
    TaskPriority.low: Color(0xFF4A90D9),
    TaskPriority.medium: Color(0xFFF39C12),
    TaskPriority.high: Color(0xFFE74C3C),
  };

  static const _priorityLabels = {
    TaskPriority.low: 'Низкий',
    TaskPriority.medium: 'Средний',
    TaskPriority.high: 'Высокий',
  };

  Widget _priorityCard(TaskPriority p) {
    final selected = _priority == p;
    final color = _priorityColors[p]!;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: _isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _priorityLabels[p]!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(allCategoriesProvider);
    final dateFormat = DateFormat('d MMMM yyyy', 'ru');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(
          _isEditing ? 'Редактирование' : 'Новая задача',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              AppStrings.save,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── Title & Description ─────────────────────────
            _sectionCard(
              children: [
                _sectionHeader('Основное'),
                TextFormField(
                  controller: _titleController,
                  decoration: _fieldDecoration(hint: 'Что нужно сделать?'),
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название задачи';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _fieldDecoration(hint: 'Добавьте описание...'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Date, Time, Recurrence ──────────────────────
            _sectionCard(
              children: [
                _sectionHeader('Когда'),
                _infoRow(
                  icon: Icons.calendar_today_outlined,
                  text: _selectedDate != null
                      ? dateFormat.format(_selectedDate!)
                      : 'Выберите дату',
                  hasValue: _selectedDate != null,
                  onTap: _pickDate,
                  onClear: _selectedDate != null
                      ? () => setState(() => _selectedDate = null)
                      : null,
                ),
                _thinDivider(),
                _infoRow(
                  icon: Icons.access_time_outlined,
                  text: _selectedTime != null
                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                      : 'Выберите время',
                  hasValue: _selectedTime != null,
                  onTap: _pickTime,
                  onClear: _selectedTime != null
                      ? () => setState(() => _selectedTime = null)
                      : null,
                ),
                _thinDivider(),
                _infoRow(
                  icon: Icons.repeat_rounded,
                  text: _recurrenceLabel(_recurrenceType),
                  hasValue: _recurrenceType != null,
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
              ],
            ),

            const SizedBox(height: 12),

            // ── Priority ────────────────────────────────────
            _sectionCard(
              children: [
                _sectionHeader(AppStrings.taskPriority),
                Row(
                  children: [
                    _priorityCard(TaskPriority.low),
                    const SizedBox(width: 8),
                    _priorityCard(TaskPriority.medium),
                    const SizedBox(width: 8),
                    _priorityCard(TaskPriority.high),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Reminders ───────────────────────────────────
            _sectionCard(
              children: [
                _sectionHeader('Напоминания'),
                ReminderPicker(
                  selectedOffsets: _reminderOffsets,
                  onChanged: (offsets) => _reminderOffsets = offsets,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Tags ────────────────────────────────────────
            _sectionCard(
              children: [
                _sectionHeader(AppStrings.taskTags),
                TagInput(
                  tags: _tags,
                  onChanged: (tags) => _tags = tags,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Category ────────────────────────────────────
            categories.when(
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
              data: (cats) {
                if (cats.isEmpty) return const SizedBox();
                return _sectionCard(
                  children: [
                    _sectionHeader(AppStrings.taskCategory),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _categoryChip(
                          label: 'Без категории',
                          selected: _categoryId == null,
                          onTap: () => setState(() => _categoryId = null),
                        ),
                        ...cats.map((cat) => _categoryChip(
                              label: cat.name,
                              selected: _categoryId == cat.id,
                              onTap: () => setState(() => _categoryId = cat.id),
                              dotColor: Color(cat.colorValue),
                            )),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? dotColor,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: _isDark ? 0.15 : 0.08)
              : _fieldFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? _accent : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
