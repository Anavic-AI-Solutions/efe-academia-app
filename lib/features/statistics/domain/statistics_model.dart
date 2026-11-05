class StatisticsModel {
  final String role;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> details;

  StatisticsModel({
    required this.role,
    required this.metrics,
    required this.details,
  });

  factory StatisticsModel.empty() => StatisticsModel(
        role: '',
        metrics: const {},
        details: const {},
      );

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      role: json['role']?.toString() ?? '',
      metrics: _asMap(json['metrics']),
      details: _asMap(json['details']),
    );
  }

  bool get isEmpty => metrics.isEmpty && details.isEmpty;

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }
}
