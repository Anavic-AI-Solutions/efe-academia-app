import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/form_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../students/providers/student_grades_provider.dart';
import '../../domain/classroom_grades_summary.dart';
import '../../domain/qualification_model.dart';
import '../../domain/qualification_options.dart';
import '../../domain/qualification_score.dart';
import '../../providers/qualification_provider.dart';

/// Current academic period: 1° Mar-May · 2° Jun-Sep · 3° Oct-Dec.
String currentAcademicPeriod() {
  final month = DateTime.now().month;
  if (month >= 6 && month <= 9) return '2';
  if (month >= 10) return '3';
  return '1';
}

/// Outcome reported by the form through `Navigator.pop`.
enum QualificationFormResult { saved, deleted }

class QualificationFormSheet extends ConsumerStatefulWidget {
  /// Grade to edit. When null the form creates a new one.
  final QualificationModel? qualification;

  /// Fixes the classroom, e.g. when opened from the classroom grades screen.
  final String? classroomId;

  /// Classroom choices for the create mode when no classroom is fixed.
  final List<QualificationClassroomOption>? classrooms;

  /// Students available for the create mode.
  final List<ClassroomGradeStudent> students;

  /// Preselected student.
  final String? initialStudentId;

  const QualificationFormSheet({
    super.key,
    this.qualification,
    this.classroomId,
    this.classrooms,
    required this.students,
    this.initialStudentId,
  });

  @override
  ConsumerState<QualificationFormSheet> createState() =>
      _QualificationFormSheetState();
}

