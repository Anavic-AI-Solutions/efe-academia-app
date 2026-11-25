import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/page_pagination.dart';
import '../../classrooms/domain/classroom_model.dart';
import '../../classrooms/providers/classroom_provider.dart';
import '../data/request_api.dart';
import '../data/request_repository.dart';
import '../domain/request_model.dart';

final requestApiProvider = Provider<RequestApi>((ref) {
  return RequestApi(ref.watch(apiClientProvider));
});

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository(ref.watch(requestApiProvider));
});

class RequestListState {
  final PageResult<RequestModel> page;
  final bool isLoading;
  final String? error;
  final String search;
  final String status;
  final String type;

  RequestListState({
    PageResult<RequestModel>? page,
    this.isLoading = false,
    this.error,
    this.search = '',
    this.status = 'pending',
    this.type = 'all',
  }) : page = page ?? PageResult<RequestModel>.empty();

  RequestListState copyWith({
    PageResult<RequestModel>? page,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? status,
    String? type,
  }) {
    return RequestListState(
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }
}

class RequestListNotifier extends StateNotifier<RequestListState> {
  final RequestRepository _repository;
  int _requestId = 0;
  int _lastRequestedPage = 1;

  RequestListNotifier(this._repository) : super(RequestListState()) {
    load();
  }

  Future<void> load({int page = 1}) async {
    _lastRequestedPage = page;
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.getRequests(
        search: state.search.isEmpty ? null : state.search,
        status: state.status,
        type: state.type,
        page: page,
      );

      if (!mounted || requestId != _requestId) return;
      if (result.data.isEmpty && page > 1 && result.total > 0) {
        await load(page: 1);
        return;
      }

      state = state.copyWith(page: result, isLoading: false, clearError: true);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load(page: state.page.page);

  Future<void> retry() => load(page: _lastRequestedPage);

  Future<void> setSearch(String value) async {
    if (state.search == value) return;
    state = state.copyWith(search: value);
    await load();
  }

  Future<void> setStatus(String value) async {
    if (state.status == value) return;
    state = state.copyWith(status: value);
    await load();
  }

  Future<void> setType(String value) async {
    if (state.type == value) return;
    state = state.copyWith(type: value);
    await load();
  }

  Future<void> goToPage(int page) {
    if (page < 1 || page > state.page.totalPages || page == state.page.page) {
      return Future.value();
    }
    return load(page: page);
  }
}

final requestListProvider =
    StateNotifierProvider<RequestListNotifier, RequestListState>((ref) {
  return RequestListNotifier(ref.watch(requestRepositoryProvider));
});

final requestDetailProvider =
    FutureProvider.family<RequestModel, ({RequestKind kind, String id})>(
  (ref, key) =>
      ref.watch(requestRepositoryProvider).getRequest(key.kind, key.id),
);

final requestClassroomOptionsProvider =
    FutureProvider.family<List<ClassroomModel>, String>((ref, search) async {
  final result = await ref.watch(classroomRepositoryProvider).getClassrooms(
        search: search,
        page: 1,
        limit: 50,
      );
  return result.data;
});
