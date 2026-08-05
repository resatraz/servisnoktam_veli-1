import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import 'setup_driver_screen.dart';
import 'map_picker_screen.dart';

class SetupLocationScreen extends StatefulWidget {
  const SetupLocationScreen({super.key});

  @override
  State<SetupLocationScreen> createState() => _SetupLocationScreenState();
}

class _SetupLocationScreenState extends State<SetupLocationScreen> {
  double? _lat;
  double? _lng;
  bool _loading = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum Servisi Kapalı. Lütfen Açın.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konum İzni Reddedildi.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum İzni Kalıcı Olarak Reddedildi.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
        });
      }
    } catch (e) {
      debugPrint('Konum Hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum Alınamadı. Haritadan Konum Seçebilirsiniz.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAndContinue() async {
    if (_lat == null || _lng == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('homeLat', _lat!);
    await prefs.setDouble('homeLng', _lng!);
    if (!mounted) return;
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const SetupDriverScreen()));
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => MapPickerScreen(
        initialLat: _lat,
        initialLng: _lng,
      )),
    );
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Ayarı'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.primaryLight),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_on, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text('Ev Konumunuzu Belirleyin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Servis Evinize Yaklaştığında Bildirim Almak İçin',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  if (_lat != null && _lng != null)
                    Column(
                      children: [
                        const Text(
                          'Konum Seçildi ✓',
                          style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Konumu Otomatik Al'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickLocationFromMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Haritadan Konum Seç'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _lat != null && _lng != null ? _saveAndContinue : null,
                child: const Text('Devam Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
