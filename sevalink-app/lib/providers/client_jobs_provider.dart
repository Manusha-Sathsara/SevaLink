import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/client_jobs_repository.dart';
import '../providers/auth_provider.dart';

final clientJobsRepositoryProvider = Provider<ClientJobsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ClientJobsRepository(dioClient);
});

final clientJobStatsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, clientId) async {
  final repository = ref.watch(clientJobsRepositoryProvider);
  return await repository.getJobStats(clientId);
});

class ClientJobsParams {
  final int clientId;
  final String status;

  ClientJobsParams({required this.clientId, required this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientJobsParams &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          status == other.status;

  @override
  int get hashCode => clientId.hashCode ^ status.hashCode;
}

final clientJobsProvider = FutureProvider.family<List<Map<String, dynamic>>, ClientJobsParams>((ref, params) async {
  final repository = ref.watch(clientJobsRepositoryProvider);
  return await repository.getJobsWithQuotes(params.clientId, status: params.status);
});
