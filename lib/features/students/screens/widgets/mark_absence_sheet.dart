import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../dashboard/domain/professor_classroom_summary.dart';

/// Formatea una fecha como `yyyy-MM-dd`, el formato del endpoint de parte.
String formatAbsenceDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime _dateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Último día seleccionable: hoy (el parte es registro, no planificación).
DateTime absenceMaxDate(DateTime today) => _dateOnly(today);

/// Primer día seleccionable: hoy − 90 días.
DateTime absenceMinDate(DateTime today) =>
    _dateOnly(today).subtract(const Duration(days: 90));

/// Une los ausentes ya registrados con el alumno, sin duplicar.
Set<String> mergeAbsentIds(Iterable<String> existing, String studentId) =>
    {...existing, studentId};

/// Sheet para marcar la inasistencia de un alumno en una fecha.
///
/// Resuelve el aula igual que CreateQualificationSheet: fija cuando
/// [classroomId] no es nulo, si no con dropdown de [classrooms].
/// Hace merge con el parte del día (nunca envía solo al alumno) y devuelve
/// `true` si la ausencia es nueva o `false` si el alumno ya estaba ausente.
class MarkAbsenceSheet extends ConsumerStatefulWidget {
  final String studentId;
  final String? classroomId;
  final List<ProfessorClassroomSummary>? classrooms;

  const MarkAbsenceSheet({
    super.key,
    required this.studentId,
    this.classroomId,
    this.classrooms,
  });

  @override
  ConsumerState<MarkAbsenceSheet> createState() => _MarkAbsenceSheetState();
}

class _MarkAbsenceSheetState extends ConsumerState<MarkAbsenceSheet> {
  late String? _classroomId = widget.classroomId ??
      (widget.classrooms != null && widget.classrooms!.isNotEmpty
          ? widget.classrooms!.first.id
          : null);
  late DateTime _selectedDate = _dateOnly(DateTime.now());
  String? _submitError;
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: absenceMinDate(DateTime.now()),
      lastDate: absenceMaxDate(DateTime.now()),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = _dateOnly(picked));
    }
  }

  Future<void> _submit() async {
    final classroomId = _classroomId;
    if (classroomId == null) return;

    final date = formatAbsenceDate(_selectedDate);

    setState(() {
      _submitError = null;
      _isSaving = true;
    });

    try {
      final repository = ref.read(attendanceRepositoryProvider);
      final day = await repository.getAttendance(classroomId, date: date);
      final existing = day.students
          .where((student) => student.isAbsent)
          .map((student) => student.id);
      final alreadyAbsent = existing.contains(widget.studentId);
      await repository.saveAttendance(
        classroomId,
        date: date,
        absentStudentIds: mergeAbsentIds(existing, widget.studentId).toList(),
      );

      // Refresca el parte del día por si la pantalla de asistencia está
      // abierta; solo el sheet conoce el aula resuelta.
      ref.invalidate(attendanceProvider(classroomId));

      if (mounted) {
        Navigator.of(context).pop(!alreadyAbsent);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _submitError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkSurface : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightInk;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.navInactive.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.absenceMarkTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.classroomId == null) ...[
                _FieldLabel(label: l10n.absenceMarkClassroom),
                DropdownButtonFormField<String>(
                  value: _classroomId,
                  isExpanded: true,
                  decoration: _inputDecoration(),
                  items: (widget.classrooms ?? const [])
                      .map(
                        (classroom) => DropdownMenuItem(
                          value: classroom.id,
                          child: Text(
                            classroom.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _classroomId = value),
                ),
                const SizedBox(height: 12),
              ],
              _FieldLabel(label: l10n.absenceMarkDate),
              InkWell(
                onTap: _isSaving ? null : _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDecoration(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatAbsenceDate(_selectedDate),
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.absenceMarkInfo,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.absenceMarkError,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.absent,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.gradeFormSave,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.gradeEmptyBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
