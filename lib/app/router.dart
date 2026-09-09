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
// Placeholder screens for unimplemented routes
// ---------------------------------------------------------------------------

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
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
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Chat'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Profile'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
