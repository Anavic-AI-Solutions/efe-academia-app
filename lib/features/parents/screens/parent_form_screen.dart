import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/entity_form_screen.dart';
import '../../../l10n/l10n.dart';
import '../../students/providers/student_provider.dart';
import '../domain/parent_model.dart';
import '../providers/parent_provider.dart';
import 'widgets/parent_card.dart';

/// Full screen create/edit form for parents.
///
/// Creation is used when neither [parent] nor [parentId] is provided. When
/// only [parentId] is provided the parent is loaded through
/// [parentDetailProvider].
class ParentFormScreen extends ConsumerStatefulWidget {
  const ParentFormScreen({
    super.key,
    this.parent,
    this.parentId,
  });

  final ParentModel? parent;
  final String? parentId;

  @override
  ConsumerState<ParentFormScreen> createState() => _ParentFormScreenState();
}

class _ParentFormScreenState extends ConsumerState<ParentFormScreen> {
  static const _statuses = ['pending', 'approved', 'rejected'];

  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _identityController = TextEditingController();

  String _status = 'pending';
  bool _isSaving = false;
  bool _isLoadingParent = false;
  bool _loadFailed = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  bool get _isEditing => widget.parent != null || widget.parentId != null;

  String? get _editingId => widget.parent?.id ?? widget.parentId;

  @override
  void initState() {
    super.initState();
    final parent = widget.parent;
    if (parent != null) {
      _applyParent(parent);
    } else if (widget.parentId != null) {
      _isLoadingParent = true;
      _loadParent();
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _loadParent() async {
    try {
      final parent =
          await ref.read(parentDetailProvider(widget.parentId!).future);
      if (!mounted) return;
      setState(() {
        _applyParent(parent);
        _isLoadingParent = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingParent = false;
        _loadFailed = true;
        _error = context.l10n.parentsLoadError;
      });
    }
  }

  void _applyParent(ParentModel parent) {
    _fullnameController.text = parent.fullname;
    _emailController.text = parent.email;
    _phoneController.text = parent.phone;
    _addressController.text = parent.address;
    _identityController.text = parent.identityNumber;
    _status = _statuses.contains(parent.status) ? parent.status : 'pending';
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
      l10n.parentsFormEmail,
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

    final repository = ref.read(parentRepositoryProvider);
    final fullname = _fullnameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final identityNumber = _identityController.text.trim();

    try {
      if (_isEditing) {
        await repository.updateParent(
          _editingId!,
          fullname: fullname,
          email: email,
          phone: phone,
          address: address,
          identityNumber: identityNumber,
          status: _status,
        );
      } else {
        await repository.createParent(
          fullname: fullname,
          email: email,
          phone: phone,
          address: address,
          identityNumber: identityNumber,
          status: _status,
        );
      }
      if (!mounted) return;
      ref.invalidate(studentParentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? l10n.parentsUpdated : l10n.parentsCreated,
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
            ? l10n.parentsFormEditTitle
            : l10n.parentsFormCreateTitle,
        saveLabel: l10n.commonSave,
        onSave: _isLoadingParent || _loadFailed || _isSaving ? null : _save,
        isSaving: _isSaving,
        error: _error,
        children: [
          if (_isLoadingParent)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _field(
              key: const Key('parent-form-fullname'),
              controller: _fullnameController,
              label: l10n.parentsFormFullname,
              validator: (value) => _required(
                'fullname',
                value,
                l10n.parentsFormFullname,
              ),
              onChanged: (_) => _clearFieldError('fullname'),
            ),
            _field(
              key: const Key('parent-form-email'),
              controller: _emailController,
              label: l10n.parentsFormEmail,
              validator: _validateEmail,
              onChanged: (_) => _clearFieldError('email'),
              keyboardType: TextInputType.emailAddress,
            ),
            _field(
              key: const Key('parent-form-phone'),
              controller: _phoneController,
              label: l10n.parentsFormPhone,
              validator: (value) => _fieldErrors['phone'],
              onChanged: (_) => _clearFieldError('phone'),
              keyboardType: TextInputType.phone,
            ),
            _field(
              key: const Key('parent-form-address'),
              controller: _addressController,
              label: l10n.parentsFormAddress,
              validator: (value) => _fieldErrors['address'],
              onChanged: (_) => _clearFieldError('address'),
            ),
            _field(
              key: const Key('parent-form-identity'),
              controller: _identityController,
              label: l10n.parentsFormIdentity,
              validator: (value) => _required(
                'identity_number',
                value,
                l10n.parentsFormIdentity,
              ),
              onChanged: (_) => _clearFieldError('identity_number'),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                key: const Key('parent-form-status'),
                initialValue: _status,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.parentsFormStatus,
                ),
                items: [
                  for (final status in _statuses)
                    DropdownMenuItem(
                      value: status,
                      child: Text(parentStatusLabel(status, l10n)),
                    ),
                ],
                validator: (value) => _fieldErrors['status'],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _status = value;
                    _fieldErrors = Map.of(_fieldErrors)..remove('status');
                  });
                },
              ),
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
