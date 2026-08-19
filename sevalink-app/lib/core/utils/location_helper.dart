import 'dart:math' as math;

/// Extracts a clean, high-level city/town/area name from a full geocoded address.
/// Removes plus codes (e.g. P387+M4J), street names (Road, Mawatha, Lane),
/// postal codes (e.g. 00700), and country suffixes.
String getApproximateLocation(String address) {
  if (address.isEmpty) return 'Unknown Location';
  
  // Split by comma
  final rawParts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (rawParts.isEmpty) return 'Unknown Location';

  final parts = <String>[];
  for (final part in rawParts) {
    // Skip country
    if (part.toLowerCase() == 'sri lanka') continue;
    // Skip plus codes (e.g., P387+M4J or RWF3+CJQ)
    if (part.contains('+') || RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}').hasMatch(part)) continue;
    // Skip pure numbers or postal codes (e.g. 00700 or 10250)
    if (RegExp(r'^\d+$').hasMatch(part)) continue;
    
    // Clean postal code attached to city name (e.g. "Colombo 00700" -> "Colombo")
    final cleaned = part.replaceAll(RegExp(r'\b\d{5}\b'), '').trim();
    if (cleaned.isNotEmpty) {
      parts.add(cleaned);
    }
  }

  if (parts.isEmpty) return 'Unknown Location';

  // Filter out specific street/road components
  final nonStreetParts = parts.where((part) {
    final lower = part.toLowerCase();
    return !lower.contains('road') &&
           !lower.contains(' rd') &&
           !lower.contains('mawatha') &&
           !lower.contains('lane') &&
           !lower.contains(' st') &&
           !lower.contains('street') &&
           !lower.contains('ave') &&
           !lower.contains('avenue') &&
           !lower.contains('highway') &&
           !lower.contains('drive') &&
           !lower.contains('place') &&
           !lower.contains('court');
  }).toList();

  if (nonStreetParts.isNotEmpty) {
    // If multiple city parts exist (e.g. ["Dehiwala-Mount Lavinia", "Colombo"]), return the most specific local city
    return nonStreetParts.first;
  }

  // Fallback to the last available cleaned part
  return parts.last;
}

/// Calculates distance between two GPS coordinates in kilometers using the Haversine formula.
double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;

  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) *
          math.cos(_degreesToRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) {
  return degrees * (math.pi / 180.0);
}

/// Formats distance in km to a clean, rounded 1-decimal string (e.g., "1.6 km", "0.8 km").
String formatDistance(double distanceKm) {
  if (distanceKm < 0.1) return '< 0.1 km';
  return '${distanceKm.toStringAsFixed(1)} km';
}

/// Returns a privacy-safe high-level job location combined with distance from the worker.
/// E.g. "Boralesgamuwa • 2.4 km" or "Colombo"
String formatJobLocationPreview(
  String fullAddress, {
  double? jobLat,
  double? jobLng,
  double? workerLat,
  double? workerLng,
}) {
  final highLevel = getApproximateLocation(fullAddress);

  if (jobLat != null && jobLng != null && workerLat != null && workerLng != null &&
      jobLat != 0.0 && jobLng != 0.0 && workerLat != 0.0 && workerLng != 0.0) {
    final dist = calculateDistanceKm(workerLat, workerLng, jobLat, jobLng);
    return '$highLevel • ${formatDistance(dist)}';
  }

  return highLevel;
}

