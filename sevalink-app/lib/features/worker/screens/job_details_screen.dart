
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/job.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  Future<void> _openMap(String location, BuildContext context) async {
    final Uri mapUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    try {
      await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildStatusRow(),
                  const SizedBox(height: 20),
                  _buildBudgetCard(),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Job Description',
                    icon: Icons.description_outlined,
                    child: Text(
                      job.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _openMap(job.location, context),
                    child: _buildSection(
                      title: 'Location',
                      icon: Icons.location_on_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.map_outlined,
                                    color: Color(0xFF006B5E), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.location,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Tap to view on full map',
                                      style: TextStyle(
                                          fontSize: 13, color: Color(0xFF006B5E)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AbsorbPointer(
                            child: _EmbeddedMap(location: job.location),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Job Details',
                    icon: Icons.info_outline_rounded,
                    child: Column(
                      children: [
                        _buildDetailRow(
                            Icons.category_outlined, 'Category', job.category),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                            Icons.access_time_rounded, 'Posted', job.postedAt),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                            Icons.new_releases_outlined,
                            'Status',
                            job.isNew ? 'Newly Posted' : 'Active'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildClientCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF1A3FBB),
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3FBB), Color(0xFF0E257A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (job.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C896),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Text(
                    job.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        _buildChip(
            Icons.location_on_outlined, job.location, const Color(0xFF1A3FBB)),
        const SizedBox(width: 10),
        _buildChip(Icons.access_time_rounded, job.postedAt,
            const Color(0xFF6B7280)),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006B5E), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006B5E).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Rs.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Budget Range',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${job.minBudget} - ${job.maxBudget}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1A3FBB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 18, color: Color(0xFF1A3FBB)),
              SizedBox(width: 8),
              Text(
                'Posted By',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFE8EAF6),
                child: Text(
                  'C',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3FBB),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937)),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 14, color: Color(0xFF006B5E)),
                        SizedBox(width: 4),
                        Text('Verified Client',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF006B5E))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF006B5E), width: 1),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF006B5E),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A3FBB),
                side: const BorderSide(color: Color(0xFF1A3FBB), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Go Back',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                context.push('/worker/send-quote', extra: job);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B5E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Send Quote',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmbeddedMap extends StatefulWidget {
  final String location;
  const _EmbeddedMap({required this.location});

  @override
  State<_EmbeddedMap> createState() => _EmbeddedMapState();
}

class _EmbeddedMapState extends State<_EmbeddedMap> {
  LatLng? _target;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
  }

  Future<void> _loadCoordinates() async {
    try {
      final locations = await locationFromAddress(widget.location);
      if (locations.isNotEmpty) {
        if (mounted) {
          setState(() {
            _target = LatLng(locations.first.latitude, locations.first.longitude);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF006B5E))),
      );
    }
    
    if (_target == null) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_rounded, color: Colors.grey, size: 30),
              const SizedBox(height: 8),
              Text(
                'Could not load map for ${widget.location}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _target!, zoom: 14),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('job_location'),
              position: _target!,
            )
          },
        ),
      ),
    );
  }
}

