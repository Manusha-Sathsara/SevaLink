import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/client_dashboard_repository.dart';
import 'auth_provider.dart';
import '../../features/dashboard/screens/client_dashboard_screen.dart';

final clientDashboardRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ClientDashboardRepository(dioClient);
});

final topWorkersProvider = FutureProvider<List<WorkerProfile>>((ref) async {
  final repository = ref.watch(clientDashboardRepositoryProvider);
  return await repository.getDashboardData();
});
