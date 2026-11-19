import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/event_model.dart';
import '../../providers/event_provider.dart';

/// Paleta de 6 colores disponibles para un evento.
const eventColorPalette = <int>[
  0xFF3B82F6,
  0xFF10B981,
  0xFFF59E0B,
  0xFFEF4444,
  0xFF8B5CF6,
  0xFFEC4899,
];

class EventFormSheet extends ConsumerStatefulWidget {
  /// `null` crea un evento; con valor, lo edita.
  final EventModel? event;

  /// Picker inyectable para tests; por defecto abre fecha + hora del sistema.
  final Future<DateTime?> Function(DateTime initial)? pickDateTime;

  const EventFormSheet({super.key, required this.event, this.pickDateTime});

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  late int _color;

  bool _isSaving = false;

  String? _titleError;
  String? _descriptionError;
  String? _startError;
  String? _endError;
  String? _rangeError;
  String? _generalError;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _start = event.start ?? _defaultStart();
      _end = event.end ?? _start.add(const Duration(hours: 1));
      _color = event.color;
    } else {
      _start = _defaultStart();
      _end = _start.add(const Duration(hours: 1));
      _color = eventColorPalette.first;
    }
  }

  /// Próxima hora en punto, para que el rango inicial sea siempre válido.
  static DateTime _defaultStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDefault(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final picked = await (widget.pickDateTime ?? _pickDefault)(_start);
    if (picked == null || !mounted) return;
    setState(() {
      _start = picked;
      _startError = null;
      _rangeError = null;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await (widget.pickDateTime ?? _pickDefault)(_end);
    if (picked == null || !mounted) return;
    setState(() {
      _end = picked;
      _endError = null;
      _rangeError = null;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final title = _titleController.text.trim();

    final titleError = title.isEmpty ? l10n.commonFormRequired : null;
    final rangeError = _end.isAfter(_start) ? null : l10n.eventFormInvalidRange;

    setState(() {
      _titleError = titleError;
      _descriptionError = null;
      _rangeError = rangeError;
      _startError = null;
      _endError = null;
      _generalError = null;
    });
    if (titleError != null || rangeError != null) return;

    setState(() => _isSaving = true);

    final repository = ref.read(eventRepositoryProvider);
    final description = _descriptionController.text.trim();
    try {
      if (_isEdit) {
        await repository.updateEvent(
          widget.event!.id,
          title: title,
          description: description,
          start: _start,
          end: _end,
          color: _color,
        );
      } else {
        await repository.createEvent(
          title: title,
          description: description,
          start: _start,
          end: _end,
          color: _color,
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
        _startError = e.fieldErrors['start_date'];
        _endError = e.fieldErrors['end_date'];
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
    const known = {'title', 'description', 'start_date', 'end_date'};
    return e.fieldErrors.isNotEmpty && e.fieldErrors.keys.every(known.contains);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormSheet(
      title: _isEdit ? l10n.eventFormEditTitle : l10n.eventFormCreateTitle,
      saveLabel: l10n.commonSave,
      onSave: _submit,
      isSaving: _isSaving,
      error: _generalError,
      children: [
        _FieldLabel(label: l10n.eventFormTitle),
        TextField(
          key: const Key('event-title-field'),
          controller: _titleController,
          decoration: _inputDecoration().copyWith(errorText: _titleError),
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.eventFormDescription),
        TextField(
          key: const Key('event-description-field'),
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
        _FieldLabel(label: l10n.eventFormStart),
        _DateTimeButton(
          key: const Key('event-start-button'),
          value: _start,
          enabled: !_isSaving,
          onTap: _pickStart,
        ),
        if (_startError != null) _ErrorText(message: _startError!),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.eventFormEnd),
        _DateTimeButton(
          key: const Key('event-end-button'),
          value: _end,
          enabled: !_isSaving,
          onTap: _pickEnd,
        ),
        if (_endError != null) _ErrorText(message: _endError!),
        if (_rangeError != null) _ErrorText(message: _rangeError!),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.eventFormColor),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final color in eventColorPalette)
              GestureDetector(
                key: Key('event-color-$color'),
                onTap: _isSaving
                    ? null
                    : () => setState(() {
                          _color = color;
                          _generalError = null;
                        }),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color == color
                          ? (isDark ? Colors.white : AppColors.lightInk)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: _color == color
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
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

class _DateTimeButton extends StatelessWidget {
  final DateTime value;
  final bool enabled;
  final VoidCallback onTap;

  const _DateTimeButton({
    super.key,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.event_outlined, size: 18),
        label: Text(
          AppFormatters.formatDateTime(value),
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
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
