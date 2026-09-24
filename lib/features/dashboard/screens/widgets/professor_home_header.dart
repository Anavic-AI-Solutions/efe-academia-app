import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/professor_colors.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../l10n/l10n.dart';

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

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.professorGreetingMorning;
    if (hour < 20) return context.l10n.professorGreetingAfternoon;
    return context.l10n.professorGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: ProfessorColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: avatarUrl,
                name: name,
                size: 36,
                showBorder: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(context),
                      style: const TextStyle(
                        fontSize: 10,
                        color: ProfessorColors.onPrimaryMuted,
                      ),
                    ),
                    Text(
                      l10n.professorHomeTitle(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ProfessorColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: PhosphorIconsRegular.bell,
                showDot: unreadCount > 0,
                onTap: onNotifications,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: PhosphorIconsRegular.magnifyingGlass,
                onTap: onSearch,
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    this.showDot = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: ProfessorColors.overlay,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: ProfessorColors.onPrimary),
          ),
          if (showDot)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: ProfessorColors.onPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
