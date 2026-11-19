import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/faqs/data/faq_repository.dart';
import 'package:efe_mobile/features/faqs/domain/faq_model.dart';
import 'package:efe_mobile/features/faqs/providers/faq_provider.dart';
import 'package:efe_mobile/features/faqs/screens/widgets/faq_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_app.dart';

class _FakeFaqRepository implements FaqRepository {
  Map<String, Object?>? createdArgs;
  Map<String, Object?>? updatedArgs;
  String? updatedId;
  Object? error;

  @override
  Future<PageResult<FaqModel>> getFaqs({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async =>
      PageResult<FaqModel>.empty();

  @override
  Future<FaqModel> createFaq({
    required String question,
    required String answer,
  }) async {
    if (error != null) throw error!;
    createdArgs = {'question': question, 'answer': answer};
    return FaqModel(id: 'new', question: question, answer: answer);
  }

  @override
  Future<FaqModel> updateFaq(
    String id, {
    required String question,
    required String answer,
  }) async {
    if (error != null) throw error!;
    updatedId = id;
    updatedArgs = {'question': question, 'answer': answer};
    return FaqModel(id: id, question: question, answer: answer);
  }

  @override
  Future<void> deleteFaq(String id) async {}
}

Future<void> _pumpForm(
  WidgetTester tester,
  _FakeFaqRepository repository, {
  FaqModel? faq,
  ValueNotifier<bool?>? result,
}) async {
  tester.view.physicalSize = const Size(400 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [faqRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: localizedApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final saved = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => FaqFormSheet(faq: faq),
                );
                if (result != null) result.value = saved;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.text('Guardar');
  await tester.ensureVisible(save);
  await tester.pump();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pregunta y respuesta vacías muestran ambos errores y no guardan',
      (tester) async {
    final repository = _FakeFaqRepository();
    await _pumpForm(tester, repository);

    await _tapSave(tester);

    expect(find.text('Este campo es obligatorio'), findsNWidgets(2));
    expect(repository.createdArgs, isNull);
    expect(repository.updatedArgs, isNull);
  });

  testWidgets('creación válida llama createFaq con pregunta y respuesta',
      (tester) async {
    final repository = _FakeFaqRepository();
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, result: result);

    await tester.enterText(
      find.byKey(const Key('faq-question-field')),
      '  ¿Cómo pago?  ',
    );
    await tester.enterText(
      find.byKey(const Key('faq-answer-field')),
      'Desde la sección Cuotas',
    );

    await _tapSave(tester);

    expect(repository.createdArgs, {
      'question': '¿Cómo pago?',
      'answer': 'Desde la sección Cuotas',
    });
    expect(repository.updatedArgs, isNull);
    expect(result.value, isTrue);
  });

  testWidgets('edición prellena y llama updateFaq', (tester) async {
    final repository = _FakeFaqRepository();
    final result = ValueNotifier<bool?>(null);
    final faq = FaqModel(
      id: 'f1',
      question: 'Pregunta original',
      answer: 'Respuesta original',
    );
    await _pumpForm(tester, repository, faq: faq, result: result);

    expect(find.text('Editar pregunta'), findsOneWidget);
    expect(find.text('Pregunta original'), findsOneWidget);
    expect(find.text('Respuesta original'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('faq-question-field')),
      'Pregunta editada',
    );
    await _tapSave(tester);

    expect(repository.updatedId, 'f1');
    expect(repository.updatedArgs, {
      'question': 'Pregunta editada',
      'answer': 'Respuesta original',
    });
    expect(repository.createdArgs, isNull);
    expect(result.value, isTrue);
  });

  testWidgets('un 422 pinta los errores por campo', (tester) async {
    final repository = _FakeFaqRepository()
      ..error = ValidationException(fieldErrors: {
        'question': 'La pregunta es inválida',
        'answer': 'La respuesta es inválida',
      });
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, result: result);

    await tester.enterText(
      find.byKey(const Key('faq-question-field')),
      'Pregunta',
    );
    await tester.enterText(
      find.byKey(const Key('faq-answer-field')),
      'Respuesta',
    );

    await _tapSave(tester);

    expect(find.text('La pregunta es inválida'), findsOneWidget);
    expect(find.text('La respuesta es inválida'), findsOneWidget);
    expect(result.value, isNull);
  });

  testWidgets('un error general no cierra el formulario', (tester) async {
    final repository = _FakeFaqRepository()
      ..error = ApiException(statusCode: 500, message: 'boom');
    final result = ValueNotifier<bool?>(null);
    await _pumpForm(tester, repository, result: result);

    await tester.enterText(
      find.byKey(const Key('faq-question-field')),
      'Pregunta',
    );
    await tester.enterText(
      find.byKey(const Key('faq-answer-field')),
      'Respuesta',
    );

    await _tapSave(tester);

    expect(find.text('No se pudo guardar'), findsOneWidget);
    expect(result.value, isNull);
  });
}
