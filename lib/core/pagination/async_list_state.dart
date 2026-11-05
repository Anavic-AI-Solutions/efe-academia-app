import 'package:efe_mobile/core/api/cursor_pagination.dart';

class AsyncListState<T> {
  final CursorPagination<T> page;
  final bool isLoading;
  final String? error;

  const AsyncListState({
    required this.page,
    this.isLoading = false,
    this.error,
  });

  List<T> get data => page.data;
  String? get nextCursor => page.nextCursor;
  bool get hasMore => page.hasMore;
  int get total => page.total ?? 0;

  AsyncListState<T> copyWith({
    CursorPagination<T>? page,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AsyncListState<T>(
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
