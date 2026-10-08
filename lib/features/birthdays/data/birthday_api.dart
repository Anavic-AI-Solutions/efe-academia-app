import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class BirthdayApi {
  final ApiClient _client;
  BirthdayApi(this._client);

  Future<Response> getTodayBirthdays() =>
      _client.get('/birthdays', queryParameters: const {'scope': 'today'});
}
