import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/google_maps_service.dart';

class JobLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const JobLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<JobLocationPickerScreen> createState() => _JobLocationPickerScreenState();
}

class _JobLocationPickerScreenState extends State<JobLocationPickerScreen> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;
  LatLng _cameraPosition = const LatLng(6.9271, 79.8612); // Colombo default
  String _formattedAddress = '';
  
  // Suggestion & Debounce State
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _isGeocoding = false;
  bool _isSuggestionsVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _cameraPosition = widget.initialLocation!;
      _reverseGeocode(_cameraPosition);
    } else {
      _setCurrentLocation();
    }
  }

  Future<void> _setCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _reverseGeocode(_cameraPosition);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _reverseGeocode(_cameraPosition);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _reverseGeocode(_cameraPosition);
        return;
      } 

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      if (mounted) {
        final target = LatLng(position.latitude, position.longitude);
        setState(() {
          _cameraPosition = target;
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 14),
          ),
        );
        _reverseGeocode(target);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _reverseGeocode(_cameraPosition);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Debounces user input and queries the autocomplete API
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSuggestionsVisible = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await _mapsService.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
          _isSuggestionsVisible = results.isNotEmpty;
        });
      }
    });
  }

  /// Reverse geocode coordinates to update text field and address string
  Future<void> _reverseGeocode(LatLng coordinates) async {
    setState(() => _isGeocoding = true);
    final address = await _mapsService.reverseGeocode(coordinates.latitude, coordinates.longitude);
    if (mounted) {
      setState(() {
        _isGeocoding = false;
        if (address != null && address.isNotEmpty) {
          _formattedAddress = address;
          // Only update search field if user is not actively typing
          if (!_searchFocusNode.hasFocus) {
            _searchController.text = address;
          }
        } else {
          _formattedAddress = 'Unknown Location';
        }
      });
    }
  }

  /// Triggered when user selects a prediction from autocomplete dropdown list
  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['place_id'];
    final description = suggestion['description'];

    // Unfocus and hide list
    _searchFocusNode.unfocus();
    setState(() {
      _isSuggestionsVisible = false;
      _searchController.text = description;
      _formattedAddress = description;
    });

    // Fetch coordinates
    final latLng = await _mapsService.getPlaceLatLng(placeId);
    if (latLng != null && mounted) {
      final target = LatLng(latLng['lat']!, latLng['lng']!);
      _cameraPosition = target;
      
      // Animate map camera to coordinates
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map filling the entire background
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _cameraPosition,
              zoom: 14,
            ),
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (widget.initialLocation == null && _cameraPosition != const LatLng(6.9271, 79.8612)) {
                _mapController?.moveCamera(CameraUpdate.newLatLng(_cameraPosition));
              }
            },
            onCameraMove: (position) {
              // Update target center continuously during panning
              _cameraPosition = position.target;
            },
            onCameraIdle: () {
              // Perform reverse geocoding on central coordinates when panning stops
              _reverseGeocode(_cameraPosition);
            },
          ),

          // Uber-style fixed pin in the center of the viewport
          Center(
            child: Transform.translate(
              offset: const Offset(0, -22), // Align pin tip with exact map center
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF2A9134), // SevaLink Brand Orange
                size: 44,
              ),
            ),
          ),

          // Top Autocomplete Search Section
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2A9134), size: 22),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2A9134)),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // Autocomplete Suggestions List
                if (_isSuggestionsVisible)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _suggestions.length,
                      separatorBuilder: (ctx, idx) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                          title: Text(
                            suggestion['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Action Panel
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selected Address HUD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_pin, color: Color(0xFF2A9134), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            _isGeocoding
                                ? const Text(
                                    'Loading address...',
                                    style: TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
                                  )
                                : Text(
                                    _formattedAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm Button
                ElevatedButton(
                  onPressed: _isGeocoding
                      ? null
                      : () {
                          // Return location details to post job screen
                          Navigator.of(context).pop({
                            'latitude': _cameraPosition.latitude,
                            'longitude': _cameraPosition.longitude,
                            'address': _formattedAddress,
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF054A29), // SevaLink Brand Teal
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
