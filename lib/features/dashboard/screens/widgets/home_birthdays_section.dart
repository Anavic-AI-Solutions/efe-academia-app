import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/l10n.dart';
import '../../../birthdays/domain/birthday_model.dart';
import '../../../birthdays/providers/birthday_provider.dart';

/// Acento pastel para la sección de cumpleaños (caso vacío normal y
/// fallback "próximamente").
const _birthdayAccent = Color(0xFFE8A0BF);

/// Cumpleaños de hoy en el home del profesor: avatar + nombre + edad.
///
/// Vacío normal → `EmptyState` pastel. El endpoint ya existe; 404/501 queda
/// como fallback para despliegues viejos, sin error rojo. Tap en un
/// cumpleaños con `studentAppId` → `/students/{id}`. Un error de otro
/// origen muestra `ErrorView` compacto sin tumbar el resto del home.
class HomeBirthdaysSection extends ConsumerWidget {
  const HomeBirthdaysSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final birthdays = ref.watch(todayBirthdaysProvider);
    final available = ref.watch(birthdaysAvailableProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeBirthdays,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 11),
        birthdays.when(
          loading: () => const Column(
            children: [
              LoadingShimmer(
                width: double.infinity,
                height: 64,
                borderRadius: 16,
              ),
              SizedBox(height: 10),
              LoadingShimmer(
                width: double.infinity,
                height: 64,
                borderRadius: 16,
              ),
            ],
          ),
          error: (error, _) => ErrorView(
            message: l10n.homeBirthdays,
            detail: error.toString(),
            onRetry: () => ref.invalidate(todayBirthdaysProvider),
          ),
          data: (items) {
            if (!available) {
              return EmptyState(
                icon: PhosphorIconsRegular.cake,
                title: l10n.homeBirthdaysSoon,
                accentColor: _birthdayAccent,
              );
            }
            if (items.isEmpty) {
              return EmptyState(
                icon: PhosphorIconsRegular.cake,
                title: l10n.homeBirthdaysEmpty,
                accentColor: _birthdayAccent,
              );
            }
            return Column(
              children: [
                for (final birthday in items)
                  _HomeBirthdayTile(birthday: birthday),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HomeBirthdayTile extends StatelessWidget {
  final BirthdayModel birthday;

  const _HomeBirthdayTile({required this.birthday});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        birthday.name.isNotEmpty ? birthday.name.characters.first : '?';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: birthday.studentAppId == null
          ? null
          : () => context.push('/students/${birthday.studentAppId}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _birthdayAccent.withOpacity(0.18),
            child: Text(
              initial,
              style: AppTypography.titleMedium.copyWith(
                color: _birthdayAccent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              birthday.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _birthdayAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  PhosphorIconsRegular.cake,
                  size: 16,
                  color: _birthdayAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${birthday.ageTurning}',
                  style: AppTypography.titleSmall.copyWith(
                    color: _birthdayAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
