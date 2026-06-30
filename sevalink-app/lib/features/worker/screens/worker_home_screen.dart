import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'worker_profile_screen.dart';
import 'worker_onboarding_screen.dart';
import 'job_details_screen.dart';
import 'my_jobs_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../../data/models/job.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/worker_feed_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../jobs/screens/job_location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// (Mock data removed — now using real backend feed)

//  Worker Home Screen
class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  int _selectedIndex = 0;

  void _goToTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(workerFeedProvider);
    final stats = feedState.stats;

    // Check if worker profile stats are loaded but incomplete
    final isProfileIncomplete = stats.workerId != null &&
        (stats.categoryId == null || stats.location.isEmpty || stats.hourlyRate.isEmpty);

    if (!feedState.isLoading && feedState.error == null && isProfileIncomplete) {
      return const WorkerOnboardingScreen();
    }

    return Scaffold(
      backgroundColor: context.sevaColors.bodyBg,
      endDrawer: const _NotificationsDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  Widget _buildBody() {
    final user = ref.watch(authProvider).user;
    final stats = ref.watch(workerFeedProvider).stats;
    final workerName = stats.fullName.isNotEmpty ? stats.fullName : (user?.fullName ?? 'Worker');
    final hasNewNotifications = ref.watch(notificationProvider).unreadCount > 0;

    switch (_selectedIndex) {
      case 0:
        return _HomeContent(
          workerName: workerName,
          hasNewNotifications: hasNewNotifications,
          onGoToJobs: () => _goToTab(1),
          onGoToProfile: () => _goToTab(3),
        );
      case 1:
        return const MyJobsScreen();
      case 2:
        return const ChatListScreen(showBottomNav: false);
      case 3:
        return const WorkerProfileScreen(showBackButton: false);
      default:
        return _HomeContent(
          workerName: workerName,
          hasNewNotifications: hasNewNotifications,
          onGoToJobs: () => _goToTab(1),
          onGoToProfile: () => _goToTab(3),
        );
    }
  }
}

// ─── Home Content (connected to real backend) ─────────────────────────────────
class _HomeContent extends ConsumerWidget {
  final VoidCallback? onGoToJobs;
  final VoidCallback? onGoToProfile;
  final String workerName;
  final bool hasNewNotifications;

