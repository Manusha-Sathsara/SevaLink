String getApproximateLocation(String address) {
  if (address.isEmpty) return '';
  final parts = address.split(',').map((p) => p.trim()).toList();
  
  if (parts.length <= 1) return address;

  if (parts.last.toLowerCase() == 'sri lanka') {
    parts.removeLast();
  }

  if (parts.isEmpty) return 'Unknown Location';

  if (parts.length >= 2) {
    if (parts.first.contains('+')) {
      parts.removeAt(0);
    }
  }

  final cleanParts = parts.where((part) {
    final lower = part.toLowerCase();
    return !lower.contains('road') &&
           !lower.contains(' rd') &&
           !lower.contains('mawatha') &&
           !lower.contains('lane') &&
           !lower.contains(' st') &&
           !lower.contains('street') &&
           !lower.contains('ave') &&
           !lower.contains('avenue') &&
           !lower.contains('highway');
  }).toList();

  if (cleanParts.isNotEmpty) {
    if (cleanParts.length >= 2) {
      return "${cleanParts[cleanParts.length - 2]}, ${cleanParts.last}";
    } else {
      return cleanParts.last;
    }
  }

  return parts.last;
}
