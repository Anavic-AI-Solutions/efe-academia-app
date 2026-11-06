import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class BirthdayApi {
  final ApiClient _client;
  BirthdayApi(this._client);

  Future<Response> getBirthdays({
    String scope = 'upcoming',
    int days = 30,
  }) =>
      _client.get('/birthdays', queryParameters: {
        'scope': scope,
        'days': days,
      });

  Future<Response> getTodayBirthdays() => getBirthdays(scope: 'today');
}
