class ClassroomFilters {
  final List<String> branches;
  final List<String> levels;
  final List<String> years;
  final List<String> statuses;

  const ClassroomFilters({
    this.branches = const [],
    this.levels = const [],
    this.years = const [],
    this.statuses = const [],
  });

  factory ClassroomFilters.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ClassroomFilters(
      branches: _stringList(data['branches']),
      levels: _stringList(data['levels']),
      years: _stringList(data['years']),
      statuses: _stringList(data['statuses']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }
}
