import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../domain/birthday_model.dart';
import '../providers/birthday_provider.dart';

/// Acento pastel compartido con la tarjeta resumen de cumpleaños.
const _birthdayAccent = Color(0xFFE8A0BF);

/// Cumpleaños de hoy + próximos 30 días, filtrados por rol en el backend.
class BirthdayListScreen extends ConsumerWidget {
  const BirthdayListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final birthdays = ref.watch(upcomingBirthdaysProvider);
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
                onRetry: () => ref.invalidate(upcomingBirthdaysProvider),
              ),
              data: (items) => _buildData(
                context,
                ref,
                items: items,
                available: available,
                l10n: l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildData(
    BuildContext context,
    WidgetRef ref, {
    required List<BirthdayModel> items,
    required bool available,
    required AppLocalizations l10n,
  }) {
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
        title: l10n.birthdaysNoUpcoming,
        accentColor: _birthdayAccent,
      );
    }

    final today = items.where((birthday) => birthday.daysUntil == 0).toList();
    final upcoming = items.where((birthday) => birthday.daysUntil > 0).toList();

    return RefreshIndicator(
      onRefresh: () => ref.refresh(upcomingBirthdaysProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          if (today.isNotEmpty) ...[
            _SectionTitle(
              text: l10n.birthdaysTodaySection,
              accent: true,
            ),
            for (final birthday in today)
              _BirthdayTile(birthday: birthday, l10n: l10n),
            const SizedBox(height: 14),
          ],
          _SectionTitle(text: l10n.birthdaysUpcomingSection),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                l10n.birthdaysNoUpcoming,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutedFor(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
            )
          else
            for (final birthday in upcoming)
              _BirthdayTile(birthday: birthday, l10n: l10n),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool accent;

  const _SectionTitle({required this.text, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppTypography.titleMedium.copyWith(
          color: accent
              ? _birthdayAccent
              : (isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BirthdayTile extends StatelessWidget {
  final BirthdayModel birthday;
  final AppLocalizations l10n;

  const _BirthdayTile({required this.birthday, required this.l10n});

  String get _daysText {
    if (birthday.daysUntil == 0) return l10n.birthdaysToday;
    if (birthday.daysUntil == 1) return l10n.birthdaysTomorrow;
    return l10n.birthdaysInDays(birthday.daysUntil);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        birthday.name.isNotEmpty ? birthday.name.characters.first : '?';
    final birthDate = birthday.birthDate == null
        ? null
        : DateFormat('d/M').format(birthday.birthDate!);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  birthday.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (birthDate != null) ...[
                      Text(
                        birthDate,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        l10n.birthdaysTurning(birthday.ageTurning),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _birthdayAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _daysText,
              style: AppTypography.labelSmall.copyWith(
                color: _birthdayAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
