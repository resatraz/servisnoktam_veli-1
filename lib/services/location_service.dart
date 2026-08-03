import 'dart:math' as math;

class LocationService {
  static double calculateDistance(
    double lat1, double lng1, double lat2, double lng2) {
    // Haversine formula - geolocator olmadan manuel hesaplama
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
}
