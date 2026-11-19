import 'package:dio/dio.dart';
import 'package:efe_mobile/features/events/data/event_api.dart';
import 'package:efe_mobile/features/events/data/event_repository.dart';
import 'package:efe_mobile/features/events/domain/event_model.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _response(Object? data) => Response(
      requestOptions: RequestOptions(path: '/events'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _eventPayload({int? createdBy}) => {
      'data': {
        'type': 'events',
        'id': 'e1',
        'attributes': {
          'title': 'Acto escolar',
          'description': 'Patio central',
          'start_date': '2026-12-01T10:00:00',
          'end_date': '2026-12-01T12:00:00',
          'color': '#3B82F6',
          if (createdBy != null) 'created_by': createdBy,
        },
      },
    };

class _FakeEventApi implements EventApi {
  Map<String, dynamic>? created;
  Map<String, dynamic>? updated;
  String? updatedId;
  String? deletedId;
  Object? error;

  @override
  Future<Response> getEvents({String? cursor, int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<Response> getCalendar({
    required String startDate,
    required String endDate,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response> createEvent(Map<String, dynamic> data) async {
    if (error != null) throw error!;
    created = data;
    return _response(_eventPayload(createdBy: 7));
  }

  @override
  Future<Response> updateEvent(String id, Map<String, dynamic> data) async {
    if (error != null) throw error!;
    updatedId = id;
    updated = data;
    return _response(_eventPayload(createdBy: 7));
  }

  @override
  Future<Response> deleteEvent(String id) async {
    if (error != null) throw error!;
    deletedId = id;
    return _response(null);
  }
}

void main() {
  group('EventRepository.createEvent', () {
    test('envía start_date/end_date ISO y color con #', () async {
      final api = _FakeEventApi();
      final repository = EventRepository(api);

      final event = await repository.createEvent(
        title: 'Acto escolar',
        description: 'Patio central',
        start: DateTime(2026, 12, 1, 10, 30),
        end: DateTime(2026, 12, 1, 12, 45),
        color: 0xFF10B981,
      );

      expect(api.created, {
        'title': 'Acto escolar',
        'description': 'Patio central',
        'start_date': '2026-12-01T10:30:00.000',
        'end_date': '2026-12-01T12:45:00.000',
        'color': '#10B981',
      });
      expect(event.id, 'e1');
      expect(event.createdBy, 7);
    });

    test('incluye la descripción vacía al crear', () async {
      final api = _FakeEventApi();
      final repository = EventRepository(api);

      await repository.createEvent(
        title: 'Solo título',
        start: DateTime(2026, 12, 1, 10),
        end: DateTime(2026, 12, 1, 11),
      );

      expect(api.created!.containsKey('description'), isTrue);
      expect(api.created!['description'], '');
      expect(api.created!['color'], '#3B82F6');
    });
  });

  group('EventRepository.updateEvent', () {
    test('pega a /events/{id} con el payload JSON', () async {
      final api = _FakeEventApi();
      final repository = EventRepository(api);

      final event = await repository.updateEvent(
        'e1',
        title: 'Editado',
        description: '',
        start: DateTime(2026, 12, 2, 9),
        end: DateTime(2026, 12, 2, 10),
        color: 0xFFEF4444,
      );

      expect(api.updatedId, 'e1');
      expect(api.updated!['title'], 'Editado');
      expect(api.updated!.containsKey('description'), isTrue);
      expect(api.updated!['description'], '');
      expect(api.updated!['start_date'], '2026-12-02T09:00:00.000');
      expect(api.updated!['end_date'], '2026-12-02T10:00:00.000');
      expect(api.updated!['color'], '#EF4444');
      expect(event.id, 'e1');
    });
  });

  group('EventRepository.deleteEvent', () {
    test('envía el id a eliminar', () async {
      final api = _FakeEventApi();
      final repository = EventRepository(api);

      await repository.deleteEvent('e1');

      expect(api.deletedId, 'e1');
    });
  });

  group('EventModel.createdBy', () {
    test('parsea created_by numérico', () {
      final event = EventModel.fromJson(_eventPayload(createdBy: 7));

      expect(event.createdBy, 7);
    });

    test('parsea created_by como string numérico', () {
      final event = EventModel.fromJson({
        'data': {
          'id': 'e2',
          'attributes': {'title': 'Acto', 'created_by': '42'},
        },
      });

      expect(event.createdBy, 42);
    });

    test('sin created_by queda en null', () {
      final event = EventModel.fromJson({
        'data': {
          'id': 'e3',
          'attributes': {'title': 'Acto'},
        },
      });

      expect(event.createdBy, isNull);
    });

    test('created_by no numérico no lanza', () {
      final event = EventModel.fromJson({
        'data': {
          'id': 'e4',
          'attributes': {'title': 'Acto', 'created_by': 'nadie'},
        },
      });

      expect(event.createdBy, isNull);
    });
  });
}
