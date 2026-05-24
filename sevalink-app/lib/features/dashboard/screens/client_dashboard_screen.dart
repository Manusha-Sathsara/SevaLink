import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Assuming this is the correct path based on the original codebase structure
import '../../../providers/auth_provider.dart';

// ============================================================================
// DOMAIN MODELS (Mock Data Structures)
// ============================================================================

class ServiceCategory {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const ServiceCategory({
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class WorkerProfile {
  final String name;
  final String profession;
  final int hourlyRate;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String imageUrl;

  const WorkerProfile({
    required this.name,
    required this.profession,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.imageUrl,
  });
}

// ============================================================================
// MAIN DASHBOARD SCREEN
// ============================================================================

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
  int _currentNavIndex = 0;

  // --- Static Data Provisioning to Match Design Specifications ---
  final List<ServiceCategory> _categories = const [
    ServiceCategory(title: 'Electrician', icon: Icons.bolt_outlined, bgColor: Color(0xFFFEF5E5), iconColor: Color(0xFFD49A00)),
    ServiceCategory(title: 'Plumber', icon: Icons.plumbing_outlined, bgColor: Color(0xFFE8F1FE), iconColor: Color(0xFF2962FF)),
    ServiceCategory(title: 'Carpenter', icon: Icons.handyman_outlined, bgColor: Color(0xFFFEF0E5), iconColor: Color(0xFFE65C00)),
    ServiceCategory(title: 'Painter', icon: Icons.format_paint_outlined, bgColor: Color(0xFFF4EBFE), iconColor: Color(0xFF9C27B0)),
    ServiceCategory(title: 'Cleaner', icon: Icons.auto_awesome_outlined, bgColor: Color(0xFFFEE8F0), iconColor: Color(0xFFE91E63)),
    ServiceCategory(title: 'Mechanic', icon: Icons.settings_outlined, bgColor: Color(0xFFF0F4F8), iconColor: Color(0xFF455A64)),
    ServiceCategory(title: 'Gardener', icon: Icons.eco_outlined, bgColor: Color(0xFFE8F8EE), iconColor: Color(0xFF2E7D32)),
    ServiceCategory(title: 'Technician', icon: Icons.laptop_chromebook_outlined, bgColor: Color(0xFFE8EAF6), iconColor: Color(0xFF3F51B5)),
  ];

  final List<WorkerProfile> _topWorkers = const [
    WorkerProfile(
      name: 'Sunil Perera',
      profession: 'Electrician',
      hourlyRate: 1200,
      rating: 4.8,
      reviewCount: 156,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop', 
    ),
    WorkerProfile(
      name: 'Nimal Silva',
      profession: 'Plumber',
      hourlyRate: 1400,
      rating: 4.9,
      reviewCount: 203,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?q=80&w=300&auto=format&fit=crop',
    ),
    WorkerProfile(
      name: 'Lakshman Fernando',
      profession: 'Carpenter',
      hourlyRate: 1600,
      rating: 4.7,
      reviewCount: 127,
      isVerified: true,
      imageUrl: 'https://images.unsplash.com/photo-1534081333815-ae5019106622?q=80&w=300&auto=format&fit=crop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Graceful fallback for authentication state retrieval
    String displayFullName = "Dilini Rajapaksa";
    
    try {
      final user = ref.watch(authProvider).user;
      if (user != null && user.fullName != null && user.fullName!.isNotEmpty) {
        displayFullName = user.fullName!;
      }
    } catch (_) {
      // Catch exceptions to ensure UI layout stability if provider fails
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Neutral background to enhance contrast
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Implementation of the overlapping Z-axis header design
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildOrangeHeader(displayFullName),
                
                // Positioned padding forces the quick action cards to straddle the header boundary
                Padding(
                  padding: const EdgeInsets.only(top: 230.0), 
                  child: _buildQuickActionCards(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildServiceCategories(),
            const SizedBox(height: 32),
            _buildTopRatedWorkers(),
            const SizedBox(height: 32),
            _buildTrustBanner(),
            const SizedBox(height: 40), // Ensures scroll clearance above the bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================================================
  // COMPONENT BUILDERS
  // ==========================================================================

  Widget _buildOrangeHeader(String userName) {
    return Container(
      height: 290,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 65, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFE65100), // Primary vibrant orange establishing brand identity
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row containing the dynamic greeting and notification systems
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello,',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              // Custom implementation of a notification badge using Stack
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                    Positioned(
                      top: 2,
                      right: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935), // High-urgency red indicator
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE65100), width: 2), // Matches header background
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // Custom Search Bar Implementation
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for services...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Contextual Location Indicator
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'Dehiwala, Colombo',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          // Primary Call-to-Action Card: Post a Job
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD84315), // Deep Orange for visual weight
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD84315).withOpacity(0.3), // Colored shadow technique
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 30)), 
                  const SizedBox(height: 16),
                  const Text(
                    'Post a Job',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get quotes from\nworkers',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Secondary Call-to-Action Card: My Jobs
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2962FF), // High-contrast blue for separation of intent
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2962FF).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 30)), 
                  const SizedBox(height: 16),
                  const Text(
                    'My Jobs',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track ongoing\nwork',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Categories',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(), // Defers scroll control to parent SingleChildScrollView
            shrinkWrap: true, // Forces layout engine to compute explicit height
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8, // Configured to accommodate icon and text label vertically
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 68,
                    width: 68,
                    decoration: BoxDecoration(
                      color: cat.bgColor,
                      borderRadius: BorderRadius.circular(22), // Squircle curvature
                    ),
                    child: Icon(cat.icon, color: cat.iconColor, size: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.title,
                    style: const TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.black87
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopRatedWorkers() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Top Rated Workers',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              InkWell(
                onTap: () {
                  // Execution point for full list navigation
                },
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _topWorkers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final worker = _topWorkers[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hardware-accelerated image clipping for profile aesthetic
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        worker.imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 90, height: 90,
                            color: Colors.grey.shade100,
                            child: Icon(Icons.person, color: Colors.grey.shade300, size: 40),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  worker.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Rs. ${worker.hourlyRate}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                worker.profession,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'per hour',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Programmatic star rating generation
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (starIndex) {
                                  IconData iconData;
                                  if (starIndex < worker.rating.floor()) {
                                    iconData = Icons.star_rounded;
                                  } else if (starIndex < worker.rating) {
                                    iconData = Icons.star_half_rounded;
                                  } else {
                                    iconData = Icons.star_outline_rounded;
                                  }
                                  return Icon(iconData, color: const Color(0xFFFFC107), size: 18);
                                }),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${worker.rating}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${worker.reviewCount})',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Conditional rendering of trust signal
                          if (worker.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0E5), // Subtle tint of brand primary
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_outlined, color: Color(0xFFE65100), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Seva Verified',
                                    style: TextStyle(
                                      color: Color(0xFFE65100),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A56DB), // Deep trust blue
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A56DB).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why Choose SevaLink?',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTrustRow('All workers are background verified'),
            const SizedBox(height: 12),
            _buildTrustRow('Secure payment protection'),
            const SizedBox(height: 12),
            _buildTrustRow('24/7 customer support'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustRow(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF006B3D), // Distinctive active state coloring
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