class _QualificationFormSheetState
    extends ConsumerState<QualificationFormSheet> {
  late final bool _isEditing = widget.qualification != null;
  late final TextEditingController _scoreController;
  late final TextEditingController _descriptionController;
  late String? _studentId;
  late String? _classroomId;
  late String _type;
  late String _period;
  String? _scoreError;
  String? _submitError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final qualification = widget.qualification;

    _studentId = qualification?.studentId.isNotEmpty == true
        ? qualification!.studentId
        : widget.initialStudentId ??
            (widget.students.isNotEmpty
                ? widget.students.first.studentId
                : null);
    // Editing never moves a grade: the grade's own classroom wins over the
    // caller argument.
    _classroomId = qualification?.classroomId.isNotEmpty == true
        ? qualification!.classroomId
        : widget.classroomId ??
            (widget.classrooms != null && widget.classrooms!.isNotEmpty
                ? widget.classrooms!.first.id
                : null);
    _type = qualification?.type.trim().isNotEmpty == true
        ? qualification!.type
        : 'Parcial';
    _period = qualification?.period.trim().isNotEmpty == true
        ? qualification!.period
        : currentAcademicPeriod();
    _scoreController = TextEditingController(
      text: qualification?.scoreLabel ?? '',
    );
    _descriptionController = TextEditingController(
      text: qualification?.description ?? '',
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Students for the dropdown. In edit mode the grade's student is always
  /// present, even when the caller did not pass the student list.
  List<ClassroomGradeStudent> get _studentOptions {
    final options = [...widget.students];
    final qualification = widget.qualification;
    if (qualification != null &&
        qualification.studentId.isNotEmpty &&
        !options
            .any((student) => student.studentId == qualification.studentId)) {
      options.insert(
        0,
        ClassroomGradeStudent(
          studentId: qualification.studentId,
          fullname: qualification.studentName.isNotEmpty
              ? qualification.studentName
              : qualification.studentId,
        ),
      );
    }
    return options;
  }

  /// Classroom choices. In edit mode the grade's classroom is always present.
  List<QualificationClassroomOption> get _classroomOptions {
    final options = [...?widget.classrooms];
    final classroomId = _classroomId;
    if (classroomId != null &&
        !options.any((classroom) => classroom.id == classroomId)) {
      options.insert(
        0,
        QualificationClassroomOption(
          id: classroomId,
          name: _classroomLabel(classroomId),
        ),
      );
    }
    return options;
  }

  String _classroomLabel(String classroomId) {
    for (final classroom in widget.classrooms ?? const []) {
      if (classroom.id == classroomId) return classroom.name;
    }
    final qualification = widget.qualification;
    if (qualification != null && qualification.classroomName.isNotEmpty) {
      return qualification.classroomName;
    }
    return classroomId;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final classroomId = _classroomId;
    final studentId = _studentId;

    if (classroomId == null) {
      setState(() => _submitError = l10n.studentGradeNoClassrooms);
      return;
    }

    final score = normalizeQualificationScore(
      _scoreController.text,
      original: widget.qualification?.scoreLabel,
    );
    if (score == null || studentId == null) {
      setState(() {
        _scoreError = l10n.gradeFormScoreInvalid;
        _submitError = null;
      });
      return;
    }

    setState(() {
      _scoreError = null;
      _submitError = null;
      _isSaving = true;
    });

    final description = _descriptionController.text.trim();
    try {
      final repository = ref.read(qualificationRepositoryProvider);
      if (_isEditing) {
        await repository.updateQualification(
          id: widget.qualification!.id,
          studentId: studentId,
          classroomId: classroomId,
          score: score,
          type: _type,
          period: _period,
          category: widget.qualification!.category,
          description: description,
        );
      } else {
        await repository.createQualification(
          studentId: studentId,
          classroomId: classroomId,
          score: score,
          type: _type,
          period: _period,
          description: description,
        );
      }

      _invalidateRelated(studentId, classroomId);

      if (!mounted) return;
      Navigator.of(context).pop(QualificationFormResult.saved);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _scoreError = e.fieldErrors['score'];
        _submitError = _scoreError != null && e.fieldErrors.length == 1
            ? null
            : (e.detail ?? l10n.gradeFormError);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = e.detail ?? l10n.gradeFormError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = l10n.gradeFormError;
      });
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final qualification = widget.qualification;
    if (qualification == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: l10n.gradeFormDeleteTitle,
      message: l10n.commonDeleteMessage,
      confirmLabel: l10n.commonDeleteConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      await ref
          .read(qualificationRepositoryProvider)
          .deleteQualification(qualification.id);

      _invalidateRelated(
        qualification.studentId.isNotEmpty
            ? qualification.studentId
            : _studentId,
        qualification.classroomId.isNotEmpty
            ? qualification.classroomId
            : _classroomId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(QualificationFormResult.deleted);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = l10n.gradeFormDeleteError;
      });
    }
  }

  void _invalidateRelated(String? studentId, String? classroomId) {
    if (studentId != null && studentId.isNotEmpty) {
      ref.invalidate(studentGradesProvider(studentId));
    }
    if (classroomId != null && classroomId.isNotEmpty) {
      ref.invalidate(classroomGradesProvider(classroomId));
    }
    if (studentId != null &&
        studentId.isNotEmpty &&
        classroomId != null &&
        classroomId.isNotEmpty) {
      ref.invalidate(
        boletinProvider((studentId: studentId, classroomId: classroomId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canDelete =
        ref.watch(authProvider).user?.canDeleteQualifications ?? false;
    final students = _studentOptions;
    final typeOptions = qualificationTypeOptions(widget.qualification?.type);
    final periodOptions =
        qualificationPeriodOptions(widget.qualification?.period);

    return FormSheet(
      title: _isEditing ? l10n.gradeFormEditTitle : l10n.gradeFormTitle,
      saveLabel: l10n.gradeFormSave,
      onSave: (_isSaving || _classroomId == null) ? null : _submit,
      isSaving: _isSaving,
      error: _submitError,
      children: [
        if (_isEditing) ...[
          _FieldLabel(label: l10n.studentGradeClassroom),
          DropdownButtonFormField<String>(
            key: const Key('qualification-form-classroom'),
            initialValue: _classroomId,
            isExpanded: true,
            decoration: _inputDecoration(),
            items: _classroomOptions
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
            onChanged: null,
          ),
          const SizedBox(height: 12),
        ] else if (widget.classroomId == null) ...[
          _FieldLabel(label: l10n.studentGradeClassroom),
          DropdownButtonFormField<String>(
            key: const Key('qualification-form-classroom'),
            initialValue: _classroomId,
            isExpanded: true,
            decoration: _inputDecoration(),
            items: _classroomOptions
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
          key: const Key('qualification-form-student'),
          initialValue: _studentId,
          isExpanded: true,
          decoration: _inputDecoration(),
          items: students
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
          onChanged: _isEditing || students.length == 1
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
                    key: const Key('qualification-form-type'),
                    initialValue: _type,
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: typeOptions
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
                    key: const Key('qualification-form-period'),
                    initialValue: _period,
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: periodOptions
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
          key: const Key('qualification-form-score'),
          controller: _scoreController,
          decoration: _inputDecoration(hint: l10n.gradeFormScoreTextHint)
              .copyWith(errorText: _scoreError),
        ),
        const SizedBox(height: 12),
        if (_isEditing && widget.qualification!.category.trim().isNotEmpty) ...[
          _FieldLabel(label: l10n.gradeFormCategory),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gradeEmptyBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.qualification!.category,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _FieldLabel(label: l10n.gradeFormDescription),
        TextField(
          key: const Key('qualification-form-description'),
          controller: _descriptionController,
          maxLines: 2,
          decoration: _inputDecoration(),
        ),
        if (_isEditing && canDelete) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('qualification-form-delete'),
              onPressed: _isSaving ? null : _delete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.gradeFormDelete),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ],
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
