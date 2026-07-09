import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../providers/search_provider.dart';
import '../../../data/models/worker_search_result.dart';
import '../../../data/models/search_suggestion.dart';


// CATEGORY DATA


class _CategoryOption {
  final String label;
  final String apiValue;
  final IconData icon;
  final Color iconColor;
  const _CategoryOption(this.label, this.apiValue, this.icon, this.iconColor);
}

const _kCategories = [
  _CategoryOption('Electrician', 'ELECTRICIAN', Icons.bolt, Color(0xFF5BBA6F)),
  _CategoryOption('Plumber',     'PLUMBER',     Icons.plumbing, Color(0xFF2A9134)),
  _CategoryOption('Carpenter',   'CARPENTER',   Icons.handyman, Color(0xFF8D6E63)),
  _CategoryOption('Painter',     'PAINTER',     Icons.palette, Color(0xFF3FA34D)),
  _CategoryOption('Cleaner',     'CLEANER',     Icons.cleaning_services, Color(0xFF5BBA6F)),
  _CategoryOption('Mechanic',    'MECHANIC',    Icons.settings, Color(0xFF137547)),
  _CategoryOption('Gardener',    'GARDENER',    Icons.eco, Color(0xFF4CAF50)),
  _CategoryOption('Technician',  'TECHNICIAN',  Icons.laptop, Color(0xFF2A9134)),
];


// ENUMS


enum _ActivePanel { none, filters, sort }


// ENUMS


enum _SortOption { relevant, ratingHigh, mostReviews, priceLow, priceHigh, mostExperienced }

extension _SortOptionX on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.relevant:        return 'Relevance';
      case _SortOption.ratingHigh:      return 'Highest Rated';
      case _SortOption.mostReviews:     return 'Most Reviews';
      case _SortOption.priceLow:        return 'Price: Low to High';
      case _SortOption.priceHigh:       return 'Price: High to Low';
      case _SortOption.mostExperienced: return 'Most Experienced';
    }
  }

  String get shortLabel {
    switch (this) {
      case _SortOption.relevant:        return 'Relevance';
      case _SortOption.ratingHigh:      return 'Top Rated';
      case _SortOption.mostReviews:     return 'Most Reviews';
      case _SortOption.priceLow:        return 'Price ↑';
      case _SortOption.priceHigh:       return 'Price ↓';
      case _SortOption.mostExperienced: return 'Experience';
    }
  }
}

enum _MinRating { fourHalf, four, threeHalf, all }

extension _MinRatingX on _MinRating {
  String get label {
    switch (this) {
      case _MinRating.fourHalf:  return '4.5+';
      case _MinRating.four:      return '4.0+';
      case _MinRating.threeHalf: return '3.5+';
      case _MinRating.all:       return 'All';
    }
  }

  double? get value {
    switch (this) {
      case _MinRating.fourHalf:  return 4.5;
      case _MinRating.four:      return 4.0;
      case _MinRating.threeHalf: return 3.5;
      case _MinRating.all:       return null;
    }
  }
}

enum _PriceBand { any, under1000, band1000_1500, band1500_2000, above2000 }

extension _PriceBandX on _PriceBand {
  String get label {
    switch (this) {
      case _PriceBand.any:           return 'Any Price';
      case _PriceBand.under1000:     return 'Under Rs. 1,000';
      case _PriceBand.band1000_1500: return 'Rs. 1,000 – 1,500';
      case _PriceBand.band1500_2000: return 'Rs. 1,500 – 2,000';
      case _PriceBand.above2000:     return 'Above Rs. 2,000';
    }
  }

  bool matches(int rate) {
    switch (this) {
      case _PriceBand.any:           return true;
      case _PriceBand.under1000:     return rate < 1000;
      case _PriceBand.band1000_1500: return rate >= 1000 && rate <= 1500;
      case _PriceBand.band1500_2000: return rate > 1500 && rate <= 2000;
      case _PriceBand.above2000:     return rate > 2000;
    }
  }
}


