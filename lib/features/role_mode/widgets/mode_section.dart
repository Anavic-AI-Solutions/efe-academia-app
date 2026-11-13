import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/role_labels.dart';
import 'mode_switch_sheet.dart';

class ModeSection extends ConsumerWidget {
  const ModeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final roles = user?.roles ?? const <String>[];

    if (user == null || roles.length <= 1) {
      return const SizedBox(height: 24);
    }

    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.roleModeTitle, padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            onTap: () => openModeSwitcher(context, ref),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              Icons.swap_horiz_rounded,
              size: 20,
              color: AppColors.accentFor(isDark),
            ),
            title: Text(
              l10n.roleModeChange,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            subtitle: Text(
              '${l10n.roleModeCurrent}: ${roleLabel(l10n, user.role)}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.mutedFor(isDark),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedFor(isDark),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
