import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/widgets/form_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/faq_model.dart';
import '../../providers/faq_provider.dart';

class FaqFormSheet extends ConsumerStatefulWidget {
  /// `null` crea una pregunta; con valor, la edita.
  final FaqModel? faq;

  const FaqFormSheet({super.key, required this.faq});

  @override
  ConsumerState<FaqFormSheet> createState() => _FaqFormSheetState();
}

class _FaqFormSheetState extends ConsumerState<FaqFormSheet> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  bool _isSaving = false;

  String? _questionError;
  String? _answerError;
  String? _generalError;

  bool get _isEdit => widget.faq != null;

  @override
  void initState() {
    super.initState();
    final faq = widget.faq;
    if (faq != null) {
      _questionController.text = faq.question;
      _answerController.text = faq.answer;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    final questionError = question.isEmpty ? l10n.commonFormRequired : null;
    final answerError = answer.isEmpty ? l10n.commonFormRequired : null;

    setState(() {
      _questionError = questionError;
      _answerError = answerError;
      _generalError = null;
    });
    if (questionError != null || answerError != null) return;

    setState(() => _isSaving = true);

    final repository = ref.read(faqRepositoryProvider);
    try {
      if (_isEdit) {
        await repository.updateFaq(
          widget.faq!.id,
          question: question,
          answer: answer,
        );
      } else {
        await repository.createFaq(question: question, answer: answer);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _questionError = e.fieldErrors['question'] ?? _questionError;
        _answerError = e.fieldErrors['answer'] ?? _answerError;
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
    const known = {'question', 'answer'};
    return e.fieldErrors.isNotEmpty && e.fieldErrors.keys.every(known.contains);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FormSheet(
      title: _isEdit ? l10n.faqFormEditTitle : l10n.faqFormCreateTitle,
      saveLabel: l10n.commonSave,
      onSave: _submit,
      isSaving: _isSaving,
      error: _generalError,
      children: [
        _FieldLabel(label: l10n.faqFormQuestion),
        TextField(
          key: const Key('faq-question-field'),
          controller: _questionController,
          maxLines: 2,
          decoration: _inputDecoration().copyWith(errorText: _questionError),
          onChanged: (_) {
            if (_questionError != null) {
              setState(() => _questionError = null);
            }
          },
        ),
        const SizedBox(height: 12),
        _FieldLabel(label: l10n.faqFormAnswer),
        TextField(
          key: const Key('faq-answer-field'),
          controller: _answerController,
          maxLines: 4,
          decoration: _inputDecoration().copyWith(errorText: _answerError),
          onChanged: (_) {
            if (_answerError != null) setState(() => _answerError = null);
          },
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

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
