import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/upload_file.dart';
import '../../../../core/widgets/form_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/document_model.dart';
import '../../providers/document_provider.dart';

/// Extensiones aceptadas por el backend para el archivo de un documento.
const documentFileExtensions = <String>[
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'png',
  'jpg',
  'jpeg',
  'webp',
];

class DocumentFormSheet extends ConsumerStatefulWidget {
  /// `null` crea un documento; con valor, lo edita.
  final DocumentModel? document;

  /// Picker inyectable para tests; por defecto abre el selector de archivos.
  final Future<UploadFile?> Function()? pickFile;

  const DocumentFormSheet({super.key, required this.document, this.pickFile});

  @override
  ConsumerState<DocumentFormSheet> createState() => _DocumentFormSheetState();
}

class _DocumentFormSheetState extends ConsumerState<DocumentFormSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final Future<UploadFile?> Function() _pickFile =
      widget.pickFile ?? _defaultPickFile;

  UploadFile? _file;
  bool _isSaving = false;

  String? _titleError;
  String? _descriptionError;
  String? _fileError;
  String? _generalError;

  bool get _isEdit => widget.document != null;

  @override
  void initState() {
    super.initState();
    final document = widget.document;
    if (document != null) {
      _titleController.text = document.title;
      _descriptionController.text = document.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<UploadFile?> _defaultPickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: documentFileExtensions,
      allowMultiple: false,
      withData: kIsWeb,
    );
    final files = result?.files ?? const [];
    if (files.isEmpty) return null;
    final file = files.first;
    return UploadFile(
      name: file.name,
      size: file.size,
      path: file.path,
      bytes: file.bytes,
    );
  }

  Future<void> _pickFileAction() async {
    final picked = await _pickFile();
    if (picked == null || !mounted) return;
    setState(() {
      _file = picked;
      _fileError = null;
      _generalError = null;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final title = _titleController.text.trim();

    final titleError = title.isEmpty ? l10n.commonFormRequired : null;

    setState(() {
      _titleError = titleError;
      _generalError = null;
    });
    if (titleError != null) return;

    setState(() => _isSaving = true);

    final repository = ref.read(documentRepositoryProvider);
    final description = _descriptionController.text.trim();
    try {
      if (_isEdit) {
        await repository.updateDocument(
          widget.document!.id,
          title: title,
          description: description,
          file: _file,
        );
      } else {
        await repository.createDocument(
          title: title,
          description: description,
          file: _file,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _titleError = e.fieldErrors['title'] ?? _titleError;
        _descriptionError = e.fieldErrors['description'];
        _fileError = e.fieldErrors['file'];
        _generalError =
            _hasOnlyFieldErrors(e) ? null : (e.detail ?? l10n.commonSaveError);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _generalError = e.detail ?? l10n.commonSaveError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _generalError = l10n.commonSaveError;
      });
    }
  }

  bool _hasOnlyFieldErrors(ValidationException e) {
    const known = {'title', 'description', 'file'};
    return e.fieldErrors.isNotEmpty && e.fieldErrors.keys.every(known.contains);
  }

  String? get _existingFileName {
    final document = widget.document;
    if (document == null) return null;
    final raw = document.mediaUrls.isNotEmpty
        ? document.mediaUrls.first
        : document.fileUrl;
    if (raw.isEmpty) return null;
    final segments = Uri.tryParse(raw)?.pathSegments ?? const [];
    if (segments.isEmpty) return raw;
    return segments.last;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final existingFileName = _existingFileName;

    return FormSheet(
      title:
          _isEdit ? l10n.documentFormEditTitle : l10n.documentFormCreateTitle,
      saveLabel: l10n.commonSave,
      onSave: _submit,
      isSaving: _isSaving,
      error: _generalError,
      children: [
        _FieldLabel(label: l10n.documentFormTitle),
        TextField(
          key: const Key('document-title-field'),
          controller: _titleController,
          decoration: _inputDecoration().copyWith(errorText: _titleError),
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.documentFormDescription),
        TextField(
          key: const Key('document-description-field'),
          controller: _descriptionController,
          maxLines: 3,
          decoration: _inputDecoration().copyWith(errorText: _descriptionError),
          onChanged: (_) {
            if (_descriptionError != null) {
              setState(() => _descriptionError = null);
            }
          },
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.documentFormFile),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('document-pick-file'),
            onPressed: _isSaving ? null : _pickFileAction,
            icon: const Icon(Icons.attach_file, size: 18),
            label: Text(l10n.documentFormPickFile),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.documentFormFileHint,
          style: AppTypography.labelSmall.copyWith(color: AppColors.muted),
        ),
        if (_file != null) ...[
          const SizedBox(height: 6),
          Text(
            _file!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ] else if (existingFileName != null) ...[
          const SizedBox(height: 6),
          Text(
            existingFileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ],
        if (_fileError != null) ...[
          const SizedBox(height: 4),
          Text(
            _fileError!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
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
