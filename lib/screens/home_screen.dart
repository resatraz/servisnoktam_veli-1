import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  StreamSubscription<DatabaseEvent>? _locationSub;

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
    _locationSub = FirebaseDatabase.instance
      .ref('locations/${widget.driverId}')
      .onValue
      .listen((event) {
        if (event.snapshot.value == null) return;
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _driverLocation = LocationModel.fromMap(map);
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
    _locationSub?.cancel();
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
          // Map
          Expanded(
            child: _driverLocation != null && _driverLocation!.isActive
              ? FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(_driverLocation!.lat, _driverLocation!.lng),
                    initialZoom: 15,
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
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                        Marker(
                          point: LatLng(widget.homeLat, widget.homeLng),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.home,
                            color: AppColors.success,
                            size: 40,
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.background,
                  backgroundImage: _driver?.photoUrl.isNotEmpty == true
                    ? CachedNetworkImageProvider(_driver!.photoUrl)
                    : null,
                  child: _driver?.photoUrl.isEmpty == true
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