  const _HomeContent({
    this.workerName = 'Worker',
    this.hasNewNotifications = false,
    this.onGoToJobs,
    this.onGoToProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(workerFeedProvider);
    final jobs = feedState.jobs;
    final isLoading = feedState.isLoading;
    final error = feedState.error;
    final newCount = jobs.where((j) => j.isNew).length;

    return RefreshIndicator(
      color: const Color(0xFF0F9B8E),
      onRefresh: () => ref.read(workerFeedProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _Header(
                  workerName: workerName,
                  hasNewNotifications: hasNewNotifications,
                  stats: feedState.stats,
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: _QuickAccessSection(
                    onMyJobsTap: onGoToJobs,
                    onProfileTap: onGoToProfile,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: const _EarningsCard(),
            ),
          ),
          // ── Section header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Jobs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.sevaColors.textPrimary,
                    ),
                  ),
                  if (!isLoading && newCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F9B8E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$newCount new',
                        style: const TextStyle(
                          color: Color(0xFF0F9B8E),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ── Loading state ─────────────────────────────────────────────────
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0F9B8E)),
              ),
            )
          // ── Error state ───────────────────────────────────────────────────
          else if (error != null)
            SliverFillRemaining(
              child: _ErrorView(
                onRetry: () =>
                    ref.read(workerFeedProvider.notifier).refresh(),
              ),
            )
          // ── Empty state ───────────────────────────────────────────────────
          else if (jobs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_off_outlined,
                        size: 64,
                        color: context.sevaColors.textSecondary
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No open jobs right now',
                      style: TextStyle(
                          color: context.sevaColors.textSecondary,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(
                          color: context.sevaColors.textSecondary
                              .withValues(alpha: 0.6),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          // ── Jobs list ─────────────────────────────────────────────────────
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _JobCard(job: jobs[index]),
                ),
                childCount: jobs.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 64,
              color: context.sevaColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'Could not load jobs',
            style: TextStyle(
                color: context.sevaColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again',
            style: TextStyle(
                color: context.sevaColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9B8E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

//  Header

class _Header extends ConsumerWidget {
  final String workerName;
  final bool hasNewNotifications;
  final WorkerStats stats;

  const _Header({
    required this.workerName,
    this.hasNewNotifications = false,
    this.stats = const WorkerStats(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD3410A), Color(0xFFE8520B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Scaffold.of(context).openEndDrawer();
                },
                child: Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    if (hasNewNotifications)
                      Positioned(
                        top: 7,
                        right: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Location & Availability Selector Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final currentLatLng = (stats.latitude != null && stats.longitude != null)
                        ? LatLng(stats.latitude!, stats.longitude!)
                        : null;
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobLocationPickerScreen(
                          initialLocation: currentLatLng,
                        ),
                      ),
                    );

                    if (result != null) {
                      final lat = result['latitude'] as double?;
                      final lng = result['longitude'] as double?;
                      final address = result['address'] as String? ?? '';
                      if (address.isNotEmpty) {
                        await ref.read(workerFeedProvider.notifier).updateLocation(
                          location: address,
                          latitude: lat,
                          longitude: lng,
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stats.location.isNotEmpty ? stats.location : 'Set Location',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Availability status pill (Tap to toggle)
              InkWell(
                onTap: () async {
                  await ref.read(workerFeedProvider.notifier).updateAvailability(!stats.isAvailable);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: stats.isAvailable
                        ? const Color(0xFF27AE60).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: stats.isAvailable ? const Color(0xFF27AE60) : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: stats.isAvailable ? const Color(0xFF2EC76E) : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stats.isAvailable ? 'Available' : 'Busy',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  value: '${stats.totalJobs}',
                  label: 'Total Jobs',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  value: stats.rating > 0
                      ? stats.rating.toStringAsFixed(1)
                      : '—',
                  label: 'Rating',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  value: stats.isAvailable ? 'Available' : 'Busy',
                  label: 'Status',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(

        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

//  Quick Access
class _QuickAccessSection extends ConsumerWidget {
  final VoidCallback? onMyJobsTap;
  final VoidCallback? onProfileTap;
  const _QuickAccessSection({this.onMyJobsTap, this.onProfileTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sevaColors;
    final isDark  = context.isDark;
    // Watch the live jobs list to get real active count
    final jobs = ref.watch(workerJobsListProvider).jobs;
    final activeCount = jobs.where((j) => j.status == JobStatus.active).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: colors.border, width: 1) : null,
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _QuickCard(
                label: 'My Jobs',
                sublabel: '$activeCount active ${activeCount == 1 ? 'job' : 'jobs'}',
                color: const Color(0xFF27AE60),
                icon: Icons.assignment_outlined,
                onTap: onMyJobsTap ?? () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                label: 'Profile',
                sublabel: 'Edit details',
                color: const Color(0xFF8B2FC9),
                icon: Icons.person_outline,
                onTap: onProfileTap ?? () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickCard({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 26),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text(sublabel,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// Earnings Card
class _EarningsCard extends ConsumerWidget {
  const _EarningsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsState = ref.watch(workerJobsListProvider);
    final jobs = jobsState.jobs;

    final todayStr = DateTime.now().toString().split(' ').first;
    final todayEarnings = jobs
        .where((j) => j.status == JobStatus.completed && j.date == todayStr)
        .fold<int>(0, (sum, j) {
      final cleanStr = j.budget.replaceAll('Rs. ', '').replaceAll(',', '');
      return sum + (int.tryParse(cleanStr) ?? 0);
    });

    final totalEarnings = jobs
        .where((j) => j.status == JobStatus.completed)
        .fold<int>(0, (sum, j) {
      final cleanStr = j.budget.replaceAll('Rs. ', '').replaceAll(',', '');
      return sum + (int.tryParse(cleanStr) ?? 0);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9B8E), Color(0xFF0D7A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Earnings",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Rs. ${todayEarnings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Total Earnings: Rs. ${totalEarnings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.trending_up_rounded,
              color: Colors.white, size: 36),
        ],
      ),
    );
  }
}

// ─── Job Card (real backend Job model) ───────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Job job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final colors = context.sevaColors;
    final isDark  = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: colors.border, width: 1) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + New badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(job.title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                ),
                if (job.isNew) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F9B8E).withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('New',
                        style: TextStyle(
                            color: Color(0xFF0F9B8E),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 6),
            Text(job.description,
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4)),

            const SizedBox(height: 12),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 12),

            // Location + time
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                      job.location + (job.distanceKm != null ? ' (${job.distanceKm!.toStringAsFixed(1)} km)' : ''),
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time,
                    size: 14, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(job.postedAt,
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 12)),
              ],
            ),

            const SizedBox(height: 10),

            // Budget — own row so it never competes with buttons
            Row(
              children: [
                const Text(
                  'Rs.',
                  style: TextStyle(
                    color: Color(0xFF0F9B8E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${job.minBudget} - ${job.maxBudget}',
                    style: const TextStyle(
                        color: Color(0xFF0F9B8E),
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Action buttons ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailsScreen(job: job),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      foregroundColor: colors.textPrimary,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/worker/send-quote', extra: job);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C3A),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Send Quote',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//  Bottom Navigation
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.sevaColors;
    final isDark  = context.isDark;
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Home'},
      {'icon': Icons.work_outline, 'active': Icons.work, 'label': 'Jobs'},
      {
        'icon': Icons.chat_bubble_outline,
        'active': Icons.chat_bubble,
        'label': 'Chat'
      },
      {
        'icon': Icons.person_outline,
        'active': Icons.person,
        'label': 'Profile'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == selectedIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected
                          ? items[i]['active'] as IconData
                          : items[i]['icon'] as IconData,
                      color: selected
                          ? const Color(0xFF0F9B8E)
                          : const Color(0xFF9CA3AF),
                      size: 24,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? const Color(0xFF0F9B8E)
                            : const Color(0xFF9CA3AF),
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Notifications Drawer ─────────────────────────────────────────────────────
class _NotificationsDrawer extends ConsumerWidget {
  const _NotificationsDrawer();

  void _handleNotificationTap(BuildContext context, WidgetRef ref, int notifId) {
    ref.read(notificationProvider.notifier).markAsRead(notifId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sevaColors;
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;

    return Drawer(
      backgroundColor: colors.cardBg,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (notificationState.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${notificationState.unreadCount} New',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(
              child: notificationState.isLoading && notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 52, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No notifications yet',
                                  style: TextStyle(color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notif = notifications[index];
                            return InkWell(
                              onTap: () => _handleNotificationTap(context, ref, notif.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: notif.isRead ? Colors.transparent : const Color(0xFF0F9B8E).withValues(alpha: 0.05),
                                  border: Border(bottom: BorderSide(color: colors.divider)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: notif.isRead ? Colors.grey.shade100 : const Color(0xFF0F9B8E).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.notifications_active,
                                        color: notif.isRead ? Colors.grey.shade400 : const Color(0xFF0F9B8E),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                              fontSize: 15,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.message,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}