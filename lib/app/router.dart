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
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.house),
            selectedIcon: Icon(PhosphorIconsFill.house),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.chalkboardTeacher),
            selectedIcon: Icon(PhosphorIconsFill.chalkboardTeacher),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.users),
            selectedIcon: Icon(PhosphorIconsFill.users),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.chatCircle),
            selectedIcon: Icon(PhosphorIconsFill.chatCircle),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.userCircle),
            selectedIcon: Icon(PhosphorIconsFill.userCircle),
            label: 'Profile',
          ),
        ],
      ),
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
      // Standalone routes (not in bottom nav)
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
