import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/grade_badge.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classrooms/domain/classroom_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../students/providers/student_provider.dart';
import '../domain/boletin_data.dart';
import '../providers/qualification_provider.dart';

/// Boletín de notas de un alumno por aula (`/students/:id/boletin`).
///
/// Muestra el boletín completo del aula elegida: notas por período con el
/// promedio por período, asistencia por período, inasistencias y
/// observaciones públicas. Con 2+ aulas del hijo aparecen chips (default la
/// primera; cambiar refetchea porque el provider es family por aula) y al pie
/// se descarga el PDF oficial por URL firmada (launcher inyectable para
/// tests; un fallo del link avisa con snackbar, sin crashear).
///
/// Para profesores la lista de aulas se acota a la intersección con sus
/// aulas del dashboard (`authorizeBoletin` rechaza las ajenas con 403); sin
/// intersección se muestra `boletinNoAccess` sin chips ni descarga.
class StudentBoletinScreen extends ConsumerStatefulWidget {
  final String studentId;

  /// Launcher inyectable para tests; por defecto abre con `url_launcher`.
  final Future<bool> Function(Uri)? openUrl;

  const StudentBoletinScreen({
    super.key,
    required this.studentId,
    this.openUrl,
  });

  @override
  ConsumerState<StudentBoletinScreen> createState() =>
      _StudentBoletinScreenState();
}

