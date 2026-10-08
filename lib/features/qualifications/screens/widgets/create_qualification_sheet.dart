import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../dashboard/domain/professor_classroom_summary.dart';
import '../../domain/classroom_grades_summary.dart';
import '../../providers/qualification_provider.dart';

const _types = ['Parcial', 'Oral'];
const _periods = ['1', '2', '3'];

/// Current academic period: 1° Mar-May · 2° Jun-Sep · 3° Oct-Dec.
String currentAcademicPeriod() {
  final month = DateTime.now().month;
  if (month >= 6 && month <= 9) return '2';
  if (month >= 10) return '3';
  return '1';
}

class CreateQualificationSheet extends ConsumerStatefulWidget {
  final String? classroomId;
  final List<ProfessorClassroomSummary>? classrooms;
  final List<ClassroomGradeStudent> students;
  final String? initialStudentId;

  const CreateQualificationSheet({
    super.key,
    this.classroomId,
    this.classrooms,
    required this.students,
    this.initialStudentId,
  });

  @override
  ConsumerState<CreateQualificationSheet> createState() =>
      _CreateQualificationSheetState();
}

class _CreateQualificationSheetState
    extends ConsumerState<CreateQualificationSheet> {
  final _scoreController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String? _studentId = widget.initialStudentId ??
      (widget.students.isNotEmpty ? widget.students.first.studentId : null);
  late String? _classroomId = widget.classroomId ??
      (widget.classrooms != null && widget.classrooms!.isNotEmpty
          ? widget.classrooms!.first.id
          : null);
  String _type = _types.first;
  late String _period = currentAcademicPeriod();
  String? _scoreError;
  String? _submitError;
  bool _isSaving = false;

  @override
  void dispose() {
    _scoreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? _parseScore(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || value < 0 || value > 10) return null;
    return value;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final score = _parseScore(_scoreController.text);
    final classroomId = _classroomId;

    if (score == null || _studentId == null || classroomId == null) {
      setState(() => _scoreError = l10n.gradeFormScoreInvalid);
      return;
    }

    setState(() {
      _scoreError = null;
      _submitError = null;
      _isSaving = true;
    });

    try {
      await ref.read(qualificationRepositoryProvider).createQualification(
            studentId: _studentId!,
            classroomId: classroomId,
            score: score.toString(),
            type: _type,
            period: _period,
            description: _descriptionController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop(true);
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
                l10n.gradeFormTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.classroomId == null) ...[
                _FieldLabel(label: l10n.studentGradeClassroom),
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
              _FieldLabel(label: l10n.gradeFormStudent),
              DropdownButtonFormField<String>(
                value: _studentId,
                isExpanded: true,
                decoration: _inputDecoration(),
                items: widget.students
                    .map(
                      (student) => DropdownMenuItem(
                        value: student.studentId,
                        child: Text(
                          student.fullname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.students.length == 1
                    ? null
                    : (value) => setState(() => _studentId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: l10n.gradeFormType),
                        DropdownButtonFormField<String>(
                          value: _type,
                          decoration: _inputDecoration(),
                          items: _types
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _type = value ?? _type),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: l10n.gradeFormPeriod),
                        DropdownButtonFormField<String>(
                          value: _period,
                          decoration: _inputDecoration(),
                          items: _periods
                              .map(
                                (period) => DropdownMenuItem(
                                  value: period,
                                  child: Text('$period°'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _period = value ?? _period),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FieldLabel(label: l10n.gradeFormScore),
              TextField(
                controller: _scoreController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(hint: l10n.gradeFormScoreHint)
                    .copyWith(errorText: _scoreError),
              ),
              const SizedBox(height: 12),
              _FieldLabel(label: l10n.gradeFormDescription),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: _inputDecoration(),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.gradeFormError,
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

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
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
