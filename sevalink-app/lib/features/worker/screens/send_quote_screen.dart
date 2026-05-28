// lib/features/worker/screens/send_quote_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/job.dart';

class SendQuoteScreen extends StatefulWidget {
  final Job job;

  const SendQuoteScreen({super.key, required this.job});

  @override
  State<SendQuoteScreen> createState() => _SendQuoteScreenState();
}

class _SendQuoteScreenState extends State<SendQuoteScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  final _timelineController = TextEditingController();

  int _selectedTimeline = 0; // 0=Hours, 1=Days, 2=Weeks
  bool _isSubmitting = false;
  bool _submitted = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _timelineUnits = ['Hours', 'Days', 'Weeks'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildJobSummaryCard(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('Your Quote Amount *'),
                        const SizedBox(height: 10),
                        _buildAmountField(),
                        const SizedBox(height: 6),
                        _buildBudgetHint(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('Estimated Completion Time *'),
                        const SizedBox(height: 10),
                        _buildTimelineRow(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('Your Message to Client *'),
                        const SizedBox(height: 10),
                        _buildMessageField(),
                        const SizedBox(height: 24),
                        _buildTipsCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF006B5E),
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
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Quote',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          Text(
            'Submit your bid for this job',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      expandedHeight: 70,
    );
  }

  Widget _buildJobSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3FBB), Color(0xFF0E257A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3FBB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.work_outline_rounded,
                  color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Text('Job Summary',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.job.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(widget.job.location,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.access_time_rounded,
                  color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(widget.job.postedAt,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_rupee,
                    color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Budget: Rs. ${widget.job.minBudget} - Rs. ${widget.job.maxBudget}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF), fontWeight: FontWeight.normal),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF006B5E), width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937)),
      decoration: _fieldDecoration('Enter your quote amount').copyWith(
        prefixText: 'Rs. ',
        prefixStyle: const TextStyle(
          color: Color(0xFF006B5E),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Please enter your quote amount';
        final amount = int.tryParse(val);
        if (amount == null || amount <= 0) return 'Enter a valid amount';
        return null;
      },
    );
  }

  Widget _buildBudgetHint() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 13, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 5),
          Text(
            'Client budget: Rs. ${widget.job.minBudget} – Rs. ${widget.job.maxBudget}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _timelineController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937)),
            decoration: _fieldDecoration('e.g. 3'),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        // Timeline unit toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Row(
            children: List.generate(_timelineUnits.length, (i) {
              final selected = _selectedTimeline == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedTimeline = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF006B5E)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _timelineUnits[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      controller: _messageController,
      maxLines: 5,
      style: const TextStyle(
          fontSize: 15, color: Color(0xFF1F2937), height: 1.5),
      decoration: _fieldDecoration(
          'Introduce yourself and explain why you\'re the best fit for this job. Mention your experience, tools you\'ll use, and any questions you have...'),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please write a message to the client';
        }
        if (val.trim().length < 20) {
          return 'Message must be at least 20 characters';
        }
        return null;
      },
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: Color(0xFF16A34A), size: 16),
              SizedBox(width: 8),
              Text(
                'Tips for a winning quote',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTip('Be competitive but realistic with your price'),
          _buildTip('Mention your relevant experience clearly'),
          _buildTip('Respond quickly — clients prefer fast responses'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF16A34A), size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitQuote,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006B5E),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF006B5E).withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Submit Quote',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF006B5E),
                    size: 70,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Quote Sent!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your quote for "${widget.job.title}" has been sent successfully. The client will review it and get back to you.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    height: 1.6),
              ),
              const SizedBox(height: 40),
              _buildSuccessStat('Quote Amount',
                  'Rs. ${_amountController.text}', Icons.attach_money_rounded),
              const SizedBox(height: 12),
              _buildSuccessStat(
                'Estimated Time',
                '${_timelineController.text} ${_timelineUnits[_selectedTimeline]}',
                Icons.schedule_rounded,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/worker/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Dashboard',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => context.go('/worker/home'),
                child: const Text(
                  'View My Jobs',
                  style: TextStyle(
                      color: Color(0xFF006B5E),
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStat(String label, String value, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF006B5E), size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