class _StudentBoletinScreenState extends ConsumerState<StudentBoletinScreen> {
  String? _selectedClassroomId;
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfessor = ref.watch(authProvider).user?.isProfessor ?? false;
    // Ids de las aulas del profesor (dashboard): para el rol profesor solo
    // esas aulas son visibles; el resto daría 403 en la API.
    final professorClassrooms =
        isProfessor ? ref.watch(dashboardProvider).data?.classrooms : null;
    final professorClassroomIds =
        professorClassrooms?.map((classroom) => classroom.id).toSet() ??
            const <String>{};
    final classroomsAsync = ref.watch(
      studentClassroomsProvider(widget.studentId),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: classroomsAsync.when(
        loading: () => _headerBody(
          l10n,
          const ListShimmer(itemCount: 5, itemHeight: 64),
        ),
        error: (error, _) => _headerBody(
          l10n,
          ErrorView(
            message: l10n.classroomsLoadError,
            detail: error.toString(),
            onRetry: () =>
                ref.invalidate(studentClassroomsProvider(widget.studentId)),
          ),
        ),
        data: (classrooms) {
          // Profesor: solo sus aulas (la API rechaza las ajenas con 403);
          // el resto de los roles ven las aulas del alumno tal cual.
          final visible = isProfessor
              ? classrooms
                  .where((c) => professorClassroomIds.contains(c.id))
                  .toList()
              : classrooms;

          if (visible.isEmpty) {
            if (isProfessor) {
              return _headerBody(
                l10n,
                EmptyState(
                  icon: PhosphorIconsRegular.lock,
                  title: l10n.boletinNoAccess,
                ),
              );
            }
            return _headerBody(
              l10n,
              EmptyState(
                icon: PhosphorIconsRegular.books,
                title: l10n.classroomsEmptyTitle,
              ),
            );
          }

          final selectedId = _selectedClassroomId != null &&
                  visible.any((c) => c.id == _selectedClassroomId)
              ? _selectedClassroomId!
              : visible.first.id;
          final key = (
            studentId: widget.studentId,
            classroomId: selectedId,
          );
          final boletinAsync = ref.watch(boletinProvider(key));
          final boletin = boletinAsync.valueOrNull;
          final fullname = boletin?.studentFullname ?? '';

          return Column(
            children: [
              ScreenHeader(
                title: l10n.boletinTitle,
                subtitle: fullname.isEmpty ? null : fullname,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              // La fila aparece si el alumno tiene 2+ aulas; para un profesor
              // puede quedar un único chip (las demás son ajenas).
              if (classrooms.length > 1)
                _ClassroomChips(
                  classrooms: visible,
                  selectedId: selectedId,
                  onSelected: (id) => setState(() => _selectedClassroomId = id),
                ),
              Expanded(child: _buildBody(boletinAsync, key, l10n, isDark)),
              if (boletin != null)
                _DownloadBar(
                  l10n: l10n,
                  isLoading: _downloading,
                  onPressed: () => _downloadBoletin(selectedId),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Column base con el encabezado (sin subtítulo hasta tener los datos).
  Widget _headerBody(AppLocalizations l10n, Widget body) {
    return Column(
      children: [
        ScreenHeader(
          title: l10n.boletinTitle,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildBody(
    AsyncValue<BoletinData> boletinAsync,
    ({String studentId, String classroomId}) key,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return boletinAsync.when(
      loading: () => const ListShimmer(itemCount: 5, itemHeight: 64),
      error: (error, _) => ErrorView(
        message: l10n.gradesLoadError,
        detail: error.toString(),
        onRetry: () => ref.invalidate(boletinProvider(key)),
      ),
      data: (data) => RefreshIndicator(
        color: AppColors.accentFor(isDark),
        onRefresh: () => _refresh(key),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          children: _sections(data, l10n, isDark),
        ),
      ),
    );
  }

  /// Pull-to-refresh: vuelve a pedir el boletín del aula elegida.
  Future<void> _refresh(({String studentId, String classroomId}) key) async {
    ref.invalidate(boletinProvider(key));
    try {
      await ref.read(boletinProvider(key).future);
    } catch (_) {
      // El ErrorView del provider ya refleja el fallo; el refresh no rompe.
    }
  }

  List<Widget> _sections(BoletinData data, AppLocalizations l10n, bool isDark) {
    final absences = data.absences;

    return [
      SectionHeader(title: l10n.studentsTabGrades),
      const SizedBox(height: 10),
      ..._gradeCards(data, l10n, isDark),
      const SizedBox(height: 18),
      SectionHeader(title: l10n.dashboardAttendance),
      const SizedBox(height: 10),
      _AttendanceCard(absences: absences, l10n: l10n, isDark: isDark),
      if (absences.list.isNotEmpty) ...[
        const SizedBox(height: 18),
        SectionHeader(title: l10n.studentsTabAbsences),
        const SizedBox(height: 10),
        _AbsencesCard(absences: absences.list, l10n: l10n, isDark: isDark),
      ],
      if (data.observations.isNotEmpty) ...[
        const SizedBox(height: 18),
        SectionHeader(title: l10n.boletinObservations),
        const SizedBox(height: 10),
        _ObservationsCard(
          observations: data.observations,
          l10n: l10n,
          isDark: isDark,
        ),
      ],
    ];
  }

  /// Cards “{n}° Período” de los períodos con notas; sin notas, el vacío.
  List<Widget> _gradeCards(
    BoletinData data,
    AppLocalizations l10n,
    bool isDark,
  ) {
    if (data.qualifications.isEmpty) {
      return [
        AppCard(
          child: Text(
            l10n.boletinNoGrades,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedFor(isDark),
            ),
          ),
        ),
      ];
    }

    final byPeriod = <String, List<BoletinQualification>>{};
    for (final qualification in data.qualifications) {
      byPeriod.putIfAbsent(qualification.period, () => []).add(qualification);
    }
    final orderedPeriods = [
      ...data.periods.where(byPeriod.containsKey),
      ...byPeriod.keys.where((period) => !data.periods.contains(period)),
    ];

    return [
      for (final period in orderedPeriods)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PeriodCard(
            period: period,
            qualifications: byPeriod[period]!,
            average: data.averages[period],
            l10n: l10n,
            isDark: isDark,
          ),
        ),
    ];
  }

  /// Pide la URL firmada del PDF y la abre externamente. Si el link falla
  /// (404/red) o el launcher no abre, avisa con snackbar sin crashear.
  Future<void> _downloadBoletin(String classroomId) async {
    if (_downloading) return;
    setState(() => _downloading = true);

    var opened = false;
    try {
      final url = await ref
          .read(qualificationRepositoryProvider)
          .getBoletinUrl(widget.studentId, classroomId);
      final uri = Uri.tryParse(url);
      if (uri != null && url.trim().isNotEmpty) {
        opened = await _launch(uri);
      }
    } catch (_) {
      // ApiException 404/red y cualquier fallo del launcher terminan en el
      // mismo aviso: nunca se propaga el error.
      opened = false;
    }

    if (!mounted) return;
    setState(() => _downloading = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.boletinDownloadError)),
      );
    }
  }

  Future<bool> _launch(Uri uri) {
    final openUrl = widget.openUrl;
    if (openUrl != null) return openUrl(uri);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Etiqueta del período: `{n}° Período` si es numérico; el texto tal cual si
/// no lo es (datos raros del backend no rompen la pantalla).
String _periodLabel(AppLocalizations l10n, String period) {
  final n = int.tryParse(period);
  return n != null ? l10n.boletinPeriod(n) : period;
}

/// Porcentaje de asistencia del boletín: 2 decimales con coma (`95,00%`).
String _attendanceValue(double? value) {
  if (value == null) return '—';
  return '${NumberFormat('#,##0.00', 'es_AR').format(value)}%';
}

/// Color de la nota: escala de notas si es numérica; tinta normal si no.
Color _scoreColor(String score, bool isDark) {
  final value = double.tryParse(score.trim());
  if (value == null) return AppColors.inkFor(isDark);
  return AppColors.gradeColor(value);
}

/// Chips de aula (solo con 2+): pill con `accentFor` en el elegido (tinte,
/// borde y texto) para cumplir el contraste en claro y oscuro.
class _ClassroomChips extends StatelessWidget {
  final List<ClassroomModel> classrooms;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _ClassroomChips({
    required this.classrooms,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentFor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: classrooms.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final classroom = classrooms[index];
            final selected = classroom.id == selectedId;

            return GestureDetector(
              onTap: () => onSelected(classroom.id),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withOpacity(0.12)
                      : AppColors.chipFor(isDark),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected
                        ? accent
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: selected ? 1.2 : 0.5,
                  ),
                ),
                child: Text(
                  classroom.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? accent : AppColors.mutedFor(isDark),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Card de un período: título + badge de promedio y filas tipo → nota.
class _PeriodCard extends StatelessWidget {
  final String period;
  final List<BoletinQualification> qualifications;
  final double? average;
  final AppLocalizations l10n;
  final bool isDark;

  const _PeriodCard({
    required this.period,
    required this.qualifications,
    required this.average,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _periodLabel(l10n, period),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFor(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.gradesGridAverage,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedFor(isDark),
                ),
              ),
              const SizedBox(width: 6),
              GradeBadge(grade: average),
            ],
          ),
          const Divider(height: 18),
          for (var i = 0; i < qualifications.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    qualifications[i].type,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedFor(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  qualifications[i].score,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _scoreColor(qualifications[i].score, isDark),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Card de asistencia: resumen (total/justificadas/sin justificar) y el
/// porcentaje de los períodos 1..3 (los ausentes van con “—”).
class _AttendanceCard extends StatelessWidget {
  final BoletinAbsences absences;
  final AppLocalizations l10n;
  final bool isDark;

  const _AttendanceCard({
    required this.absences,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              // `feesDetailTotal` es la etiqueta genérica “Total” del sistema.
              Expanded(
                child: _StatCell(
                  label: l10n.feesDetailTotal,
                  value: AppFormatters.formatNumber(absences.total),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatCell(
                  label: l10n.studentsAbsenceJustified,
                  value: AppFormatters.formatNumber(absences.justified),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatCell(
                  label: l10n.studentsAbsenceUnjustified,
                  value: AppFormatters.formatNumber(absences.unjustified),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          for (var n = 1; n <= 3; n++) ...[
            if (n > 1) const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${l10n.boletinPeriod(n)}: '
                '${_attendanceValue(absences.attendanceByPeriod['$n'])}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkFor(isDark),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Celda de resumen: valor grande arriba, etiqueta muted abajo.
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatCell({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.inkFor(isDark),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedFor(isDark),
          ),
        ),
      ],
    );
  }
}

/// Card con las inasistencias: fecha · cantidad · badge justificada.
class _AbsencesCard extends StatelessWidget {
  final List<BoletinAbsence> absences;
  final AppLocalizations l10n;
  final bool isDark;

  const _AbsencesCard({
    required this.absences,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < absences.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    absences[i].date,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedFor(isDark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppFormatters.formatNumber(absences[i].quantity),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFor(isDark),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  status: absences[i].justified ? 'justified' : 'unjustified',
                  label: absences[i].justified
                      ? l10n.studentsAbsenceJustified
                      : l10n.studentsAbsenceUnjustified,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Card con las observaciones: fecha + período y la descripción.
class _ObservationsCard extends StatelessWidget {
  final List<BoletinObservation> observations;
  final AppLocalizations l10n;
  final bool isDark;

  const _ObservationsCard({
    required this.observations,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < observations.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        observations[i].date,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedFor(isDark),
                        ),
                      ),
                    ),
                    if (observations[i].period.isNotEmpty)
                      Text(
                        _periodLabel(l10n, observations[i].period),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentFor(isDark),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  observations[i].description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.inkFor(isDark),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón fijo al pie con la descarga del PDF.
class _DownloadBar extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isLoading;
  final VoidCallback onPressed;

  const _DownloadBar({
    required this.l10n,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: PillButton(
        label: l10n.boletinDownloadAction,
        icon: PhosphorIconsRegular.downloadSimple,
        isLoading: isLoading,
        onPressed: onPressed,
      ),
    );
  }
}
