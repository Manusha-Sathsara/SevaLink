
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../providers/worker_feed_provider.dart';
import '../../../providers/worker_jobs_list_provider.dart';
import '../../jobs/screens/job_location_picker_screen.dart';

class WorkerProfileScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const WorkerProfileScreen({super.key, this.showBackButton = false});

  @override
  ConsumerState<WorkerProfileScreen> createState() =>
      _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends ConsumerState<WorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  File? _profileImage;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  late TextEditingController _skillsController;
  late TextEditingController _rateController;

  // Skill tags state
  List<String> _skillTags = [];

  // Onboarding/Edit setup states
  int? _selectedCategoryId;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final user = authState.user;
    final stats = ref.read(workerFeedProvider).stats;

    _nameController = TextEditingController(
        text: stats.fullName.isNotEmpty ? stats.fullName : (user?.fullName ?? 'Worker'));
    _emailController =
        TextEditingController(text: user?.email ?? 'worker@sevalink.lk');
    _phoneController = TextEditingController(
        text: stats.phoneNumber.isNotEmpty ? stats.phoneNumber : (user?.phoneNumber ?? '+94 77 123 4567'));
    _locationController = TextEditingController(
        text: stats.location.isNotEmpty ? stats.location : 'Colombo, Sri Lanka');
    _bioController = TextEditingController(
        text: stats.bio.isNotEmpty ? stats.bio : 'Experienced electrician with 8+ years working on residential and commercial projects.');
    _skillsController = TextEditingController();
    _rateController = TextEditingController(
        text: stats.hourlyRate.isNotEmpty ? stats.hourlyRate : '2,500');

    _skillTags = stats.skills.isNotEmpty
        ? List.from(stats.skills)
        : ['Electrician', 'AC Repair', 'Wiring'];

    _selectedCategoryId = stats.categoryId;
    _selectedLatitude = stats.latitude;
    _selectedLongitude = stats.longitude;

    // Restore profile image from Riverpod state
    final extra = authState.profileExtra;
    if (extra.profileImagePath != null) {
      final file = File(extra.profileImagePath!);
      if (file.existsSync()) {
        _profileImage = file;
      }
    }

    // Force refresh worker profile from backend on screen initialization
    Future.microtask(() {
      ref.read(workerFeedProvider.notifier).refresh();
    });
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => JobLocationPickerScreen(
          initialLocation: (_selectedLatitude != null && _selectedLongitude != null)
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result['latitude'] as double?;
        _selectedLongitude = result['longitude'] as double?;
        _locationController.text = result['address'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileImagePermanently(String tempPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(tempPath);
      final savedImage = await File(tempPath).copy('${appDir.path}/$fileName');
      
      if (mounted) {
        setState(() => _profileImage = savedImage);
        
        final bytes = await savedImage.readAsBytes();
        await ref.read(workerFeedProvider.notifier).uploadWorkerProfileImage(
          savedImage.path,
          fileName,
          bytes,
        );

        ref.read(authProvider.notifier).updateProfileImage(savedImage.path);
      }
    } catch (e) {
      debugPrint('Error saving profile image: $e');
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Profile Picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // View — only when a photo is already set
              if (_profileImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.visibility_rounded,
                        color: Color(0xFF2A9134)),
                  ),
                  title: const Text('View Profile Picture'),
                  onTap: () {
                    Navigator.pop(context);
                    _viewProfileImage();
                  },
                ),

              // Choose from Gallery
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF054A29)),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked != null && mounted) {
                    await _saveProfileImagePermanently(picked.path);
                  }
                },
              ),

              // Take a Photo
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF2A9134)),
                ),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (picked != null && mounted) {
                    await _saveProfileImagePermanently(picked.path);
                  }
                },
              ),

              // Remove — only when a photo is set
              if (_profileImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444)),
                  ),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Color(0xFFEF4444))),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _profileImage = null);
                    ref.read(authProvider.notifier).updateProfileImage(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewProfileImage() {
    if (_profileImage == null) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (ctx, anim, anim2) => _FullScreenImageViewer(image: _profileImage!),
        transitionsBuilder: (ctx, animation, secAnim, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Sync changes to the backend database
      await ref.read(workerFeedProvider.notifier).updateWorkerProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
        skills: _skillTags,
        hourlyRate: _rateController.text.trim(),
        categoryId: _selectedCategoryId,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );

      // Keep Auth provider state updated for name/phone changes
      ref.read(authProvider.notifier).updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        bio: _bioController.text.trim(),
        hourlyRate: _rateController.text.trim(),
      );

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF054A29),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
      }
      if (mounted) {
        String errorMessage = 'Failed to update profile: $e';
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

  void _addSkill(String skill) {
    final s = skill.trim();
    if (s.isNotEmpty && !_skillTags.contains(s)) {
      setState(() => _skillTags.add(s));
    }
    _skillsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WorkerFeedState>(workerFeedProvider, (previous, next) {
      if (!_isEditing) {
        final stats = next.stats;
        if (stats.fullName.isNotEmpty) _nameController.text = stats.fullName;
        if (stats.phoneNumber.isNotEmpty) _phoneController.text = stats.phoneNumber;
        if (stats.location.isNotEmpty) _locationController.text = stats.location;
        if (stats.bio.isNotEmpty) _bioController.text = stats.bio;
        if (stats.hourlyRate.isNotEmpty) _rateController.text = stats.hourlyRate;
        setState(() {
          _selectedCategoryId = stats.categoryId;
          _selectedLatitude = stats.latitude;
          _selectedLongitude = stats.longitude;
          _skillTags = stats.skills.isNotEmpty
              ? List.from(stats.skills)
              : ['Electrician', 'AC Repair', 'Wiring'];
        });
      }
    });

    final stats = ref.watch(workerFeedProvider).stats;
    final jobsState = ref.watch(workerJobsListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeaderWidget(),
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatarCard(stats),
                      const SizedBox(height: 20),
                      _buildSection('Personal Information', [
                        _buildField(
                          label: 'Full Name',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                          enabled: _isEditing,
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Email Address',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          enabled: false, // email not editable
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Location',
                          controller: _locationController,
                          icon: Icons.location_on_outlined,
                          enabled: false, // Tap-to-select only
                          onTap: _isEditing ? _selectLocation : null,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection('Professional Details', [
                        if (_isEditing) ...[
                          _buildCategoryDropdownField(),
                          const SizedBox(height: 14),
                        ] else ...[
                          _buildField(
                            label: 'Service Category',
                            controller: TextEditingController(text: stats.categoryName ?? 'Not Set'),
                            icon: Icons.category_rounded,
                            enabled: false,
                          ),
                          const SizedBox(height: 14),
                        ],
                        _buildField(
                          label: 'Bio / About Me',
                          controller: _bioController,
                          icon: Icons.notes_rounded,
                          enabled: _isEditing,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _buildRateField(),
                        const SizedBox(height: 14),
                        _buildSkillsSection(),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection('Stats', [_buildStatsRow(stats, jobsState)]),
                      const SizedBox(height: 20),
                      if (_isEditing) ...[
                        _buildSaveButton(),
                        const SizedBox(height: 12),
                        _buildCancelButton(),
                      ] else ...[
                        _buildLogoutButton(),
                      ],
                      const SizedBox(height: 50),
                    ],
                  ),
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

  //  HEADER
  Widget _buildHeaderWidget() {
    return Container(
      height: 190,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A9134), Color(0xFF3FA34D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              if (widget.showBackButton)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              if (widget.showBackButton) const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isEditing = !_isEditing),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  AVATAR CARD

  Widget _buildAvatarCard(WorkerStats stats) {
    final colors = context.sevaColors;
    final isDark  = context.isDark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: colors.border, width: 1) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: (_profileImage == null && (stats.profileImageUrl == null || stats.profileImageUrl!.isEmpty))
                        ? const LinearGradient(
                            colors: [Color(0xFF2A9134), Color(0xFF054A29)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A9134).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _profileImage != null
                      ? ClipOval(
                          child: Image.file(
                            _profileImage!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (stats.profileImageUrl != null && stats.profileImageUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                stats.profileImageUrl!,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      _getInitials(_nameController.text),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                _getInitials(_nameController.text),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _isEditing
                          ? const Color(0xFF054A29)
                          : const Color(0xFF2A9134),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Worker',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded,
                        color: Color(0xFF5BBA6F), size: 15),
                    Text(
                      stats.rating > 0 ? ' ${stats.rating.toStringAsFixed(1)}' : ' —',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 13, color: colors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _locationController.text.isNotEmpty
                            ? _locationController.text
                            : 'Colombo, Sri Lanka',
                        style: TextStyle(
                            fontSize: 12, color: colors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  SECTION WRAPPER

  Widget _buildSection(String title, List<Widget> children) {
    final colors = context.sevaColors;
    final isDark  = context.isDark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: colors.border, width: 1) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  //  FIELD

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? prefix,
    VoidCallback? onTap,
  }) {
    final colors = context.sevaColors;
    final isDark  = context.isDark;
    final isFieldEnabled = enabled || onTap != null;
    final fillColor = isDark
        ? (isFieldEnabled ? colors.inputFill : colors.cardBg2)
        : (isFieldEnabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6));
    final borderColor = isDark ? colors.border : const Color(0xFFE5E7EB);
    final disabledBorderColor = isDark ? colors.border : Colors.grey.shade200;
    return TextFormField(
      controller: controller,
      enabled: isFieldEnabled,
      readOnly: onTap != null,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
          fontSize: 14,
          color: colors.textPrimary,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            size: 18,
            color: isFieldEnabled ? const Color(0xFF054A29) : colors.textSecondary),
        prefixText: prefix,
        labelStyle: TextStyle(
          fontSize: 13,
          color: isFieldEnabled ? colors.textSecondary : colors.textSecondary.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: disabledBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFF054A29), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: disabledBorderColor),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildCategoryDropdownField() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      dropdownColor: Colors.white,
      style: TextStyle(
          color: context.sevaColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500),
      hint: const Text(
        'Select a category',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      ),
      decoration: InputDecoration(
        labelText: 'Service Category',
        prefixIcon: const Icon(Icons.category_rounded, size: 18, color: Color(0xFF054A29)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A9134), width: 2.0),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 1, child: Text('Electrical')),
        DropdownMenuItem(value: 2, child: Text('Plumbing')),
        DropdownMenuItem(value: 3, child: Text('Carpentry')),
        DropdownMenuItem(value: 4, child: Text('Cleaning')),
        DropdownMenuItem(value: 5, child: Text('Painting')),
        DropdownMenuItem(value: 6, child: Text('General')),
      ],
      onChanged: (val) {
        setState(() {
          _selectedCategoryId = val;
        });
      },
      validator: (val) => val == null ? 'Required' : null,
    );
  }

  //  HOURLY RATE (custom — pure text prefix, no icon fallback issues)

  Widget _buildRateField() {
    final colors = context.sevaColors;
    final isDark  = context.isDark;
    final color = _isEditing ? const Color(0xFF054A29) : colors.textSecondary;
    final fillColor = isDark
        ? (_isEditing ? colors.inputFill : colors.cardBg2)
        : (_isEditing ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6));
    final borderColor = isDark ? colors.border : const Color(0xFFE5E7EB);
    final disabledBorderColor = isDark ? colors.border : Colors.grey.shade200;
    return TextFormField(
      controller: _rateController,
      enabled: _isEditing,
      keyboardType: TextInputType.number,
      style: TextStyle(
          fontSize: 14,
          color: colors.textPrimary,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'Hourly Rate',
        labelStyle: TextStyle(
          fontSize: 13,
          color: _isEditing ? colors.textSecondary : colors.textSecondary.withValues(alpha: 0.6),
        ),
        prefixIcon: Center(
          widthFactor: 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'LKR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: disabledBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF054A29), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: disabledBorderColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  //  SKILLS

  Widget _buildSkillsSection() {
    final colors = context.sevaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills / Specializations',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._skillTags.map((s) => _buildSkillChip(s)),
            if (_isEditing)
              GestureDetector(
                onTap: () => _showAddSkillDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF054A29),
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14, color: Color(0xFF054A29)),
                      SizedBox(width: 4),
                      Text('Add',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF054A29),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF054A29).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: const TextStyle(
              color: Color(0xFF054A29),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _skillTags.remove(skill)),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: Color(0xFF054A29)),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSkillDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Skill'),
        content: TextField(
          controller: _skillsController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Plumbing, Painting',
          ),
          onSubmitted: (v) {
            _addSkill(v);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _addSkill(_skillsController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF054A29),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(WorkerStats stats, WorkerJobsListState jobsState) {
    final jobs = jobsState.jobs;
    final completedCount = jobs.where((j) => j.status == JobStatus.completed).length;
    final totalJobsCount = jobs.length;
    final completionRate = totalJobsCount > 0
        ? '${((completedCount / totalJobsCount) * 100).toInt()}%'
        : '100%';

    final ratingStr = stats.rating > 0 ? stats.rating.toStringAsFixed(1) : '—';
    final totalJobsStr = stats.totalJobs.toString();

    return Row(
      children: [
        Expanded(child: _buildStatItem(totalJobsStr, 'Total Jobs', Icons.work_rounded)),
        _buildStatDivider(),
        Expanded(
            child: _buildStatItem(
                ratingStr, 'Avg Rating', Icons.star_rounded)),
        _buildStatDivider(),
        Expanded(
            child: _buildStatItem(
                completionRate, 'Completion', Icons.check_circle_rounded)),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    final colors = context.sevaColors;
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF054A29), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 50, width: 1, color: context.sevaColors.divider);
  }

  // BUTTONS

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF054A29),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : const Text(
          'Save Changes',
          style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    final colors = context.sevaColors;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () => setState(() => _isEditing = false),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.border),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'Cancel',
          style:
          TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }



  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Log Out'),
              content:
              const Text('Are you sure you want to log out of SevaLink?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Log Out',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true && mounted) {
            await ref.read(authProvider.notifier).logout();
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon:
        const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
        label: const Text(
          'Log Out',
          style: TextStyle(
              color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // flu HELPERS

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'W';
  }
}

// ─── Full-Screen Profile Image Viewer ────────────────────────────────────────

class _FullScreenImageViewer extends StatefulWidget {
  final File image;
  const _FullScreenImageViewer({required this.image});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDoubleTap(TapDownDetails details) {
    final isZoomedIn =
        _transformationController.value != Matrix4.identity();
    if (isZoomedIn) {
      // Zoom back out
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity(),
      ).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOut),
      );
      _animationController.forward(from: 0);
    } else {
      // Zoom into tapped point (2.5x)
      final position = details.localPosition;
      final x = -position.dx * 1.5;
      final y = -position.dy * 1.5;
      final zoomed = Matrix4.identity()
        ..translateByDouble(x, y, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: zoomed,
      ).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOut),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 22),
          ),
        ),
        title: const Text(
          'Profile Picture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onDoubleTapDown: _onDoubleTap,
        onDoubleTap: () {}, // needed for onDoubleTapDown to fire
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.8,
            maxScale: 5.0,
            child: Hero(
              tag: 'profile_image',
              child: Image.file(
                widget.image,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
