import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/role_labels.dart';
import 'mode_switch_sheet.dart';

class ModeSwitchChip extends ConsumerWidget {
  const ModeSwitchChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final roles = user?.roles ?? const <String>[];

    if (user == null || roles.length <= 1) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => openModeSwitcher(context, ref),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.overlay,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                size: 14,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                '${l10n.roleModeCurrent}: ${roleLabel(l10n, user.role)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
