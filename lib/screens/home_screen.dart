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
  Timer? _locationTimer;
  DateTime? _lastUpdateTime;
  final MapController _mapController = MapController();

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
    // Firestore'dan real-time konum dinleme
    FirestoreService.listenDriverLocation(widget.driverId).listen((locationData) {
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
    
    // 500m kala bildirim
    if (!_hasNotified500 && distance < 500) {
      setState(() => _hasNotified500 = true);
      NotificationService.showNotification(
        title: 'Servis Yaklaşıyor!',
        body: 'Şoför Evinize 500 Metreden Daha Yakın.',
      );
    }
    
    // 50m kala tekrar bildirim
    if (!_hasNotified50 && distance < 50) {
      setState(() => _hasNotified50 = true);
      NotificationService.showNotification(
        title: 'Servis Çok Yakın!',
        body: 'Şoför Evinize 50 Metreden Daha Yakın.',
      );
    }
    
    // Adrese varınca bildirim
    if (!_hasNotifiedArrived && distance < 10) {
      setState(() => _hasNotifiedArrived = true);
      NotificationService.showNotification(
        title: 'Öğrenci Adrese Vardı',
        body: 'Şoför Adrese Ulaştı.',
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
      print('Konum yenileme hatası: $e');
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
                _driverLocation != null && _driverLocation!.isActive
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(_driverLocation!.lat, _driverLocation!.lng),
                        initialZoom: 16,
                        minZoom: 10,
                        maxZoom: 20,
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
                          Text('Konum Bekleniyor...'),
                        ],
                      ),
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
