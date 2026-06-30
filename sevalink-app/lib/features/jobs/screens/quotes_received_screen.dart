import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/quotation_provider.dart';
import '../../../data/models/quotation_model.dart';

class QuotesReceivedScreen extends ConsumerWidget {
  final int jobId;
  final Map<String, dynamic> jobDetails;

  const QuotesReceivedScreen({
    super.key,
    required this.jobId,
    required this.jobDetails,
  });

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '2 hours ago';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (e) {
      return '2 hours ago';
    }
  }

  String _formatBudget(dynamic amount) {
    if (amount == null) return '0';
    final num = amount is double ? amount.toInt() : amount as int;
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(num % 1000 == 0 ? 0 : 1)}K'.replaceAll('.0K', ',000');
    }
    return num.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(jobQuotationsProvider(jobId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quotes Received',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            quotesAsync.when(
              data: (quotes) {
                final activeCount = quotes.where((q) => q.status != 'REJECTED').length;
                return Text(
                  '$activeCount quotes for your job',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (error, stack) => const SizedBox(),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2A9134),
        onRefresh: () async {
          ref.invalidate(jobQuotationsProvider(jobId));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildJobHeader(),
            ),
            quotesAsync.when(
              data: (quotes) {
                final activeQuotes = quotes.where((q) => q.status != 'REJECTED').toList();
                if (activeQuotes.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No quotes received yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildQuoteCard(context, activeQuotes[index]);
                    },
                    childCount: activeQuotes.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF2A9134))),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHeader() {
    final title = jobDetails['title'] ?? 'Electrical Wiring for New Kitchen';
    final description = jobDetails['description'] ?? 'Need complete electrical wiring for newly renovated kitchen...';
    final budgetMin = jobDetails['budgetMin'];
    final budgetMax = jobDetails['budgetMax'];
    final createdAt = jobDetails['createdAt']?.toString();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F635C), // Dark green background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 6),
              Text(
                'Posted ${_timeAgo(createdAt)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Budget: Rs.${_formatBudget(budgetMin ?? 8000)} - ${_formatBudget(budgetMax ?? 12000)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, Quotation quote) {
    // Format price
    final formatter = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formattedPrice = quote.proposedPrice.toInt().toString().replaceAllMapped(formatter, (m) => ',');

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Rating, Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: quote.workerAvatar.isNotEmpty
                    ? Image.network(
                        quote.workerAvatar,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.person, color: Colors.grey.shade400, size: 30),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.workerName.replaceAll(' ', '\n'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFF5BBA6F), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          quote.workerRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          ' (${quote.workerReviewCount})',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, color: Color(0xFF2A9134), size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Seva Verified',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: const Color(0xFF2A9134),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. $formattedPrice',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF054A29), // Teal color
                    ),
                  ),
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Time
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey.shade500, size: 16),
              const SizedBox(width: 6),
              Text(
                'Estimated time: ${quote.eta}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Message Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quote.message,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to chat
                    context.push('/client/chat/${quote.workerUserId}', extra: {'name': quote.workerName});
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Color(0xFF1F2937), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Quote Details
                    context.push('/client/quote-details', extra: quote);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9134),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
