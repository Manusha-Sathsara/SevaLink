import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../providers/auth_provider.dart';

class RateWorkerScreen extends ConsumerStatefulWidget {
  final int workerId;
  final int jobId;
  final String? workerName;

  const RateWorkerScreen({
    super.key,
    required this.workerId,
    required this.jobId,
    this.workerName,
  });

  @override
  ConsumerState<RateWorkerScreen> createState() => _RateWorkerScreenState();
}

class _RateWorkerScreenState extends ConsumerState<RateWorkerScreen>
    with TickerProviderStateMixin {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingReview = true;
  bool _hasAlreadyReviewed = false;
  final List<File> _selectedPhotos = [];
  bool _isUploadingPhotos = false;

  // Animation controllers per star
  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starScales;

  static const int _maxChars = 300;

  @override
  void initState() {
    super.initState();
    _starControllers = List.generate(
      5,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    _starScales = _starControllers.map((ctrl) {
      return Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.elasticOut),
      );
    }).toList();
    _checkIfAlreadyReviewed();
  }

  @override
  void dispose() {
    for (final ctrl in _starControllers) {
      ctrl.dispose();
    }
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAlreadyReviewed() async {
    try {
      final user = ref.read(authProvider).user;
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(
        '/reviews/check',
        queryParameters: {'clientId': user?.id, 'jobId': widget.jobId},
      );
      if (mounted) {
        setState(() {
          _hasAlreadyReviewed = res.data['hasReviewed'] == true;
          _isCheckingReview = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingReview = false);
    }
  }

  void _onStarTap(int starIndex) {
    setState(() => _rating = starIndex + 1);
    // Bounce each filled star
    for (int i = 0; i <= starIndex; i++) {
      _starControllers[i].forward().then((_) => _starControllers[i].reverse());
    }
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }

  Color get _ratingColor {
    switch (_rating) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF97316);
      case 3:
        return const Color(0xFFEAB308);
      case 4:
        return const Color(0xFF22C55E);
      case 5:
        return const Color(0xFF16A34A);
      default:
        return Colors.grey.shade400;
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty && mounted) {
      final remaining = 5 - _selectedPhotos.length;
      final toAdd = picked.take(remaining).map((x) => File(x.path)).toList();
      setState(() => _selectedPhotos.addAll(toAdd));
    }
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  Future<List<String>> _uploadPhotos() async {
    final dio = ref.read(dioClientProvider).dio;
    final List<String> fileNames = [];
    for (final photo in _selectedPhotos) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          photo.path,
          filename: photo.path.split('/').last,
        ),
      });
      final res = await dio.post('/reviews/upload-photo', data: formData);
      if (res.data['fileName'] != null) {
        fileNames.add(res.data['fileName'] as String);
      }
    }
    return fileNames;
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).user;
      final dio = ref.read(dioClientProvider).dio;

      // Upload photos first if any
      List<String> photoFileNames = [];
      if (_selectedPhotos.isNotEmpty) {
        setState(() => _isUploadingPhotos = true);
        photoFileNames = await _uploadPhotos();
        if (mounted) setState(() => _isUploadingPhotos = false);
      }

      await dio.post('/reviews', data: {
        'client': {'id': user?.id},
        'worker': {'id': widget.workerId},
        'jobPost': {'id': widget.jobId},
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'photoUrls': photoFileNames.join(','),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Review submitted! Thank you.'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final msg = e is DioException && e.response?.data is Map
            ? (e.response!.data['message'] ?? 'Failed to submit review')
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() {_isLoading = false; _isUploadingPhotos = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A9134),
        foregroundColor: Colors.white,
        title: const Text(
          'Rate & Review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isCheckingReview
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2A9134)))
          : _hasAlreadyReviewed
              ? _buildAlreadyReviewedState()
              : _buildReviewForm(),
    );
  }

  Widget _buildAlreadyReviewedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16A34A),
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Review Already Submitted',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You have already reviewed this job. Your feedback helps the community!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9134),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    final workerName = widget.workerName ?? 'the Worker';
    final commentLen = _commentController.text.length;
    final isOverLimit = commentLen > _maxChars;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A9134), Color(0xFF5BBA6F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  'How was your experience with\n$workerName?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Star Rating Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Overall Rating',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 20),
                // Interactive star row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < _rating;
                    return GestureDetector(
                      onTap: () => _onStarTap(i),
                      child: AnimatedBuilder(
                        animation: _starScales[i],
                        builder: (context, child) => Transform.scale(
                          scale: _starScales[i].value,
                          child: child,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              key: ValueKey('$i-$filled'),
                              color: filled ? const Color(0xFFF59E0B) : const Color(0xFFE0E0E0),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _ratingLabel,
                    key: ValueKey(_rating),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _ratingColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Review textarea
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write a Review',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Share details about your experience — punctuality, quality of work, communication…',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2A9134), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$commentLen / $_maxChars',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverLimit ? const Color(0xFFEF4444) : Colors.grey.shade500,
                        fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Photo section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Add Photos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(optional, up to 5)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Add photo button
                      if (_selectedPhotos.length < 5)
                        GestureDetector(
                          onTap: _pickPhotos,
                          child: Container(
                            width: 84,
                            height: 84,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8EE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF2A9134).withValues(alpha: 0.4),
                                width: 1.5,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    color: Color(0xFF2A9134), size: 28),
                                SizedBox(height: 4),
                                Text(
                                  'Gallery',
                                  style: TextStyle(
                                    color: Color(0xFF2A9134),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Selected photos
                      ..._selectedPhotos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final photo = entry.value;
                        return Container(
                          width: 84,
                          height: 84,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  photo,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: (_isLoading || isOverLimit || _rating == 0) ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A9134),
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                        if (_isUploadingPhotos) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Uploading photos…',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _rating == 0 ? 'Select a Rating First' : 'Submit Review',
                          style: TextStyle(
                            fontSize: 17,
                            color: _rating == 0 ? Colors.grey : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
