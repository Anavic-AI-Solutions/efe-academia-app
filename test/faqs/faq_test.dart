import 'dart:async';

import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/page_pagination.dart';
import 'package:efe_mobile/features/faqs/data/faq_api.dart';
import 'package:efe_mobile/features/faqs/data/faq_repository.dart';
import 'package:efe_mobile/features/faqs/domain/faq_model.dart';
import 'package:efe_mobile/features/faqs/providers/faq_provider.dart';
import 'package:efe_mobile/features/faqs/screens/faq_screen.dart';
import 'package:efe_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/faqs'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _faqJson(String id, {String question = '¿Pregunta?'}) => {
      'type': 'faq',
      'id': id,
      'attributes': {
        'question': question,
        'answer': 'Respuesta $id',
        'category': 'general',
        'created_at': '2026-09-01T10:00:00',
      },
    };

class _FakeFaqApi implements FaqApi {
  final List<Map<String, Object?>> calls = [];
  final List<Object?> payloads = [];

  @override
  Future<Response> getFaqs({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add({'search': search, 'page': page, 'perPage': perPage});
    return _response(payloads.removeAt(0));
  }
}

class _FakeFaqRepository implements FaqRepository {
  _FakeFaqRepository(this.pages);

  final List<PageResult<FaqModel>> pages;

  @override
  Future<PageResult<FaqModel>> getFaqs({
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    return pages.removeAt(0);
  }
}

class _DelayedFaqRepository implements FaqRepository {
  _DelayedFaqRepository(this.future);

  final Future<PageResult<FaqModel>> future;

  @override
  Future<PageResult<FaqModel>> getFaqs({
    String? search,
    int page = 1,
    int perPage = 10,
  }) =>
      future;
}

PageResult<FaqModel> _page(
  List<FaqModel> data, {
  int page = 1,
  int perPage = 10,
  int total = 24,
}) =>
    PageResult(
      data: data,
      page: page,
      perPage: perPage,
      total: total,
    );

void main() {
  group('FaqRepository', () {
    test('parses the JSON:API item and page metadata', () async {
      final api = _FakeFaqApi()
        ..payloads.add({
          'data': [_faqJson('1'), _faqJson('2')],
          'meta': {
            'current_page': 2,
            'last_page': 3,
            'per_page': 10,
            'total': 24,
          },
        });
      final repository = FaqRepository(api);

      final result = await repository.getFaqs(search: 'pago', page: 2);

      expect(result.data, hasLength(2));
      expect(result.data.first.id, '1');
      expect(result.data.first.question, '¿Pregunta?');
      expect(result.data.first.answer, 'Respuesta 1');
      expect(result.page, 2);
      expect(result.perPage, 10);
      expect(result.total, 24);
      expect(result.totalPages, 3);
      expect(api.calls.single['search'], 'pago');
      expect(api.calls.single['page'], 2);
    });

    test('accepts a flat fallback item and missing meta', () async {
      final api = _FakeFaqApi()
        ..payloads.add({
          'data': [
            {'id': 9, 'question': 'Plan', 'answer': 'Mensual'},
          ],
        });
      final repository = FaqRepository(api);

      final result = await repository.getFaqs();

      expect(result.data.single.id, '9');
      expect(result.total, 1);
      expect(result.page, 1);
    });
  });

  group('FaqListNotifier', () {
    test('loads ten items per page and navigates to another page', () async {
      final faqs = List.generate(
        10,
        (index) => FaqModel(
          id: '$index',
          question: 'Pregunta $index',
          answer: 'Respuesta $index',
        ),
      );
      final api = _FakeFaqApi()
        ..payloads.add({
          'data': faqs
              .map((faq) => _faqJson(faq.id, question: faq.question))
              .toList(),
          'meta': {
            'current_page': 1,
            'last_page': 3,
            'per_page': 10,
            'total': 24,
          },
        })
        ..payloads.add({
          'data': [_faqJson('10')],
          'meta': {
            'current_page': 2,
            'last_page': 3,
            'per_page': 10,
            'total': 24,
          },
        });
      final notifier = FaqListNotifier(FaqRepository(api));

      await notifier.load();
      expect(notifier.state.page.data, hasLength(10));
      expect(api.calls.first['perPage'], 10);
      expect(notifier.state.page.totalPages, 3);

      await notifier.goToPage(2);
      expect(api.calls.last['page'], 2);
      expect(notifier.state.page.page, 2);
    });

    test('search resets to the first page', () async {
      final api = _FakeFaqApi()
        ..payloads.add({
          'data': [_faqJson('1')],
          'meta': {
            'current_page': 2,
            'last_page': 3,
            'per_page': 10,
            'total': 24,
          },
        })
        ..payloads.add({
          'data': [_faqJson('2')],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 10,
            'total': 1,
          },
        });
      final notifier = FaqListNotifier(FaqRepository(api));

      await notifier.load(page: 2);
      await notifier.setSearch('horario');

      expect(api.calls.last['search'], 'horario');
      expect(api.calls.last['page'], 1);
      expect(notifier.state.page.page, 1);
    });

    test('disposing the provider during a request does not throw', () async {
      final completer = Completer<PageResult<FaqModel>>();
      final container = ProviderContainer(
        overrides: [
          faqRepositoryProvider.overrideWithValue(
            _DelayedFaqRepository(completer.future),
          ),
        ],
      );
      container.listen(faqListProvider, (_, __) {});

      final pending = container.read(faqListProvider.notifier).load();
      container.dispose();
      completer.complete(_page(const []));

      await pending;
    });
  });

  testWidgets('FAQ rows expand their answer when tapped', (tester) async {
    final repository = _FakeFaqRepository([
      _page([
        FaqModel(
          id: '1',
          question: '¿Cómo pago?',
          answer: 'Desde la sección Cuotas',
        ),
      ]),
    ]);
    final container = ProviderContainer(
      overrides: [
        faqRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('es', 'AR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FaqScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    AnimatedCrossFade crossFade() =>
        tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));

    expect(crossFade().crossFadeState, CrossFadeState.showFirst);

    await tester.tap(find.text('¿Cómo pago?'));
    await tester.pumpAndSettle();

    expect(crossFade().crossFadeState, CrossFadeState.showSecond);
  });
}
