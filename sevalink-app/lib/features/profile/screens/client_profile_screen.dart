import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_profile_provider.dart';
import '../../../providers/client_jobs_provider.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  int _currentNavIndex = 3; // Profile is index 3

  void _onNavTapped(int index) {
    if (index == _currentNavIndex) return;
    switch (index) {
      case 0:
        context.go('/client/home');
        setState(() => _currentNavIndex = 0);
        break;
      case 1:
        context.go('/client/jobs');
        setState(() => _currentNavIndex = 1);
        break;
      case 2:
        context.go('/client/chat');
        setState(() => _currentNavIndex = 2);
        break;
      case 3:
        setState(() => _currentNavIndex = 3);
        break;
      default:
        setState(() => _currentNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(clientProfileProvider);
    final clientId = ref.watch(authProvider).user?.id ?? 0;
    final jobStatsAsync = ref.watch(clientJobStatsProvider(clientId));

    String fullName = 'Loading...';
    String email = 'Loading...';
    String phone = 'Loading...';
    String location = 'Loading...';
    String memberSince = 'Joined recently';
    String initials = 'U';
    String? networkImageUrl;

    if (profileState is AsyncData) {
      final profile = profileState.value!;
      fullName = profile.fullName.isNotEmpty ? profile.fullName : 'Priya Desai';
      email = profile.email.isNotEmpty ? profile.email : 'priya.desai@email.com';
      phone = profile.phoneNumber.isNotEmpty ? profile.phoneNumber : 'Not provided';
      location = profile.location?.isNotEmpty == true ? profile.location! : 'Not provided';
      initials = _getInitials(fullName);
      networkImageUrl = profile.profileImageUrl;
    } else if (profileState is AsyncError) {
      fullName = 'Error loading profile';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(initials, networkImageUrl),
            const SizedBox(height: 60),
            
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Client',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildDetailCard(Icons.mail_outline_rounded, 'Email', email),
                  const SizedBox(height: 12),
                  _buildDetailCard(Icons.phone_outlined, 'Phone', phone),
                  const SizedBox(height: 12),
                  _buildDetailCard(Icons.location_on_outlined, 'Location', location),
                  const SizedBox(height: 12),
                  _buildDetailCard(Icons.calendar_today_outlined, 'Member Since', memberSince),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/client/edit-profile');
                      },
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF054A29),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildActivityCard(jobStatsAsync),
                  
                  const SizedBox(height: 24),
                  _buildSettingsCard(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    int numWords = names.length > 2 ? 2 : names.length;
    for (int i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials.isEmpty ? 'U' : initials;
  }

  Widget _buildHeader(String initials, String? networkImageUrl) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Green header banner
        Container(
          height: 160,
          width: double.infinity,
          color: const Color(0xFF054A29),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/client/home');
                      }
                    },
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12.0, right: 48.0),
                      child: Text(
                        'My Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Avatar
        Positioned(
          bottom: -50,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF054A29),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: ClipOval(
                child: networkImageUrl != null && networkImageUrl.isNotEmpty
                    ? Image.network(
                        networkImageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(AsyncValue<Map<String, dynamic>> jobStatsAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          jobStatsAsync.when(
            data: (stats) {
              final jobsPosted = stats['total']?.toString() ?? '0';
              final completed = stats['done']?.toString() ?? '0';
              final avgRating = stats['averageRating']?.toString() ?? stats['average_rating']?.toString() ?? '0.0';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn(jobsPosted, 'Jobs Posted'),
                  _buildStatColumn(completed, 'Completed'),
                  _buildStatColumn(avgRating, 'Avg Rating'),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text('Error loading stats')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF054A29),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile('Payment Methods'),
          _buildSettingsTile('Notification Settings'),
          _buildSettingsTile('Privacy & Security'),
          _buildSettingsTile('Help & Support'),
          _buildSettingsTile(
            'Logout',
            isDestructive: true,
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              context.go('/auth/role-selection');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
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
