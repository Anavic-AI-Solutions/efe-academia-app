import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/entity_form_screen.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/l10n.dart';
import '../domain/classroom_model.dart';
import '../providers/classroom_provider.dart';

/// Full screen create/edit form for classrooms.
///
/// Creation is used when neither [classroom] nor [classroomId] is provided.
/// When only [classroomId] is provided the classroom is loaded through
/// [classroomDetailProvider]. Optional fields are always sent, so clearing
/// them on edit stores empty values.
class ClassroomFormScreen extends ConsumerStatefulWidget {
  const ClassroomFormScreen({
    super.key,
    this.classroom,
    this.classroomId,
  });

  final ClassroomModel? classroom;
  final String? classroomId;

  @override
  ConsumerState<ClassroomFormScreen> createState() =>
      _ClassroomFormScreenState();
}

class _ClassroomFormScreenState extends ConsumerState<ClassroomFormScreen> {
  static const _statuses = ['active', 'inactive'];
  static const _shifts = ['morning', 'afternoon', 'night'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dayController = TextEditingController();
  final _hourController = TextEditingController();
  final _roomController = TextEditingController();
  final _yearController = TextEditingController();
  final _branchController = TextEditingController();
  final _levelController = TextEditingController();
  final _gradeController = TextEditingController();
  final _bookController = TextEditingController();
  final _commissionController = TextEditingController();
  final _courseDaysController = TextEditingController();
  final _period1DaysController = TextEditingController();
  final _period2DaysController = TextEditingController();
  final _period3DaysController = TextEditingController();

  String _status = 'active';
  String _shift = '';
  bool _isArchived = false;
  bool _isSaving = false;
  bool _isLoadingClassroom = false;
  bool _loadFailed = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  bool get _isEditing => widget.classroom != null || widget.classroomId != null;

  String? get _editingId => widget.classroom?.id ?? widget.classroomId;

  @override
  void initState() {
    super.initState();
    final classroom = widget.classroom;
    if (classroom != null) {
      _applyClassroom(classroom);
    } else if (widget.classroomId != null) {
      _isLoadingClassroom = true;
      _loadClassroom();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _roomController.dispose();
    _yearController.dispose();
    _branchController.dispose();
    _levelController.dispose();
    _gradeController.dispose();
    _bookController.dispose();
    _commissionController.dispose();
    _courseDaysController.dispose();
    _period1DaysController.dispose();
    _period2DaysController.dispose();
    _period3DaysController.dispose();
    super.dispose();
  }

  Future<void> _loadClassroom() async {
    try {
      final classroom =
          await ref.read(classroomDetailProvider(widget.classroomId!).future);
      if (!mounted) return;
      setState(() {
        _applyClassroom(classroom);
        _isLoadingClassroom = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingClassroom = false;
        _loadFailed = true;
        _error = context.l10n.classroomsDetailLoadError;
      });
    }
  }

  void _applyClassroom(ClassroomModel classroom) {
    _nameController.text = classroom.name;
    _descriptionController.text = classroom.description;
    _dayController.text = classroom.day;
    _hourController.text = classroom.hour;
    _roomController.text = classroom.room;
    _yearController.text = classroom.year;
    _branchController.text = classroom.branch;
    _levelController.text = classroom.level;
    _gradeController.text = classroom.grade;
    _bookController.text = classroom.book;
    _commissionController.text = classroom.commission;
    _courseDaysController.text =
        classroom.courseDays > 0 ? '${classroom.courseDays}' : '';
    _period1DaysController.text =
        classroom.period1Days > 0 ? '${classroom.period1Days}' : '';
    _period2DaysController.text =
        classroom.period2Days > 0 ? '${classroom.period2Days}' : '';
    _period3DaysController.text =
        classroom.period3Days > 0 ? '${classroom.period3Days}' : '';
    _status = _normalizeStatus(classroom.status);
    _shift = _normalizeShift(classroom.shift);
    _isArchived = classroom.isArchived;
  }

  String _normalizeStatus(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'active';
    if (normalized == 'active' || normalized == 'inactive') return normalized;
    // Some records store the status in Spanish.
    if (normalized == 'activo' || normalized == 'activa') return 'active';
    if (normalized == 'inactivo' || normalized == 'inactiva') return 'inactive';
    return value.trim();
  }

  String _normalizeShift(String value) {
    switch (value.trim().toLowerCase()) {
      case 'morning':
      case 'mañana':
        return 'morning';
      case 'afternoon':
      case 'tarde':
        return 'afternoon';
      case 'night':
      case 'noche':
        return 'night';
      default:
        return value.trim();
    }
  }

  List<String> _optionsWithCurrent(
    List<String> canonical,
    String current,
  ) {
    if (current.isEmpty || canonical.contains(current)) return canonical;
    return [...canonical, current];
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'active':
        return context.l10n.classroomsStatusActive;
      case 'inactive':
        return context.l10n.classroomsStatusInactive;
      default:
        return value;
    }
  }

  String _shiftLabel(String value) {
    switch (value) {
      case 'morning':
        return context.l10n.classroomsShiftMorning;
      case 'afternoon':
        return context.l10n.classroomsShiftAfternoon;
      case 'night':
        return context.l10n.classroomsShiftNight;
      default:
        return value;
    }
  }

  void _clearFieldError(String key) {
    if (!_fieldErrors.containsKey(key)) return;
    setState(() {
      _fieldErrors = Map.of(_fieldErrors)..remove(key);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;

    final l10n = context.l10n;
    setState(() {
      _isSaving = true;
      _error = null;
      _fieldErrors = {};
    });

    final repository = ref.read(classroomRepositoryProvider);
    try {
      final saved = _isEditing
          ? await repository.updateClassroom(
              _editingId!,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              status: _status,
              shift: _shift,
              day: _dayController.text.trim(),
              hour: _hourController.text.trim(),
              room: _roomController.text.trim(),
              year: _yearController.text.trim(),
              branch: _branchController.text.trim(),
              level: _levelController.text.trim(),
              grade: _gradeController.text.trim(),
              book: _bookController.text.trim(),
              commission: _commissionController.text.trim(),
              courseDays: _courseDaysController.text.trim(),
              period1Days: _period1DaysController.text.trim(),
              period2Days: _period2DaysController.text.trim(),
              period3Days: _period3DaysController.text.trim(),
              isArchived: _isArchived,
            )
          : await repository.createClassroom(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              status: _status,
              shift: _shift,
              day: _dayController.text.trim(),
              hour: _hourController.text.trim(),
              room: _roomController.text.trim(),
              year: _yearController.text.trim(),
              branch: _branchController.text.trim(),
              level: _levelController.text.trim(),
              grade: _gradeController.text.trim(),
              book: _bookController.text.trim(),
              commission: _commissionController.text.trim(),
              courseDays: _courseDaysController.text.trim(),
              period1Days: _period1DaysController.text.trim(),
              period2Days: _period2DaysController.text.trim(),
              period3Days: _period3DaysController.text.trim(),
              isArchived: _isArchived,
            );
      if (!mounted) return;
      final id = _isEditing ? _editingId! : saved.id;
      ref.invalidate(classroomListProvider);
      ref.invalidate(classroomDetailProvider(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? l10n.classroomsUpdated : l10n.classroomsCreated,
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _fieldErrors = Map.of(e.fieldErrors);
        _error = l10n.commonSaveError;
      });
      _formKey.currentState?.validate();
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = l10n.commonSaveError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = l10n.commonSaveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: EntityFormScreen(
        title: _isEditing
            ? l10n.classroomsFormEditTitle
            : l10n.classroomsFormCreateTitle,
        saveLabel: l10n.commonSave,
        onSave: _isLoadingClassroom || _loadFailed || _isSaving ? null : _save,
        isSaving: _isSaving,
        error: _error,
        children: [
          if (_isLoadingClassroom)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SectionHeader(
              title: l10n.classroomsSectionData,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _field(
              key: const Key('classroom-form-name'),
              controller: _nameController,
              label: l10n.classroomsName,
              errorKey: 'name',
              isRequired: true,
            ),
            _field(
              key: const Key('classroom-form-description'),
              controller: _descriptionController,
              label: l10n.classroomsDescription,
              errorKey: 'description',
            ),
            _dropdown(
              key: const Key('classroom-form-status'),
              label: l10n.classroomsStatus,
              value: _status,
              canonical: _statuses,
              labelFor: _statusLabel,
              errorKey: 'status',
              onChanged: (value) => setState(() => _status = value),
            ),
            _dropdown(
              key: const Key('classroom-form-shift'),
              label: l10n.classroomsShift,
              value: _shift,
              canonical: _shifts,
              labelFor: _shiftLabel,
              errorKey: 'shift',
              onChanged: (value) => setState(() => _shift = value),
            ),
            SwitchListTile(
              key: const Key('classroom-form-archived'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.classroomsFormArchived),
              value: _isArchived,
              onChanged: (value) => setState(() => _isArchived = value),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: l10n.classroomsSectionSchedule,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _field(
              key: const Key('classroom-form-day'),
              controller: _dayController,
              label: l10n.classroomsDay,
              errorKey: 'day',
            ),
            _field(
              key: const Key('classroom-form-hour'),
              controller: _hourController,
              label: l10n.classroomsHour,
              errorKey: 'hour',
            ),
            _field(
              key: const Key('classroom-form-room'),
              controller: _roomController,
              label: l10n.classroomsRoom,
              errorKey: 'room',
            ),
            _field(
              key: const Key('classroom-form-branch'),
              controller: _branchController,
              label: l10n.classroomsBranch,
              errorKey: 'branch',
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: l10n.classroomsSectionAcademic,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _field(
              key: const Key('classroom-form-year'),
              controller: _yearController,
              label: l10n.classroomsYear,
              errorKey: 'year',
            ),
            _field(
              key: const Key('classroom-form-level'),
              controller: _levelController,
              label: l10n.classroomsLevel,
              errorKey: 'level',
            ),
            _field(
              key: const Key('classroom-form-grade'),
              controller: _gradeController,
              label: l10n.classroomsGrade,
              errorKey: 'grade',
            ),
            _field(
              key: const Key('classroom-form-book'),
              controller: _bookController,
              label: l10n.classroomsBook,
              errorKey: 'book',
            ),
            _field(
              key: const Key('classroom-form-commission'),
              controller: _commissionController,
              label: l10n.classroomsCommission,
              errorKey: 'commission',
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: l10n.classroomsSectionPeriods,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            _field(
              key: const Key('classroom-form-course-days'),
              controller: _courseDaysController,
              label: l10n.classroomsCourseDays,
              errorKey: 'course_days',
              keyboardType: TextInputType.number,
            ),
            _field(
              key: const Key('classroom-form-period-1-days'),
              controller: _period1DaysController,
              label: l10n.classroomsFormPeriod1Days,
              errorKey: 'period_1_days',
              keyboardType: TextInputType.number,
            ),
            _field(
              key: const Key('classroom-form-period-2-days'),
              controller: _period2DaysController,
              label: l10n.classroomsFormPeriod2Days,
              errorKey: 'period_2_days',
              keyboardType: TextInputType.number,
            ),
            _field(
              key: const Key('classroom-form-period-3-days'),
              controller: _period3DaysController,
              label: l10n.classroomsFormPeriod3Days,
              errorKey: 'period_3_days',
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String errorKey,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (isRequired) {
            final required = AppValidators.required(
              value,
              context.l10n,
              label,
            );
            if (required != null) return required;
          }
          return _fieldErrors[errorKey];
        },
        onChanged: (_) => _clearFieldError(errorKey),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _dropdown({
    required Key key,
    required String label,
    required String value,
    required List<String> canonical,
    required String Function(String) labelFor,
    required String errorKey,
    required ValueChanged<String> onChanged,
  }) {
    final options = _optionsWithCurrent(canonical, value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        key: key,
        initialValue: value.isEmpty ? null : value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(labelFor(option)),
            ),
        ],
        validator: (_) => _fieldErrors[errorKey],
        onChanged: (selected) {
          if (selected == null) return;
          _clearFieldError(errorKey);
          onChanged(selected);
        },
      ),
    );
  }
}
