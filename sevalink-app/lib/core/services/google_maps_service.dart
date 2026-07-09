import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class GoogleMapsService {
  static const String _apiKey = 'AIzaSyAPPANjNMTd7qWJmadVw5DNyfp9rpEhfVQ';
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /// Query Google Places Autocomplete API.
  /// Filters suggestions specifically to Sri Lanka ('lk') for SevaLink context.
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String input) async {
    if (input.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'components': 'country:lk',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['predictions'] != null) {
          return List<Map<String, dynamic>>.from(data['predictions']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching autocomplete suggestions: $e');
      return [];
    }
  }

  /// Get place coordinates (latitude/longitude) using Place Details API.
  Future<Map<String, double>?> getPlaceLatLng(String placeId) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry',
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['result'] != null) {
          final geometry = data['result']['geometry'];
          if (geometry != null && geometry['location'] != null) {
            final location = geometry['location'];
            return {
              'lat': (location['lat'] as num).toDouble(),
              'lng': (location['lng'] as num).toDouble(),
            };
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting place coordinates: $e');
      return null;
    }
  }

  /// Query Google Reverse Geocoding API.
  /// Returns the human-readable formatted address for a set of coordinates.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] as String?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error performing reverse geocoding: $e');
      return null;
    }
  }
}
