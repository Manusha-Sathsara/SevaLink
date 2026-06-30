import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';

class PublicWorkerProfileScreen extends ConsumerStatefulWidget {
  final int workerId;
  const PublicWorkerProfileScreen({super.key, required this.workerId});

  @override
  ConsumerState<PublicWorkerProfileScreen> createState() =>
      _PublicWorkerProfileScreenState();
}

class _PublicWorkerProfileScreenState
    extends ConsumerState<PublicWorkerProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _worker;

  @override
  void initState() {
    super.initState();
    _fetchWorker();
  }

  Future<void> _fetchWorker() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/workers/${widget.workerId}');
      if (mounted) {
        setState(() {
          _worker = res.data as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callWorker(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2A9134))),
      );
    }

    if (_error != null || _worker == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A9134),
          foregroundColor: Colors.white,
          title: const Text('Worker Profile'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Could not load profile', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchWorker, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final user = _worker!['user'] as Map<String, dynamic>? ?? {};
    final name = user['fullName'] ?? 'Worker';
    final phone = user['phoneNumber'] ?? '';
    final location = user['location'] ?? '';
    final email = user['email'] ?? '';
    String? avatarUrl = user['profileImageUrl'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarUrl = ApiEndpoints.rewriteImageUrl(avatarUrl);
    }

    final rating = (_worker!['rating'] ?? 0.0).toDouble();
    final totalJobs = _worker!['totalJobs'] ?? 0;
    final experienceYears = _worker!['experienceYears'] ?? 0;
    final bio = _worker!['bio'] ?? '';
    final skills = (_worker!['skills'] ?? '') as String;
    final hourlyRateVal = _worker!['hourlyRate'];
    final hourlyRate = hourlyRateVal != null ? hourlyRateVal.toString() : '';
    final categoryName = (_worker!['category'] is Map)
        ? (_worker!['category']['name'] ?? '')
        : '';

    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'W';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Orange header background
          Positioned(
            top: 0, left: 0, right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A9134), Color(0xFF5BBA6F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Worker Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Profile card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Avatar + name row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: avatarUrl != null && avatarUrl.isNotEmpty
                                              ? Image.network(
                                                  avatarUrl,
                                                  width: 90,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (ctx, err, stack) =>
                                                      _buildInitialAvatar(initials, 90),
                                                )
                                              : _buildInitialAvatar(initials, 90),
                                        ),
                                        Positioned(
                                          right: -4,
                                          bottom: -4,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: const Icon(
                                              Icons.verified,
                                              color: Color(0xFF2A9134),
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          if (categoryName.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F8EE),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                categoryName,
                                                style: const TextStyle(
                                                  color: Color(0xFF2A9134),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  color: Color(0xFF2A9134), size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                              Text(
                                                ' ($totalJobs reviews)',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (location.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on_outlined,
                                                    size: 14,
                                                    color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    location,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Call button if phone available
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Divider(color: Colors.grey.shade100),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _callWorker(phone),
                                      icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                                      label: Text(
                                        'Call $phone',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF054A29),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Stats row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildStatCard(
                                  Icons.work_outline, '$experienceYears yrs', 'Experience'),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                  Icons.check_circle_outline, '$totalJobs', 'Jobs Done'),
                              if (hourlyRate.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                _buildStatCard(
                                    Icons.monetization_on_outlined,
                                    'Rs.$hourlyRate/hr',
                                    'Rate'),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Skills
                        if (skills.isNotEmpty) ...[
                          _buildSection(
                            'Skills',
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .map((s) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F8EE),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                              color: const Color(0xFF5BBA6F)),
                                        ),
                                        child: Text(
                                          s,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF2A9134),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Bio
                        if (bio.isNotEmpty) ...[
                          _buildSection(
                            'About',
                            Text(
                              bio,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email (non-sensitive info)
                        if (email.isNotEmpty)
                          _buildSection(
                            'Contact',
                            Row(
                              children: [
                                const Icon(Icons.email_outlined,
                                    color: Color(0xFF2A9134), size: 18),
                                const SizedBox(width: 10),
                                Text(email,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey.shade700)),
                              ],
                            ),
                          ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(String initials, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A9134), Color(0xFF054A29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.33,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2A9134), size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
