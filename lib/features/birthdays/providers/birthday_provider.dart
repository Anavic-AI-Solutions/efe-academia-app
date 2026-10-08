import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_provider.dart';
import '../data/birthday_api.dart';
import '../domain/birthday_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final birthdayApiProvider = Provider<BirthdayApi>((ref) {
  return BirthdayApi(ref.watch(apiClientProvider));
});

/// Disponibilidad del backend de cumpleaños.
///
/// El endpoint `GET /api/v1/birthdays` aún no existe en el backend: ante
/// 404/501 el provider entrega `[]` y marca este flag en `false` para que el
/// widget muestre "Disponible próximamente" en vez de un error rojo.
final birthdaysAvailableProvider = StateProvider<bool>((ref) => true);

/// Cumpleaños de hoy para el home del profesor.
///
/// Ante 404/501 (backend aún no implementado) devuelve `[]` con
/// [birthdaysAvailableProvider] en `false`. Cualquier otro error se propaga
/// para que la sección muestre su `ErrorView` aislado sin tumbar el home.
final todayBirthdaysProvider =
    FutureProvider.autoDispose<List<BirthdayModel>>((ref) async {
  final api = ref.watch(birthdayApiProvider);
  try {
    final response = await api.getTodayBirthdays();
    final data = response.data;
    final items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? [])
        : data as List<dynamic>? ?? [];
    ref.read(birthdaysAvailableProvider.notifier).state = true;
    return items
        .map((e) => BirthdayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    if (_isBackendMissing(e)) {
      ref.read(birthdaysAvailableProvider.notifier).state = false;
      return <BirthdayModel>[];
    }
    rethrow;
  }
});

bool _isBackendMissing(DioException e) {
  final statusCode = e.response?.statusCode;
  if (statusCode == 404 || statusCode == 501) return true;
  final error = e.error;
  if (error is ApiException &&
      (error.statusCode == 404 || error.statusCode == 501)) {
    return true;
  }
  return false;
}
