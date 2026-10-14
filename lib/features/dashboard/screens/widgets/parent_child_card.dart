import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/parent_home_data.dart';

/// Tarjeta de un hijo en el home de padres: identidad, aula/año y los
/// tiles de Promedio / Asistencia.
///
/// [summary] puede faltar (backend viejo o hijo sin resumen): en ese caso
/// ambos tiles muestran “—” y el subtítulo de aula/año no se renderiza.
class ParentChildCard extends StatelessWidget {
  final String name;
  final ParentChildSummary? summary;
  final VoidCallback onTap;

  const ParentChildCard({
    super.key,
    required this.name,
    this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitle = _subtitleFor(summary);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: name, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkFor(isDark),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.mutedFor(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: AppColors.formatGrade(summary?.averageGrade),
                  label: l10n.gradesGridAverage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: _attendanceLabel(summary?.attendanceRate),
                  label: l10n.dashboardAttendance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `"{aula} · {año}° año"` con las partes presentes; `null` sin datos.
String? _subtitleFor(ParentChildSummary? summary) {
  final classroom = summary?.classroomName ?? '';
  final year = summary?.year ?? '';
  final parts = <String>[
    if (classroom.isNotEmpty) classroom,
    if (year.isNotEmpty) '$year° año',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String _attendanceLabel(double? rate) {
  if (rate == null) return '—';
  return '${rate.round()}%';
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.chipFor(isDark),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.accentFor(isDark),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.mutedFor(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
