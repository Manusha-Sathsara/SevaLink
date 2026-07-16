import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/worker_search_result.dart';

class SearchRepository {
  final DioClient _dioClient;

  SearchRepository(this._dioClient);

  /// Keyword search — hits `/api/search?keyword=<query>`
  Future<List<WorkerSearchResult>> searchByKeyword(String keyword) async {
    final response = await _dioClient.dio.get(
      '${ApiEndpoints.baseUrl}/search',
      queryParameters: {'keyword': keyword},
    );
    return _parseList(response);
  }

  /// Category search — hits `/api/search/category?name=<category>`
  Future<List<WorkerSearchResult>> searchByCategory(String category) async {
    final response = await _dioClient.dio.get(
      '${ApiEndpoints.baseUrl}/search/category',
      queryParameters: {'name': category},
    );
    return _parseList(response);
  }

  /// Combined search — keyword + optional category
  Future<List<WorkerSearchResult>> combinedSearch({
    String? keyword,
    String? category,
  }) async {
    final params = <String, dynamic>{};
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (category != null && category.isNotEmpty) params['category'] = category;

    final response = await _dioClient.dio.get(
      '${ApiEndpoints.baseUrl}/search/full',
      queryParameters: params,
    );
    return _parseList(response);
  }

  List<WorkerSearchResult> _parseList(Response response) {
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => WorkerSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Handle wrapped responses: { "data": [...] } or { "workers": [...] }
    if (data is Map<String, dynamic>) {
      final list = data['data'] ?? data['workers'] ?? data['content'] ?? [];
      if (list is List) {
        return list
            .map((e) => WorkerSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }
}
