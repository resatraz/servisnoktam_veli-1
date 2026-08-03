import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_draggable_marker/flutter_map_draggable_marker.dart';
import '../core/theme.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _selectedLocation = LatLng(41.0082, 28.9784); // İstanbul varsayılan
    }
  }

  void _onTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.primaryLight),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedLocation!,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.servisnoktam.veli',
                ),
                DraggableMarker(
                  width: 40,
                  height: 40,
                  marker: Marker(
                    point: _selectedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  onDragEnd: (position) {
                    setState(() {
                      _selectedLocation = position;
                    });
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_selectedLocation != null)
                  Text(
                    'Seçilen Konum: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedLocation != null
                        ? () => Navigator.pop(context, _selectedLocation)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Konumu Kaydet'),
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
