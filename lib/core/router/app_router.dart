import 'package:go_router/go_router.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/tasks/task_form_screen.dart';
import '../../presentation/screens/tasks/task_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    ShellRoute(
      builder: (context, state, child) => HomeScreen(child: child),
      routes: [
        GoRoute(
          path: '/today',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TodayTab(),
          ),
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TasksTab(),
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalendarTab(),
          ),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CategoriesTab(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsTab(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/task/new',
      builder: (context, state) => const TaskFormScreen(),
    ),
    GoRoute(
      path: '/task/edit/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TaskFormScreen(taskId: id);
      },
    ),
    GoRoute(
      path: '/task/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TaskDetailScreen(taskId: id);
      },
    ),
  ],
);
