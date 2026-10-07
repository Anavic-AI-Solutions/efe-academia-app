import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../students/domain/student_model.dart';
import '../../domain/material_model.dart';
import '../../domain/material_type.dart';
import '../../domain/material_upload_file.dart';
import '../../providers/material_provider.dart';

/// Categorías de material definidas en el backend (`Material::CATEGORIES`).
const materialCategories = [
  'Vocabulario',
  'Gramática',
  'Exámenes',
  'Tareas',
  'Audio',
  'Otro',
];

const maxMaterialFiles = 10;
const maxMaterialFileBytes = 50 * 1024 * 1024;

class MaterialFormSheet extends ConsumerStatefulWidget {
  final String classroomId;

  /// Si es `null` el sheet crea un material nuevo; si no, lo edita.
  final MaterialModel? material;

  /// Picker inyectable para tests; por defecto usa [FilePicker.platform].
  final Future<List<MaterialUploadFile>> Function()? pickFiles;

  const MaterialFormSheet({
    super.key,
    required this.classroomId,
    this.material,
    this.pickFiles,
  });

  @override
  ConsumerState<MaterialFormSheet> createState() => _MaterialFormSheetState();
}

class _MaterialFormSheetState extends ConsumerState<MaterialFormSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final Future<List<MaterialUploadFile>> Function() _pickFiles =
      widget.pickFiles ?? _defaultPickFiles;

  String? _category;
  List<MaterialUploadFile> _files = [];
  String _visibility = 'all';
  final Set<String> _studentIds = {};
  DateTime? _availableUntil;

  List<StudentModel>? _students;
  bool _studentsLoading = false;
  String? _studentsLoadError;

  String? _nameError;
  String? _filesError;
  String? _studentsError;
  String? _submitError;
  bool _isSaving = false;

  bool _loadingDetail = false;
  String? _detailError;
  bool _detailTriggered = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.material != null && !_detailTriggered) {
      _detailTriggered = true;
      _loadDetail();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<List<MaterialUploadFile>> _defaultPickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result == null) return const [];
    return result.files
        .map(
          (file) => MaterialUploadFile(
            name: file.name,
            size: file.size,
            path: file.path,
            bytes: file.bytes,
          ),
        )
        .toList();
  }

  Future<void> _loadDetail() async {
    final detailError = context.l10n.materialFormDetailError;
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });
    try {
      final detail = await ref
          .read(materialRepositoryProvider)
          .getMaterial(widget.material!.id);
      if (!mounted) return;
      setState(() {
        _nameController.text = detail.name;
        _descriptionController.text = detail.description;
        _category = detail.category.isEmpty ? null : detail.category;
        _visibility = detail.visibility.isEmpty ? 'all' : detail.visibility;
        _studentIds
          ..clear()
          ..addAll(detail.studentIds);
        _availableUntil = DateTime.tryParse(detail.availableUntil);
        _loadingDetail = false;
      });
      if (_visibility == 'specific') {
        _loadStudentsIfNeeded();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _detailError = detailError;
      });
    }
  }

  void _loadStudentsIfNeeded() {
    if (_students != null || _studentsLoading) return;
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final loadError = context.l10n.materialFormDetailError;
    setState(() {
      _studentsLoading = true;
      _studentsLoadError = null;
    });
    try {
      final students = await ref
          .read(materialRepositoryProvider)
          .getClassroomStudents(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _students = students;
        _studentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _studentsLoading = false;
        _studentsLoadError = loadError;
      });
    }
  }

  void _onVisibilityChanged(String value) {
    setState(() {
      _visibility = value;
      _studentsError = null;
    });
    if (value == 'specific') {
      _loadStudentsIfNeeded();
    }
  }

  Future<void> _pickFilesAction() async {
    final picked = await _pickFiles();
    if (picked.isEmpty) return;
    setState(() {
      _files = picked;
      _filesError = _validatePickedFiles(picked);
    });
  }

  String? _validatePickedFiles(List<MaterialUploadFile> files) {
    if (files.length > maxMaterialFiles) {
      return context.l10n.materialFormFilesTooMany;
    }
    if (files.any((file) => file.size > maxMaterialFileBytes)) {
      return context.l10n.materialFormFileTooLarge;
    }
    return null;
  }

  Future<void> _pickAvailableUntil() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _availableUntil ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 1095)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_availableUntil ?? now),
    );
    if (time == null) return;
    setState(() {
      _availableUntil =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final filesError = _files.isEmpty
        ? (widget.material == null ? l10n.materialFormFilesRequired : null)
        : _validatePickedFiles(_files);
    final studentsError = _visibility == 'specific' && _studentIds.isEmpty
        ? l10n.materialFormStudentsRequired
        : null;

    setState(() {
      _nameError = name.isEmpty ? l10n.materialFormNameRequired : null;
      _filesError = filesError;
      _studentsError = studentsError;
    });
    if (name.isEmpty || filesError != null || studentsError != null) return;

    setState(() {
      _submitError = null;
      _isSaving = true;
    });

    final repository = ref.read(materialRepositoryProvider);
    final material = widget.material;
    final type = _files.isNotEmpty ? materialTypeFor(_files.first.name) : null;
    try {
      if (material == null) {
        await repository.createMaterial(
          classroomId: widget.classroomId,
          name: name,
          description: _descriptionController.text.trim(),
          type: type,
          category: _category,
          visibility: _visibility,
          availableUntil: _availableUntil?.toIso8601String(),
          studentIds: _studentIds.toList(),
          files: _files,
        );
      } else {
        await repository.updateMaterial(
          material.id,
          name: name,
          description: _descriptionController.text.trim(),
          type: type,
          category: _category,
          visibility: _visibility,
          availableUntil: _availableUntil?.toIso8601String(),
          studentIds: _visibility == 'specific' ? _studentIds.toList() : null,
        );
        if (_files.isNotEmpty) {
          await repository.replaceFiles(material.id, files: _files);
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _submitError = l10n.materialFormError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightInk;

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
                widget.material == null
                    ? l10n.materialFormTitleNew
                    : l10n.materialFormTitleEdit,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingDetail)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_detailError != null)
                _LoadError(
                  message: _detailError!,
                  onRetry: _loadDetail,
                )
              else ...[
                _buildBody(l10n),
                if (_submitError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.materialFormError,
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
                            l10n.materialFormSave,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: l10n.materialFormName),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration().copyWith(errorText: _nameError),
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.materialFormCategory),
        DropdownButtonFormField<String>(
          value: _category,
          isExpanded: true,
          hint: Text(l10n.materialFormCategory),
          decoration: _inputDecoration(),
          items: materialCategories
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.materialFormDescription),
        TextField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.materialFormFiles),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _pickFilesAction,
            icon: const Icon(Icons.attach_file, size: 18),
            label: Text(l10n.materialFormPickFiles),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._files.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    _formatSize(file.size),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_filesError != null)
          Text(
            _filesError!,
            style: const TextStyle(fontSize: 12, color: AppColors.absent),
          ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.materialFormVisibility),
        Row(
          children: [
            ChoiceChip(
              label: Text(l10n.materialFormVisibilityAll),
              selected: _visibility == 'all',
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _visibility == 'all' ? Colors.white : null,
              ),
              onSelected: (_) => _onVisibilityChanged('all'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.materialFormVisibilitySpecific),
              selected: _visibility == 'specific',
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _visibility == 'specific' ? Colors.white : null,
              ),
              onSelected: (_) => _onVisibilityChanged('specific'),
            ),
          ],
        ),
        if (_visibility == 'specific') ...[
          const SizedBox(height: 10),
          if (_studentsLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (_studentsLoadError != null)
            _LoadError(message: _studentsLoadError!, onRetry: _loadStudents)
          else if (_students != null && _students!.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.materialFormStudentsRequired,
              style: const TextStyle(fontSize: 12, color: AppColors.absent),
            ),
          ] else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final student in _students ?? const <StudentModel>[])
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        student.fullname,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: _studentIds.contains(student.id),
                      onChanged: _isSaving
                          ? null
                          : (checked) => setState(() {
                                if (checked ?? false) {
                                  _studentIds.add(student.id);
                                } else {
                                  _studentIds.remove(student.id);
                                }
                              }),
                    ),
                ],
              ),
            ),
          ],
          if (_studentsError != null)
            Text(
              _studentsError!,
              style: const TextStyle(fontSize: 12, color: AppColors.absent),
            ),
        ],
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.materialFormAvailableUntil),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _pickAvailableUntil,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _availableUntil == null
                      ? l10n.materialFormAvailableUntil
                      : AppFormatters.formatDateTime(_availableUntil!),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            if (_availableUntil != null)
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _availableUntil = null),
                child: Text(
                  l10n.materialFormClearDate,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
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

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: AppColors.absent),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
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
