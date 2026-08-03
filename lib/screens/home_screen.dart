import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import '../core/models/driver_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'announcements_screen.dart';
import 'setup_driver_screen.dart';

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
  DateTime? _lastUpdateTime;

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
        _lastUpdateTime = DateTime.now();
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

  String _getStatusText() {
    if (_driverLocation == null) return 'Bekleniyor';
    if (!_driverLocation!.isActive) {
      final diff = _lastUpdateTime != null 
          ? DateTime.now().difference(_lastUpdateTime!)
          : const Duration(minutes: 10);
      if (diff.inMinutes < 60) {
        return 'Son görülme: ${diff.inMinutes} dk önce';
      } else {
        return 'Son görülme: ${diff.inHours} saat önce';
      }
    }
    return '● Canlı Takip';
  }

  Color _getStatusColor() {
    if (_driverLocation == null) return AppColors.textSecondary;
    if (!_driverLocation!.isActive) return AppColors.danger;
    return AppColors.success;
  }

  String _getLastUpdateText() {
    if (_lastUpdateTime == null) return 'Güncelleme bekleniyor...';
    final now = DateTime.now();
    final diff = now.difference(_lastUpdateTime!);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} saniye önce güncellendi';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dakika önce güncellendi';
    } else {
      return '${diff.inHours} saat önce güncellendi';
    }
  }

  String _getDistanceText() {
    if (_driverLocation == null) return 'Mesafe hesaplanıyor...';
    final distance = LocationService.calculateDistance(
      widget.homeLat, widget.homeLng,
      _driverLocation!.lat, _driverLocation!.lng,
    );
    if (distance < 1000) {
      return '${distance.toInt()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  Future<void> _resetNotification() async {
    setState(() => _hasNotified = false);
  }

  void _callDriver() {
    if (_driver?.phone.isNotEmpty == true) {
      // URL launcher ile arama yapılabilir
      // Şimdilik sadece placeholder
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_driver!.phone} aranıyor...')),
      );
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const SetupDriverScreen()));
          },
        ),
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
          // Harita
          Expanded(
            child: _driverLocation != null && _driverLocation!.isActive
              ? FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(_driverLocation!.lat, _driverLocation!.lng),
                    initialZoom: 15,
                    minZoom: 10,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.servisnoktam.veli',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_driverLocation!.lat, _driverLocation!.lng),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.directions_bus,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        Marker(
                          point: LatLng(widget.homeLat, widget.homeLng),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.home,
                            size: 40,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst satır: Durum ve mesafe
                Row(
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
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mesafe
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getDistanceText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Alt satır: Son güncelleme ve arama butonu
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.update, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _getLastUpdateText(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, size: 20),
                          onPressed: _callDriver,
                          tooltip: 'Sürücüyü Ara',
                          color: AppColors.primary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Text(
                          'Ara',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
