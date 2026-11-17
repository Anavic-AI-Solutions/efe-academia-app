import 'package:dio/dio.dart';

import '../api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    if (statusCode == null) {
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          handler.reject(_wrapError(err, TimeoutException()));
          return;
        case DioExceptionType.connectionError:
          handler.reject(_wrapError(err, NetworkException()));
          return;
        default:
          handler.next(err);
          return;
      }
    }

    switch (statusCode) {
      case 401:
        handler.reject(
          _wrapError(
            err,
            UnauthorizedException(detail: _extractErrorDetail(err)),
          ),
        );
        return;
      case 403:
        handler.reject(
          _wrapError(err, ForbiddenException(detail: _extractErrorDetail(err))),
        );
        return;
      case 404:
        handler.reject(
          _wrapError(err, NotFoundException(detail: _extractErrorDetail(err))),
        );
        return;
      case 422:
        final fieldErrors = _parseFieldErrors(err);
        handler.reject(
          _wrapError(
            err,
            ValidationException(
              fieldErrors: fieldErrors,
              detail: _extractErrorDetail(err),
            ),
          ),
        );
        return;
      case 500:
        handler.reject(
          _wrapError(
            err,
            ApiException(
              statusCode: 500,
              message: 'Error interno del servidor',
              detail: _extractErrorDetail(err),
            ),
          ),
        );
        return;
      default:
        handler.reject(
          _wrapError(
            err,
            ApiException(
              statusCode: statusCode,
              message: 'La solicitud falló',
              detail: _extractErrorDetail(err),
            ),
          ),
        );
        return;
    }
  }

  DioException _wrapError(DioException original, ApiException exception) {
    return DioException(
      requestOptions: original.requestOptions,
      response: original.response,
      type: original.type,
      error: exception,
    );
  }

  String? _extractErrorDetail(DioException err) {
    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors[0]['detail']?.toString();
      }

      // ApiResponder shape: {"error": {"message": ..., "detail": ...}}
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final detail = error['detail']?.toString();
        if (detail != null && detail.isNotEmpty) return detail;
        final message = error['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }

      // Laravel shape: {"message": ..., "errors": {"field": [messages]}}
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }

      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return err.message;
  }

  Map<String, String> _parseFieldErrors(DioException err) {
    final fieldErrors = <String, String>{};
    final data = err.response?.data;

    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final messages = entry.value;
          if (messages is List && messages.isNotEmpty) {
            fieldErrors[entry.key.toString()] = messages.first.toString();
          }
        }
        return fieldErrors;
      }
      if (errors is List) {
        for (final error in errors) {
          if (error is Map<String, dynamic>) {
            final pointer = error['source']?['pointer']?.toString();
            final detail = error['detail']?.toString();
            if (pointer != null && detail != null) {
              final field = pointer.split('/').last;
              fieldErrors[field] = detail;
            }
          }
        }
      }
    }

    return fieldErrors;
  }
}
