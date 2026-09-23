import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AbsenceApi {
  final ApiClient _client;
  AbsenceApi(this._client);

  Future<Response> getAbsences({
    String? studentId,
    int page = 1,
    int limit = 20,
  }) =>
      _client.get('/absences', queryParameters: {
        if (studentId != null) 'student_id': studentId,
        'page': page,
        'per_page': limit,
      });
}
