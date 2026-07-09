import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../providers/client_profile_provider.dart';

class EditClientProfileScreen extends ConsumerStatefulWidget {
  const EditClientProfileScreen({super.key});

  @override
  ConsumerState<EditClientProfileScreen> createState() => _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends ConsumerState<EditClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  bool _isLoading = false;
  File? _profileImage;
  bool _isUploadingProfileImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();

    final profileState = ref.read(clientProfileProvider);
    profileState.whenData((profile) {
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phoneNumber;
      _locationController.text = profile.location ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
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

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: const Color(0xFF2A9134),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF2A9134),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    setState(() {
      _profileImage = File(cropped.path);
      _isUploadingProfileImage = true;
    });

    try {
      final xfile = XFile(cropped.path);
      await ref.read(clientProfileProvider.notifier).uploadProfileImage(xfile);
    } finally {
      if (mounted) setState(() => _isUploadingProfileImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(clientProfileProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            location: _locationController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Explicitly redirect to profile screen instead of just popping
        context.go('/client/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_nameController.text.isNotEmpty ? _nameController.text : 'U');
    final profileState = ref.watch(clientProfileProvider);
    String? networkImageUrl;
    profileState.whenData((profile) {
      networkImageUrl = profile.profileImageUrl;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Orange gradient header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2A9134), Color(0xFF3FA34D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Edit Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploadingProfileImage ? null : _pickAndCropImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3FA34D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: _isUploadingProfileImage
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : _profileImage != null
                                            ? Image.file(
                                                _profileImage!,
                                                width: 90,
                                                height: 90,
                                                fit: BoxFit.cover,
                                              )
                                            : networkImageUrl != null && networkImageUrl!.isNotEmpty
                                                ? Image.network(
                                                    networkImageUrl!,
                                                    width: 90,
                                                    height: 90,
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
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _isUploadingProfileImage ? Colors.grey.shade400 : const Color(0xFF2A9134),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to change profile photo',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Form fields card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormField(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            controller: _nameController,
                            validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                          ),
                          const Divider(height: 24),
                          _buildFormField(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            controller: _emailController,
                            readOnly: true,
                          ),
                          const Divider(height: 24),
                          _buildFormField(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Phone is required';
                              if (val.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
                                return 'Phone number must be exactly 10 digits';
                              }
                              return null;
                            },
                          ),
                          const Divider(height: 24),
                          _buildFormField(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            controller: _locationController,
                            validator: (val) => val == null || val.isEmpty ? 'Location is required' : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Saving...' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A9134),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cancel text
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: readOnly ? Colors.grey.shade500 : const Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
