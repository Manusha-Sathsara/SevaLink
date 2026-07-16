
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';

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

  // Mock skill tags
  final List<String> _skillTags = ['Electrician', 'AC Repair', 'Wiring'];

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final user = authState.user;
    final extra = authState.profileExtra;
    _nameController = TextEditingController(text: user?.fullName ?? 'Worker');
    _emailController =
        TextEditingController(text: user?.email ?? 'worker@sevalink.lk');
    _phoneController =
        TextEditingController(text: user?.phoneNumber ?? '+94 77 123 4567');
    _locationController = TextEditingController(text: extra.location);
    _bioController = TextEditingController(text: extra.bio);
    _skillsController = TextEditingController();
    _rateController = TextEditingController(text: extra.hourlyRate);
    // Restore profile image from Riverpod state
    if (extra.profileImagePath != null) {
      _profileImage = File(extra.profileImagePath!);
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.visibility_rounded,
                        color: Color(0xFF1A3FBB)),
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
                      color: Color(0xFF006B5E)),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked != null && mounted) {
                    setState(() => _profileImage = File(picked.path));
                    ref.read(authProvider.notifier).updateProfileImage(picked.path);
                  }
                },
              ),

              // Take a Photo
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF1A3FBB)),
                ),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (picked != null && mounted) {
                    setState(() => _profileImage = File(picked.path));
                    ref.read(authProvider.notifier).updateProfileImage(picked.path);
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
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 900));
    // Persist changes to Riverpod state so all screens see the update
    ref.read(authProvider.notifier).updateProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      bio: _bioController.text.trim(),
      hourlyRate: _rateController.text.trim(),
    );
    setState(() {
      _isSaving = false;
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
          backgroundColor: const Color(0xFF006B5E),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarCard(),
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
                          enabled: _isEditing,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection('Professional Details', [
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
                      _buildSection('Stats', [_buildStatsRow()]),
                      const SizedBox(height: 20),
                      if (_isEditing) ...[
                        _buildSaveButton(),
                        const SizedBox(height: 12),
                        _buildCancelButton(),
                      ] else ...[
                        _buildLogoutButton(),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  HEADER
  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: 160,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3FBB), Color(0xFF0E257A)],
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
      ),
    );
  }

  //  AVATAR CARD

  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
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
                    gradient: _profileImage == null
                        ? const LinearGradient(
                            colors: [Color(0xFF1A3FBB), Color(0xFF006B5E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A3FBB).withValues(alpha: 0.3),
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
                          ? const Color(0xFF006B5E)
                          : const Color(0xFF1A3FBB),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
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
                        color: Color(0xFFF59E0B), size: 15),
                    const Text(
                      ' 4.8',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _locationController.text.isNotEmpty
                            ? _locationController.text
                            : 'Colombo, Sri Lanka',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
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
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            size: 18,
            color: enabled ? const Color(0xFF006B5E) : Colors.grey.shade400),
        prefixText: prefix,
        labelStyle: TextStyle(
          fontSize: 13,
          color: enabled ? const Color(0xFF6B7280) : Colors.grey.shade400,
        ),
        filled: true,
        fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFF006B5E), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  //  HOURLY RATE (custom — pure text prefix, no icon fallback issues)

  Widget _buildRateField() {
    final color = _isEditing ? const Color(0xFF006B5E) : Colors.grey.shade400;
    return TextFormField(
      controller: _rateController,
      enabled: _isEditing,
      keyboardType: TextInputType.number,
      style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'Hourly Rate',
        labelStyle: TextStyle(
          fontSize: 13,
          color: _isEditing ? const Color(0xFF6B7280) : Colors.grey.shade400,
        ),
        // prefixIcon with a Text shows in ALL states (enabled, disabled, focused)
        // This avoids the $ fallback that icon codepoints can produce
        prefixIcon: Center(
          widthFactor: 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Rs.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        filled: true,
        fillColor: _isEditing ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006B5E), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  //  SKILLS

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills / Specializations',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
                        color: const Color(0xFF006B5E),
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14, color: Color(0xFF006B5E)),
                      SizedBox(width: 4),
                      Text('Add',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF006B5E),
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
        border: Border.all(color: const Color(0xFF006B5E).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: const TextStyle(
              color: Color(0xFF006B5E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _skillTags.remove(skill)),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: Color(0xFF006B5E)),
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
              backgroundColor: const Color(0xFF006B5E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  //  STATS ROW

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('156', 'Total Jobs', Icons.work_rounded)),
        _buildStatDivider(),
        Expanded(
            child: _buildStatItem(
                '4.8', 'Avg Rating', Icons.star_rounded)),
        _buildStatDivider(),
        Expanded(
            child: _buildStatItem(
                '98%', 'Completion', Icons.check_circle_rounded)),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF006B5E), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 50, width: 1, color: const Color(0xFFF3F4F6));
  }

  // BUTTONS

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006B5E),
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
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () => setState(() => _isEditing = false),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'Cancel',
          style:
          TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w600),
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
