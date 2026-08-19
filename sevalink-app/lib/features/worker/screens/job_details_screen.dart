
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/job.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/location_helper.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    return Scaffold(
      backgroundColor: colors.bodyBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildStatusRow(context),
                  const SizedBox(height: 20),
                  _buildBudgetCard(),
                  const SizedBox(height: 20),
                  _buildSection(
                    context: context,
                    title: 'Job Description',
                    icon: Icons.description_outlined,
                    child: Text(
                      job.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: (Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light).textSecondary,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context: context,
                    title: 'Location & Proximity',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.location_city_rounded,
                                  color: Color(0xFF054A29), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getApproximateLocation(job.location),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: (Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light).textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    job.distanceKm != null
                                        ? 'Approx. ${job.distanceKm!.toStringAsFixed(1)} km from your location'
                                        : 'General vicinity',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF054A29).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF054A29).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF054A29)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Exact address & navigation route will be unlocked once your quotation is accepted by the client.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF054A29).withValues(alpha: 0.9),
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context: context,
                    title: 'Job Details',
                    icon: Icons.info_outline_rounded,
                    child: Column(
                      children: [
                        _buildDetailRow(context,
                            Icons.category_outlined, 'Category', job.category),
                        const SizedBox(height: 12),
                        _buildDetailRow(context,
                            Icons.access_time_rounded, 'Posted', job.postedAt),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                            context,
                            Icons.new_releases_outlined,
                            'Status',
                            job.isNew ? 'Newly Posted' : 'Active'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildClientCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF2A9134),
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A9134), Color(0xFF3FA34D)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (job.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C896),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Text(
                    job.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildChip(
              context,
              Icons.location_on_outlined,
              getApproximateLocation(job.location) + (job.distanceKm != null ? ' • ${job.distanceKm!.toStringAsFixed(1)} km' : ''),
              const Color(0xFF2A9134)),
        ),
        const SizedBox(width: 10),
        _buildChip(context, Icons.access_time_rounded, job.postedAt,
            const Color(0xFF6B7280)),
      ],
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, Color color) {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: colors.border) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF054A29), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF054A29).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Rs.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Budget Range',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${job.minBudget} - ${job.maxBudget}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: colors.border, width: 1) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2A9134)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? colors.cardBg2 : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: colors.textSecondary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: colors.textSecondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientCard(BuildContext context) {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: colors.border, width: 1) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 18, color: Color(0xFF2A9134)),
              SizedBox(width: 8),
              Text(
                'Posted By',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFE8EAF6),
                child: Text(
                  'C',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A9134),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937)),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 14, color: Color(0xFF054A29)),
                        SizedBox(width: 4),
                        Text('Verified Client',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF054A29))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF054A29), width: 1),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF054A29),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final colors = Theme.of(context).extension<SevaLinkColors>() ?? SevaLinkColors.light;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: colors.cardBg,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2A9134),
                side: const BorderSide(color: Color(0xFF2A9134), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Go Back',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                context.push('/worker/send-quote', extra: job);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF054A29),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Send Quote',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

