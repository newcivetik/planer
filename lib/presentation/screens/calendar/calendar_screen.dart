import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/task_providers.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/common/empty_state.dart';

enum CalendarView { day, week, month }

final calendarViewProvider =
    StateProvider<CalendarView>((ref) => CalendarView.month);

const _accent = Color(0xFF4A90D9);
const _accentLight = Color(0x1A4A90D9);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedMonth = DateTime.now();
  late DateTime _selectedDay;
  late final PageController _monthPageController;
  static const int _initialMonthPage = 1200;

  // Cache for days with tasks (date string -> bool)
  final Map<String, bool> _daysWithTasks = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _monthPageController = PageController(initialPage: _initialMonthPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedDateProvider.notifier).state = _selectedDay;
    });
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final startDay = first.subtract(Duration(days: (first.weekday - 1) % 7));
    final days = <DateTime>[];
    for (var d = startDay;
        d.isBefore(last.add(const Duration(days: 7)));
        d = d.add(const Duration(days: 1))) {
      days.add(d);
      if (days.length >= 42) break;
    }
    return days;
  }

  List<DateTime> _daysInWeek(DateTime day) {
    final monday = day.subtract(Duration(days: (day.weekday - 1) % 7));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  List<int> _hoursOfDay() => List.generate(24, (i) => i);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _focusedMonth = DateTime(day.year, day.month);
    });
    ref.read(selectedDateProvider.notifier).state = day;
  }

  void _goToToday() {
    final now = DateTime.now();
    _selectDay(now);
    final view = ref.read(calendarViewProvider);
    if (view == CalendarView.month) {
      _monthPageController.animateToPage(
        _initialMonthPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateBack(CalendarView view) {
    setState(() {
      switch (view) {
        case CalendarView.month:
          _focusedMonth =
              DateTime(_focusedMonth.year, _focusedMonth.month - 1);
        case CalendarView.week:
          _selectedDay = _selectedDay.subtract(const Duration(days: 7));
          _focusedMonth = DateTime(_selectedDay.year, _selectedDay.month);
        case CalendarView.day:
          _selectedDay = _selectedDay.subtract(const Duration(days: 1));
          _focusedMonth = DateTime(_selectedDay.year, _selectedDay.month);
      }
    });
    ref.read(selectedDateProvider.notifier).state = _selectedDay;
  }

  void _navigateForward(CalendarView view) {
    setState(() {
      switch (view) {
        case CalendarView.month:
          _focusedMonth =
              DateTime(_focusedMonth.year, _focusedMonth.month + 1);
        case CalendarView.week:
          _selectedDay = _selectedDay.add(const Duration(days: 7));
          _focusedMonth = DateTime(_selectedDay.year, _selectedDay.month);
        case CalendarView.day:
          _selectedDay = _selectedDay.add(const Duration(days: 1));
          _focusedMonth = DateTime(_selectedDay.year, _selectedDay.month);
      }
    });
    ref.read(selectedDateProvider.notifier).state = _selectedDay;
  }

  String _headerTitle(CalendarView view) {
    switch (view) {
      case CalendarView.month:
        final title = DateFormat('LLLL yyyy', 'ru').format(_focusedMonth);
        return title[0].toUpperCase() + title.substring(1);
      case CalendarView.week:
        final week = _daysInWeek(_selectedDay);
        final start = DateFormat('d MMM', 'ru').format(week.first);
        final end = DateFormat('d MMM', 'ru').format(week.last);
        return '$start \u2014 $end';
      case CalendarView.day:
        final title = DateFormat('d MMMM, EEEE', 'ru').format(_selectedDay);
        return title[0].toUpperCase() + title.substring(1);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksForSelectedDateProvider);
    final view = ref.watch(calendarViewProvider);

    // Track which days have tasks
    final allTasks = ref.watch(allTasksProvider);
    allTasks.whenData((list) {
      _daysWithTasks.clear();
      for (final t in list) {
        if (t.date != null) {
          _daysWithTasks[_dayKey(t.date!)] = true;
        }
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, view),
            _buildViewSwitcher(theme, view),
            const SizedBox(height: 4),
            // Calendar area
            if (view == CalendarView.month) _buildMonthView(theme),
            if (view == CalendarView.week) _buildWeekStrip(theme),
            if (view == CalendarView.day) _buildDayHeader(theme),
            // Divider
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(top: 8),
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
            // Tasks for selected day
            Expanded(
              child: view == CalendarView.day
                  ? _buildDayTimeline(theme, tasks)
                  : _buildTaskList(tasks),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: chevrons + title + today button ──

  Widget _buildHeader(ThemeData theme, CalendarView view) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 26),
            onPressed: () => _navigateBack(view),
            splashRadius: 20,
            color: theme.colorScheme.onSurface,
          ),
          Expanded(
            child: Text(
              _headerTitle(view),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 26),
            onPressed: () => _navigateForward(view),
            splashRadius: 20,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          _buildTodayButton(theme),
        ],
      ),
    );
  }

  Widget _buildTodayButton(ThemeData theme) {
    final isToday = _isSameDay(_selectedDay, DateTime.now());
    return GestureDetector(
      onTap: _goToToday,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isToday ? _accentLight : Colors.transparent,
          border: Border.all(
            color: isToday ? _accent : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Сегодня',
          style: theme.textTheme.labelMedium?.copyWith(
            color: _accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── View switcher ──

  Widget _buildViewSwitcher(ThemeData theme, CalendarView view) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<CalendarView>(
        segments: const [
          ButtonSegment(
            value: CalendarView.day,
            label: Text('День', style: TextStyle(fontSize: 13)),
          ),
          ButtonSegment(
            value: CalendarView.week,
            label: Text('Неделя', style: TextStyle(fontSize: 13)),
          ),
          ButtonSegment(
            value: CalendarView.month,
            label: Text('Месяц', style: TextStyle(fontSize: 13)),
          ),
        ],
        selected: {view},
        onSelectionChanged: (v) =>
            ref.read(calendarViewProvider.notifier).state = v.first,
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _accent;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return theme.colorScheme.onSurface;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: _accent.withValues(alpha: 0.3)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
    );
  }

  // ── Month view ──

  Widget _buildMonthView(ThemeData theme) {
    final weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final days = _daysInMonth(_focusedMonth);
    final rowCount = (days.length / 7).ceil();

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: weekDays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Day grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: List.generate(rowCount, (rowIndex) {
              return Row(
                children: List.generate(7, (colIndex) {
                  final index = rowIndex * 7 + colIndex;
                  if (index >= days.length) return const Expanded(child: SizedBox());
                  final day = days[index];
                  return Expanded(child: _buildMonthDayCell(theme, day));
                }),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDayCell(ThemeData theme, DateTime day) {
    final isCurrentMonth = day.month == _focusedMonth.month;
    final isSelected = _isSameDay(day, _selectedDay);
    final isToday = _isSameDay(day, DateTime.now());
    final hasTasks = _daysWithTasks[_dayKey(day)] == true;

    return GestureDetector(
      onTap: () => _selectDay(day),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 42,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _accent : null,
                border: isToday && !isSelected
                    ? Border.all(color: _accent, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : !isCurrentMonth
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
                          : isToday
                              ? _accent
                              : theme.colorScheme.onSurface,
                ),
              ),
            ),
            // Dot indicator for tasks
            SizedBox(
              height: 6,
              child: hasTasks && !isSelected
                  ? Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accent,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Week strip ──

  Widget _buildWeekStrip(ThemeData theme) {
    final weekDays = _daysInWeek(_selectedDay);
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(7, (i) {
          final day = weekDays[i];
          final isSelected = _isSameDay(day, _selectedDay);
          final isToday = _isSameDay(day, DateTime.now());
          final hasTasks = _daysWithTasks[_dayKey(day)] == true;

          return Expanded(
            child: GestureDetector(
              onTap: () => _selectDay(day),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    dayNames[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _accent : null,
                      border: isToday && !isSelected
                          ? Border.all(color: _accent, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? _accent
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 4,
                    child: hasTasks && !isSelected
                        ? Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accent,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Day header (day view) ──

  Widget _buildDayHeader(ThemeData theme) {
    final weekDays = _daysInWeek(_selectedDay);
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: List.generate(7, (i) {
          final day = weekDays[i];
          final isSelected = _isSameDay(day, _selectedDay);
          final isToday = _isSameDay(day, DateTime.now());

          return Expanded(
            child: GestureDetector(
              onTap: () => _selectDay(day),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    dayNames[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? _accent
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _accent : null,
                      border: isToday && !isSelected
                          ? Border.all(color: _accent, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? _accent
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Day timeline ──

  Widget _buildDayTimeline(ThemeData theme, AsyncValue<List<dynamic>> tasks) {
    return tasks.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _accent),
      ),
      error: (err, _) => Center(
        child: Text('Ошибка: $err',
            style: TextStyle(color: theme.colorScheme.error)),
      ),
      data: (taskList) {
        final hours = _hoursOfDay();
        return ListView.builder(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
          itemCount: hours.length,
          itemBuilder: (context, index) {
            final hour = hours[index];
            final hourTasks =
                taskList.where((t) => t.timeHour == hour).toList();

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time label
                  SizedBox(
                    width: 50,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Hour row
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: hourTasks.isEmpty
                          ? GestureDetector(
                              onTap: () => context.push('/task/new'),
                              behavior: HitTestBehavior.opaque,
                              child: const SizedBox.expand(),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                children: hourTasks
                                    .map((task) => TaskCard(
                                          task: task,
                                          onTap: () =>
                                              context.push('/task/${task.id}'),
                                          onToggle: () {
                                            ref
                                                .read(taskActionsProvider)
                                                .toggleCompletion(
                                                    task.id, !task.isCompleted);
                                          },
                                          onDelete: () {
                                            ref
                                                .read(taskActionsProvider)
                                                .deleteTask(task.id);
                                          },
                                        ))
                                    .toList(),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Task list (week/month views) ──

  Widget _buildTaskList(AsyncValue<List<dynamic>> tasks) {
    return tasks.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _accent),
      ),
      error: (err, _) => Center(child: Text('Ошибка: $err')),
      data: (taskList) {
        if (taskList.isEmpty) {
          return const EmptyState(
            icon: Icons.event_available,
            message: 'Нет задач на этот день',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: taskList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final task = taskList[index];
            return TaskCard(
              task: task,
              onTap: () => context.push('/task/${task.id}'),
              onToggle: () {
                ref
                    .read(taskActionsProvider)
                    .toggleCompletion(task.id, !task.isCompleted);
              },
              onDelete: () {
                ref.read(taskActionsProvider).deleteTask(task.id);
              },
            );
          },
        );
      },
    );
  }
}
