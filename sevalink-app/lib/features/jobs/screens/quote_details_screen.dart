import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/quotation_provider.dart';
import '../../../providers/client_jobs_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/quotation_model.dart';

class QuoteDetailsScreen extends ConsumerStatefulWidget {
  final Quotation quotation;

  const QuoteDetailsScreen({super.key, required this.quotation});

  @override
  ConsumerState<QuoteDetailsScreen> createState() => _QuoteDetailsScreenState();
}

class _QuoteDetailsScreenState extends ConsumerState<QuoteDetailsScreen> {
  bool _isLoading = false;

  void _acceptQuote() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(quotationRepositoryProvider).acceptQuotation(widget.quotation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote accepted successfully!'), backgroundColor: Colors.green),
        );
        // Refresh the quotes list
        ref.invalidate(jobQuotationsProvider(widget.quotation.jobPostId));
        
        // Refresh client jobs list and stats
        final user = ref.read(authProvider).user;
        if (user != null) {
          final clientId = user.id;
          ref.invalidate(clientJobStatsProvider(clientId));
          ref.invalidate(clientJobsProvider);
        }

        // Navigate directly to the timeline screen
        context.go('/client/jobs/${widget.quotation.jobPostId}/timeline');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _declineQuote() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(quotationRepositoryProvider).declineQuotation(widget.quotation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote declined.')),
        );
        ref.invalidate(jobQuotationsProvider(widget.quotation.jobPostId));
        
        // Refresh client jobs list and stats
        final user = ref.read(authProvider).user;
        if (user != null) {
          final clientId = user.id;
          ref.invalidate(clientJobStatsProvider(clientId));
          ref.invalidate(clientJobsProvider);
        }

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quotation;
    final formatter = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formattedPrice = quote.proposedPrice.toInt().toString().replaceAllMapped(formatter, (m) => ',');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Orange Header Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              color: const Color(0xFF2A9134),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Quote Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for centering
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Worker Profile Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: quote.workerAvatar.isNotEmpty
                                            ? Image.network(
                                                quote.workerAvatar,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey.shade200,
                                                child: Icon(Icons.person, color: Colors.grey.shade400, size: 40),
                                              ),
                                      ),
                                      Positioned(
                                        right: -4,
                                        bottom: -4,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.verified, color: Color(0xFF2A9134), size: 24),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quote.workerName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          quote.workerProfession,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Color(0xFF2A9134), size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              quote.workerRating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            Text(
                                              ' (${quote.workerReviewCount} reviews)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, color: Colors.grey.shade500, size: 16),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                quote.workerLocation,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade100),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, color: Color(0xFF2A9134), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Experience: ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    '${quote.workerExperienceYears} years',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (quote.workerTotalJobs > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Jobs Completed: ',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    Text(
                                      '${quote.workerTotalJobs}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (quote.workerSkills.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Skills',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: quote.workerSkills.split(',').map((skill) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        skill.trim(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (quote.workerBio.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  quote.workerBio,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Quoted Amount Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8EE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8F8EE)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Quoted Amount',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF137547),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs. $formattedPrice',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF137547),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.access_time, color: Color(0xFF137547), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Estimated Time: ${quote.eta}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF137547),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Completion Time Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF4B5563), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Completion Time',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        quote.eta,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'The worker estimates this job will be completed in approximately ${quote.eta}.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Message Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F8EE), // Light purple
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF137547), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Message from Worker',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '"${quote.message}"',
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontSize: 15,
                                    height: 1.6,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        if (quote.status == 'ACCEPTED')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                                SizedBox(width: 8),
                                Text(
                                  'Accepted',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (quote.status == 'REJECTED')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel, color: Color(0xFFDC2626)),
                                SizedBox(width: 8),
                                Text(
                                  'Declined',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _declineQuote,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.red.shade200),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.close, color: Colors.red.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Decline',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _acceptQuote,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A), // Green
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isLoading 
                                      ? const SizedBox(
                                          width: 24, 
                                          height: 24, 
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Accept Quote',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        
                        // Note text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8EE), // Light blue
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF137547),
                                fontSize: 13,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(text: 'Note: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: 'Once you accept this quote, the worker will be notified and you can track the job progress. You can also chat with the worker to discuss further details.'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // View Profile link
                        GestureDetector(
                          onTap: () {
                            context.push('/client/worker/${quote.workerId}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF2A9134)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_outline, color: Color(0xFF2A9134), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'View Full Worker Profile',
                                  style: TextStyle(
                                    color: Color(0xFF2A9134),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_ios, color: Color(0xFF2A9134), size: 14),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
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
}
