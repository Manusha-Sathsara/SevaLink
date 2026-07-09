import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../data/repositories/quotation_repository.dart';
import '../data/models/quotation_model.dart';

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return QuotationRepository(dioClient);
});

final jobQuotationsProvider = FutureProvider.autoDispose.family<List<Quotation>, int>((ref, jobId) async {
  final repository = ref.watch(quotationRepositoryProvider);
  return await repository.getJobQuotations(jobId);
});