// SEARCH SCREEN

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const SearchScreen({super.key, this.initialCategory});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  Timer? _debounceSuggestions;

  // Filter & sort state
  _SortOption _sortOption  = _SortOption.relevant;
  _MinRating  _minRating   = _MinRating.all;
  _PriceBand  _priceBand   = _PriceBand.any;
  bool        _verifiedOnly = false;
  String?     _selectedCategory;
  _ActivePanel _activePanel = _ActivePanel.none;

  // In-memory recent searches (most-recent first, max 5)
  final List<String> _recentSearches = [];

  // GPS coordinates
  double? _lat;
  double? _lng;

  static const _orange = Color(0xFF2A9134);
  static const _bg     = Color(0xFFF2F3F7);

  //  Helpers

  /// Client-side filter + sort applied on top of the backend results.
  List<WorkerSearchResult> _applyFilters(List<WorkerSearchResult> raw) {
    final isAvailableOnly = ref.watch(searchProvider).isAvailableOnly;
    final list = raw.where((w) {
      if (isAvailableOnly && !w.isAvailable) return false;
      if (_verifiedOnly && !w.isVerified) return false;
      final minVal = _minRating.value;
      if (minVal != null && w.rating < minVal) return false;
      if (!_priceBand.matches(w.hourlyRate))    return false;
      return true;
    }).toList();

    switch (_sortOption) {
      case _SortOption.ratingHigh:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.priceLow:
        list.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
        break;
      case _SortOption.priceHigh:
        list.sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
        break;
      case _SortOption.mostReviews:
        list.sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
        break;
      case _SortOption.mostExperienced:
        list.sort((a, b) => b.totalJobs.compareTo(a.totalJobs));
        break;
      default:
        break; // backend order for relevant
    }
    return list;
  }

  void _addToRecent(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query.trim());
      _recentSearches.insert(0, query.trim());
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });
  }

  String _mapDbCategoryToApiValue(String name) {
    switch (name.toLowerCase()) {
      case 'electrical': case 'electrician': return 'ELECTRICIAN';
      case 'plumbing':   case 'plumber':     return 'PLUMBER';
      case 'carpentry':  case 'carpenter':   return 'CARPENTER';
      case 'painting':   case 'painter':     return 'PAINTER';
      case 'cleaning':   case 'cleaner':     return 'CLEANER';
      case 'mechanic':                       return 'MECHANIC';
      case 'gardener':                       return 'GARDENER';
      case 'technician':                     return 'TECHNICIAN';
      default:                               return name.toUpperCase();
    }
  }

  // Lifecycle 

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() { if (mounted) setState(() {}); });
    
    // Clear/reset search state fresh if we came here without pre-selected category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory == null) {
        ref.read(searchProvider.notifier).reset();
        if (mounted) {
          setState(() {
            _controller.clear();
            _selectedCategory = null;
            _sortOption = _SortOption.relevant;
            _minRating = _MinRating.all;
            _priceBand = _PriceBand.any;
            _verifiedOnly = false;
          });
        }
      }
    });

    _fetchLocation().then((_) {
      if (widget.initialCategory != null) {
        _selectedCategory = widget.initialCategory;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(searchProvider.notifier).searchByCategory(
            widget.initialCategory!, lat: _lat, lng: _lng,
          );
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _debounceSuggestions?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5)),
      );
      if (mounted) setState(() { _lat = pos.latitude; _lng = pos.longitude; });
    } catch (_) {}
  }

  // Search actions 

  void _onQueryChanged(String value) {
    _debounceSuggestions?.cancel();
    _debounceSuggestions = Timer(const Duration(milliseconds: 150), () {
      ref.read(searchProvider.notifier).fetchSuggestions(value);
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (value.trim().isEmpty) {
        ref.read(searchProvider.notifier).reset();
        return;
      }
      final trimmed = value.trim().toUpperCase();
      final matchedCat = _kCategories.firstWhere(
        (c) => c.apiValue == trimmed || c.label.toUpperCase() == trimmed,
        orElse: () => const _CategoryOption('', '', Icons.search, Colors.grey),
      );
      if (matchedCat.apiValue.isNotEmpty) {
        setState(() => _selectedCategory = matchedCat.apiValue);
        ref.read(searchProvider.notifier).searchByCategory(matchedCat.apiValue, lat: _lat, lng: _lng);
      } else {
        ref.read(searchProvider.notifier).search(value, category: _selectedCategory, lat: _lat, lng: _lng);
      }
    });
  }

  void _submitSearch(String value) {
    if (value.trim().isEmpty) return;
    _focusNode.unfocus();
    _addToRecent(value.trim());
    ref.read(searchProvider.notifier).search(value, category: _selectedCategory, lat: _lat, lng: _lng);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() { _selectedCategory = null; _sortOption = _SortOption.relevant; _minRating = _MinRating.all; _priceBand = _PriceBand.any; _verifiedOnly = false; });
    ref.read(searchProvider.notifier).reset();
    _focusNode.requestFocus();
  }

  void _tapRecent(String query) {
    _controller.text = query;
    _focusNode.unfocus();
    _addToRecent(query);
    ref.read(searchProvider.notifier).search(query, category: _selectedCategory, lat: _lat, lng: _lng);
  }

  void _tapTrendingCategory(_CategoryOption cat) {
    _controller.text = cat.label;
    _focusNode.unfocus();
    setState(() => _selectedCategory = cat.apiValue);
    _addToRecent(cat.label);
    ref.read(searchProvider.notifier).searchByCategory(cat.apiValue, lat: _lat, lng: _lng);
  }

  // Build 

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody(searchState)),
          ],
        ),
      ),
    );
  }

  // Top bar 

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Icon(Icons.chevron_left_rounded, size: 28, color: Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(width: 4),
          // Search field
          Expanded(
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 22, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onQueryChanged,
                    onSubmitted: _submitSearch,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'Search workers, services...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
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

  // Body router 

  Widget _buildBody(SearchState state) {
    // Suggestions overlay when typing
    if (_focusNode.hasFocus && state.suggestions.isNotEmpty && _controller.text.isNotEmpty) {
      return _buildSuggestions(state.suggestions);
    }

    switch (state.status) {
      case SearchStatus.initial:
        return _buildPreSearch();
      case SearchStatus.loading:
        return _buildLoading();
      case SearchStatus.error:
        return _buildError(state.errorMessage ?? 'Unknown error');
      case SearchStatus.success:
        final filtered = _applyFilters(state.results);
        return _buildResultsView(state.results, filtered, state.query);
    }
  }

  //  Pre-search state 
  Widget _buildPreSearch() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          _sectionHeader(Icons.history_rounded, 'Recent Searches'),
          const SizedBox(height: 12),
          ..._recentSearches.map(_recentItem),
          const SizedBox(height: 24),
        ],
        _sectionHeader(Icons.trending_up_rounded, 'Trending Services'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _kCategories.map(_trendingChip).toList(),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _orange),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _recentItem(String query) {
    return GestureDetector(
      onTap: () => _tapRecent(query),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(query, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            ),
            Icon(Icons.north_west_rounded, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _trendingChip(_CategoryOption cat) {
    return GestureDetector(
      onTap: () => _tapTrendingCategory(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, size: 16, color: _orange),
            const SizedBox(width: 6),
            Text(cat.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }

  // Suggestions 
  Widget _buildSuggestions(List<SearchSuggestion> suggestions) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1),
        itemBuilder: (context, i) {
          final item = suggestions[i];
          if (item.type == 'WORKER') return const SizedBox.shrink();

          IconData icon;
          Color color;
          if (item.type == 'CATEGORY') {
            icon = Icons.category_rounded;    color = _orange;
          } else if (item.type == 'SKILL') {
            icon = Icons.construction_rounded; color = Colors.green.shade600;
          } else {
            icon = Icons.search_rounded;       color = Colors.grey.shade600;
          }

          return ListTile(
            leading: Icon(icon, color: color, size: 22),
            title: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                children: _highlightMatch(item.text, _controller.text),
              ),
            ),
            trailing: Icon(Icons.north_west_rounded, color: Colors.grey.shade300, size: 16),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: () {
              _controller.text = item.text;
              _focusNode.unfocus();
              if (item.type == 'CATEGORY') {
                final mapped = _mapDbCategoryToApiValue(item.text);
                final matched = _kCategories.firstWhere(
                  (c) => c.apiValue == mapped || c.label.toUpperCase() == item.text.toUpperCase() || c.apiValue == item.text.toUpperCase(),
                  orElse: () => const _CategoryOption('', '', Icons.search, Colors.grey),
                );
                if (matched.apiValue.isNotEmpty) {
                  setState(() => _selectedCategory = matched.apiValue);
                  _addToRecent(item.text);
                  ref.read(searchProvider.notifier).searchByCategory(matched.apiValue, lat: _lat, lng: _lng);
                  return;
                }
              }
              _submitSearch(item.text);
            },
          );
        },
      ),
    );
  }

  List<TextSpan> _highlightMatch(String text, String query) {
    if (query.isEmpty) return [TextSpan(text: text)];
    final lo = text.toLowerCase();
    final lq = query.toLowerCase();
    final idx = lo.indexOf(lq);
    if (idx == -1) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(text: text.substring(idx, idx + query.length), style: const TextStyle(fontWeight: FontWeight.bold, color: _orange)),
      TextSpan(text: text.substring(idx + query.length)),
    ];
  }

  // Results view 

  Widget _buildResultsView(List<WorkerSearchResult> raw, List<WorkerSearchResult> filtered, String query) {
    return Column(
      children: [
        _buildFilterSortBar(raw.length, filtered.length),
        Divider(color: Colors.grey.shade200, height: 1),
        if (_activePanel == _ActivePanel.filters) ...[
          _buildFiltersPanel(),
          Divider(color: Colors.grey.shade200, height: 1),
        ],
        if (_activePanel == _ActivePanel.sort) ...[
          _buildSortPanel(),
          Divider(color: Colors.grey.shade200, height: 1),
        ],
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(query, _selectedCategory)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => _showWorkerDetails(ctx, filtered[i]),
                    child: _buildWorkerCard(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }



  //  Filter / sort bar

  Widget _buildFilterSortBar(int total, int shown) {
    final countText = shown == total
        ? '$shown result${shown == 1 ? '' : 's'}'
        : '$shown of $total results';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Filters button
          _ActionPill(
            icon: Icons.tune_rounded,
            label: 'Filters',
            isActive: _activePanel == _ActivePanel.filters,
            onTap: () {
              _focusNode.unfocus();
              setState(() {
                if (_activePanel == _ActivePanel.filters) {
                  _activePanel = _ActivePanel.none;
                } else {
                  _activePanel = _ActivePanel.filters;
                }
              });
            },
          ),
          const SizedBox(width: 10),
          // Sort button
          _ActionPill(
            icon: Icons.swap_vert_rounded,
            label: _sortOption.shortLabel,
            isActive: _activePanel == _ActivePanel.sort,
            onTap: () {
              _focusNode.unfocus();
              setState(() {
                if (_activePanel == _ActivePanel.sort) {
                  _activePanel = _ActivePanel.none;
                } else {
                  _activePanel = _ActivePanel.sort;
                }
              });
            },
          ),
          const Spacer(),
          // Result count
          Text(countText, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  //  Inline panels

  Widget _buildFiltersPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CATEGORY
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4E68),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _buildCategoryChipsInline(),
          const SizedBox(height: 16),

          // MINIMUM RATING
          const Text(
            'MINIMUM RATING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4E68),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _buildRatingRowInline(),
          const SizedBox(height: 16),

          // HOURLY RATE
          const Text(
            'HOURLY RATE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4E68),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _buildPriceGridInline(),
          const SizedBox(height: 16),

          // TOGGLES (Verified Only, Available Now)
          _buildTogglePillsInline(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildCategoryChipsInline() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "All" chip
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = null;
            });
            ref.read(searchProvider.notifier).search(_controller.text, category: null, lat: _lat, lng: _lng);
          },
          child: _filterChip('All', isActive: _selectedCategory == null, icon: null),
        ),
        ..._kCategories.map((cat) => GestureDetector(
          onTap: () {
            final nextCategory = _selectedCategory == cat.apiValue ? null : cat.apiValue;
            setState(() {
              _selectedCategory = nextCategory;
            });
            ref.read(searchProvider.notifier).search(_controller.text, category: nextCategory, lat: _lat, lng: _lng);
          },
          child: _filterChip(
            cat.label,
            isActive: _selectedCategory == cat.apiValue,
            icon: cat.icon,
            iconColor: cat.iconColor,
          ),
        )),
      ],
    );
  }

  Widget _filterChip(String label, {required bool isActive, IconData? icon, Color? iconColor}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2A9134) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF2A9134) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : (iconColor ?? const Color(0xFF374151)),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRowInline() {
    return Row(
      children: _MinRating.values.map((r) {
        final active = _minRating == r;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _minRating = r;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2A9134) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active ? const Color(0xFF2A9134) : const Color(0xFFE5E7EB),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r != _MinRating.all) ...[
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: active ? Colors.white : const Color(0xFF5BBA6F),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceGridInline() {
    final bands = _PriceBand.values.skip(1).toList(); // skip 'any'
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _priceChipInline(bands[0])),
            const SizedBox(width: 10),
            Expanded(child: _priceChipInline(bands[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _priceChipInline(bands[2])),
            const SizedBox(width: 10),
            Expanded(child: _priceChipInline(bands[3])),
          ],
        ),
      ],
    );
  }

  Widget _priceChipInline(_PriceBand band) {
    final active = _priceBand == band;
    return GestureDetector(
      onTap: () {
        setState(() {
          _priceBand = active ? _PriceBand.any : band;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A9134) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? const Color(0xFF2A9134) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        child: Text(
          band.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePillsInline() {
    final isAvailableOnly = ref.watch(searchProvider).isAvailableOnly;
    return Row(
      children: [
        Expanded(
          child: _toggleChipInline(
            icon: Icons.check_circle_outline_rounded,
            label: 'Verified Only',
            active: _verifiedOnly,
            onTap: () {
              setState(() {
                _verifiedOnly = !_verifiedOnly;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _toggleChipInline(
            icon: Icons.access_time_rounded,
            label: 'Available Now',
            active: isAvailableOnly,
            onTap: () {
              ref.read(searchProvider.notifier).toggleAvailabilityFilter(lat: _lat, lng: _lng);
            },
          ),
        ),
      ],
    );
  }

  Widget _toggleChipInline({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A9134) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? const Color(0xFF2A9134) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : const Color(0xFF374151),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _sortChipInline(_SortOption.relevant)),
              const SizedBox(width: 10),
              Expanded(child: _sortChipInline(_SortOption.ratingHigh)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _sortChipInline(_SortOption.mostReviews)),
              const SizedBox(width: 10),
              Expanded(child: _sortChipInline(_SortOption.priceLow)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _sortChipInline(_SortOption.priceHigh)),
              const SizedBox(width: 10),
              Expanded(child: _sortChipInline(_SortOption.mostExperienced)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sortChipInline(_SortOption opt) {
    final active = _sortOption == opt;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortOption = opt;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A9134) : const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          opt.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }



  // Worker card 

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
          // Avatar + verified overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: worker.imageUrl != null
                    ? Image.network(
                        worker.imageUrl!,
                        width: 80, height: 80, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(worker.name),
                      )
                    : _avatarFallback(worker.name),
              ),
              if (worker.isVerified)
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded, color: _orange, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rate
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        worker.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (worker.hourlyRate > 0)
                      Text(
                        'LKR ${worker.hourlyRate}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _orange),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                // Profession & Availability
                Row(
                  children: [
                    Text(
                      worker.profession,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: worker.isAvailable
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFECEFF1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: worker.isAvailable
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF90A4AE),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            worker.isAvailable ? 'Available' : 'Busy',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: worker.isAvailable
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF546E7A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Location
                if (worker.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          worker.location,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // Stars + per hour
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      IconData ico;
                      if (i < worker.rating.floor()) {
                        ico = Icons.star_rounded;
                      } else if (i < worker.rating) {
                        ico = Icons.star_half_rounded;
                      } else {
                        ico = Icons.star_outline_rounded;
                      }
                      return Icon(ico, color: const Color(0xFF5BBA6F), size: 15);
                    }),
                    const SizedBox(width: 5),
                    Text(
                      worker.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    if (worker.hourlyRate > 0) ...[
                      const Spacer(),
                      Text('per hour', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ],
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
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _orange),
      ),
    );
  }

  //Worker details sheet

  void _showWorkerDetails(BuildContext context, WorkerSearchResult worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: worker.imageUrl != null
                      ? Image.network(worker.imageUrl!, width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(worker.name))
                      : _avatarFallback(worker.name),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text(worker.profession, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFF5BBA6F), size: 18),
                          const SizedBox(width: 4),
                          Text(worker.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                          if (worker.isVerified) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFE8F8EE), borderRadius: BorderRadius.circular(8)),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_outlined, color: _orange, size: 12),
                                  SizedBox(width: 4),
                                  Text('Verified', style: TextStyle(color: _orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _detailRow(Icons.location_on_outlined,    'Location',    worker.location),
            const SizedBox(height: 12),
            _detailRow(Icons.monetization_on_outlined, 'Hourly Rate', 'LKR ${worker.hourlyRate} / hour'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Close', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/client/chat/${worker.id}', extra: {'name': worker.name});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          ],
        ),
      ],
    );
  }

  // Loading 

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _skeletonCard(),
    );
  }

  Widget _skeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sh(130, 14), const SizedBox(height: 8),
              _sh(90,  12), const SizedBox(height: 12),
              _sh(160, 10), const SizedBox(height: 8),
              _sh(80,  24),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sh(double w, double h) => Container(
    width: w, height: h,
    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
  );

  //  Error 
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Search failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => ref.read(searchProvider.notifier).search(_controller.text, category: _selectedCategory, lat: _lat, lng: _lng),
            child: const Text('Retry'),
          ),
        ]),
      ),
    );
  }

  //  Empty 

  Widget _buildEmpty(String query, String? category) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MagnifyingGlassIllustration(size: 110),
              const SizedBox(height: 24),
              const Text(
                'No results found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Try different keywords or clear some filters',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ACTION PILL (Filters / Sort buttons)

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2A9134) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isActive
              ? Border.all(color: const Color(0xFF2A9134), width: 1.5)
              : Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF374151),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF374151),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MagnifyingGlassIllustration extends StatelessWidget {
  final double size;
  const MagnifyingGlassIllustration({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MagnifyingGlassPainter(),
      ),
    );
  }
}

