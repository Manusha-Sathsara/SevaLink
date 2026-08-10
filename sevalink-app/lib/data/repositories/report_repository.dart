// lib/data/repositories/report_repository.dart
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/report.dart';

class ReportRepository {
  final DioClient _dioClient;
  ReportRepository(this._dioClient);

  /// Submit a new report
  Future<Report> createReport({
    required int reportedUserId,
    int? jobId,
    required ReportType reportType,
    required String description,
    String? evidence,
  }) async {
    try {
      final body = <String, dynamic>{
        'reportedUserId': reportedUserId,
        'reportType': reportType.name,
        'description': description,
      };
      if (jobId != null) body['jobId'] = jobId;
      if (evidence != null && evidence.isNotEmpty) body['evidence'] = evidence;

      final response = await _dioClient.dio.post(
        ApiEndpoints.createReport,
        data: body,
      );
      return Report.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all reports submitted by the logged-in user
  Future<List<Report>> getMyReports() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.myReports);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Report.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a specific report by ID
  Future<Report> getReportById(int reportId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.reportById(reportId),
      );
      return Report.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
