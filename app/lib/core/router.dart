import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/capture_preview_screen.dart';
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
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
          routes: [
            GoRoute(
              path: 'preview',
              name: 'preview',
              pageBuilder: (_, state) => _fadeSlidePage(
                state,
                CapturePreviewScreen(imagePath: state.extra as String),
              ),
            ),
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
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HistoryListScreen(),
          ),
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
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ProfileScreen(),
          ),
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

    final showRail = !(location == '/home/progress' || location == '/home/preview' || location.startsWith('/home/result'));

    if (!showRail) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ─── Premium Custom Bento Sidebar ───
          Container(
            width: 104,
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildSidebarItem(
                  context: context,
                  isActive: index == 0,
                  icon: Icons.camera_alt_outlined,
                  activeIcon: Icons.camera_alt,
                  label: '실시간 검사',
                  onTap: () => context.go('/home'),
                ),
                _buildDivider(),
                _buildSidebarItem(
                  context: context,
                  isActive: index == 1,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: '이력 관리',
                  onTap: () => context.go('/history'),
                ),
                _buildDivider(),
                _buildSidebarItem(
                  context: context,
                  isActive: index == 2,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: '프로필',
                  onTap: () => context.go('/profile'),
                ),
                _buildDivider(),
                const Spacer(),
              ],
            ),
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.border,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.border.withValues(alpha: 0.5),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required bool isActive,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive ? AppColors.surfaceVariant : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Stack(
          children: [
            // Left active neon purple border line
            if (isActive)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            // Centered tactile layout block
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? activeIcon : icon,
                      size: 28,
                      color: isActive ? AppColors.primary : AppColors.onSurfaceMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelMd.copyWith(
                        color: isActive ? AppColors.primary : AppColors.onSurfaceMuted,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
