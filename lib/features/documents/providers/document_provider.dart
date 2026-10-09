import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../../core/api/cursor_pagination.dart';
import '../data/document_api.dart';
import '../data/document_repository.dart';
import '../domain/document_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final documentApiProvider = Provider<DocumentApi>((ref) {
  return DocumentApi(ref.watch(apiClientProvider));
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(documentApiProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DocumentListState {
  final CursorPagination<DocumentModel> pagination;
  final bool isLoading;
  final String? error;

  DocumentListState({
    CursorPagination<DocumentModel>? pagination,
    this.isLoading = false,
    this.error,
  }) : pagination = pagination ?? CursorPagination<DocumentModel>.empty();

  DocumentListState copyWith({
    CursorPagination<DocumentModel>? pagination,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DocumentListState(
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DocumentListNotifier extends StateNotifier<DocumentListState> {
  final DocumentRepository _repository;

  DocumentListNotifier(this._repository) : super(DocumentListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getDocuments();
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getDocuments();
      state = state.copyWith(pagination: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.pagination.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.getDocuments(
        cursor: state.pagination.nextCursor,
      );
      state = state.copyWith(
        pagination: result.copyWith(
          data: [...state.pagination.data, ...result.data],
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final documentListProvider =
    StateNotifierProvider<DocumentListNotifier, DocumentListState>((ref) {
  return DocumentListNotifier(ref.watch(documentRepositoryProvider));
});

/// Últimos documentos para el home del profesor: primera página, los 5 primeros.
final homeDocumentsProvider =
    FutureProvider.autoDispose<List<DocumentModel>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final page = await repository.getDocuments();
  return page.data.take(5).toList();
});

/// Detalle de un documento por id para `DocumentDetailScreen`.
final documentDetailProvider = FutureProvider.autoDispose
    .family<DocumentModel, String>((ref, id) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getDocument(id);
});
