import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/client_jobs_provider.dart';
import '../../../providers/auth_provider.dart';

class ClientJobsScreen extends ConsumerStatefulWidget {
  const ClientJobsScreen({super.key});

  @override
  ConsumerState<ClientJobsScreen> createState() => _ClientJobsScreenState();
}

class _ClientJobsScreenState extends ConsumerState<ClientJobsScreen>
    with WidgetsBindingObserver {
  final int _currentNavIndex = 1; // Jobs tab
  int _selectedTabIndex = 0;
  final List<String> _statusFilters = ['OPEN', 'ASSIGNED', 'COMPLETED', 'CANCELLED'];
  int _prevCompletedCount = 0;

  void _onNavTapped(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0:
        context.go('/client/home');
        break;
      case 1:
        break; // Already here
      case 2:
        context.go('/client/chat');
        break;
      case 3:
        context.go('/client/profile');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshJobs();
    }
  }

  void _refreshJobs() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.invalidate(clientJobStatsProvider(user.id));
      ref.invalidate(clientJobsProvider);
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (e) {
      return '';
    }
  }

  Future<void> _deleteJob(int jobId) async {
    try {
      final repository = ref.read(clientJobsRepositoryProvider);
      await repository.deleteJob(jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job post deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Invalidate stats and jobs providers
        final user = ref.read(authProvider).user;
        if (user != null) {
          ref.invalidate(clientJobStatsProvider(user.id));
          ref.invalidate(clientJobsProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(int jobId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Job Posted?'),
        content: const Text(
          'Are you sure you want to permanently remove this job post? This will delete all associated quotations and progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteJob(jobId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final clientId = user?.id ?? 0;
    final statsAsync = ref.watch(clientJobStatsProvider(clientId));
    final jobsAsync = ref.watch(clientJobsProvider(ClientJobsParams(
      clientId: clientId,
      status: _statusFilters[_selectedTabIndex],
    )));

    // Watch completed count to auto-switch tab when a job finishes
    final completedAsync = ref.watch(clientJobsProvider(ClientJobsParams(
      clientId: clientId,
      status: 'COMPLETED',
    )));
    completedAsync.whenData((completedJobs) {
      final count = completedJobs.length;
      if (count > _prevCompletedCount) {
        _prevCompletedCount = count;
        if (_selectedTabIndex != 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedTabIndex = 2);
          });
        }
      } else {
        _prevCompletedCount = count;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF2A9134), // Deep orange background for top
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/client/home'),
                      ),
                      const Text(
                        'My Jobs',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () => context.push('/client/jobs/post'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: statsAsync.when(
                    data: (stats) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatSquare('${stats['total'] ?? 0}', 'Total'),
                        _buildStatSquare('${stats['open'] ?? 0}', 'Open'),
                        _buildStatSquare('${stats['active'] ?? 0}', 'Active'),
                        _buildStatSquare('${stats['done'] ?? 0}', 'Done'),
                      ],
                    ),
                    loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Colors.white))),
                    error: (err, stack) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatSquare('0', 'Total'),
                        _buildStatSquare('0', 'Open'),
                        _buildStatSquare('0', 'Active'),
                        _buildStatSquare('0', 'Done'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // White Overlap Container (Tabs & Jobs)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Tabs without scrollbar
                  Padding(
                    padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildTabItem(0, 'Open', null),
                          const SizedBox(width: 16),
                          _buildTabItem(1, 'In Progress', null),
                          const SizedBox(width: 16),
                          _buildTabItem(2, 'Completed', Icons.check_circle_outline),
                          const SizedBox(width: 16),
                          _buildTabItem(3, 'Cancelled', Icons.cancel_outlined),
                        ],
                      ),
                    ),
                  ),
                  
                  // Job count + Filter
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        jobsAsync.when(
                          data: (jobs) => Text(
                            '${jobs.length} Jobs',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          loading: () => const Text('Loading...'),
                          error: (err, stack) => const Text('0 Jobs'),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Filter',
                                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Job list
                  Expanded(
                    child: jobsAsync.when(
                      data: (jobs) => jobs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.work_off_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No jobs found',
                                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              itemCount: jobs.length,
                              itemBuilder: (context, index) => _buildJobCard(jobs[index]),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2A9134))),
                      error: (e, _) => Center(child: Text('Error loading jobs: $e')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildStatSquare(String value, String label) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData? icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF1F2937) : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1F2937) : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? 'OPEN';
    final urgency = job['urgency'] ?? 'FLEXIBLE';
    final budgetMin = job['budgetMin'];
    final budgetMax = job['budgetMax'];
    final quoteCount = job['quoteCount'] ?? 5; // Default to 5 for UI parity if null
    final createdAt = job['createdAt']?.toString();

    // The UI shows Open badge as light blue bg and blue text
    Color statusBgColor;
    Color statusTextColor;
    switch (status) {
      case 'OPEN':
        statusBgColor = const Color(0xFFE8F8EE); // Light blue
        statusTextColor = const Color(0xFF4338CA); // Blue
        break;
      case 'ASSIGNED':
        statusBgColor = const Color(0xFFE8F8EE); // Light amber
        statusTextColor = const Color(0xFF2A9134); // Amber
        break;
      case 'COMPLETED':
        statusBgColor = const Color(0xFFDCFCE7); // Light green
        statusTextColor = const Color(0xFF15803D); // Green
        break;
      default:
        statusBgColor = Colors.grey.shade200;
        statusTextColor = Colors.grey.shade700;
    }

    return GestureDetector(
      onTap: () {
        if (job['id'] != null) {
          if (status == 'OPEN') {
            context.push('/client/jobs/${job['id']}/quotes', extra: job);
          } else {
            context.push('/client/jobs/${job['id']}/timeline');
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job['title'] ?? 'Electrical Wiring for New Kitchen',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status == 'ASSIGNED' ? 'Active' : status[0] + status.substring(1).toLowerCase(),
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmationDialog(job['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Remove Job', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
  
            // Category
            Text(
              job['categoryName'] ?? 'Electrician',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 14),
  
            // Description
            Text(
              job['description'] ?? 'Need complete electrical wiring for newly renovated kitchen including lights, power...',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
  
            // Urgency badge
            if (urgency == 'URGENT')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Urgent',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 16),
  
            // Budget + Time + Quotes
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Rs. ${_formatBudget(budgetMin ?? 25000)} - Rs. ${_formatBudget(budgetMax ?? 35000)}',
                    style: const TextStyle(
                      color: Color(0xFF2A9134), // Orange text
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  createdAt != null ? _timeAgo(createdAt) : '2 hours ago',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    if (job['id'] != null) {
                      context.push('/client/jobs/${job['id']}/quotes', extra: job);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$quoteCount',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        'Quotes',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  }

  String _formatBudget(dynamic amount) {
    if (amount == null) return '0';
    final num = amount is double ? amount.toInt() : amount as int;
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(num % 1000 == 0 ? 0 : 1)}K'.replaceAll('.0K', ',000');
    }
    return num.toString();
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF006B3D),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, height: 1.5),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.work_outline_rounded)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.work_rounded)),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.chat_bubble_outline_rounded)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.chat_bubble_rounded)),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline_rounded)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
