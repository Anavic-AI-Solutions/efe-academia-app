import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/l10n.dart';
import '../domain/birthday_model.dart';
import '../providers/birthday_provider.dart';

/// Acento pastel compartido con la tarjeta resumen de cumpleaños.
const _birthdayAccent = Color(0xFFE8A0BF);

/// Lista de cumpleaños de hoy.
///
/// El provider solo devuelve el día actual (el backend no expone otro
/// alcance): ante 404/501 muestra el fallback "próximamente" en vez de un
/// error rojo. Sin cálculo local de cumpleaños (el móvil no tiene
/// `birth_date`).
class BirthdayListScreen extends ConsumerWidget {
  const BirthdayListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final birthdays = ref.watch(todayBirthdaysProvider);
    final available = ref.watch(birthdaysAvailableProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(title: l10n.homeBirthdays),
          Expanded(
            child: birthdays.when(
              loading: () => const ListShimmer(),
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
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(todayBirthdaysProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _BirthdayTile(birthday: items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayTile extends StatelessWidget {
  final BirthdayModel birthday;

  const _BirthdayTile({required this.birthday});

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
