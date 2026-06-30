
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/job.dart';
import '../../worker/screens/job_details_screen.dart';
import '../../../core/themes/app_theme.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/notification_provider.dart';
import '../widgets/notifications_drawer.dart';

// WORKER DASHBOARD SCREEN


class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState
    extends ConsumerState<WorkerDashboardScreen> {
  int _currentNavIndex = 0;

  // Mock job feed data — replace with real API calls later
  final List<Job> _availableJobs = const [
    Job(
      id: 1,
      title: 'Electrical Wiring for New Kitchen',
      description:
          'Need complete electrical wiring for newly renovated kitchen including lights, power outlets, and safety switches.',
      location: 'Dehiwala, Colombo',
      postedAt: '2 hours ago',
      minBudget: 25000,
      maxBudget: 35000,
      isNew: true,
      category: 'Electrician',
    ),
    Job(
      id: 2,
      title: 'Bathroom Pipe Leak Repair',
      description:
          'Urgent leak in bathroom sink pipe. Water dripping continuously. Need immediate fix.',
      location: 'Peradeniya, Kandy',
      postedAt: '5 hours ago',
      minBudget: 8000,
      maxBudget: 12000,
      isNew: true,
      category: 'Plumber',
    ),
    Job(
      id: 3,
      title: 'Living Room Ceiling Fan Installation',
      description:
          'Install 3 ceiling fans in living room and 2 bedrooms. All fans are purchased and ready.',
      location: 'Nugegoda, Colombo',
      postedAt: '1 day ago',
      minBudget: 5000,
      maxBudget: 8000,
      isNew: false,
      category: 'Electrician',
    ),
    Job(
      id: 4,
      title: 'Wooden Gate and Fence Repair',
      description:
          'Wooden gate is broken at the hinge and needs full replacement. Side fence also needs patching in 2 places.',
      location: 'Gampaha',
      postedAt: '2 days ago',
      minBudget: 15000,
      maxBudget: 22000,
      isNew: false,
      category: 'Carpenter',
    ),
  ];

  int get _newJobCount => _availableJobs.where((j) => j.isNew).length;

  @override
  Widget build(BuildContext context) {
    String workerName = 'Worker';
    try {
      final user = ref.watch(authProvider).user;
      if (user != null && user.fullName.isNotEmpty) {
        workerName = user.fullName;
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: const NotificationsDrawer(),
      body: RefreshIndicator(
        color: const Color(0xFF054A29),
        onRefresh: () async =>
            await Future.delayed(const Duration(seconds: 1)),
        child: CustomScrollView(
          slivers: [
            _buildSliverHeader(workerName),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Quick action cards overlap the header using negative offset
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: _buildQuickActionCards(),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildEarningsBanner(),
                          const SizedBox(height: 24),
                          _buildAvailableJobsHeader(),
                          const SizedBox(height: 14),
                          ..._availableJobs.map(
                            (job) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildJobCard(job),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }


  // HEADER — Blue gradient with stats chips

  Widget _buildSliverHeader(String workerName) {
    return SliverToBoxAdapter(
      child: Container(
        padding:
            const EdgeInsets.only(top: 55, left: 22, right: 22, bottom: 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A9134), Color(0xFF3FA34D)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: greeting + notification bell
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Builder(
                  builder: (drawerContext) => GestureDetector(
                    onTap: () {
                      Scaffold.of(drawerContext).openEndDrawer();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        if (ref.watch(notificationProvider).unreadCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF2A9134), width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Stats row
            Row(
              children: [
                Expanded(
                    child: _buildStatChip(
                        '156', 'Total Jobs', Icons.work_outline_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatChip(
                        '4.8', 'Rating', Icons.star_outline_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatChip('Rs. 45k', 'This Month',
                        Icons.account_balance_wallet_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  // QUICK ACTION CARDS


  Widget _buildQuickActionCards() {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: colors.border, width: 1) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickCard(
                emoji: '📋',
                title: 'My Jobs',
                subtitle: '3 active jobs',
                color: const Color(0xFF2E7D32),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildQuickCard(
                emoji: '👤',
                title: 'Profile',
                subtitle: 'Edit details',
                color: const Color(0xFF137547),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }


  // EARNINGS BANNER


  Widget _buildEarningsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF054A29), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF054A29).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Earnings",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rs. 2,450',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '+15% from yesterday',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.show_chart_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }


  // AVAILABLE JOBS SECTION


  Widget _buildAvailableJobsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Available Jobs',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_newJobCount new',
            style: const TextStyle(
              color: Color(0xFF054A29),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(Job job) {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: colors.border, width: 1) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row + New badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (job.isNew) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF81C784), width: 1),
                          ),
                          child: const Text(
                            'New',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description (2 lines max)
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Location + Time

                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        job.location,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        job.postedAt,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Divider
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            // Bottom action row
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(
                children: [
                  const Text(
                    'Rs.',
                    style: TextStyle(
                      color: Color(0xFF054A29),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_formatBudget(job.minBudget)} - ${_formatBudget(job.maxBudget)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF054A29),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View Details button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => JobDetailsScreen(job: job)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFD1D5DB), width: 1.2),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Quote button
                  GestureDetector(
                    onTap: () {
                      context.push('/worker/send-quote', extra: job);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF054A29),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF054A29).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Send Quote',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBudget(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toString();
  }


  // BOTTOM NAVIGATION BAR


  Widget _buildBottomNavigationBar() {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: colors.cardBg,
        elevation: 0,
        selectedItemColor: const Color(0xFF054A29),
        unselectedItemColor: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12, height: 1.5),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 12, height: 1.5),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_outlined)),
            activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_rounded)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.work_outline_rounded)),
            activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.work_rounded)),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble_outline_rounded)),
            activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble_rounded)),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline_rounded)),
            activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_rounded)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}



