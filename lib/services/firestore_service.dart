import '../core/models/driver_model.dart';

class FirestoreService {
  // Mock implementation - Firebase olmadan çalışması için
  static Future<List<DriverModel>> getDrivers() async {
    // Mock data döndür
    return [
      DriverModel(
        id: 'driver1',
        name: 'Ahmet Yılmaz',
        plate: '34 ABC 123',
        school: 'İlkokul',
        photoUrl: '',
        phone: '5551234567',
        isActive: true,
      ),
      DriverModel(
        id: 'driver2',
        name: 'Mehmet Demir',
        plate: '34 XYZ 789',
        school: 'Ortaokul',
        photoUrl: '',
        phone: '5559876543',
        isActive: true,
      ),
    ];
  }

  static Future<DriverModel?> getDriver(String driverId) async {
    // Mock data döndür
    if (driverId == 'driver1') {
      return DriverModel(
        id: 'driver1',
        name: 'Ahmet Yılmaz',
        plate: '34 ABC 123',
        school: 'İlkokul',
        photoUrl: '',
        phone: '5551234567',
        isActive: true,
      );
    } else if (driverId == 'driver2') {
      return DriverModel(
        id: 'driver2',
        name: 'Mehmet Demir',
        plate: '34 XYZ 789',
        school: 'Ortaokul',
        photoUrl: '',
        phone: '5559876543',
        isActive: true,
      );
    }
    return null;
  }

  static Stream listenDriverLocation(String driverId) {
    // Mock stream - konum güncellemesi simülasyonu
    return Stream.periodic(const Duration(seconds: 3), (count) {
      return {
        'lat': 37.1674 + (count % 10) * 0.001,
        'lng': 38.7955 + (count % 10) * 0.001,
        'isActive': true,
      };
    });
  }

  static Future<void> saveParentInfo(String parentId, Map<String, dynamic> data) async {
    // Mock - hiçbir şey yapma
  }

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    // Mock data döndür
    return [];
  }
}
