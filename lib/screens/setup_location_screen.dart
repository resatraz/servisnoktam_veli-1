import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      debugPrint('Konum hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum alınamadı. Haritadan konum seçebilirsiniz.'),
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
                  Text('Servis evinize yaklaştığında bildirim almak için',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  if (_lat != null && _lng != null)
                    Column(
                      children: [
                        Text('Enlem: ${_lat!.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 11,
                            color: AppColors.textSecondary)),
                        Text('Boylam: ${_lng!.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 11,
                            color: AppColors.textSecondary)),
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
                  const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _lat != null && _lng != null ? _saveAndContinue : null,
                child: const Text('Devam et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
