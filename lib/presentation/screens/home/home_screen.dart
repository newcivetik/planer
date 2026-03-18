import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../screens/tasks/task_list_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../today/today_screen.dart';

class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) => const TodayScreen();
}

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) => const TaskListScreen();
}

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key});

  @override
  Widget build(BuildContext context) => const CalendarScreen();
}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) => const CategoriesScreen();
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScreen();
}

class HomeScreen extends StatelessWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  static const _tabs = [
    '/today',
    '/tasks',
    '/calendar',
    '/categories',
    '/settings',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    const accentColor = Color(0xFF4A90D9);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: NavigationBar(
          height: 60,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: accentColor.withValues(alpha: 0.12),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            context.go(_tabs[index]);
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today, color: accentColor),
              label: AppStrings.today,
            ),
            NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt, color: accentColor),
              label: AppStrings.tasks,
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: accentColor),
              label: AppStrings.calendar,
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder, color: accentColor),
              label: AppStrings.categories,
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: accentColor),
              label: AppStrings.settings,
            ),
          ],
        ),
      ),
      floatingActionButton: currentIndex <= 2
          ? FloatingActionButton(
              onPressed: () => context.push('/task/new'),
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add),
            ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            )
          : null,
    );
  }
}
