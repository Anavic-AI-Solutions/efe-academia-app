import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/classrooms/screens/classroom_list_screen.dart';
import '../features/classrooms/screens/classroom_detail_screen.dart';
import '../features/attendance/screens/attendance_screen.dart';
import '../features/qualifications/screens/classroom_grades_screen.dart';
import '../features/students/screens/student_list_screen.dart';
import '../features/students/screens/student_detail_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_detail_screen.dart';
import '../features/chat/providers/chat_provider.dart';
import '../features/relations/screens/new_chat_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/notifications/screens/notification_list_screen.dart';
import '../features/news/screens/news_list_screen.dart';
import '../features/events/screens/event_list_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../app/theme/app_colors.dart';
import '../core/widgets/badge_counter.dart';
import '../l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Custom Bottom Navigation Bar
// ---------------------------------------------------------------------------

class CustomBottomNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const CustomBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    // Single unified accent for every role.
    const accent = AppColors.primary;
    final inactive =
        isDark ? AppColors.darkTextSecondary : AppColors.navInactive;
    // Hidden (0) while loading or on error.
    final unreadChats = ref.watch(chatUnreadCountProvider).valueOrNull ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: PhosphorIconsRegular.house,
                selectedIcon: PhosphorIconsFill.house,
                label: l10n.navHome,
                isSelected: navigationShell.currentIndex == 0,
                onTap: () => navigationShell.goBranch(
                  0,
                  initialLocation: 0 == navigationShell.currentIndex,
                ),
                accent: accent,
                inactive: inactive,
              ),
              _NavItem(
                icon: PhosphorIconsRegular.chalkboardTeacher,
                selectedIcon: PhosphorIconsFill.chalkboardTeacher,
                label: l10n.navClasses,
                isSelected: navigationShell.currentIndex == 1,
                onTap: () => navigationShell.goBranch(
                  1,
                  initialLocation: 1 == navigationShell.currentIndex,
                ),
                accent: accent,
                inactive: inactive,
              ),
              _NavItem(
                icon: PhosphorIconsRegular.chatCircle,
                selectedIcon: PhosphorIconsFill.chatCircle,
                label: l10n.navChat,
                badgeCount: unreadChats,
                isSelected: navigationShell.currentIndex == 2,
                onTap: () => navigationShell.goBranch(
                  2,
                  initialLocation: 2 == navigationShell.currentIndex,
                ),
                accent: accent,
                inactive: inactive,
              ),
              _NavItem(
                icon: PhosphorIconsRegular.userCircle,
                selectedIcon: PhosphorIconsFill.userCircle,
                label: l10n.navProfile,
                isSelected: navigationShell.currentIndex == 3,
                onTap: () => navigationShell.goBranch(
                  3,
                  initialLocation: 3 == navigationShell.currentIndex,
                ),
                accent: accent,
                inactive: inactive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;
  final Color inactive;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    required this.isSelected,
    required this.onTap,
    required this.accent,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? accent : inactive;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BadgeCounter(
              count: badgeCount,
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : inactive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scaffold with bottom navigation
// ---------------------------------------------------------------------------

class ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomBottomNav(navigationShell: navigationShell),
    );
  }
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNav(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/classrooms',
                builder: (context, state) => const ClassroomListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ClassroomDetailScreen(
                      classroomId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'attendance',
                        builder: (context, state) => AttendanceScreen(
                          classroomId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'grades',
                        builder: (context, state) => ClassroomGradesScreen(
                          classroomId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const NewChatScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ChatDetailScreen(
                      chatId: state.pathParameters['id']!,
                      chatName: state.uri.queryParameters['name'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/students',
        builder: (context, state) => const StudentListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => StudentDetailScreen(
              studentId: state.pathParameters['id']!,
              classroomId: state.uri.queryParameters['classroomId'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsListScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventListScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
});
