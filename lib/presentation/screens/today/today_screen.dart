import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/database.dart';
import '../../providers/task_providers.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/common/empty_state.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _completedExpanded = false;

  static const _accentColor = Color(0xFF4A90D9);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  List<Task> _sortActiveTasks(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    tasks.sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      final aOverdue = aDate != null && aDate.isBefore(today);
      final bOverdue = bDate != null && bDate.isBefore(today);
      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;
      if (aDate != null && bDate != null) {
        final dateCmp = aDate.compareTo(bDate);
        if (dateCmp != 0) return dateCmp;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }
      return b.priority.index.compareTo(a.priority.index);
    });
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = ref.watch(todayTasksProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMMM, EEEE', 'ru');

    return Scaffold(
      body: todayTasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(theme, dateFormat),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.wb_sunny_outlined,
                    message: AppStrings.noTasksToday,
                  ),
                ),
              ],
            );
          }

          final activeTasks = tasks.where((t) => !t.isCompleted).toList();
          final completedTasks = tasks.where((t) => t.isCompleted).toList();
          final sortedActive = _sortActiveTasks(activeTasks);
          final total = tasks.length;
          final completedCount = completedTasks.length;
          final activeCount = activeTasks.length;
          final progress = total > 0 ? completedCount / total : 0.0;

          return CustomScrollView(
            slivers: [
              // Header: greeting + date
              SliverToBoxAdapter(
                child: _buildHeader(theme, dateFormat),
              ),

              // Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        theme,
                        icon: Icons.list_alt_rounded,
                        label: 'Всего',
                        count: total,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        theme,
                        icon: Icons.radio_button_unchecked,
                        label: 'Активные',
                        count: activeCount,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        theme,
                        icon: Icons.check_circle_outline,
                        label: 'Выполнено',
                        count: completedCount,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, duration: 400.ms),
              ),

              // Progress bar
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEEEEEE),
                          color: _accentColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$completedCount из $total задач выполнено',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
              ),

              // Active tasks section header
              if (sortedActive.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    theme,
                    title: 'Активные',
                    count: activeCount,
                    isExpanded: true,
                    onTap: null,
                  ),
                ),

              // Active tasks list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = sortedActive[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      child: _buildTaskItem(context, ref, task, theme),
                    );
                  },
                  childCount: sortedActive.length,
                ),
              ),

              // Completed tasks section header
              if (completedTasks.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    theme,
                    title: 'Выполнено',
                    count: completedCount,
                    isExpanded: _completedExpanded,
                    onTap: () {
                      setState(() {
                        _completedExpanded = !_completedExpanded;
                      });
                    },
                  ),
                ),

              // Completed tasks list (collapsible)
              if (completedTasks.isNotEmpty && _completedExpanded)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = completedTasks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: _buildTaskItem(context, ref, task, theme),
                      );
                    },
                    childCount: completedTasks.length,
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, DateFormat dateFormat) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required String title,
    required int count,
    required bool isExpanded,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(
              '$title ($count)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (onTap != null)
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ThemeData theme,
  ) {
    return TaskCard(
      task: task,
      onTap: () => context.push('/task/${task.id}'),
      onToggle: () {
        ref.read(taskActionsProvider).toggleCompletion(
              task.id,
              !task.isCompleted,
            );
      },
      onDelete: () {
        ref.read(taskActionsProvider).deleteTask(task.id);
      },
    );
  }
}
