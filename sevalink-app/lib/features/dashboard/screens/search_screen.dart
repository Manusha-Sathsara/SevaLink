import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/search_provider.dart';
import '../../../data/models/worker_search_result.dart';


// Category chip data

class _CategoryOption {
  final String label;
  final String apiValue;
  final IconData icon;
  const _CategoryOption(this.label, this.apiValue, this.icon);
}

const _kCategories = [
  _CategoryOption('Electrician', 'ELECTRICIAN', Icons.bolt_outlined),
  _CategoryOption('Plumber', 'PLUMBER', Icons.plumbing_outlined),
  _CategoryOption('Carpenter', 'CARPENTER', Icons.handyman_outlined),
  _CategoryOption('Painter', 'PAINTER', Icons.format_paint_outlined),
  _CategoryOption('Cleaner', 'CLEANER', Icons.auto_awesome_outlined),
  _CategoryOption('Mechanic', 'MECHANIC', Icons.settings_outlined),
  _CategoryOption('Gardener', 'GARDENER', Icons.eco_outlined),
  _CategoryOption('Technician', 'TECHNICIAN', Icons.laptop_chromebook_outlined),
];


// Search Screen

class SearchScreen extends ConsumerStatefulWidget {
  /// Optional pre-selected category (when tapping a category tile on dashboard)
  final String? initialCategory;

  const SearchScreen({super.key, this.initialCategory});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String? _selectedCategory;

  // Animation for the screen entrance
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _primaryBlue = Color(0xFF2B4EEF);
  static const _blueDark = Color(0xFF1A2FBF);
  static const _bg = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    // Pre-select category if passed from dashboard
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(searchProvider.notifier)
            .searchByCategory(widget.initialCategory!);
      });
    } else {
      // Auto-focus keyboard when no initial category
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    // Reset provider state when leaving screen
    ref.read(searchProvider.notifier).reset();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(searchProvider.notifier).search(
            value,
            category: _selectedCategory,
          );
    });
  }

  void _onCategoryTap(_CategoryOption cat) {
    setState(() {
      if (_selectedCategory == cat.apiValue) {
        // Deselect
        _selectedCategory = null;
        ref
            .read(searchProvider.notifier)
            .search(_controller.text, category: null);
      } else {
        _selectedCategory = cat.apiValue;
        ref.read(searchProvider.notifier).search(
              _controller.text,
              category: cat.apiValue,
            );
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _selectedCategory = null);
    ref.read(searchProvider.notifier).reset();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeader(searchState),
              _buildCategoryChips(),
              Expanded(child: _buildBody(searchState)),
            ],
          ),
        ),
      ),
    );
  }

  //  Header with search bar
  Widget _buildHeader(SearchState searchState) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_blueDark, _primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find a Worker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Search by name, skill or category',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search input
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded,
                    color: Colors.grey.shade400, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onQueryChanged,
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'e.g. plumber, Sunil, electrician...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => ref
                        .read(searchProvider.notifier)
                        .search(v, category: _selectedCategory),
                  ),
                ),
                if (_controller.text.isNotEmpty || _selectedCategory != null)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.close_rounded,
                          color: Colors.grey.shade400, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  Category filter chips
  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _kCategories.map((cat) {
            final isSelected = _selectedCategory == cat.apiValue;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => _onCategoryTap(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryBlue : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? _primaryBlue
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 16,
                        color:
                            isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  //  Body — initial / loading / error / results
  Widget _buildBody(SearchState state) {
    switch (state.status) {
      case SearchStatus.initial:
        return _buildInitialHint();
      case SearchStatus.loading:
        return _buildLoading();
      case SearchStatus.error:
        return _buildError(state.errorMessage ?? 'Unknown error');
      case SearchStatus.success:
        if (state.isEmpty) return _buildEmpty(state.query, state.selectedCategory);
        return _buildResults(state.results);
    }
  }

  Widget _buildInitialHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 48, color: _primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Search for a worker',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a name or skill above, or pick\na category to browse workers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
      itemBuilder: (ctx, idx) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 130, height: 14),
                const SizedBox(height: 8),
                _shimmerBox(width: 90, height: 12),
                const SizedBox(height: 12),
                _shimmerBox(width: 160, height: 10),
                const SizedBox(height: 8),
                _shimmerBox(width: 80, height: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildEmpty(String query, String? category) {
    final label = category != null
        ? 'No $category workers found'
        : 'No results for "$query"';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword or category.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Search failed',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => ref
                  .read(searchProvider.notifier)
                  .search(_controller.text, category: _selectedCategory),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  //  Result list
  Widget _buildResults(List<WorkerSearchResult> workers) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: workers.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildWorkerCard(workers[index]),
    );
  }

  Widget _buildWorkerCard(WorkerSearchResult worker) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: worker.imageUrl != null
                ? Image.network(
                    worker.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _avatarFallback(worker.name),
                  )
                : _avatarFallback(worker.name),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        worker.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (worker.hourlyRate > 0)
                      Text(
                        'Rs. ${worker.hourlyRate}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _primaryBlue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      worker.profession,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (worker.hourlyRate > 0)
                      Text(
                        'per hour',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                  ],
                ),
                if (worker.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          worker.location,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Star rating
                    Row(
                      children: List.generate(5, (i) {
                        IconData icon;
                        if (i < worker.rating.floor()) {
                          icon = Icons.star_rounded;
                        } else if (i < worker.rating) {
                          icon = Icons.star_half_rounded;
                        } else {
                          icon = Icons.star_outline_rounded;
                        }
                        return Icon(icon,
                            color: const Color(0xFFFFC107), size: 16);
                      }),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      worker.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A)),
                    ),
                    const Spacer(),
                    if (worker.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_outlined,
                                color: _primaryBlue, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Seva Verified',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  Widget _avatarFallback(String name) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E5),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _primaryBlue,
        ),
      ),
    );
  }
}
