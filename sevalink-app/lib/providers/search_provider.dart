import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/worker_search_result.dart';
import '../data/models/search_suggestion.dart';
import '../data/repositories/search_repository.dart';
import '../providers/auth_provider.dart';

//  Repository provider
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SearchRepository(dioClient);
});

//  State
enum SearchStatus { initial, loading, success, error }

class SearchState {
  final List<WorkerSearchResult> results;
  final List<SearchSuggestion> suggestions;
  final SearchStatus status;
  final String? errorMessage;
  final String query;
  final String? selectedCategory;
  final bool isAvailableOnly;

  const SearchState({
    this.results = const [],
    this.suggestions = const [],
    this.status = SearchStatus.initial,
    this.errorMessage,
    this.query = '',
    this.selectedCategory,
    this.isAvailableOnly = false,
  });

  SearchState copyWith({
    List<WorkerSearchResult>? results,
    List<SearchSuggestion>? suggestions,
    SearchStatus? status,
    String? errorMessage,
    String? query,
    String? selectedCategory,
    bool? isAvailableOnly,
    bool clearCategory = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      status: status ?? this.status,
      errorMessage: errorMessage,
      query: query ?? this.query,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      isAvailableOnly: isAvailableOnly ?? this.isAvailableOnly,
    );
  }

  bool get hasResults => results.isNotEmpty;
  bool get isEmpty =>
      status == SearchStatus.success && results.isEmpty;
}

//  Notifier
class SearchNotifier extends Notifier<SearchState> {
  late SearchRepository _repo;

  @override
  SearchState build() {
    _repo = ref.watch(searchRepositoryProvider);
    return const SearchState();
  }

  Future<void> search(String query, {String? category, double? lat, double? lng}) async {
    // If both are empty and we don't have availability filter, reset
    if (query.trim().isEmpty && category == null && !state.isAvailableOnly) {
      state = state.copyWith(status: SearchStatus.initial, results: [], query: query, selectedCategory: category);
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
        available: state.isAvailableOnly ? true : null,
        lat: lat,
        lng: lng,
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

  Future<void> searchByCategory(String category, {double? lat, double? lng}) async {
    state = state.copyWith(
      status: SearchStatus.loading,
      selectedCategory: category,
      query: '',
    );
    try {
      // Use combinedSearch so we can pass coordinates for proximity sorting
      final results = await _repo.combinedSearch(
        category: category,
        available: state.isAvailableOnly ? true : null,
        lat: lat,
        lng: lng,
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

  Future<void> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }
    try {
      final list = await _repo.getSuggestions(query);
      state = state.copyWith(suggestions: list);
    } catch (_) {
      // Fail silently for autocomplete
      state = state.copyWith(suggestions: []);
    }
  }

  Future<void> toggleAvailabilityFilter({double? lat, double? lng}) async {
    final newAvailable = !state.isAvailableOnly;
    state = state.copyWith(isAvailableOnly: newAvailable);
    // Re-trigger search with new filter
    await search(state.query, category: state.selectedCategory, lat: lat, lng: lng);
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

//  Provider
final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
