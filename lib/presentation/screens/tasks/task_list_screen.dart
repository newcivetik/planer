import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/database.dart';
import '../../providers/task_providers.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/common/empty_state.dart';

enum TaskFilter { all, active, completed }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
final searchQueryProvider = StateProvider<String>((ref) => '');

class _TaskSection {
  final String title;
  final List<Task> tasks;
  final Color? accentColor;
  final bool collapsedByDefault;

  _TaskSection({
    required this.title,
    required this.tasks,
    this.accentColor,
    this.collapsedByDefault = false,
  });
}

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final Map<String, bool> _expandedSections = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSectionExpanded(String title, {bool defaultExpanded = true}) {
    return _expandedSections[title] ?? defaultExpanded;
  }

  void _toggleSection(String title, {bool defaultExpanded = true}) {
    setState(() {
      _expandedSections[title] =
          !(_expandedSections[title] ?? defaultExpanded);
    });
  }

  List<_TaskSection> _buildSections(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final next7 = today.add(const Duration(days: 7));

    final overdue = <Task>[];
    final todayTasks = <Task>[];
    final tomorrowTasks = <Task>[];
    final next7Days = <Task>[];
    final someday = <Task>[];
    final completed = <Task>[];

    for (final task in tasks) {
      if (task.isCompleted) {
        completed.add(task);
        continue;
      }

      if (task.date == null) {
        someday.add(task);
        continue;
      }

      final taskDay = DateTime(
        task.date!.year,
        task.date!.month,
        task.date!.day,
      );

      if (taskDay.isBefore(today)) {
        overdue.add(task);
      } else if (taskDay.isAtSameMomentAs(today)) {
        todayTasks.add(task);
      } else if (taskDay.isAtSameMomentAs(tomorrow)) {
        tomorrowTasks.add(task);
      } else if (taskDay.isBefore(next7) || taskDay.isAtSameMomentAs(next7)) {
        next7Days.add(task);
      } else {
        someday.add(task);
      }
    }

    // Sort each group by priority desc, then by time
    void sortGroup(List<Task> group) {
      group.sort((a, b) {
        final priCmp = b.priority.index.compareTo(a.priority.index);
        if (priCmp != 0) return priCmp;
        if (a.date != null && b.date != null) {
          final dateCmp = a.date!.compareTo(b.date!);
          if (dateCmp != 0) return dateCmp;
        }
        if (a.timeHour != null && b.timeHour != null) {
          final hourCmp = a.timeHour!.compareTo(b.timeHour!);
          if (hourCmp != 0) return hourCmp;
          return (a.timeMinute ?? 0).compareTo(b.timeMinute ?? 0);
        }
        return 0;
      });
    }

    sortGroup(overdue);
    sortGroup(todayTasks);
    sortGroup(tomorrowTasks);
    sortGroup(next7Days);
    sortGroup(someday);
    completed.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));

    final sections = <_TaskSection>[];

    if (overdue.isNotEmpty) {
      sections.add(_TaskSection(
        title: 'Просроченные',
        tasks: overdue,
        accentColor: Colors.red,
      ));
    }
    if (todayTasks.isNotEmpty) {
      sections.add(_TaskSection(
        title: 'Сегодня',
        tasks: todayTasks,
      ));
    }
    if (tomorrowTasks.isNotEmpty) {
      sections.add(_TaskSection(
        title: 'Завтра',
        tasks: tomorrowTasks,
      ));
    }
    if (next7Days.isNotEmpty) {
      sections.add(_TaskSection(
        title: 'Следующие 7 дней',
        tasks: next7Days,
      ));
    }
    if (someday.isNotEmpty) {
      sections.add(_TaskSection(
        title: 'Когда-нибудь',
        tasks: someday,
      ));
    }
    if (completed.isNotEmpty) {
      sections.add(_TaskSection(
        title: 'Завершённые',
        tasks: completed,
        collapsedByDefault: true,
      ));
    }

    return sections;
  }

  List<Task> _applySearchAndFilter(List<Task> tasks) {
    final searchQuery = ref.read(searchQueryProvider);
    final filter = ref.read(taskFilterProvider);
    var filtered = List<Task>.from(tasks);

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              (t.description?.toLowerCase().contains(query) ?? false) ||
              t.tags.toLowerCase().contains(query))
          .toList();
    }

    switch (filter) {
      case TaskFilter.active:
        filtered = filtered.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        filtered = filtered.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        break;
    }

    filtered.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.date != null && b.date != null) return a.date!.compareTo(b.date!);
      if (a.date != null) return -1;
      if (b.date != null) return 1;
      return b.priority.index.compareTo(a.priority.index);
    });

    return filtered;
  }

  bool get _isFlat {
    final searchQuery = ref.watch(searchQueryProvider);
    final filter = ref.watch(taskFilterProvider);
    return searchQuery.isNotEmpty || filter != TaskFilter.all;
  }

  Widget _buildTaskItem(Task task) {
    return TaskCard(
      task: task,
      onTap: () => context.push('/task/${task.id}'),
      onToggle: () {
        ref.read(taskActionsProvider).toggleCompletion(task.id, !task.isCompleted);
      },
      onDelete: () {
        ref.read(taskActionsProvider).deleteTask(task.id);
      },
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count, {
    Color? accentColor,
    bool defaultExpanded = true,
  }) {
    final theme = Theme.of(context);
    final expanded = _isSectionExpanded(title, defaultExpanded: defaultExpanded);
    final color = accentColor ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: () => _toggleSection(title, defaultExpanded: defaultExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (accentColor ?? theme.colorScheme.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accentColor ?? theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectioned(List<Task> tasks) {
    final sections = _buildSections(tasks);

    if (sections.isEmpty) {
      return EmptyState(
        icon: Icons.check_box_outlined,
        message: AppStrings.noTasks,
        actionLabel: 'Создать задачу',
        onAction: () => context.push('/task/new'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sections.fold<int>(
        0,
        (sum, s) =>
            sum +
            1 +
            (_isSectionExpanded(
              s.title,
              defaultExpanded: !s.collapsedByDefault,
            )
                ? s.tasks.length
                : 0),
      ),
      itemBuilder: (context, index) {
        var current = 0;
        for (final section in sections) {
          if (index == current) {
            return _buildSectionHeader(
              section.title,
              section.tasks.length,
              accentColor: section.accentColor,
              defaultExpanded: !section.collapsedByDefault,
            );
          }
          current++;

          final expanded = _isSectionExpanded(
            section.title,
            defaultExpanded: !section.collapsedByDefault,
          );
          if (expanded) {
            final taskIndex = index - current;
            if (taskIndex < section.tasks.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildTaskItem(section.tasks[taskIndex]),
              );
            }
            current += section.tasks.length;
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFlatList(List<Task> tasks) {
    final searchQuery = ref.watch(searchQueryProvider);
    final filtered = _applySearchAndFilter(tasks);

    if (filtered.isEmpty) {
      return EmptyState(
        icon: searchQuery.isNotEmpty ? Icons.search_off : Icons.check_box_outlined,
        message: searchQuery.isNotEmpty ? 'Ничего не найдено' : AppStrings.noTasks,
        actionLabel: searchQuery.isEmpty ? 'Создать задачу' : null,
        onAction: searchQuery.isEmpty ? () => context.push('/task/new') : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildTaskItem(filtered[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(allTasksProvider);
    final filter = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск задач...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              )
            : const Text(AppStrings.tasks),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
          PopupMenuButton<TaskFilter>(
            icon: Icon(
              Icons.filter_list,
              color: filter != TaskFilter.all
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onSelected: (value) {
              ref.read(taskFilterProvider.notifier).state = value;
            },
            itemBuilder: (_) => [
              _buildFilterItem(TaskFilter.all, 'Все', filter),
              _buildFilterItem(TaskFilter.active, 'Активные', filter),
              _buildFilterItem(TaskFilter.completed, 'Завершённые', filter),
            ],
          ),
        ],
      ),
      body: allTasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return EmptyState(
              icon: Icons.check_box_outlined,
              message: AppStrings.noTasks,
              actionLabel: 'Создать задачу',
              onAction: () => context.push('/task/new'),
            );
          }

          if (_isFlat) {
            return _buildFlatList(tasks);
          }

          return _buildSectioned(tasks);
        },
      ),
    );
  }

  PopupMenuItem<TaskFilter> _buildFilterItem(
    TaskFilter value,
    String label,
    TaskFilter current,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (current == value)
            Icon(
              Icons.check,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            )
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
