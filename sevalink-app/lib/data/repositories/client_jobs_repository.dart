import '../../core/network/dio_client.dart';

class ClientJobsRepository {
  final DioClient _dioClient;

  ClientJobsRepository(this._dioClient);

  Future<Map<String, dynamic>> getJobStats(int clientId) async {
    try {
      final response = await _dioClient.dio.get('/jobs/client/$clientId/stats');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch job stats');
    } catch (e) {
      throw Exception('Error fetching job stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getJobsWithQuotes(int clientId, {String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'ALL') {
        queryParams['status'] = status;
      }
      final response = await _dioClient.dio.get(
        '/jobs/client/$clientId/with-quotes',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Failed to fetch jobs');
    } catch (e) {
      throw Exception('Error fetching jobs: $e');
    }
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
    try {
      final response = await _dioClient.dio.post(
        '/jobs',
        data: jobData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create job');
    } catch (e) {
      throw Exception('Error creating job: $e');
    }
  }

  Future<void> deleteJob(int jobId) async {
    try {
      final response = await _dioClient.dio.delete('/jobs/$jobId');
      if (response.statusCode == 200) {
        return;
      }
      throw Exception('Failed to delete job');
    } catch (e) {
      throw Exception('Error deleting job: $e');
    }
  }
}