class _MagnifyingGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.44, size.height * 0.44);
    final radius = size.width * 0.26;

    // Handle Paint (bottom right)
    final handlePaint = Paint()
      ..color = const Color(0xFF137547) // Purple handle
      ..style = PaintingStyle.fill;

    // Save canvas, rotate to draw handle at 45 degrees
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.785398); // 45 degrees in radians (pi/4)

    // Draw the neck of the handle
    final neckPaint = Paint()
      ..color = const Color(0xFF137547) // Darker purple neck
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * 0.035, radius - 2, size.width * 0.07, size.height * 0.08),
        const Radius.circular(3),
      ),
      neckPaint,
    );

    // Draw the main handle body (capsule shape)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * 0.065, radius + size.height * 0.06, size.width * 0.13, size.height * 0.32),
        Radius.circular(size.width * 0.065),
      ),
      handlePaint,
    );
    canvas.restore();

    // Frame Paint (Outer border of the lens)
    final framePaint = Paint()
      ..color = const Color(0xFF137547) // Darker purple frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;

    // Draw outer frame
    canvas.drawCircle(center, radius, framePaint);

    // Lens Paint (Cyan-blue gradient)
    final lensPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF5BBA6F), // Bright cyan
          Color(0xFF2A9134), // Vibrant blue
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Draw lens fill (slightly smaller than radius so frame doesn't get overlapped)
    canvas.drawCircle(center, radius - (size.width * 0.03), lensPaint);

    // Highlight (White crescent on the top-left)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius * 0.62),
        3.14159 + 0.3, // start angle
        1.1, // sweep angle
      );

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


