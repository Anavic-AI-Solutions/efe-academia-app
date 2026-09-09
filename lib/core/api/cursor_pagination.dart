class CursorPagination<T> {
  final List<T> data;
  final String? nextCursor;
  final bool hasMore;
  final int? total;

  CursorPagination({
    required this.data,
    this.nextCursor,
    required this.hasMore,
    this.total,
  });

  CursorPagination<T> copyWith({
    List<T>? data,
    String? nextCursor,
    bool? hasMore,
    int? total,
  }) {
    return CursorPagination<T>(
      data: data ?? this.data,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
    );
  }

  factory CursorPagination.empty() => CursorPagination<T>(
        data: [],
        hasMore: false,
      );
}
