import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'worker_profile_screen.dart';
import 'job_details_screen.dart';
import 'my_jobs_screen.dart';
import '../../../data/models/job.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/worker_jobs_provider.dart';
import '../../../data/models/notification_model.dart';
//  Local UI model
class JobListing {
  final String id;
  final String title;
  final String description;
  final String location;
  final String postedAgo;
  final String minBudget;
  final String maxBudget;
  final bool isNew;

  const JobListing({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.postedAgo,
    required this.minBudget,
    required this.maxBudget,
    this.isNew = false,
  });
}

//  Mock data
const _mockJobs = [
  JobListing(
    id: '1',
    title: 'Electrical Wiring for New Kitchen',
    description:
    'Need complete electrical wiring for newly renovated kitchen including lights, power...',
    location: 'Dehiwala, Colombo',
    postedAgo: '2 hours ago',
    minBudget: '25,000',
    maxBudget: '35,000',
    isNew: true,
  ),
  JobListing(
    id: '2',
    title: 'Bathroom Pipe Leak Repair',
    description:
    'Urgent leak in bathroom sink pipe. Water dripping continuously. Need immediate fix.',
    location: 'Peradeniya, Kandy',
    postedAgo: '5 hours ago',
    minBudget: '8,000',
    maxBudget: '12,000',
    isNew: true,
  ),
  JobListing(
    id: '3',
    title: 'AC Installation – Living Room',
    description:
    'Install a 1.5 ton split AC unit. Bracket and pipe work included. Brand new unit.',
    location: 'Nugegoda, Colombo',
    postedAgo: '8 hours ago',
    minBudget: '5,000',
    maxBudget: '8,000',
    isNew: false,
  ),
];

//  Worker Home Screen
class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workerJobsProvider.notifier).fetchNearbyJobs(6.9271, 79.8612);
    });
  }

  void _goToTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      endDrawer: const _NotificationsDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  Widget _buildBody() {
    //  Read real user name from auth provider
    final user = ref.watch(authProvider).user;
    final workerName = user?.fullName ?? 'Worker';
    final hasNewNotifications = ref.watch(notificationProvider).unreadCount > 0;

    switch (_selectedIndex) {
      case 0:
        return _HomeContent(
          workerName: workerName,
          hasNewNotifications: hasNewNotifications,
          onNotificationTap: () {},
          onGoToJobs: () => _goToTab(1),
          onGoToProfile: () => _goToTab(3),
        );
      case 1:
        return const MyJobsScreen();
      case 2:
        return const _ChatPage();
      case 3:
        return const WorkerProfileScreen(showBackButton: false);
      default:
        return _HomeContent(
          workerName: workerName,
          hasNewNotifications: hasNewNotifications,
          onNotificationTap: () {},
          onGoToJobs: () => _goToTab(1),
          onGoToProfile: () => _goToTab(3),
        );
    }
  }
}

//  Home Content
class _HomeContent extends ConsumerWidget {
  final VoidCallback? onGoToJobs;
  final VoidCallback? onGoToProfile;
  final VoidCallback? onNotificationTap;
  final String workerName;
  final bool hasNewNotifications;

