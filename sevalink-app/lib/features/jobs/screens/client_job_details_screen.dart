import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_jobs_provider.dart';
import '../../../providers/quotation_provider.dart';
import '../../../core/constants/api_endpoints.dart';

class ClientJobDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> job;

  const ClientJobDetailsScreen({super.key, required this.job});

  @override
  ConsumerState<ClientJobDetailsScreen> createState() => _ClientJobDetailsScreenState();
}

class _ClientJobDetailsScreenState extends ConsumerState<ClientJobDetailsScreen> {
  bool _isLoading = false;
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    if (widget.job['status'] == 'COMPLETED') {
      _checkIfRated();
    }
  }

  Future<void> _checkIfRated() async {
    try {
      final user = ref.read(authProvider).user;
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/reviews/check?clientId=${user?.id}&jobId=${widget.job['id']}');
      if (mounted) {
        setState(() {
          _hasRated = res.data['hasReviewed'] ?? false;
        });
      }
    } catch (e) {
      // Ignore error for now
    }
  }

  Future<void> _cancelJob() async {
    final reasonController = TextEditingController();
    String selectedReason = 'Found someone else';
    final status = widget.job['status'] ?? 'OPEN';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(status == 'ASSIGNED' ? 'Cancel Job' : 'Delete Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status == 'ASSIGNED'
                  ? 'Are you sure you want to cancel this job? The assigned worker will be notified.'
                  : 'Are you sure you want to delete this job? Please provide a reason.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedReason,
                items: const [
                  DropdownMenuItem(value: 'Found someone else', child: Text('Found someone else')),
                  DropdownMenuItem(value: 'No longer needed', child: Text('No longer needed')),
                  DropdownMenuItem(value: 'Created by mistake', child: Text('Created by mistake')),
                  DropdownMenuItem(value: 'Budget issues', child: Text('Budget issues')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Please describe your reason',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Keep Job'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final reason = selectedReason == 'Other'
                    ? (reasonController.text.trim().isEmpty ? 'Other' : reasonController.text.trim())
                    : selectedReason;
                Navigator.of(dialogContext).pop(reason);
              },
              child: Text(
                status == 'ASSIGNED' ? 'Cancel Job' : 'Delete',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result is String) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(authProvider).user;
        final dio = ref.read(dioClientProvider).dio;
        await dio.put('/jobs/${widget.job['id']}/delete?clientId=${user?.id}', data: {'reason': result});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'ASSIGNED' ? 'Job cancelled successfully' : 'Job deleted successfully'),
              backgroundColor: Colors.orange.shade700,
            ),
          );
          ref.invalidate(clientJobsProvider);
          ref.invalidate(clientJobStatsProvider);
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showWorkerDetails(Map<String, dynamic> workerData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) {
          final name = workerData['name'] ?? 'Worker';
          final rating = (workerData['rating'] ?? 0.0).toDouble();
          final totalJobs = workerData['totalJobs'] ?? 0;
          final bio = workerData['bio'] ?? '';
          final phone = workerData['phone'] ?? '';
          final category = workerData['category'] ?? '';
          final profileImageUrl = workerData['profileImageUrl'];

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Profile header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFF2A9134).withValues(alpha: 0.1),
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(ApiEndpoints.rewriteImageUrl(profileImageUrl.toString()))
                                : null,
                            child: profileImageUrl == null
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'W',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2A9134),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                if (category.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A9134).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(color: Color(0xFF2A9134), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• $totalJobs jobs done',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(bio, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                      ],

                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_outlined, color: Color(0xFF2A9134)),
                              const SizedBox(width: 12),
                              Text(phone, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      // Rating stars display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) => Icon(
                          i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 28,
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.job['status'] ?? 'OPEN';
    final isCompleted = status == 'COMPLETED';
    final canCancel = status == 'OPEN' || status == 'ASSIGNED';
    final isAssigned = status == 'ASSIGNED';

    final quotesAsync = ref.watch(jobQuotationsProvider(widget.job['id']));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: const Color(0xFF2A9134),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.job['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Category: ${widget.job['categoryName'] ?? ''}', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(widget.job['description'] ?? ''),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Budget', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Rs. ${widget.job['budgetMin']} - ${widget.job['budgetMax']}', style: const TextStyle(color: Color(0xFF2A9134), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Assigned worker details button
                  if (isAssigned || isCompleted) ...[
                    const SizedBox(height: 16),
                    quotesAsync.when(
                      data: (quotes) {
                        final acceptedQuote = quotes.where((q) => q.status == 'ACCEPTED').firstOrNull;
                        if (acceptedQuote == null) return const SizedBox();
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              // Fetch worker details
                              try {
                                final dio = ref.read(dioClientProvider).dio;
                                final res = await dio.get('/workers/${acceptedQuote.workerId}');
                                final data = res.data;
                                final workerInfo = {
                                  'name': data['user']?['fullName'] ?? 'Worker',
                                  'phone': data['user']?['phoneNumber'] ?? '',
                                  'bio': data['bio'] ?? '',
                                  'rating': data['rating'] ?? 0.0,
                                  'totalJobs': data['totalJobs'] ?? 0,
                                  'category': data['category']?['name'] ?? '',
                                  'profileImageUrl': data['user']?['profileImageUrl'],
                                };
                                if (mounted) _showWorkerDetails(workerInfo);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not load worker details: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.person_outline, color: Color(0xFF2A9134)),
                            label: const Text('View Worker Details', style: TextStyle(color: Color(0xFF2A9134), fontSize: 15)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2A9134)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                      error: (err, stack) => const SizedBox(),
                    ),
                  ],

                  // Rate worker button for completed jobs
                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    quotesAsync.when(
                      data: (quotes) {
                        final acceptedQuote = quotes.where((q) => q.status == 'ACCEPTED').firstOrNull;
                        if (acceptedQuote != null) {
                          if (_hasRated) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Review Submitted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          } else {
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await context.push('/client/rate-worker/${acceptedQuote.workerId}/${widget.job['id']}');
                                  _checkIfRated();
                                },
                                icon: const Icon(Icons.star_outline),
                                label: const Text('Rate Worker', style: TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox();
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const SizedBox(),
                    ),
                  ],
                  
                  if (canCancel) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _cancelJob,
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        label: Text(
                          status == 'ASSIGNED' ? 'Cancel Job' : 'Delete Job',
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN': return Colors.blue;
      case 'ASSIGNED': return Colors.orange;
      case 'COMPLETED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }
}
