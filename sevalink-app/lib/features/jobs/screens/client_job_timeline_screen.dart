import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_jobs_provider.dart';
import '../../../core/themes/app_theme.dart';

class ClientJobTimelineScreen extends ConsumerStatefulWidget {
  final int jobId;
  const ClientJobTimelineScreen({super.key, required this.jobId});

  @override
  ConsumerState<ClientJobTimelineScreen> createState() => _ClientJobTimelineScreenState();
}

class _ClientJobTimelineScreenState extends ConsumerState<ClientJobTimelineScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _jobDetails;
  List<dynamic> _timeline = [];
  Map<String, dynamic>? _assignedWorker;

  Timer? _pollingTimer;
  GoogleMapController? _mapController;

  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
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

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch dialer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dialer for $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchRoutePoints() async {
    if (_isFetchingRoute) return;
    if (_assignedWorker?['latitude'] == null ||
        _assignedWorker?['longitude'] == null ||
        _jobDetails?['latitude'] == null ||
        _jobDetails?['longitude'] == null) {
      return;
    }
    final double jobLat = (_jobDetails!['latitude'] as num).toDouble();
    final double jobLng = (_jobDetails!['longitude'] as num).toDouble();
    final double workerLat = (_assignedWorker!['latitude'] as num).toDouble();
    final double workerLng = (_assignedWorker!['longitude'] as num).toDouble();

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

  Future<void> _fetchData({bool background = false}) async {
    if (!mounted) return;
    if (!background && _jobDetails == null) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final dio = ref.read(dioClientProvider).dio;
      
      // 1. Fetch job details
      final jobResponse = await dio.get('/jobs/detail/${widget.jobId}');
      final newJobDetails = jobResponse.data;

      // 2. Fetch timeline
      final timelineResponse = await dio.get('/jobs/detail/${widget.jobId}/timeline');
      final newTimeline = timelineResponse.data;

      // 3. If ASSIGNED (or later) and not COMPLETED, get assigned worker
      final status = newJobDetails?['status'] ?? 'OPEN';
      Map<String, dynamic>? newAssignedWorker;

      if (status != 'OPEN' && status != 'CANCELLED') {
        try {
          final workerResponse = await dio.get('/jobs/${widget.jobId}/assigned-worker');
          newAssignedWorker = workerResponse.data;
        } catch (_) {
          // Worker details could be empty if not accepted yet (fallback)
        }
      }

      if (mounted) {
        setState(() {
          _jobDetails = newJobDetails;
          _timeline = newTimeline;
          _assignedWorker = newAssignedWorker;
          _isLoading = false;
          _error = null;
        });

        // Trigger map camera update if worker location changed and en route
        final hasArrived = _isStepCompleted('WORKER_ARRIVED');
        final isEnRoute = _isStepCompleted('WORKER_EN_ROUTE') && !hasArrived;
        if (isEnRoute) {
          _fetchRoutePoints();
          if (_mapController != null &&
              _assignedWorker?['latitude'] != null &&
              _assignedWorker?['longitude'] != null &&
              _jobDetails?['latitude'] != null &&
              _jobDetails?['longitude'] != null) {
            final jobLatLng = LatLng(_jobDetails!['latitude'], _jobDetails!['longitude']);
            final workerLatLng = LatLng(_assignedWorker!['latitude'], _assignedWorker!['longitude']);
            
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
          }
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
              'Your complaint will be reviewed by the admin panel.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the issue in detail...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
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
              Text('Error loading timeline: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final jobTitle = _jobDetails?['title'] ?? 'Job Timeline';
    final jobStatus = _jobDetails?['status'] ?? 'ASSIGNED';
    final clientConfirmed = _jobDetails?['clientPaymentConfirmed'] ?? false;
    final workerConfirmed = _jobDetails?['workerPaymentConfirmed'] ?? false;

    // Timeline status checking
    final hasArrived = _isStepCompleted('WORKER_ARRIVED');
    final isDone = _isStepCompleted('JOB_DONE');
    final isEnRoute = _isStepCompleted('WORKER_EN_ROUTE') && !hasArrived;

    return Scaffold(
      backgroundColor: colors.bodyBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A9134),
        foregroundColor: Colors.white,
        title: Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Invalidate so ClientJobsScreen gets fresh data on return
            ref.invalidate(clientJobsProvider);
            context.go('/client/jobs');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map section (only en route)
              if (isEnRoute &&
                  _assignedWorker?['latitude'] != null &&
                  _assignedWorker?['longitude'] != null &&
                  _jobDetails?['latitude'] != null &&
                  _jobDetails?['longitude'] != null) ...[
                _buildLiveMapSection(colors),
                const SizedBox(height: 20),
              ],

              // Worker details
              if (_assignedWorker != null) ...[
                _buildWorkerCard(colors),
                const SizedBox(height: 20),
              ],

              // Stepper list
              _buildStepperCard(colors),
              const SizedBox(height: 20),

              // Dual Payment checkmarks
              if (isDone) ...[
                _buildPaymentStatusCard(colors, clientConfirmed, workerConfirmed),
                const SizedBox(height: 20),
              ],

              // Action buttons
              _buildActions(jobStatus, hasArrived, isDone),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMapSection(SevaLinkColors colors) {
    final jobLatLng = LatLng(_jobDetails!['latitude'], _jobDetails!['longitude']);
    final workerLatLng = LatLng(_assignedWorker!['latitude'], _assignedWorker!['longitude']);

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
          initialCameraPosition: CameraPosition(target: jobLatLng, zoom: 13),
          onMapCreated: (ctrl) {
            _mapController = ctrl;
            // set bounds
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
              infoWindow: const InfoWindow(title: 'Worker Live Location'),
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

  Widget _buildWorkerCard(SevaLinkColors colors) {
    final user = _assignedWorker!['user'] ?? {};
    final name = user['fullName'] ?? 'Worker';
    final phone = user['phoneNumber'] ?? '';
    final rating = (_assignedWorker!['rating'] ?? 5.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F5F2),
            radius: 24,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'W',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A9134), fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(phone, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF054A29).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.phone, color: Color(0xFF054A29)),
                onPressed: () => _makeCall(phone),
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
                final userId = user['id'] ?? 0;
                if (userId != 0) {
                  context.push(
                    '/client/chat/$userId',
                    extra: {
                      'name': name,
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

  Widget _buildActions(String status, bool hasArrived, bool isDone) {
    final isCancelled = status == 'CANCELLED';
    final isCompleted = status == 'COMPLETED';

    if (isCancelled || isCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment Confirm Action
        if (isDone && _jobDetails!['clientPaymentConfirmed'] != true)

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