  const _HomeContent({
    this.workerName = 'Worker',
    this.hasNewNotifications = false,
    this.onGoToJobs,
    this.onGoToProfile,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsState = ref.watch(workerJobsProvider);
    
    // Map backend Job to JobListing for UI compatibility
    final uiJobs = jobsState.nearbyJobs.map((j) => JobListing(
      id: j.id.toString(),
      title: j.title,
      description: j.description,
      location: j.location,
      postedAgo: j.postedAt,
      minBudget: j.minBudget.toString(),
      maxBudget: j.maxBudget.toString(),
      isNew: j.isNew,
    )).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: _Header(
              workerName: workerName,
              hasNewNotifications: hasNewNotifications,
              onNotificationTap: onNotificationTap,
            )),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: _QuickAccessSection(
              onMyJobsTap: onGoToJobs,
              onProfileTap: onGoToProfile,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: const _EarningsCard(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Jobs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F9B8E).withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${uiJobs.length} new',
                    style: TextStyle(
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
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _JobCard(job: uiJobs[index]),
            ),
            childCount: uiJobs.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

//  Header

class _Header extends StatelessWidget {
  final String workerName;
  final bool hasNewNotifications;
  final VoidCallback? onNotificationTap;

  const _Header({
    required this.workerName,
    this.hasNewNotifications = false,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2FBF), Color(0xFF2B4EEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 2),

                  Text(
                    workerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  if (onNotificationTap != null) onNotificationTap!();
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
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: _StatChip(value: '156', label: 'Total Jobs')),
              SizedBox(width: 10),
              Expanded(child: _StatChip(value: '4.8', label: 'Rating')),
              SizedBox(width: 10),
              Expanded(child: _StatChip(value: 'Rs. 45k', label: 'This Month')),
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
class _QuickAccessSection extends StatelessWidget {
  final VoidCallback? onMyJobsTap;
  final VoidCallback? onProfileTap;
  const _QuickAccessSection({this.onMyJobsTap, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
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
                sublabel: '3 active jobs',
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
class _EarningsCard extends StatelessWidget {
  const _EarningsCard();

  @override
  Widget build(BuildContext context) {
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
              children: const [
                Text("Today's Earnings",
                    style:
                    TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 6),
                Text('Rs.2,450',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('+15% from yesterday',
                    style:
                    TextStyle(color: Colors.white70, fontSize: 12)),
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

//  Job Card — FIXED overflow
class _JobCard extends StatelessWidget {
  final JobListing job;
  const _JobCard({required this.job});

  // Convert local JobListing → your data-layer Job model
  Job _toDataJob() => Job(
    id: int.tryParse(job.id) ?? 0,
    title: job.title,
    description: job.description,
    location: job.location,
    postedAt: job.postedAgo,
    minBudget: int.tryParse(
        job.minBudget.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0,
    maxBudget: int.tryParse(
        job.maxBudget.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0,
    isNew: job.isNew,
    category: 'General',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
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
                style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    height: 1.4)),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // Location + time
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.location,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(job.postedAgo,
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12)),
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

            //  Buttons — each Expanded, NO overflow ever
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobDetailsScreen(job: _toDataJob()),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(
                          color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      foregroundColor: const Color(0xFF374151),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: navigate to send_quote_screen.dart
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C3A),
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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

//  Chat Placeholder
class _ChatPage extends StatelessWidget {
  const _ChatPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Chat',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('Coming soon',
              style:
              TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

//  Notifications Drawer
class _NotificationsDrawer extends ConsumerWidget {
  const _NotificationsDrawer();

  void _navigateToJob(BuildContext context, WidgetRef ref, int? jobId) {
    Navigator.pop(context); // close drawer
    // Since we only have the jobId, in a real app we'd fetch the job details here
    // or navigate to a job screen passing the ID.
    // For now we will just show a snackbar if jobId is missing.
    if (jobId != null) {
      // Find the job from workerJobsProvider
      final jobsState = ref.read(workerJobsProvider);
      try {
        final job = jobsState.nearbyJobs.firstWhere((j) => j.id == jobId);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
        );
      } catch (e) {
        // Job not found in current feed
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Expanded(
              child: notificationState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : notificationState.notifications.isEmpty
                      ? const Center(child: Text("No notifications yet"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: notificationState.notifications.length,
                          itemBuilder: (context, index) {
                            final notif = notificationState.notifications[index];
                            return _buildNotificationItem(
                              context,
                              ref,
                              notif: notif,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref, {
    required NotificationModel notif,
  }) {
    final bgColor = notif.isRead ? Colors.transparent : const Color(0xFFEFF6FF);
    final iconColor = const Color(0xFF1A3FBB);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      tileColor: bgColor,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: notif.isRead ? const Color(0xFFF3F4F6) : const Color(0xFFDDE7FF),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.work_outline_rounded, color: iconColor, size: 22),
      ),
      title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600, fontSize: 14)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(notif.message, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ),
      trailing: notif.isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
      onTap: () {
        ref.read(notificationProvider.notifier).markAsRead(notif.id);
        _navigateToJob(context, ref, notif.relatedJobId);
      },
    );
  }
}