import '../core/models/driver_model.dart';

class FirestoreService {
  // Mock implementation - Firebase olmadan çalışması için
  static Future<List<DriverModel>> getDrivers() async {
    // Mock data döndür
    return [
      DriverModel(
        id: 'driver1',
        name: 'Ahmet Yılmaz',
        phone: '5551234567',
        plate: '34 ABC 123',
        capacity: 20,
        isActive: true,
      ),
      DriverModel(
        id: 'driver2',
        name: 'Mehmet Demir',
        phone: '5559876543',
        plate: '34 XYZ 789',
        capacity: 15,
        isActive: true,
      ),
    ];
  }

  static Future<DriverModel?> getDriver(String driverId) async {
    // Mock data döndür
    return null;
  }

  static Stream listenDriverLocation(String driverId) {
    // Mock stream - hiçbir şey yapma
    return const Stream.empty();
  }

  static Future<void> saveParentInfo(String parentId, Map<String, dynamic> data) async {
    // Mock - hiçbir şey yapma
  }

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    // Mock data döndür
    return [];
  }
}
