class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? detail;

  ApiException({this.statusCode, required this.message, this.detail});

  @override
  String toString() => detail ?? message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({super.message = 'No autorizado', super.detail})
      : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException({super.message = 'Acceso denegado', super.detail})
      : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException({super.message = 'No encontrado', super.detail})
      : super(statusCode: 404);
}

class ValidationException extends ApiException {
  final Map<String, String> fieldErrors;

  ValidationException({required this.fieldErrors, super.detail})
      : super(statusCode: 422, message: 'Error de validación');
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'Sin conexión a internet'});
}

class TimeoutException extends ApiException {
  TimeoutException({super.message = 'La solicitud tardó demasiado'});
}
