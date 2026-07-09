import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/worker_feed_provider.dart';
import '../../../core/themes/app_theme.dart';
import 'my_jobs_screen.dart' show workerJobsListProvider;

class WorkerJobTimelineScreen extends ConsumerStatefulWidget {
  final int jobId;
  const WorkerJobTimelineScreen({super.key, required this.jobId});

  @override
  ConsumerState<WorkerJobTimelineScreen> createState() => _WorkerJobTimelineScreenState();
}

class _WorkerJobTimelineScreenState extends ConsumerState<WorkerJobTimelineScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _jobDetails;
  List<dynamic> _timeline = [];
  
  // Worker live location en route
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _workerLatLng;
  GoogleMapController? _mapController;
  bool _isEnRoute = false;
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;

  Timer? _pollingTimer;
  int? _workerId;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    _stopLocationTracking();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData(background: true);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchData({bool background = false}) async {
    if (!mounted) return;
    if (!background && _jobDetails == null) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final dio = ref.read(dioClientProvider).dio;

      // 1. Fetch workerId if null
      if (_workerId == null) {
        try {
          final profileRes = await dio.get('/workers/me');
          _workerId = profileRes.data['id'];
        } catch (e) {
          debugPrint('Failed to fetch workerId from /workers/me: $e');
        }
      }
      
      // 2. Fetch job details
      final jobResponse = await dio.get('/jobs/detail/${widget.jobId}');
      final newJobDetails = jobResponse.data;

      // 3. Fetch timeline
      final timelineResponse = await dio.get('/jobs/detail/${widget.jobId}/timeline');
      final newTimeline = timelineResponse.data;

      if (mounted) {
        final hasArrived = newTimeline.any((t) => t['status'] == 'WORKER_ARRIVED');
        final enRoute = newTimeline.any((t) => t['status'] == 'WORKER_EN_ROUTE') && !hasArrived;

        setState(() {
          _jobDetails = newJobDetails;
          _timeline = newTimeline;
          _isLoading = false;
          _error = null;
          _isEnRoute = enRoute;
        });

        if (enRoute) {
          if (_positionSubscription == null) {
            _startLocationTracking();
          } else {
            _fetchRoutePoints();
          }
        } else {
          _stopLocationTracking();
        }

        // If job is COMPLETED, refresh the jobs list provider so MyJobsScreen
        // auto-switches to the Completed tab
        final jobStatus = newJobDetails?['status'] ?? '';
        if (jobStatus == 'COMPLETED') {
          ref.read(workerJobsListProvider.notifier).loadJobs();
        }
      }
    } catch (e) {
      if (mounted && !background) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }


  Future<void> _startLocationTracking() async {
    _positionSubscription?.cancel();
    
    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
    }

    // Get current position immediately to show on map and fetch route
    try {
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      if (mounted) {
        _updateLiveLocation(pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint('Failed to get current location immediately: $e');
    }

    // Start listening to coordinates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      _updateLiveLocation(position.latitude, position.longitude);
    });
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _fetchRoutePoints() async {
    if (_isFetchingRoute) return;
    if (_workerLatLng == null || _jobDetails?['latitude'] == null || _jobDetails?['longitude'] == null) {
      return;
    }
    final double jobLat = _jobDetails!['latitude'] as double;
    final double jobLng = _jobDetails!['longitude'] as double;
    final double workerLat = _workerLatLng!.latitude;
    final double workerLng = _workerLatLng!.longitude;

    _isFetchingRoute = true;
    try {
      final dio = ref.read(dioClientProvider).dio;
      final url = 'https://router.project-osrm.org/route/v1/driving/$workerLng,$workerLat;$jobLng,$jobLat?overview=full&geometries=geojson';
      final response = await dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final routes = response.data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>?;
          if (geometry != null) {
            final coordinates = geometry['coordinates'] as List<dynamic>?;
            if (coordinates != null) {
              final List<LatLng> points = coordinates.map((coord) {
                final double lng = (coord[0] as num).toDouble();
                final double lat = (coord[1] as num).toDouble();
                return LatLng(lat, lng);
              }).toList();
              if (mounted) {
                setState(() {
                  _routePoints = points;
                });
              }
              _isFetchingRoute = false;
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch road route from OSRM: $e');
    }
    _isFetchingRoute = false;
    // Fallback to straight line
    if (mounted && _routePoints.isEmpty) {
      setState(() {
        _routePoints = [LatLng(workerLat, workerLng), LatLng(jobLat, jobLng)];
      });
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Failed to launch dialer: $e');
    }
  }

  Future<void> _updateLiveLocation(double lat, double lng) async {
    setState(() {
      _workerLatLng = LatLng(lat, lng);
    });
    _fetchRoutePoints();

    // Send coordinates to backend
    try {
      final dio = ref.read(dioClientProvider).dio;
      final workerId = _workerId ?? ref.read(workerFeedProvider).stats.workerId;
      if (workerId != null) {
        await dio.put('/workers/$workerId/location', queryParameters: {
          'latitude': lat,
          'longitude': lng,
        });
      }
    } catch (e) {

      debugPrint('Failed to upload location: $e');
    }

    // Auto-check proximity arrival
    if (_jobDetails?['latitude'] != null && _jobDetails?['longitude'] != null) {
      final jobLat = _jobDetails!['latitude'] as double;
      final jobLng = _jobDetails!['longitude'] as double;
      
      final distance = Geolocator.distanceBetween(lat, lng, jobLat, jobLng);
      if (distance < 100) {
        // Auto-arrive worker
        _stopLocationTracking();
        _updateTimelineStatus('WORKER_ARRIVED', 'Worker arrived at job location (Geofenced Auto Arrival)');
      }
    }
  }

  Future<void> _updateTimelineStatus(String status, String note) async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.put('/jobs/detail/${widget.jobId}/timeline', queryParameters: {
        'status': status,
        'note': note,
      });
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Job'),
        content: const Text('Are you sure you want to cancel this job? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.put('/jobs/${widget.jobId}/cancel');
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job cancelled successfully'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel job: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/jobs/${widget.jobId}/confirm-payment');
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment confirmed!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm payment: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showComplaintDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('File Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe the issue in detail. The admin panel will review it.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe issue here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final desc = controller.text.trim();
              if (desc.isEmpty) return;
              Navigator.pop(ctx);
              _submitComplaint(desc);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9134)),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint(String description) async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/jobs/${widget.jobId}/complaint', data: {'description': description});
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint filed successfully.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to file complaint: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchExternalMapNavigation() async {
    if (_jobDetails?['latitude'] == null || _jobDetails?['longitude'] == null) return;
    final double destLat = _jobDetails!['latitude'] as double;
    final double destLng = _jobDetails!['longitude'] as double;

    final String url = 'google.navigation:q=$destLat,$destLng';
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to web map link
        final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$destLat,$destLng');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map navigation: $e')),
        );
      }
    }
  }

  bool _isStepCompleted(String status) {
    return _timeline.any((t) => t['status'] == status);
  }

  String _getStepTime(String status) {
    final entry = _timeline.firstWhere((t) => t['status'] == status, orElse: () => null);
    if (entry == null || entry['updatedAt'] == null) return '';
    try {
      final dt = DateTime.parse(entry['updatedAt']);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2A9134))),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Timeline')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading details: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final jobTitle = _jobDetails?['title'] ?? 'Job Navigation';
    final jobStatus = _jobDetails?['status'] ?? 'ASSIGNED';
    final clientConfirmed = _jobDetails?['clientPaymentConfirmed'] ?? false;
    final workerConfirmed = _jobDetails?['workerPaymentConfirmed'] ?? false;

    // Timeline logic
    final isAssigned = _isStepCompleted('QUOTE_ACCEPTED') && !_isStepCompleted('WORKER_EN_ROUTE');
    final hasArrived = _isStepCompleted('WORKER_ARRIVED');
    final isStarted = _isStepCompleted('JOB_STARTED');
    final isDone = _isStepCompleted('JOB_DONE');

    return Scaffold(
      backgroundColor: colors.bodyBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A9134),
        foregroundColor: Colors.white,
        title: Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Refresh jobs list so MyJobsScreen Completed tab updates
            ref.read(workerJobsListProvider.notifier).loadJobs();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/worker/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Navigation map section (if en route)
              if (_isEnRoute &&
                  _workerLatLng != null &&
                  _jobDetails?['latitude'] != null &&
                  _jobDetails?['longitude'] != null) ...[
                _buildLiveMapSection(colors),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _launchExternalMapNavigation,
                  icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                  label: const Text('Navigate in Google Maps app', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF054A29),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Job Details summary
              _buildJobSummaryCard(colors),
              const SizedBox(height: 20),

              // Stepper
              _buildStepperCard(colors),
              const SizedBox(height: 20),

              // Dual Payment checkmarks
              if (isDone) ...[
                _buildPaymentStatusCard(colors, clientConfirmed, workerConfirmed),
                const SizedBox(height: 20),
              ],

              // Actions
              _buildActions(jobStatus, isAssigned, hasArrived, isStarted, isDone),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMapSection(SevaLinkColors colors) {
    final jobLatLng = LatLng(_jobDetails!['latitude'], _jobDetails!['longitude']);
    final workerLatLng = _workerLatLng!;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: workerLatLng, zoom: 13),
          onMapCreated: (ctrl) {
            _mapController = ctrl;
            final bounds = LatLngBounds(
              southwest: LatLng(
                jobLatLng.latitude < workerLatLng.latitude ? jobLatLng.latitude : workerLatLng.latitude,
                jobLatLng.longitude < workerLatLng.longitude ? jobLatLng.longitude : workerLatLng.longitude,
              ),
              northeast: LatLng(
                jobLatLng.latitude > workerLatLng.latitude ? jobLatLng.latitude : workerLatLng.latitude,
                jobLatLng.longitude > workerLatLng.longitude ? jobLatLng.longitude : workerLatLng.longitude,
              ),
            );
            _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          },
          markers: {
            Marker(
              markerId: const MarkerId('job'),
              position: jobLatLng,
              infoWindow: const InfoWindow(title: 'Job Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
            Marker(
              markerId: const MarkerId('worker'),
              position: workerLatLng,
              infoWindow: const InfoWindow(title: 'My Live Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
            ),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: _routePoints.isNotEmpty ? _routePoints : [jobLatLng, workerLatLng],
              color: const Color(0xFF2A9134),
              width: 4,
            ),
          },
        ),
      ),
    );
  }

  Widget _buildJobSummaryCard(SevaLinkColors colors) {
    final client = _jobDetails?['client'] ?? {};
    final clientName = client['fullName'] ?? 'Client';
    final clientPhone = client['phoneNumber'] ?? '';
    final locationName = _jobDetails?['locationName'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Job Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF2A9134), size: 18),
                    const SizedBox(width: 8),
                    Text(clientName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF2A9134), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationName,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (clientPhone.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF054A29).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.phone, color: Color(0xFF054A29)),
                onPressed: () => _makeCall(clientPhone),
              ),
            ),
          ],
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD3410A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD3410A)),
              onPressed: () {
                final clientId = client['id'] ?? 0;
                if (clientId != 0) {
                  context.push(
                    '/worker/chat/$clientId',
                    extra: {
                      'name': clientName,
                      'jobTitle': _jobDetails?['title'],
                      'jobBudget': _jobDetails?['budgetMin'] != null
                          ? 'Rs. ${_jobDetails!['budgetMin']} - ${_jobDetails!['budgetMax']}'
                          : null,
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperCard(SevaLinkColors colors) {
    final steps = [
      {'status': 'JOB_POSTED', 'label': 'Job Posted', 'desc': 'Job successfully posted'},
      {'status': 'QUOTE_RECEIVED', 'label': 'Quotes Received', 'desc': 'Received worker bids'},
      {'status': 'QUOTE_ACCEPTED', 'label': 'Worker Assigned', 'desc': 'Worker assigned & details shared'},
      {'status': 'WORKER_EN_ROUTE', 'label': 'Worker En Route', 'desc': 'Worker on the way'},
      {'status': 'WORKER_ARRIVED', 'label': 'Worker Arrived', 'desc': 'Worker arrived at location'},
      {'status': 'JOB_STARTED', 'label': 'Job Started', 'desc': 'Work is in progress'},
      {'status': 'JOB_DONE', 'label': 'Job Done', 'desc': 'Job marked done by worker'},
      {'status': 'PAYMENT_DONE', 'label': 'Completed', 'desc': 'Payment confirmed & completed'},
    ];


    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (ctx, i) {
              final step = steps[i];
              final isCompleted = _isStepCompleted(step['status']!);
              final time = _getStepTime(step['status']!);
              final isLast = i == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? const Color(0xFF16A34A) : Colors.grey.shade300,
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: isCompleted ? const Color(0xFF16A34A) : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['label']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isCompleted ? colors.textPrimary : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['desc']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted ? colors.textSecondary : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (time.isNotEmpty)
                    Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusCard(SevaLinkColors colors, bool clientConfirmed, bool workerConfirmed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Confirmation Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildConfirmationStatusRow('Client Confirmed', clientConfirmed),
              _buildConfirmationStatusRow('Worker Confirmed', workerConfirmed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStatusRow(String label, bool confirmed) {
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: confirmed ? const Color(0xFF16A34A) : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActions(String status, bool isAssigned, bool hasArrived, bool isStarted, bool isDone) {
    final isCancelled = status == 'CANCELLED';
    final isCompleted = status == 'COMPLETED';

    if (isCancelled || isCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Start Journey
        if (isAssigned)
          ElevatedButton.icon(
            onPressed: () => _updateTimelineStatus('WORKER_EN_ROUTE', 'Worker started journey'),
            icon: const Icon(Icons.directions_run_rounded, color: Colors.white),
            label: const Text('Start Journey (En Route)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF054A29),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

        // 2. Worker En Route -> Manual arrival button fallback
        if (_isEnRoute)
          ElevatedButton.icon(
            onPressed: () {
              _stopLocationTracking();
              _updateTimelineStatus('WORKER_ARRIVED', 'Worker arrived at location (Manual Arrive)');
            },
            icon: const Icon(Icons.location_on, color: Colors.white),
            label: const Text('I Have Arrived (Manual Fallback)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF054A29),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

        // 3. Start Job
        if (hasArrived && !isStarted)
          ElevatedButton.icon(
            onPressed: () => _updateTimelineStatus('JOB_STARTED', 'Worker started the job'),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text('Start Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF054A29),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

        // 4. Finish Job
        if (isStarted && !isDone)
          ElevatedButton.icon(
            onPressed: () => _updateTimelineStatus('JOB_DONE', 'Worker finished the job'),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Finish Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

        // 5. Confirm Payment
        if (isDone && _jobDetails!['workerPaymentConfirmed'] != true)

          ElevatedButton.icon(
            onPressed: _confirmPayment,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Confirm Payment Received', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

        const SizedBox(height: 12),

        Row(
          children: [
            // Cancel Job (only before arrival)
            if (!hasArrived)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cancelJob,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Cancel Job', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            if (!hasArrived) const SizedBox(width: 12),

            // Complaint (only after arrival)
            if (hasArrived)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showComplaintDialog,
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  label: const Text('File Complaint', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
