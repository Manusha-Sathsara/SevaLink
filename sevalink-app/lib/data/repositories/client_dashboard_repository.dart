import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../features/dashboard/screens/client_dashboard_screen.dart'; // To reuse WorkerProfile

class ClientDashboardRepository {
  final DioClient _dioClient;

  ClientDashboardRepository(this._dioClient);

  Future<List<WorkerProfile>> getDashboardData() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.clientDashboard);
      
      if (response.statusCode == 200) {
        final List<dynamic> topWorkersJson = response.data['topWorkers'] ?? [];
        return topWorkersJson.map((json) => WorkerProfile(
          id: (json['id'] as num?)?.toInt() ?? 0,
          name: json['name'] ?? 'Worker',
          profession: json['profession'] ?? 'General',
          hourlyRate: (json['hourlyRate'] as num?)?.toInt() ?? 0,
          rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
          reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
          isVerified: json['isVerified'] ?? false,
          imageUrl: json['imageUrl'] != null && (json['imageUrl'] as String).isNotEmpty
              ? ApiEndpoints.rewriteImageUrl(json['imageUrl'] as String)
              : '',
        )).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load dashboard data: ${e.message}');
    }
  }
}
