import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/entity_form_screen.dart';
import '../../../l10n/l10n.dart';
import '../../classrooms/domain/professor_model.dart';
import '../providers/professor_provider.dart';

/// Full screen create/edit form for professors.
///
/// Creation is used when neither [professor] nor [professorId] is provided.
/// When only [professorId] is provided the professor is loaded through
/// [professorDetailProvider].
class ProfessorFormScreen extends ConsumerStatefulWidget {
  const ProfessorFormScreen({
    super.key,
    this.professor,
    this.professorId,
  });

  final ProfessorModel? professor;
  final String? professorId;

  @override
  ConsumerState<ProfessorFormScreen> createState() =>
      _ProfessorFormScreenState();
}

class _ProfessorFormScreenState extends ConsumerState<ProfessorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _identityController = TextEditingController();
  final _bioController = TextEditingController();
  final _specialtyController = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingProfessor = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  bool get _isEditing => widget.professor != null || widget.professorId != null;

  String? get _editingId => widget.professor?.id ?? widget.professorId;

  @override
  void initState() {
    super.initState();
    final professor = widget.professor;
    if (professor != null) {
      _applyProfessor(professor);
    } else if (widget.professorId != null) {
      _isLoadingProfessor = true;
      _loadProfessor();
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _identityController.dispose();
    _bioController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessor() async {
    try {
      final professor =
          await ref.read(professorDetailProvider(widget.professorId!).future);
      if (!mounted) return;
      setState(() {
        _applyProfessor(professor);
        _isLoadingProfessor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfessor = false;
        _error = context.l10n.professorsLoadError;
      });
    }
  }

  void _applyProfessor(ProfessorModel professor) {
    _fullnameController.text = professor.fullname;
    _emailController.text = professor.email;
    _phoneController.text = professor.phone;
    _addressController.text = professor.address;
    _identityController.text = professor.identityNumber;
    _bioController.text = professor.bio;
    _specialtyController.text = professor.specialty;
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
      l10n.professorsFormEmail,
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

    final repository = ref.read(professorRepositoryProvider);
    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final identityNumber = _identityController.text.trim();
    final bio = _bioController.text.trim();
    final specialty = _specialtyController.text.trim();

    try {
      if (_isEditing) {
        await repository.updateProfessor(
          _editingId!,
          fullname: fullname,
          email: email,
          phone: phone,
          address: address,
          identityNumber: identityNumber,
          bio: bio,
          specialty: specialty,
        );
      } else {
        await repository.createProfessor(
          fullname: fullname,
          email: email,
          phone: phone,
          address: address,
          identityNumber: identityNumber,
          bio: bio,
          specialty: specialty,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? l10n.professorsUpdated : l10n.professorsCreated,
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
            ? l10n.professorsFormEditTitle
            : l10n.professorsFormCreateTitle,
        saveLabel: l10n.commonSave,
        onSave: _isLoadingProfessor || _isSaving ? null : _save,
        isSaving: _isSaving,
        error: _error,
        children: [
          if (_isLoadingProfessor)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _field(
              key: const Key('professor-form-fullname'),
              controller: _fullnameController,
              label: l10n.professorsFormFullname,
              validator: (value) => _required(
                'fullname',
                value,
                l10n.professorsFormFullname,
              ),
              onChanged: (_) => _clearFieldError('fullname'),
            ),
            _field(
              key: const Key('professor-form-email'),
              controller: _emailController,
              label: l10n.professorsFormEmail,
              validator: _validateEmail,
              onChanged: (_) => _clearFieldError('email'),
              keyboardType: TextInputType.emailAddress,
            ),
            _field(
              key: const Key('professor-form-phone'),
              controller: _phoneController,
              label: l10n.professorsFormPhone,
              validator: (value) => _fieldErrors['phone'],
              onChanged: (_) => _clearFieldError('phone'),
              keyboardType: TextInputType.phone,
            ),
            _field(
              key: const Key('professor-form-address'),
              controller: _addressController,
              label: l10n.professorsFormAddress,
              validator: (value) => _fieldErrors['address'],
              onChanged: (_) => _clearFieldError('address'),
            ),
            _field(
              key: const Key('professor-form-identity'),
              controller: _identityController,
              label: l10n.professorsFormIdentity,
              validator: (value) => _required(
                'identity_number',
                value,
                l10n.professorsFormIdentity,
              ),
              onChanged: (_) => _clearFieldError('identity_number'),
            ),
            _field(
              key: const Key('professor-form-bio'),
              controller: _bioController,
              label: l10n.professorsFormBio,
              validator: (value) => _fieldErrors['bio'],
              onChanged: (_) => _clearFieldError('bio'),
              maxLines: 3,
            ),
            _field(
              key: const Key('professor-form-specialty'),
              controller: _specialtyController,
              label: l10n.professorsFormSpecialty,
              validator: (value) => _fieldErrors['specialty'],
              onChanged: (_) => _clearFieldError('specialty'),
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
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
