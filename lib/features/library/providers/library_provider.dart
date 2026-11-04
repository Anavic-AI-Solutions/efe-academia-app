import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'library_repository.dart';
import 'package:efe_mobile/core/api/cursor_pagination.dart';
import 'package:efe_mobile/core/pagination/async_list_state.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final api = ref.watch(libraryApiProvider);
  return LibraryRepository(api);
});

final libraryApiProvider = Provider<LibraryApi>((ref) {
  return LibraryApi(ref.watch(apiClientProvider));
});

final libraryProvider =
    StateNotifierProvider<LibraryListNotifier, AsyncListState<MaterialModel>>(
  (ref) {
    final repository = ref.watch(libraryRepositoryProvider);
    return LibraryListNotifier(repository);
  },
);

class LibraryListNotifier
    extends StateNotifier<AsyncListState<MaterialModel>> {
  final LibraryRepository _repository;
  int _requestId = 0;

  LibraryListNotifier(this._repository)
      : super(const AsyncListState(page: CursorPagination.empty()));

  Future<void> load({String? search, String? cursor}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getMaterials(
        search: search,
        cursor: cursor,
      );
      if (requestId != _requestId) return;
      state = state.copyWith(page: result, isLoading: false);
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String? get cursor => state.page.nextCursor;
  List<MaterialModel> get data => state.page.data;
  bool get hasMore => state.page.hasMore;
  int get total => state.page.total ?? 0;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
}
