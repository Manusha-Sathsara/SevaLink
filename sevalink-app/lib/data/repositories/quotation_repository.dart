import '../../core/network/dio_client.dart';
import '../models/quotation_model.dart';

class QuotationRepository {
  final DioClient _dioClient;

  QuotationRepository(this._dioClient);

  Future<List<Quotation>> getJobQuotations(int jobId) async {
    try {
      final response = await _dioClient.dio.get('/quotations/job/$jobId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Quotation.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch job quotations');
    } catch (e) {
      throw Exception('Error fetching job quotations: $e');
    }
  }

  Future<Quotation> acceptQuotation(int quotationId) async {
    try {
      final response = await _dioClient.dio.put('/quotations/$quotationId/accept');
      if (response.statusCode == 200) {
        return Quotation.fromJson(response.data);
      }
      throw Exception('Failed to accept quotation');
    } catch (e) {
      throw Exception('Error accepting quotation: $e');
    }
  }

  Future<Quotation> declineQuotation(int quotationId) async {
    try {
      final response = await _dioClient.dio.put('/quotations/$quotationId/reject');
      if (response.statusCode == 200) {
        return Quotation.fromJson(response.data);
      }
      throw Exception('Failed to decline quotation');
    } catch (e) {
      throw Exception('Error declining quotation: $e');
    }
  }
}
