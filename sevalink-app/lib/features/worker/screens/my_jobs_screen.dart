import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'job_details_screen.dart';
import '../../../data/models/job.dart';

//  Enums & Models

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


}

//  Mock Data — replace with Riverpod + API
const _mockWorkerJobs = [
  WorkerJob(
    id: '1',
    title: 'Electrical Wiring for New Kitchen',
    clientName: 'Sunil Perera',
    location: 'Dehiwala, Colombo',
    date: '2026-05-20',
    budget: 'Rs. 30,000',
    status: JobStatus.active,
    category: 'Electrical',
  ),
  WorkerJob(
    id: '2',
    title: 'Office Rewiring Project',
    clientName: 'Lanka Enterprises',
    location: 'Maradana, Colombo',
    date: '2026-05-23',
    budget: 'Rs. 75,000',
    status: JobStatus.active,
    category: 'Electrical',
  ),
  WorkerJob(
    id: '3',
    title: 'Bathroom Pipe Leak Repair',
    clientName: 'Kamala Silva',
    location: 'Peradeniya, Kandy',
    date: '2026-05-25',
    budget: 'Rs. 10,000',
    status: JobStatus.pending,
    category: 'Plumbing',
  ),
  WorkerJob(
    id: '4',
    title: 'Garden Lighting Setup',
    clientName: 'Priya Jayawardena',
    location: 'Battaramulla, Colombo',
    date: '2026-05-28',
    budget: 'Rs. 15,000',
    status: JobStatus.pending,
    category: 'Electrical',
  ),
  WorkerJob(
    id: '5',
    title: 'AC Installation – Living Room',
    clientName: 'Nimal Fernando',
    location: 'Nugegoda, Colombo',
    date: '2026-05-10',
    budget: 'Rs. 6,500',
    status: JobStatus.completed,
    category: 'AC Repair',
  ),
  WorkerJob(
    id: '6',
    title: 'Ceiling Fan Installation × 3',
    clientName: 'Roshan De Silva',
    location: 'Kalutara',
    date: '2026-05-05',
    budget: 'Rs. 4,500',
    status: JobStatus.completed,
    category: 'Electrical',
  ),
  WorkerJob(
    id: '7',
    title: 'DB Box Upgrade',
    clientName: 'Malini Wijesinghe',
    location: 'Moratuwa, Colombo',
    date: '2026-04-28',
    budget: 'Rs. 12,000',
    status: JobStatus.completed,
    category: 'Electrical',
  ),
];

//  Screen

class MyJobsScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const MyJobsScreen({super.key, this.showBackButton = false});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<WorkerJob> _byStatus(JobStatus s) =>
      _mockWorkerJobs.where((j) => j.status == s).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active    = _byStatus(JobStatus.active);
    final pending   = _byStatus(JobStatus.pending);
    final completed = _byStatus(JobStatus.completed);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          //  Header
          _buildHeader(active.length, pending.length, completed.length),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _JobList(
                  jobs: active,
                  emptyLabel: 'No active jobs right now',
                  onMarkDone: (_) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Job marked as done!'),
                      backgroundColor: Color(0xFF0F9B8E),
                    ),
                  ),
                ),
                _JobList(
                  jobs: pending,
                  emptyLabel: 'No upcoming jobs scheduled',
                  onViewDetails: (job) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailsScreen(
                        job: Job(
                          id: int.tryParse(job.id) ?? 0,
                          title: job.title,
                          description: 'No description available.',
                          location: job.location,
                          postedAt: job.date,
                          minBudget: 0,
                          maxBudget: 0,
                          isNew: false,
                          category: job.category ?? '',
                        ),
                      ),
                    ),
                  ),
                ),
                _JobList(jobs: completed, emptyLabel: 'No completed jobs yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int active, int pending, int completed) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3FBB), Color(0xFF0E257A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  if (widget.showBackButton) const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'My Jobs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Summary chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _summaryChip('$active', 'Active', const Color(0xFF0F9B8E)),
                  const SizedBox(width: 10),
                  _summaryChip('$pending', 'To-Do', const Color(0xFFF59E0B)),
                  const SizedBox(width: 10),
                  _summaryChip('$completed', 'Done', Colors.white54),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: [
                Tab(text: 'Active ($active)'),
                Tab(text: 'To-Do ($pending)'),
                Tab(text: 'Done ($completed)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

//  Job List

class _JobList extends StatelessWidget {
  final List<WorkerJob> jobs;
  final String emptyLabel;
  final void Function(String id)? onMarkDone;
  final void Function(WorkerJob job)? onViewDetails;

  const _JobList({
    required this.jobs,
    required this.emptyLabel,
    this.onMarkDone,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: jobs.length,
      itemBuilder: (_, i) => _JobCard(
        job: jobs[i],
        onMarkDone: onMarkDone == null ? null : () => onMarkDone!(jobs[i].id),
        onViewDetails: onViewDetails == null ? null : () => onViewDetails!(jobs[i]),
      ),
    );
  }
}

// Job Card
class _JobCard extends StatelessWidget {
  final WorkerJob job;
  final VoidCallback? onMarkDone;
  final VoidCallback? onViewDetails;
  const _JobCard({required this.job, this.onMarkDone, this.onViewDetails});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.active:    return const Color(0xFF0F9B8E);
      case JobStatus.pending:   return const Color(0xFFF59E0B);
      case JobStatus.completed: return const Color(0xFF6B7280);
    }
  }

  String get _statusLabel {
    switch (job.status) {
      case JobStatus.active:    return 'Active';
      case JobStatus.pending:   return 'To-Do';
      case JobStatus.completed: return 'Completed';
    }
  }

  IconData get _statusIcon {
    switch (job.status) {
      case JobStatus.active:    return Icons.play_circle_outline_rounded;
      case JobStatus.pending:   return Icons.schedule_rounded;
      case JobStatus.completed: return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Title + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon, color: _statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                      if (job.category != null) ...[
                        const SizedBox(height: 2),
                        Text(job.category!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            //  Details
            _infoRow(Icons.person_outline_rounded, job.clientName),
            const SizedBox(height: 6),
            _infoRow(Icons.location_on_outlined, job.location),
            const SizedBox(height: 6),
            _infoRow(Icons.calendar_today_outlined, job.date),

            const SizedBox(height: 14),

            //  Budget + action button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job.budget,
                    style: const TextStyle(
                        color: Color(0xFF006B5E),
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                const Spacer(),
                _actionButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 13)),
        ),
      ],
    );
  }

  Widget _actionButton() {
    switch (job.status) {
      case JobStatus.active:
        return ElevatedButton.icon(
          onPressed: onMarkDone,
          icon: const Icon(Icons.check_rounded,
              size: 15, color: Colors.white),
          label: const Text('Mark Done',
              style: TextStyle(color: Colors.white, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F9B8E),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );


      case JobStatus.pending:
        return OutlinedButton.icon(
          onPressed: onViewDetails,
          icon: const Icon(Icons.visibility_outlined,
              size: 15, color: Color(0xFFF59E0B)),
          label: const Text('View',
              style: TextStyle(
                  color: Color(0xFFF59E0B), fontSize: 13)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            side: const BorderSide(color: Color(0xFFF59E0B)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

      case JobStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 14, color: Color(0xFF6B7280)),
              SizedBox(width: 4),
              Text('Completed',
                  style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
    }
  }
}