import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/entity_form_screen.dart';
import '../../../l10n/l10n.dart';
import '../domain/student_model.dart';
import '../providers/student_provider.dart';

/// Full screen create/edit form for students.
///
/// Creation is used when neither [student] nor [studentId] is provided. When
/// only [studentId] is provided the student is loaded through
/// [studentDetailProvider].
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({
    super.key,
    this.student,
    this.studentId,
  });

  final StudentModel? student;
  final String? studentId;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _yearController = TextEditingController();
  final _branchController = TextEditingController();
  final _identityController = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingStudent = false;
  bool _loadFailed = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  bool get _isEditing => widget.student != null || widget.studentId != null;

  String? get _editingId => widget.student?.id ?? widget.studentId;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    if (student != null) {
      _applyStudent(student);
    } else if (widget.studentId != null) {
      _isLoadingStudent = true;
      _loadStudent();
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _yearController.dispose();
    _branchController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent() async {
    try {
      final student =
          await ref.read(studentDetailProvider(widget.studentId!).future);
      if (!mounted) return;
      setState(() {
        _applyStudent(student);
        _isLoadingStudent = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingStudent = false;
        _loadFailed = true;
        _error = context.l10n.studentsDetailLoadError;
      });
    }
  }

  void _applyStudent(StudentModel student) {
    _fullnameController.text = student.fullname;
    _emailController.text = student.email;
    _yearController.text = student.year;
    _branchController.text = student.branch;
    _identityController.text = student.identityNumber;
  }

  String? _required(String key, String? value, String label) {
    final l10n = context.l10n;
    return AppValidators.required(value, l10n, label) ?? _fieldErrors[key];
  }

  String? _validateEmail(String? value) {
    final l10n = context.l10n;
    final required = AppValidators.required(
      value,
      l10n,
      l10n.studentsFormEmail,
    );
    if (required != null) return required;
    return AppValidators.email(value, l10n) ?? _fieldErrors['email'];
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

    final repository = ref.read(studentRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.updateStudent(
          _editingId!,
          fullname: _fullnameController.text.trim(),
          email: _emailController.text.trim(),
          year: _yearController.text.trim(),
          branch: _branchController.text.trim(),
          identityNumber: _identityController.text.trim(),
        );
      } else {
        await repository.createStudent(
          fullname: _fullnameController.text.trim(),
          email: _emailController.text.trim(),
          year: _yearController.text.trim(),
          branch: _branchController.text.trim(),
          identityNumber: _identityController.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? l10n.studentsUpdated : l10n.studentsCreated,
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
            ? l10n.studentsFormEditTitle
            : l10n.studentsFormCreateTitle,
        saveLabel: l10n.commonSave,
        onSave: _isLoadingStudent || _loadFailed || _isSaving ? null : _save,
        isSaving: _isSaving,
        error: _error,
        children: [
          if (_isLoadingStudent)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _field(
              key: const Key('student-form-fullname'),
              controller: _fullnameController,
              label: l10n.studentsFormFullname,
              validator: (value) => _required(
                'fullname',
                value,
                l10n.studentsFormFullname,
              ),
              onChanged: (_) => _clearFieldError('fullname'),
              textInputAction: TextInputAction.next,
            ),
            _field(
              key: const Key('student-form-email'),
              controller: _emailController,
              label: l10n.studentsFormEmail,
              validator: _validateEmail,
              onChanged: (_) => _clearFieldError('email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            _field(
              key: const Key('student-form-year'),
              controller: _yearController,
              label: l10n.studentsFormYear,
              validator: (value) => _required(
                'year',
                value,
                l10n.studentsFormYear,
              ),
              onChanged: (_) => _clearFieldError('year'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            _field(
              key: const Key('student-form-branch'),
              controller: _branchController,
              label: l10n.studentsFormBranch,
              validator: (value) => _required(
                'branch',
                value,
                l10n.studentsFormBranch,
              ),
              onChanged: (_) => _clearFieldError('branch'),
              textInputAction: TextInputAction.next,
            ),
            _field(
              key: const Key('student-form-identity'),
              controller: _identityController,
              label: l10n.studentsFormIdentity,
              validator: (value) => _required(
                'identity_number',
                value,
                l10n.studentsFormIdentity,
              ),
              onChanged: (_) => _clearFieldError('identity_number'),
              textInputAction: TextInputAction.done,
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
    required FormFieldValidator<String> validator,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
