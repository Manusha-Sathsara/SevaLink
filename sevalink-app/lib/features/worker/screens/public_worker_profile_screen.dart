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
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchWorker();
  }

  Future<void> _fetchWorker() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final results = await Future.wait([
        dio.get('/workers/${widget.workerId}'),
        dio.get('/reviews/worker/${widget.workerId}'),
      ]);
      if (mounted) {
        setState(() {
          _worker = results[0].data as Map<String, dynamic>?;
          _reviews = results[1].data is List ? results[1].data as List : [];
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
    final bio = _worker!['bio'] ?? '';
    final experienceYears = () {
      final rawExp = _worker!['experienceYears'] as num?;
      if (rawExp != null && rawExp.toInt() > 0) {
        return rawExp.toInt();
      }
      final regex = RegExp(r'(\d+)\+?\s*(?:year|yr)', caseSensitive: false);
      final match = regex.firstMatch(bio);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '1') ?? 1;
      }
      return 1; // default fallback
    }();
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
                                    Icons.payments_outlined,
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

                        const SizedBox(height: 16),

                        // Rating Summary
                        if (_reviews.isNotEmpty) ...[
                          _buildRatingSummaryCard(),
                          const SizedBox(height: 16),
                        ],

                        // Reviews list
                        _buildReviewsSection(),

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

  // Rating Summary Card
  Widget _buildRatingSummaryCard() {
    // Tally up star counts
    final counts = [0, 0, 0, 0, 0]; // index 0 = 1★ … index 4 = 5★
    double total = 0;
    for (final review in _reviews) {
      final r = (review['rating'] as num?)?.toInt() ?? 0;
      if (r >= 1 && r <= 5) {
        counts[r - 1]++;
        total += r;
      }
    }
    final avg = _reviews.isEmpty ? 0.0 : total / _reviews.length;
    final maxCount = counts.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ratings & Reviews',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Big average score
                Column(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 18,
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Breakdown bars (5★ → 1★)
                Expanded(
                  child: Column(
                    children: List.generate(5, (i) {
                      final starLabel = 5 - i;
                      final count = counts[starLabel - 1];
                      final fraction = maxCount == 0 ? 0.0 : count / maxCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              '$starLabel',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2A9134)),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 20,
                              child: Text(
                                '$count',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //  Reviews List Section
  Widget _buildReviewsSection() {
    if (_reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                'No reviews yet',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to review this worker!',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _reviews.map((review) => _buildReviewCard(review)).toList(),
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final client = review['client'] as Map? ?? {};
    final clientName = client['fullName'] as String? ?? 'Client';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final photoUrlsRaw = review['photoUrls'] as String? ?? '';
    final photoFileNames = photoUrlsRaw.isNotEmpty
        ? photoUrlsRaw.split(',').where((s) => s.trim().isNotEmpty).toList()
        : <String>[];
    final createdAt = review['createdAt'] as String?;
    final dateLabel = _formatRelativeDate(createdAt);
    final initials = clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE8F8EE),
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A9134), fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 14,
                        )),
                        const SizedBox(width: 6),
                        Text(
                          dateLabel,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
            ),
          ],
          // Photo thumbnails
          if (photoFileNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: photoFileNames.map((fileName) {
                  final url = ApiEndpoints.rewriteImageUrl(
                    '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/api/public/uploads/$fileName',
                  );
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRelativeDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} yr ago';
      if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} mo ago';
      if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      if (diff.inHours >= 1) return '${diff.inHours} hr ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}

