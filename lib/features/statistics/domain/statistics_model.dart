class StatisticsModel {
  final Map<String, dynamic> metrics;
  final List<dynamic> details;
  final String role;

  StatisticsModel({
    required this.metrics,
    required this.details,
    required this.role,
  });

  factory StatisticsModel.fromJson(Map<String, dynamic> json, [String role = 'student']) {
    return StatisticsModel(
      metrics: json['metrics'] as Map<String, dynamic>,
      details: json['details'] as List<dynamic>,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics,
      'details': details,
    };
  }
}