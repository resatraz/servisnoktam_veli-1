import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';
import '../core/models/driver_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

class SetupDriverScreen extends StatefulWidget {
  const SetupDriverScreen({super.key});

  @override
  State<SetupDriverScreen> createState() => _SetupDriverScreenState();
}

class _SetupDriverScreenState extends State<SetupDriverScreen> {
  String? _selectedId;

  Future<void> _confirm() async {
    if (_selectedId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverId', _selectedId!);
    
    // Veli için unique ID oluştur - çakışmayı önle (uuid)
    String? parentId = prefs.getString('parentId');
    if (parentId == null) {
      parentId = 'parent_${const Uuid().v4()}';
      await prefs.setString('parentId', parentId);
    }
    
    // Veli FCM token'ını kaydet (unique parentId ile)
    final token = await NotificationService.getFCMToken();
    if (token != null) {
      await FirestoreService.saveParentToken(parentId, token);
      // Ayrıca driverId ve home bilgisini de kaydet (parentCount doğru sayılsın)
      final homeLat = prefs.getDouble('homeLat');
      final homeLng = prefs.getDouble('homeLng');
      if (homeLat != null && homeLng != null) {
        await FirestoreService.saveParentInfo(parentId, {
          'driverId': _selectedId,
          'homeLocation': {'lat': homeLat, 'lng': homeLng},
          'fcmToken': token,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }
    
    final homeLat = prefs.getDouble('homeLat');
    final homeLng = prefs.getDouble('homeLng');
    if (!mounted) return;
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => HomeScreen(
        driverId: _selectedId!,
        homeLat: homeLat!,
        homeLng: homeLng!,
      )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şoför Seçimi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.primaryLight),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text('Çocuğunuzun Servisini Seçin',
              style: TextStyle(fontSize: 12, color: AppColors.primaryAccent)),
          ),
          Expanded(
            child: FutureBuilder<List<DriverModel>>(
              future: FirestoreService.getDrivers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Şoför Bulunamadı'));
                }
                final drivers = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: drivers.length,
                  itemBuilder: (context, i) {
                    final d = drivers[i];
                    final selected = _selectedId == d.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedId = d.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.background,
                              child: const Icon(Icons.person, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.name,
                                    style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text('${d.plate} • ${d.school}',
                                    style: const TextStyle(
                                      fontSize: 10, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedId != null ? _confirm : null,
                child: const Text('Devam Et'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
