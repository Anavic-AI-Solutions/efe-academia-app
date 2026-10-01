import 'package:flutter/material.dart';

import '../../../../core/widgets/home_header.dart';

/// Professor home header, delegating to the neutral [HomeHeader].
class ProfessorHomeHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onSearch;
  final Widget child;

  const ProfessorHomeHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    this.unreadCount = 0,
    required this.onNotifications,
    required this.onSearch,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return HomeHeader(
      name: name,
      avatarUrl: avatarUrl,
      unreadCount: unreadCount,
      onNotifications: onNotifications,
      onSearch: onSearch,
      child: child,
    );
  }
}
