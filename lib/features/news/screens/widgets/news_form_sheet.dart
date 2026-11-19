import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/upload_file.dart';
import '../../../../core/widgets/form_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/news_model.dart';
import '../../providers/news_provider.dart';

class NewsFormSheet extends ConsumerStatefulWidget {
  /// `null` crea una noticia; con valor, la edita.
  final NewsModel? news;

  /// Picker inyectable para tests; por defecto abre el selector de imágenes.
  final Future<UploadFile?> Function()? pickImage;

  const NewsFormSheet({super.key, required this.news, this.pickImage});

  @override
  ConsumerState<NewsFormSheet> createState() => _NewsFormSheetState();
}

class _NewsFormSheetState extends ConsumerState<NewsFormSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  late final Future<UploadFile?> Function() _pickImage =
      widget.pickImage ?? _defaultPickImage;

  DateTime? _eventDate;
  UploadFile? _image;
  bool _isSaving = false;

  String? _titleError;
  String? _descriptionError;
  String? _contentError;
  String? _eventDateError;
  String? _generalError;

  bool get _isEdit => widget.news != null;

  @override
  void initState() {
    super.initState();
    final news = widget.news;
    if (news != null) {
      _titleController.text = news.title;
      _descriptionController.text = news.description;
      _contentController.text = news.content;
      _eventDate = news.eventDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<UploadFile?> _defaultPickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
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

  Future<void> _pickImageAction() async {
    final picked = await _pickImage();
    if (picked == null || !mounted) return;
    setState(() {
      _image = picked;
      _generalError = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _eventDate = picked;
      _eventDateError = null;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    final titleError = title.isEmpty ? l10n.commonFormRequired : _titleError;
    final contentError =
        content.isEmpty ? l10n.commonFormRequired : _contentError;

    setState(() {
      _titleError = titleError;
      _contentError = contentError;
      _generalError = null;
    });
    if (titleError != null || contentError != null) return;

    setState(() => _isSaving = true);

    final repository = ref.read(newsRepositoryProvider);
    final description = _descriptionController.text.trim();
    try {
      if (_isEdit) {
        await repository.updateNews(
          widget.news!.id,
          title: title,
          description: description,
          content: content,
          eventDate: _eventDate,
          image: _image,
        );
      } else {
        await repository.createNews(
          title: title,
          description: description,
          content: content,
          eventDate: _eventDate,
          image: _image,
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
        _contentError = e.fieldErrors['content'] ?? _contentError;
        _eventDateError = e.fieldErrors['event_date'];
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
    const known = {'title', 'description', 'content', 'event_date'};
    return e.fieldErrors.isNotEmpty && e.fieldErrors.keys.every(known.contains);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final existingImage = widget.news?.mediaUrls.isNotEmpty == true
        ? widget.news!.mediaUrls.first
        : null;

    return FormSheet(
      title: _isEdit ? l10n.newsFormEditTitle : l10n.newsFormCreateTitle,
      saveLabel: l10n.commonSave,
      onSave: _submit,
      isSaving: _isSaving,
      error: _generalError,
      children: [
        _FieldLabel(label: l10n.newsFormTitle),
        TextField(
          key: const Key('news-title-field'),
          controller: _titleController,
          decoration: _inputDecoration().copyWith(errorText: _titleError),
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.newsFormDescription),
        TextField(
          key: const Key('news-description-field'),
          controller: _descriptionController,
          maxLines: 2,
          decoration: _inputDecoration().copyWith(errorText: _descriptionError),
          onChanged: (_) {
            if (_descriptionError != null) {
              setState(() => _descriptionError = null);
            }
          },
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.newsFormContent),
        TextField(
          key: const Key('news-content-field'),
          controller: _contentController,
          maxLines: 5,
          decoration: _inputDecoration().copyWith(errorText: _contentError),
          onChanged: (_) {
            if (_contentError != null) setState(() => _contentError = null);
          },
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.newsFormDate),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('news-date-button'),
            onPressed: _isSaving ? null : _pickDate,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _eventDate == null
                  ? l10n.newsFormDate
                  : AppFormatters.formatDate(_eventDate!),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        if (_eventDateError != null)
          Text(
            _eventDateError!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.newsFormImage),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('news-pick-image'),
            onPressed: _isSaving ? null : _pickImageAction,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text(l10n.newsFormPickImage),
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
          l10n.newsFormImageHint,
          style: AppTypography.labelSmall.copyWith(color: AppColors.muted),
        ),
        if (_image != null) ...[
          const SizedBox(height: 6),
          Text(
            _image!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ] else if (existingImage != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              existingImage,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
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
