import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'library_repository.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final api = ref.watch(libraryApiProvider);
  return LibraryRepository(api);
});

final libraryApiProvider = Provider<LibraryApi>((ref) {
  return LibraryApi(ref.watch(apiClientProvider));
});

final libraryProvider =
    StateNotifierProvider<LibraryListNotifier, CursorPagination<MaterialModel>>((ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return LibraryListNotifier(repository);
});

class LibraryListNotifier extends StateNotifier<CursorPagination<MaterialModel>> {
  final LibraryRepository _repository;
  int _requestId = 0;

  LibraryListNotifier(this._repository) : super(CursorPagination.empty());

  Future<void> load({String? search, String? cursor}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getMaterials(
        search: search,
        cursor: cursor,
      );
      if (requestId != _requestId) return;
      state = result.copyWith(isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  CursorPagination<MaterialModel> copyWith({
    CursorPagination<MaterialModel>? page,
    bool? isLoading,
    String? error,
  }) {
    return CursorPagination(
      cursor: page?.cursor ?? cursor,
      data: page?.data ?? data,
      hasMore: page?.hasMore ?? hasMore,
      total: page?.total ?? total,
    );
  }

  String? get cursor => state.cursor;
  List<MaterialModel> get data => state.data;
  bool get hasMore => state.hasMore;
  int get total => state.total;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
}