import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _hasNotified500 = false;
  bool _hasNotified50 = false;
  bool _hasNotifiedArrived = false;
  DateTime? _lastUpdateTime;
  final MapController _mapController = MapController();
  StreamSubscription? _locationSubscription;

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
    // Firestore'dan real-time konum dinleme - subscription sakla
    _locationSubscription?.cancel();
    _locationSubscription = FirestoreService.listenDriverLocation(widget.driverId).listen((locationData) {
      if (!mounted) return;
      if (locationData != null) {
        setState(() {
          _driverLocation = LocationModel(
            lat: locationData['lat'] ?? 0,
            lng: locationData['lng'] ?? 0,
            isActive: locationData['isActive'] ?? true,
          );
          _lastUpdateTime = DateTime.now();
        });
        _checkDistanceAndNotify();
      }
    });
  }

  void _checkDistanceAndNotify() {
    if (_driverLocation == null || !_driverLocation!.isActive) return;
    final distance = LocationService.calculateDistance(
      widget.homeLat, widget.homeLng,
      _driverLocation!.lat, _driverLocation!.lng,
    );
    
    // Tek seferde sadece 1 bildirim - en yakından başla (10m > 50m > 500m)
    if (!_hasNotifiedArrived && distance < 10) {
      setState(() => _hasNotifiedArrived = true);
      NotificationService.showNotification(
        title: 'Öğrenci Adrese Vardı',
        body: 'Şoför Adrese Ulaştı.',
      );
    } else if (!_hasNotified50 && distance < 50) {
      setState(() => _hasNotified50 = true);
      NotificationService.showNotification(
        title: 'Servis Çok Yakın!',
        body: 'Şoför Evinize 50 Metreden Daha Yakın.',
      );
    } else if (!_hasNotified500 && distance < 500) {
      setState(() => _hasNotified500 = true);
      NotificationService.showNotification(
        title: 'Servis Yaklaşıyor!',
        body: 'Şoför Evinize 500 Metreden Daha Yakın.',
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
        return 'Son Görülme: ${diff.inMinutes} Dk Önce';
      } else {
        return 'Son Görülme: ${diff.inHours} Saat Önce';
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
    if (_lastUpdateTime == null) return 'Güncelleme Bekleniyor...';
    final now = DateTime.now();
    final diff = now.difference(_lastUpdateTime!);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} Saniye Önce Güncellendi';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} Dakika Önce Güncellendi';
    } else {
      return '${diff.inHours} Saat Önce Güncellendi';
    }
  }

  double _getProgressPercentage() {
    if (_driverLocation == null) return 0.0;
    final distance = LocationService.calculateDistance(
      widget.homeLat, widget.homeLng,
      _driverLocation!.lat, _driverLocation!.lng,
    );
    // 2000m mesafeyi %100 kabul edelim
    final maxDistance = 2000.0;
    final percentage = 1.0 - (distance / maxDistance);
    return percentage.clamp(0.0, 1.0);
  }

  Color _getProgressColor() {
    final percentage = _getProgressPercentage();
    if (percentage < 0.5) return Colors.red;
    return Colors.green;
  }

  String _getDistanceText() {
    if (_driverLocation == null) return 'Mesafe Hesaplanıyor...';
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
    setState(() {
      _hasNotified500 = false;
      _hasNotified50 = false;
      _hasNotifiedArrived = false;
    });
    // Konumu yenile
    _loadDriverLocation();
  }

  Future<void> _loadDriverLocation() async {
    try {
      final locationData = await FirestoreService.listenDriverLocation(widget.driverId).first;
      if (locationData != null && mounted) {
        setState(() {
          _driverLocation = LocationModel(
            lat: locationData['lat'] ?? 0,
            lng: locationData['lng'] ?? 0,
            isActive: locationData['isActive'] ?? true,
          );
          _lastUpdateTime = DateTime.now();
        });
        _checkDistanceAndNotify();
      }
    } catch (e) {
      // Error refreshing location
    }
  }

  void _callDriver() async {
    if (_driver?.phone.isNotEmpty == true) {
      final url = 'tel:${_driver!.phone}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_driver!.phone} Aranamadı')),
          );
        }
      }
    }
  }

  void _emergencyCall() async {
    if (_driver?.phone.isNotEmpty == true) {
      final url = 'tel:${_driver!.phone}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acil Arama Yapılamadı')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
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
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _driverLocation != null && _driverLocation!.isActive
                      ? LatLng(_driverLocation!.lat, _driverLocation!.lng)
                      : const LatLng(37.1674, 38.7955), // Şanlıurfa
                    initialZoom: 14,
                    minZoom: 10,
                    maxZoom: 20,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.servisnoktam.veli',
                    ),
                    if (_driverLocation != null && _driverLocation!.isActive)
                      PolylineLayer(
                        polylines: [
                          // Okul → Şoför → Ev çizgisi
                          if (_driver?.schoolLocation != null)
                            Polyline(
                              points: [
                                LatLng(_driver!.schoolLocation!['latitude']!, _driver!.schoolLocation!['longitude']!),
                                LatLng(_driverLocation!.lat, _driverLocation!.lng),
                                LatLng(widget.homeLat, widget.homeLng),
                              ],
                              strokeWidth: 4.0,
                              color: Colors.blue,
                            ),
                          // Şoför → Ev çizgisi (okul konumu yoksa)
                          if (_driver?.schoolLocation == null)
                            Polyline(
                              points: [
                                LatLng(_driverLocation!.lat, _driverLocation!.lng),
                                LatLng(widget.homeLat, widget.homeLng),
                              ],
                              strokeWidth: 4.0,
                              color: Colors.blue,
                            ),
                        ],
                      ),
                    // Okul ve Ev marker - HER ZAMAN göster (şoför aktif olmasa bile)
                    MarkerLayer(
                      markers: [
                        if (_driver?.schoolLocation != null)
                          Marker(
                            point: LatLng(_driver!.schoolLocation!['latitude']!, _driver!.schoolLocation!['longitude']!),
                            width: 80,
                            height: 80,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5722),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF5722).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_driver?.school.isNotEmpty == true)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5722),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: Text(
                                      _driver!.school.length > 12 ? '${_driver!.school.substring(0, 12)}...' : _driver!.school,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                              ],
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
                    // Şoför marker - sadece aktifken
                    if (_driverLocation != null && _driverLocation!.isActive)
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
                        ],
                      ),
                  ],
                ),
                // Zoom butonları
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'zoom_in',
                        mini: true,
                        onPressed: () {
                          _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                        },
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'zoom_out',
                        mini: true,
                        onPressed: () {
                          _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                        },
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
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
                // Okul-Mesafe-Ev Bar
                if (_driver?.school.isNotEmpty == true)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _driver!.school,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              _getDistanceText(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              'Ev',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: AppColors.primary, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _getProgressPercentage(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getProgressColor(),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          if (_driver?.school.isNotEmpty == true)
                            Text(
                              _driver!.school,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Mesafe
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
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
                    // Normal arama butonu
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
                    const SizedBox(width: 16),
                    // Acil durum butonu
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emergency, size: 20),
                          onPressed: _emergencyCall,
                          tooltip: 'Acil Arama',
                          color: AppColors.danger,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Text(
                          'Acil',
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
