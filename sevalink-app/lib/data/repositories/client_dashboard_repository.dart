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
        final List<dynamic> topWorkersJson = response.data['topWorkers'];
        return topWorkersJson.map((json) => WorkerProfile(
          name: json['name'],
          profession: json['profession'],
          hourlyRate: (json['hourlyRate'] as num).toInt(),
          rating: (json['rating'] as num).toDouble(),
          reviewCount: json['reviewCount'],
          isVerified: json['isVerified'],
          imageUrl: json['imageUrl'] != null && (json['imageUrl'] as String).isNotEmpty
              ? ApiEndpoints.rewriteImageUrl(json['imageUrl'] as String)
              : 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop', // default if null
        )).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load dashboard data: ${e.message}');
    }
  }
}
