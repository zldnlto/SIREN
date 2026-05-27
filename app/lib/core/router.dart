import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inspection_progress_screen.dart';
import '../screens/defect_result_screen.dart';
import '../screens/normal_result_screen.dart';
import '../screens/history_list_screen.dart';
import '../screens/history_detail_screen.dart';
import '../screens/profile_screen.dart';

Page<T> _fadeSlidePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (_, state) => _fadeSlidePage(state, const LoginScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (_, state) => _fadeSlidePage(state, const HomeScreen()),
          routes: [
            GoRoute(
              path: 'progress',
              name: 'progress',
              pageBuilder: (_, state) => _fadeSlidePage(
                state,
                InspectionProgressScreen(inspectionId: state.extra as String),
              ),
            ),
            GoRoute(
              path: 'result/defect',
              name: 'result-defect',
              pageBuilder: (_, state) => _fadeSlidePage(
                state,
                DefectResultScreen(inspectionId: state.extra as String),
              ),
            ),
            GoRoute(
              path: 'result/normal',
              name: 'result-normal',
              pageBuilder: (_, state) => _fadeSlidePage(
                state,
                NormalResultScreen(inspectionId: state.extra as String),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const HistoryListScreen()),
          routes: [
            GoRoute(
              path: ':id',
              name: 'history-detail',
              pageBuilder: (_, state) => _fadeSlidePage(
                state,
                HistoryDetailScreen(
                  inspectionId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const ProfileScreen()),
        ),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = location.startsWith('/history')
        ? 1
        : location.startsWith('/profile')
            ? 2
            : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/history');
            case 2:
              context.go('/profile');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt), label: '검사'),
          NavigationDestination(icon: Icon(Icons.history), label: '이력'),
          NavigationDestination(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}
