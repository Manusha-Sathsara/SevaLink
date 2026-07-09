import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/client_jobs_provider.dart';
import '../../../providers/auth_provider.dart';
import 'job_location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategory;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _budgetMinController = TextEditingController();
  final TextEditingController _budgetMaxController = TextEditingController();

  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  final List<XFile> _selectedPhotos = [];

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Electrical'},
    {'id': 2, 'name': 'Plumbing'},
    {'id': 3, 'name': 'Carpentry'},
    {'id': 4, 'name': 'Cleaning'},
    {'id': 5, 'name': 'Painting'},
    {'id': 6, 'name': 'General'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        // Limit to 5 photos
        _selectedPhotos.addAll(picked);
        if (_selectedPhotos.length > 5) {
          _selectedPhotos.removeRange(5, _selectedPhotos.length);
        }
      });
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(clientJobsRepositoryProvider);
      final user = ref.read(authProvider).user;
      final categoryId = _categories.firstWhere((c) => c['name'] == _selectedCategory)['id'];

      final jobData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'locationName': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'category': {'id': categoryId},
        'client': {'id': user?.id},
        'budgetMin': double.tryParse(_budgetMinController.text.trim()) ?? 0,
        'budgetMax': double.tryParse(_budgetMaxController.text.trim()) ?? 0,
        'status': 'OPEN',
        'urgency': 'FLEXIBLE',
      };

      await repository.createJob(jobData);
      
      // Invalidate the jobs list to show the new job
      ref.invalidate(clientJobsProvider);
      ref.invalidate(clientJobStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job posted successfully!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting job: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Post a Job',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionContainer(
                  title: 'Service Category *',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                    hint: const Text(
                      'Select a category',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2A9134), width: 2.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['name'],
                        child: Text(
                          c['name'],
                          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionContainer(
                  title: 'Job Title *',
                  child: TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                    decoration: _buildInputDecoration('e.g., Fix kitchen electrical wiring'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionContainer(
                  title: 'Description *',
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                    decoration: _buildInputDecoration('Describe the work you need done in detail...'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionContainer(
                  title: 'Location *',
                  child: TextFormField(
                    controller: _locationController,
                    readOnly: true,
                    onTap: _selectLocation,
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                    decoration: _buildInputDecoration('Tap to select location', prefixIcon: Icons.location_on_outlined),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionContainer(
                  title: 'Budget Range',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMinController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                          decoration: _buildInputDecoration('Min', prefixText: 'Rs. '),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMaxController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                          decoration: _buildInputDecoration('Max', prefixText: 'Rs. '),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildSectionContainer(
                  title: 'Add Photos (Optional)',
                  child: Column(
                    children: [
                      if (_selectedPhotos.isNotEmpty) ...[
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedPhotos.length,
                            itemBuilder: (_, i) => Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(File(_selectedPhotos[i].path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 14,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedPhotos.removeAt(i)),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      GestureDetector(
                        onTap: _selectedPhotos.length < 5 ? _pickPhotos : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPhotos.length < 5 ? Colors.grey.shade400 : Colors.grey.shade200,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: _selectedPhotos.length < 5 ? Colors.grey.shade500 : Colors.grey.shade300,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedPhotos.isEmpty
                                    ? 'Tap to upload photos (max 5)'
                                    : _selectedPhotos.length >= 5
                                        ? 'Maximum 5 photos'
                                        : 'Add more photos (${_selectedPhotos.length}/5)',
                                style: TextStyle(
                                  color: _selectedPhotos.length < 5 ? Colors.grey.shade600 : Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF054A29),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Post Job',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {IconData? prefixIcon, String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600, size: 20) : null,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A9134), width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
