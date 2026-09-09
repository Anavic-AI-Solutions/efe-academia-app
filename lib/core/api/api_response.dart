class ApiResponse<T> {
  final T? data;
  final List<ApiError>? errors;

  ApiResponse({this.data, this.errors});

  bool get isSuccess => errors == null || errors!.isEmpty;
}

class ApiError {
  final String status;
  final String title;
  final String? detail;
  final Map<String, dynamic>? source;

  ApiError({
    required this.status,
    required this.title,
    this.detail,
    this.source,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        status: json['status']?.toString() ?? '',
        title: json['title'] ?? '',
        detail: json['detail'],
        source: json['source'],
      );
}
