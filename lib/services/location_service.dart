import 'package:geolocator/geolocator.dart';

class LocationService {
  static double calculateDistance(
    double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
