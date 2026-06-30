import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/job.dart';
import 'auth_provider.dart';

class WorkerJobsState {
  final List<Job> nearbyJobs;
  final bool isLoading;
  final String? error;

  WorkerJobsState({
    this.nearbyJobs = const [],
    this.isLoading = false,
    this.error,
  });

  WorkerJobsState copyWith({
    List<Job>? nearbyJobs,
    bool? isLoading,
    String? error,
  }) {
    return WorkerJobsState(
      nearbyJobs: nearbyJobs ?? this.nearbyJobs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WorkerJobsNotifier extends Notifier<WorkerJobsState> {

  @override
  WorkerJobsState build() {
    return WorkerJobsState();
  }

  Future<void> fetchNearbyJobs(double lat, double lng, {double radius = 15.0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.get(
        '/jobs/feed/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
        },
      );
      
      final List<dynamic> data = response.data;
      final jobs = data.map((json) => Job.fromJson(json)).toList();
      
      state = state.copyWith(
        nearbyJobs: jobs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final workerJobsProvider = NotifierProvider<WorkerJobsNotifier, WorkerJobsState>(WorkerJobsNotifier.new);
