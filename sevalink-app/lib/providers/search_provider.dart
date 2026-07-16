import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/worker_search_result.dart';
import '../data/repositories/search_repository.dart';
import '../providers/auth_provider.dart';

// ── Repository provider ────────────────────────────────────────────────────
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SearchRepository(dioClient);
});

// ── State ──────────────────────────────────────────────────────────────────
enum SearchStatus { initial, loading, success, error }

class SearchState {
  final List<WorkerSearchResult> results;
  final SearchStatus status;
  final String? errorMessage;
  final String query;
  final String? selectedCategory;

  const SearchState({
    this.results = const [],
    this.status = SearchStatus.initial,
    this.errorMessage,
    this.query = '',
    this.selectedCategory,
  });

  SearchState copyWith({
    List<WorkerSearchResult>? results,
    SearchStatus? status,
    String? errorMessage,
    String? query,
    String? selectedCategory,
    bool clearCategory = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      status: status ?? this.status,
      errorMessage: errorMessage,
      query: query ?? this.query,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }

  bool get hasResults => results.isNotEmpty;
  bool get isEmpty =>
      status == SearchStatus.success && results.isEmpty;
}

// ── Notifier ───────────────────────────────────────────────────────────────
class SearchNotifier extends Notifier<SearchState> {
  late SearchRepository _repo;

  @override
  SearchState build() {
    _repo = ref.watch(searchRepositoryProvider);
    return const SearchState();
  }

  Future<void> search(String query, {String? category}) async {
    // If both are empty, reset
    if (query.trim().isEmpty && category == null) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(
      status: SearchStatus.loading,
      query: query,
      selectedCategory: category,
    );

    try {
      final results = await _repo.combinedSearch(
        keyword: query.trim().isEmpty ? null : query.trim(),
        category: category,
      );
      state = state.copyWith(
        status: SearchStatus.success,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  Future<void> searchByCategory(String category) async {
    state = state.copyWith(
      status: SearchStatus.loading,
      selectedCategory: category,
      query: '',
    );
    try {
      final results = await _repo.searchByCategory(category);
      state = state.copyWith(
        status: SearchStatus.success,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  void clearCategory() {
    state = state.copyWith(
      clearCategory: true,
      results: [],
      status: SearchStatus.initial,
    );
  }

  void reset() {
    state = const SearchState();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Cannot reach server. Check your connection.';
    }
    if (msg.contains('401')) return 'Session expired. Please log in again.';
    if (msg.contains('404')) return 'No search endpoint found on server.';
    return 'Something went wrong. Please try again.';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────
final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
