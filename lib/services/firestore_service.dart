import 'package:firebase_database/firebase_database.dart';
import '../core/models/driver_model.dart';

class FirestoreService {
  static final _db = FirebaseDatabase.instance;

  static Future<List<DriverModel>> getDrivers() async {
    final snap = await _db.ref('drivers').get();
    if (snap.value == null) return [];
    final data = snap.value as Map<dynamic, dynamic>;
    return data.entries.map((e) {
      final map = e.value as Map<dynamic, dynamic>;
      return DriverModel.fromMap(e.key.toString(), Map<String, dynamic>.from(map));
    }).toList();
  }

  static Future<DriverModel?> getDriver(String id) async {
    final snap = await _db.ref('drivers/$id').get();
    if (snap.value == null) return null;
    final map = snap.value as Map<dynamic, dynamic>;
    return DriverModel.fromMap(id, Map<String, dynamic>.from(map));
  }

  static Future<void> saveParent({
    required String parentId,
    required double lat,
    required double lng,
    required String driverId,
    required String fcmToken,
  }) async {
    await _db.ref('parents/$parentId').set({
      'homeLocation': {'lat': lat, 'lng': lng},
      'driverId': driverId,
      'fcmToken': fcmToken,
      'createdAt': ServerValue.timestamp,
    });
  }

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final snap = await _db.ref('announcements').get();
    if (snap.value == null) return [];
    final data = snap.value as Map<dynamic, dynamic>;
    final announcements = data.entries.map((e) {
      final map = e.value as Map<dynamic, dynamic>;
      return {
        'id': e.key.toString(),
        ...Map<String, dynamic>.from(map),
      };
    }).toList();
    // Sadece 'all' veya 'parents' hedefli duyuruları filtrele
    final filtered = announcements.where((a) {
      final target = a['target'] as String? ?? 'all';
      return target == 'all' || target == 'parents';
    }).toList();
    filtered.sort((a, b) {
      final aDate = DateTime.parse(a['createdAt']);
      final bDate = DateTime.parse(b['createdAt']);
      return bDate.compareTo(aDate);
    });
    return filtered;
  }
}
