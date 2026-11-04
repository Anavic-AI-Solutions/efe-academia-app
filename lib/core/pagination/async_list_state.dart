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

  AsyncListState<T> copyWith({
    CursorPagination<T>? page,
    bool? isLoading,
    String? error,
  }) {
    return AsyncListState<T>(
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
