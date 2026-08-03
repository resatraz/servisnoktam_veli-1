import '../core/models/driver_model.dart';

class FirestoreService {
  static Future<List<DriverModel>> getDrivers() async {
    // Mock data - Firebase olmadan test için
    return [];
  }

  static Future<DriverModel?> getDriver(String id) async {
    // Mock data - Firebase olmadan test için
    return null;
  }

  static Future<void> saveParent({
    required String parentId,
    required double lat,
    required double lng,
    required String driverId,
    required String fcmToken,
  }) async {
    // Mock save - Firebase olmadan test için
  }

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    // Mock data - Firebase olmadan test için
    return [];
  }
}
