// lib/features/reports/screens/my_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/report.dart';
import '../../../providers/report_provider.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.PENDING:
        return const Color(0xFFF59E0B);
      case ReportStatus.UNDER_REVIEW:
        return const Color(0xFF3B82F6);
      case ReportStatus.ACTION_TAKEN:
        return const Color(0xFF10B981);
      case ReportStatus.DISMISSED:
        return const Color(0xFF6B7280);
    }
  }

  IconData _statusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.PENDING:
        return Icons.hourglass_empty_rounded;
      case ReportStatus.UNDER_REVIEW:
        return Icons.manage_search_rounded;
      case ReportStatus.ACTION_TAKEN:
        return Icons.check_circle_rounded;
      case ReportStatus.DISMISSED:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(myReportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Reports',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F9B8E)),
            onPressed: () => ref.read(myReportsProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: reportsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(myReportsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_off_rounded,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No reports submitted yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When you report a user, it will appear here.',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final report = reports[index];
              final color = _statusColor(report.status);

              return GestureDetector(
                onTap: () => context.push(
                  '/reports/detail',
                  extra: report.id,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Icon(_statusIcon(report.status), color: color, size: 18),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              report.status.displayName,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(report.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Report type
                      Text(
                        report.reportType.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Against user
                      Text(
                        'Against: ${report.reportedUserName}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Description preview
                      Text(
                        report.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tap hint
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'View details →',
                          style: TextStyle(
                            color: Color(0xFF0F9B8E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
