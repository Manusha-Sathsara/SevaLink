import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'worker_feed_provider.dart';

enum JobStatus { active, pending, completed }

class WorkerJob {
  final String id;
  final String title;
  final String clientName;
  final String location;
  final String date;
  final String budget;
  final JobStatus status;
  final String? category;

  const WorkerJob({
    required this.id,
    required this.title,
    required this.clientName,
    required this.location,
    required this.date,
    required this.budget,
    required this.status,
    this.category,
  });

  WorkerJob copyWith({JobStatus? status}) {
    return WorkerJob(
      id: id,
      title: title,
      clientName: clientName,
      location: location,
      date: date,
      budget: budget,
      status: status ?? this.status,
      category: category,
    );
  }
}

class WorkerJobsListState {
  final List<WorkerJob> jobs;
  final bool isLoading;
  final String? error;

  const WorkerJobsListState({
    this.jobs = const [],
    this.isLoading = false,
    this.error,
  });

  WorkerJobsListState copyWith({
    List<WorkerJob>? jobs,
    bool? isLoading,
    String? error,
  }) {
    return WorkerJobsListState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WorkerJobsListNotifier extends Notifier<WorkerJobsListState> {
  @override
  WorkerJobsListState build() {
    // Load jobs automatically when provider is read
    Future.microtask(() => loadJobs());
    return const WorkerJobsListState(isLoading: true);
  }

  Future<void> loadJobs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dioClient = ref.read(dioClientProvider);
      final user = ref.read(authProvider).user;

      if (user == null) throw Exception('Not logged in');

      // Find worker profile by user id (from workerFeedProvider stats or workers API)
      int? workerId = ref.read(workerFeedProvider).stats.workerId;
      if (workerId == null || workerId == 0) {
        final workersResponse = await dioClient.dio.get('/workers');
        final List<dynamic> workersData = workersResponse.data;
        final workerEntry = workersData.firstWhere(
          (w) => w['user'] != null && w['user']['id'] == user.id,
          orElse: () => null,
        );
        if (workerEntry != null) {
          workerId = workerEntry['id'];
        }
      }

      if (workerId == null || workerId == 0) {
        throw Exception('Worker profile not found');
      }

      // Fetch worker quotations
      final response = await dioClient.dio.get('/quotations/worker/$workerId');
      final List<dynamic> data = response.data;

      final List<WorkerJob> jobsList = [];
      for (final item in data) {
        final statusStr = item['status'] ?? 'PENDING';
        if (statusStr == 'REJECTED') continue; // Skip rejected ones

        final jobPost = item['jobPost'];
        if (jobPost == null) continue;

        // Skip if the job itself was cancelled or deleted by client
        final jobStatusStrCheck = jobPost['status'] ?? 'OPEN';
        if (jobStatusStrCheck == 'CANCELLED' || jobStatusStrCheck == 'DELETED') continue;

        final jobPostId = jobPost['id']?.toString() ?? '0';
        final title = jobPost['title'] ?? '';
        final location = jobPost['locationName'] ?? jobPost['location'] ?? '';

        // Safely extract client name
        final clientMap = jobPost['client'];
        final clientName = clientMap != null ? (clientMap['fullName'] ?? 'Client') : 'Client';

        // Proposed price or budget
        final proposedPrice = item['proposedPrice'] ?? 0.0;
        final budgetStr = 'Rs. ${proposedPrice.toInt()}';

        final date = jobPost['createdAt'] != null
            ? jobPost['createdAt'].toString().split('T').first
            : '';

        final jobStatusStr = jobPost['status'] ?? 'OPEN';
        JobStatus status;
        if (statusStr == 'ACCEPTED') {
          if (jobStatusStr == 'COMPLETED') {
            status = JobStatus.completed;
          } else {
            status = JobStatus.active;
          }
        } else {
          status = JobStatus.pending;
        }

        final categoryMap = jobPost['category'];
        final categoryName = categoryMap is Map ? (categoryMap['name'] ?? '') : (categoryMap ?? '');

        jobsList.add(WorkerJob(
          id: jobPostId,
          title: title,
          clientName: clientName,
          location: location,
          date: date,
          budget: budgetStr,
          status: status,
          category: categoryName.isNotEmpty ? categoryName : null,
        ));
      }

      state = state.copyWith(jobs: jobsList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Mark a job as completed (moves it to Done tab)
  Future<void> markDone(String id) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      
      // Update job timeline to COMPLETED
      await dioClient.dio.put(
        '/jobs/detail/$id/timeline',
        queryParameters: {
          'status': 'COMPLETED',
          'note': 'Job completed by worker',
        },
      );

      // Refresh the local job list and the worker home feed stats
      await loadJobs();
      ref.read(workerFeedProvider.notifier).refresh();
    } catch (e) {
      // Propagation of error can be handled in UI or log
    }
  }
}

final workerJobsListProvider = NotifierProvider<WorkerJobsListNotifier, WorkerJobsListState>(
  WorkerJobsListNotifier.new,
);
