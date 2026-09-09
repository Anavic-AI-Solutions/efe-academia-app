class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? detail;

  ApiException({this.statusCode, required this.message, this.detail});

  @override
  String toString() => detail ?? message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({super.message = 'Unauthorized', super.detail})
      : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException({super.message = 'Forbidden', super.detail})
      : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException({super.message = 'Not Found', super.detail})
      : super(statusCode: 404);
}

class ValidationException extends ApiException {
  final Map<String, String> fieldErrors;

  ValidationException({required this.fieldErrors, super.detail})
      : super(statusCode: 422, message: 'Validation Error');
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'No internet connection'});
}

class TimeoutException extends ApiException {
  TimeoutException({super.message = 'Request timed out'});
}
