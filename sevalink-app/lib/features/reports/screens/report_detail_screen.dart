// lib/features/reports/screens/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/report.dart';
import '../../../providers/report_provider.dart';

class ReportDetailScreen extends ConsumerWidget {
  final int reportId;
  const ReportDetailScreen({super.key, required this.reportId});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportDetailProvider(reportId));

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
          'Report Details',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: reportState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.red)),
        ),
        data: (report) {
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }
          return _buildContent(context, report);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Report report) {
    final statusColor = _statusColor(report.status);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Status banner ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: statusColor),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Status',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    report.status.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Report info card ─────────────────────────────────
        _SectionCard(
          title: 'Report Information',
          children: [
            _InfoRow(
              label: 'Report ID',
              value: '#${report.id}',
            ),
            _InfoRow(
              label: 'Type',
              value: report.reportType.displayName,
            ),
            _InfoRow(
              label: 'Reported User',
              value: report.reportedUserName,
            ),
            if (report.jobTitle != null)
              _InfoRow(
                label: 'Related Job',
                value: report.jobTitle!,
              ),
            _InfoRow(
              label: 'Submitted',
              value: _formatDate(report.createdAt),
            ),
            _InfoRow(
              label: 'Last Updated',
              value: _formatDate(report.updatedAt),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Description ──────────────────────────────────────
        _SectionCard(
          title: 'Description',
          children: [
            Text(
              report.description,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),

        // ── Evidence (if any) ────────────────────────────────
        if (report.evidence != null && report.evidence!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Evidence',
            children: [
              Text(
                report.evidence!,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],

        // ── Admin response (if any) ──────────────────────────
        if (report.adminNote != null && report.adminNote!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Admin Note',
            headerColor: const Color(0xFF1E40AF),
            children: [
              Text(
                report.adminNote!,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],

        if (report.actionTaken != null && report.actionTaken!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Action Taken',
            headerColor: const Color(0xFF065F46),
            children: [
              Text(
                report.actionTaken!,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ─────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color headerColor;

  const _SectionCard({
    required this.title,
    required this.children,
    this.headerColor = const Color(0xFF1A1A2E),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: headerColor,
              ),
            ),
          ),
          const Divider(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
