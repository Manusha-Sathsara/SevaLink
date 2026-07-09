import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/worker_feed_provider.dart';
import '../../jobs/screens/job_location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/google_maps_service.dart';

class WorkerOnboardingScreen extends ConsumerStatefulWidget {
  const WorkerOnboardingScreen({super.key});

  @override
  ConsumerState<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends ConsumerState<WorkerOnboardingScreen> {
  int _currentStep = 1; // 1 = Category, 2 = Profile Details
  bool _isSaving = false;

  // Step 1: Category Selection State
  int? _selectedCategoryId;
  String? _selectedCategoryName;

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Electrical', 'icon': Icons.bolt_rounded, 'color': Color(0xFFE8F8EE), 'iconColor': Color(0xFF2A9134)},
    {'id': 2, 'name': 'Plumbing', 'icon': Icons.water_drop_rounded, 'color': Color(0xFFECFDF5), 'iconColor': Color(0xFF10B981)},
    {'id': 3, 'name': 'Carpentry', 'icon': Icons.handyman_rounded, 'color': Color(0xFFE8F8EE), 'iconColor': Color(0xFF5BBA6F)},
    {'id': 4, 'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFFE8F8EE), 'iconColor': Color(0xFF2A9134)},
    {'id': 5, 'name': 'Painting', 'icon': Icons.format_paint_rounded, 'color': Color(0xFFE8F8EE), 'iconColor': Color(0xFF3FA34D)},
    {'id': 6, 'name': 'General', 'icon': Icons.miscellaneous_services_rounded, 'color': Color(0xFFF3F4F6), 'iconColor': Color(0xFF6B7280)},
  ];

  // Step 2: Profile Details State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Default location retrieval in the background
    _detectCurrentLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _rateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      final mapsService = GoogleMapsService();
      final address = await mapsService.reverseGeocode(position.latitude, position.longitude);

      if (mounted && address != null && address.isNotEmpty) {
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Error auto-detecting location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => JobLocationPickerScreen(
          initialLocation: (_latitude != null && _longitude != null)
              ? LatLng(_latitude!, _longitude!)
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'] as double?;
        _longitude = result['longitude'] as double?;
        _locationController.text = result['address'] ?? '';
      });
    }
  }

  Future<void> _saveOnboardingDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final workerFeedNotifier = ref.read(workerFeedProvider.notifier);

      // Save onboarding details to profile via backend call
      await workerFeedNotifier.updateWorkerProfile(
        fullName: ref.read(authProvider).user?.fullName ?? 'Worker',
        phoneNumber: ref.read(authProvider).user?.phoneNumber ?? '',
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
        skills: [_selectedCategoryName ?? 'General'],
        hourlyRate: _rateController.text.trim(),
        categoryId: _selectedCategoryId,
        latitude: _latitude,
        longitude: _longitude,
      );

      // Refresh the feed & worker profile details to pop onboarding
      await workerFeedNotifier.refresh();
    } catch (e) {
      debugPrint('Error saving onboarding: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Response status: ${e.response?.statusCode}');
      }
      if (mounted) {
        String errorMessage = 'Error saving details: $e';
        if (e is DioException && e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map && data.containsKey('message')) {
            errorMessage = data['message'];
          } else {
            errorMessage = 'Server Error: $data';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  // ── STEP 1: CATEGORY SELECTION ─────────────────────────────────────────────
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Choose your field',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your main category or specialization to continue. This helps us match you with the right jobs.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryId == cat['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = cat['id'] as int;
                      _selectedCategoryName = cat['name'] as String;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : cat['color'] as Color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2A9134) : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? const Color(0xFF2A9134).withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 36,
                          color: isSelected ? const Color(0xFF2A9134) : cat['iconColor'] as Color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF2A9134) : const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedCategoryId == null
                  ? null
                  : () => setState(() => _currentStep = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A9134),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: PROFILE DETAILS (LOCATION, RATE, BIO) ─────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937), size: 20),
                  onPressed: () => setState(() => _currentStep = 1),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Set Up Your Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your details for ${_selectedCategoryName ?? "Worker"}. These details will be visible to clients.',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Location Selector
            const Text(
              'Work Location *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              readOnly: true,
              onTap: _selectLocation,
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
              decoration: InputDecoration(
                hintText: _isLoadingLocation ? 'Retrieving current location...' : 'Tap to select location',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF2A9134), size: 20),
                suffixIcon: _isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2A9134)),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2A9134), width: 2.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2.0),
                ),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Work location is required' : null,
            ),
            const SizedBox(height: 20),

            // Hourly Rate Input
            const Text(
              'Hourly Rate (LKR) *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
              decoration: InputDecoration(
                hintText: 'e.g., 2,500',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF2A9134), size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2A9134), width: 2.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2.0),
                ),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Hourly rate is required' : null,
            ),
            const SizedBox(height: 20),

            // Bio Input (Optional)
            const Text(
              'Bio / About Me (Optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Describe your skills, work experience, and expertise...',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF2A9134), size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2A9134), width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveOnboardingDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF054A29),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Finish Setup',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
