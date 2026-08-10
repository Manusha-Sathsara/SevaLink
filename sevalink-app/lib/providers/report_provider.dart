// lib/providers/report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/report.dart';
import '../data/repositories/report_repository.dart';
import 'auth_provider.dart'; // provides dioClientProvider

// ─────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReportRepository(dioClient);
});

// ─────────────────────────────────────────────
// My Reports provider (user's submitted reports)
// ─────────────────────────────────────────────
final myReportsProvider =
    NotifierProvider.autoDispose<MyReportsNotifier, AsyncValue<List<Report>>>(
  MyReportsNotifier.new,
);

class MyReportsNotifier
    extends AutoDisposeNotifier<AsyncValue<List<Report>>> {
  late final ReportRepository _repository;

  @override
  AsyncValue<List<Report>> build() {
    _repository = ref.read(reportRepositoryProvider);
    _fetch();
    return const AsyncValue.loading();
  }

  Future<void> _fetch() async {
    try {
      final reports = await _repository.getMyReports();
      state = AsyncValue.data(reports);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _fetch();
}

// ─────────────────────────────────────────────
// Single report provider (by ID)
// ─────────────────────────────────────────────
final reportDetailProvider = NotifierProvider.autoDispose
    .family<ReportDetailNotifier, AsyncValue<Report?>, int>(
  ReportDetailNotifier.new,
);

class ReportDetailNotifier
    extends AutoDisposeFamilyNotifier<AsyncValue<Report?>, int> {
  late final ReportRepository _repository;

  @override
  AsyncValue<Report?> build(int id) {
    _repository = ref.read(reportRepositoryProvider);
    _fetch(id);
    return const AsyncValue.loading();
  }

  Future<void> _fetch(int id) async {
    try {
      final report = await _repository.getReportById(id);
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ─────────────────────────────────────────────
// Submit report notifier (handles create action)
// ─────────────────────────────────────────────
class ReportSubmitState {
  final bool isLoading;
  final String? error;
  final bool success;

  const ReportSubmitState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  ReportSubmitState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return ReportSubmitState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

final reportSubmitProvider =
    NotifierProvider.autoDispose<ReportSubmitNotifier, ReportSubmitState>(
  ReportSubmitNotifier.new,
);

class ReportSubmitNotifier
    extends AutoDisposeNotifier<ReportSubmitState> {
  late final ReportRepository _repository;

  @override
  ReportSubmitState build() {
    _repository = ref.read(reportRepositoryProvider);
    return const ReportSubmitState();
  }

  Future<bool> submit({
    required int reportedUserId,
    int? jobId,
    required ReportType reportType,
    required String description,
    String? evidence,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repository.createReport(
        reportedUserId: reportedUserId,
        jobId: jobId,
        reportType: reportType,
        description: description,
        evidence: evidence,
      );
      state = state.copyWith(isLoading: false, success: true);
      // Invalidate my reports so it refreshes on next view
      ref.invalidate(myReportsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
