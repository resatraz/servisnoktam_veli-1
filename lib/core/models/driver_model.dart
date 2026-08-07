class DriverModel {
  final String id;
  final String name;
  final String plate;
  final String school;
  final String photoUrl;
  final String phone;
  final bool isActive;
  final Map<String, double>? schoolLocation;

  DriverModel({
    required this.id,
    required this.name,
    required this.plate,
    required this.school,
    required this.photoUrl,
    required this.phone,
    required this.isActive,
    this.schoolLocation,
  });

  factory DriverModel.fromMap(String id, Map<String, dynamic> map) {
    return DriverModel(
      id: id,
      name: map['name'] ?? '',
      plate: map['plate'] ?? '',
      school: map['school'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      phone: map['phone'] ?? '',
      isActive: map['isActive'] ?? false,
      schoolLocation: map['schoolLocation'] != null
          ? {
              'latitude': map['schoolLocation']['latitude']?.toDouble() ?? 0.0,
              'longitude': map['schoolLocation']['longitude']?.toDouble() ?? 0.0,
            }
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'plate': plate,
    'school': school,
    'photoUrl': photoUrl,
    'isActive': isActive,
    'schoolLocation': schoolLocation,
  };
}

class LocationModel {
  final double lat;
  final double lng;
  final bool isActive;

  LocationModel({required this.lat, required this.lng, required this.isActive});

  factory LocationModel.fromMap(Map<dynamic, dynamic> map) {
    return LocationModel(
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? false,
    );
  }
}
