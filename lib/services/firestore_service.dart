import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/driver_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm sürücüleri getir
  static Future<List<DriverModel>> getDrivers() async {
    try {
      final snapshot = await _firestore.collection('drivers').get();
      return snapshot.docs.map((doc) {
        return DriverModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('Sürücüleri getirme hatası: $e');
      return [];
    }
  }

  // Belirli bir sürücü getir
  static Future<DriverModel?> getDriver(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();
      if (doc.exists) {
        return DriverModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Sürücü getirme hatası: $e');
      return null;
    }
  }

  // Sürücü konumunu dinle (real-time)
  static Stream listenDriverLocation(String driverId) {
    return _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('location')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  // Veli bilgilerini kaydet
  static Future<void> saveParentInfo(String parentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('parents').doc(parentId).set(data);
    } catch (e) {
      print('Veli bilgisi kaydetme hatası: $e');
    }
  }

  // Duyuruları getir
  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Duyuruları getirme hatası: $e');
      return [];
    }
  }

  // Sürücü konumunu güncelle (sürücü tarafı için)
  static Future<void> updateDriverLocation(String driverId, double lat, double lng) async {
    try {
      await _firestore
          .collection('drivers')
          .doc(driverId)
          .collection('location')
          .doc('current')
          .set({
        'lat': lat,
        'lng': lng,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Konum güncelleme hatası: $e');
    }
  }

  // Veli FCM token'ını kaydet
  static Future<void> saveParentToken(String parentId, String token) async {
    try {
      await _firestore.collection('parents').doc(parentId).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Token kaydetme hatası: $e');
    }
  }

  // Veli FCM token'ını getir
  static Future<String?> getParentToken(String parentId) async {
    try {
      final doc = await _firestore.collection('parents').doc(parentId).get();
      if (doc.exists) {
        return doc.data()?['fcmToken'];
      }
      return null;
    } catch (e) {
      print('Token getirme hatası: $e');
      return null;
    }
  }
}
