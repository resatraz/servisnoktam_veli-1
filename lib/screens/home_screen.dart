import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/models/driver_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'announcements_screen.dart';

class HomeScreen extends StatefulWidget {
  final String driverId;
  final double homeLat;
  final double homeLng;
  const HomeScreen({
    super.key,
    required this.driverId,
    required this.homeLat,
    required this.homeLng,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationModel? _driverLocation;
  DriverModel? _driver;
  bool _hasNotified = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _loadDriver();
    _listenLocation();
  }

  Future<void> _loadDriver() async {
    final driver = await FirestoreService.getDriver(widget.driverId);
    setState(() => _driver = driver);
  }

  void _listenLocation() {
    // Mock location updates - Firebase olmadan test için
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      // Rastgele konum simülasyonu
      final randomLat = widget.homeLat + (DateTime.now().millisecond % 100 - 50) / 10000;
      final randomLng = widget.homeLng + (DateTime.now().millisecond % 100 - 50) / 10000;
      setState(() {
        _driverLocation = LocationModel(
          lat: randomLat,
          lng: randomLng,
          isActive: true,
        );
      });
      _checkDistanceAndNotify();
    });
  }

  void _checkDistanceAndNotify() {
    if (_driverLocation == null || !_driverLocation!.isActive) return;
    if (_hasNotified) return;
    final distance = LocationService.calculateDistance(
      widget.homeLat, widget.homeLng,
      _driverLocation!.lat, _driverLocation!.lng,
    );
    if (distance < 500) {
      setState(() => _hasNotified = true);
      NotificationService.showNotification(
        title: 'Servis Yaklaşıyor!',
        body: 'Şoför evinize 500 metreden daha yakın.',
      );
    }
  }

  Future<void> _resetNotification() async {
    setState(() => _hasNotified = false);
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_driver?.name ?? 'Yükleniyor...'),
            if (_driver != null)
              Text(_driver!.plate,
                style: TextStyle(fontSize: 10, color: AppColors.primaryAccent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
              );
            },
            tooltip: 'Duyurular',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetNotification,
            tooltip: 'Bildirimi Sıfırla',
          ),
        ],
      ),
      body: Column(
        children: [
          // Konum bilgisi
          Expanded(
            child: _driverLocation != null && _driverLocation!.isActive
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bus, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Şoför Konumu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enlem: ${_driverLocation!.lat.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Boylam: ${_driverLocation!.lng.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ev Konumu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enlem: ${widget.homeLat.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Boylam: ${widget.homeLng.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Konum bekleniyor...'),
                    ],
                  ),
                ),
          ),
          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.background,
                  child: _driver?.photoUrl.isNotEmpty == true
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverLocation?.isActive == true
                          ? '● Canlı Takip'
                          : 'Bekleniyor',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _driverLocation?.isActive == true
                            ? AppColors.success
                            : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasNotified
                          ? '✓ Bildirim gönderildi'
                          : 'Bildirim bekleniyor',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
