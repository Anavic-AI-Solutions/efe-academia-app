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
import '../features/students/screens/student_list_screen.dart';
import '../features/students/screens/student_detail_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/notifications/screens/notification_list_screen.dart';
import '../features/news/screens/news_list_screen.dart';
import '../features/events/screens/event_list_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../app/theme/app_colors.dart';
import '../l10n/l10n.dart';

// ---------------------------------------------------------------------------
// Custom Bottom Navigation Bar
// ---------------------------------------------------------------------------

class CustomBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const CustomBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                isDark: isDark,
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
                isDark: isDark,
              ),
              _CenterSearchItem(onTap: () => context.push('/search')),
              _NavItem(
                icon: PhosphorIconsRegular.chatCircle,
                selectedIcon: PhosphorIconsFill.chatCircle,
                label: l10n.navChat,
                isSelected: navigationShell.currentIndex == 2,
                onTap: () => navigationShell.goBranch(
                  2,
                  initialLocation: 2 == navigationShell.currentIndex,
                ),
                isDark: isDark,
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
                isDark: isDark,
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
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? (isDark ? const Color(0xFF6366F1) : AppColors.primary)
        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterSearchItem extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterSearchItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x334F46E5),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                PhosphorIconsFill.magnifyingGlass,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
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
