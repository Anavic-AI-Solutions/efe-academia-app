class PageResult<T> {
  final List<T> data;
  final int page;
  final int perPage;
  final int total;

  const PageResult({
    required this.data,
    required this.page,
    required this.perPage,
    required this.total,
  });

  int get totalPages => total <= 0 ? 1 : ((total + perPage - 1) ~/ perPage);

  bool get hasPrev => page > 1;

  bool get hasNext => page < totalPages;

  int get firstItem => total == 0 ? 0 : (page - 1) * perPage + 1;

  int get lastItem => total == 0 ? 0 : firstItem + data.length - 1;

  factory PageResult.empty({int perPage = 20}) => PageResult<T>(
        data: const [],
        page: 1,
        perPage: perPage,
        total: 0,
      );

  PageResult<T> copyWith({
    List<T>? data,
    int? page,
    int? perPage,
    int? total,
  }) {
    return PageResult<T>(
      data: data ?? this.data,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
    );
  }
}
