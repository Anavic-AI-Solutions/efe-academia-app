import 'package:dio/dio.dart';
import 'package:efe_mobile/core/api/api_exception.dart';
import 'package:efe_mobile/features/faqs/data/faq_api.dart';
import 'package:efe_mobile/features/faqs/data/faq_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/faqs'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _faqPayload({String id = 'f1'}) => {
      'data': {
        'type': 'faqs',
        'id': id,
        'attributes': {
          'question': '¿Cómo pago?',
          'answer': 'Desde la sección Cuotas',
          'category': 'pagos',
        },
      },
    };

class _FakeFaqApi implements FaqApi {
  Map<String, dynamic>? created;
  Map<String, dynamic>? updated;
  String? updatedId;
  String? deletedId;
  Object? error;

  @override
  Future<Response> getFaqs({
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response> createFaq(Map<String, dynamic> data) async {
    if (error != null) throw error!;
    created = data;
    return _response(_faqPayload());
  }

  @override
  Future<Response> updateFaq(String id, Map<String, dynamic> data) async {
    if (error != null) throw error!;
    updatedId = id;
    updated = data;
    return _response(_faqPayload(id: id));
  }

  @override
  Future<Response> deleteFaq(String id) async {
    if (error != null) throw error!;
    deletedId = id;
    return _response(null);
  }
}

void main() {
  group('FaqRepository.createFaq', () {
    test('envía pregunta y respuesta en el payload JSON', () async {
      final api = _FakeFaqApi();
      final repository = FaqRepository(api);

      final faq = await repository.createFaq(
        question: '¿Cómo pago?',
        answer: 'Desde la sección Cuotas',
      );

      expect(api.created, {
        'question': '¿Cómo pago?',
        'answer': 'Desde la sección Cuotas',
      });
      expect(faq.id, 'f1');
      expect(faq.question, '¿Cómo pago?');
      expect(faq.answer, 'Desde la sección Cuotas');
    });

    test('propaga la ValidationException del interceptor 422', () async {
      final api = _FakeFaqApi()
        ..error = DioException(
          requestOptions: RequestOptions(path: '/faqs'),
          error: ValidationException(
            fieldErrors: {'question': 'La pregunta ya existe'},
          ),
        );
      final repository = FaqRepository(api);

      await expectLater(
        repository.createFaq(question: 'Repetida', answer: 'Respuesta'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.fieldErrors['question'],
            'question error',
            'La pregunta ya existe',
          ),
        ),
      );
    });
  });

  group('FaqRepository.updateFaq', () {
    test('envía el id y el payload JSON a actualizar', () async {
      final api = _FakeFaqApi();
      final repository = FaqRepository(api);

      final faq = await repository.updateFaq(
        'f1',
        question: '¿Cómo pago ahora?',
        answer: 'Desde el menú Cuotas',
      );

      expect(api.updatedId, 'f1');
      expect(api.updated, {
        'question': '¿Cómo pago ahora?',
        'answer': 'Desde el menú Cuotas',
      });
      expect(faq.id, 'f1');
    });
  });

  group('FaqRepository.deleteFaq', () {
    test('envía el id a eliminar', () async {
      final api = _FakeFaqApi();
      final repository = FaqRepository(api);

      await repository.deleteFaq('f1');

      expect(api.deletedId, 'f1');
    });

    test('traduce un DioException genérico a ApiException', () async {
      final api = _FakeFaqApi()
        ..error = DioException(
          requestOptions: RequestOptions(path: '/faqs/f1'),
          response: Response(
            requestOptions: RequestOptions(path: '/faqs/f1'),
            statusCode: 500,
          ),
        );
      final repository = FaqRepository(api);

      await expectLater(
        repository.deleteFaq('f1'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 500)),
      );
    });
  });
}
