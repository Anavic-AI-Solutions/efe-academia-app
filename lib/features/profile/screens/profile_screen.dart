import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                AppAvatar(
                  imageUrl: user?.avatarUrl,
                  name: user?.name ?? 'User',
                  size: 80,
                  showBorder: true,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'User',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                _RoleBadge(role: user?.role ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Menu items
          _MenuTile(
            icon: PhosphorIconsRegular.user,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _MenuTile(
            icon: PhosphorIconsRegular.bell,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          _MenuTile(
            icon: PhosphorIconsRegular.moon,
            title: 'Theme',
            onTap: () {},
          ),
          _MenuTile(
            icon: PhosphorIconsRegular.info,
            title: 'About',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
              icon: const Icon(PhosphorIconsBold.power),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getRoleName(role),
        style: theme.textTheme.labelSmall?.copyWith(
          color: roleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'branch':
        return const Color(0xFFF97316);
      case 'professor':
        return const Color(0xFF3B82F6);
      case 'student':
        return const Color(0xFF10B981);
      case 'parent':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'branch':
        return 'Branch Director';
      case 'professor':
        return 'Professor';
      case 'parent':
        return 'Parent';
      case 'student':
        return 'Student';
      default:
        return role.isNotEmpty ? role : 'User';
    }
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        trailing: const Icon(PhosphorIconsRegular.caretRight),
        onTap: onTap,
      ),
    );
  }
}
