class DriverModel {
  final String id;
  final String name;
  final String plate;
  final String school;
  final String photoUrl;
  final bool isActive;

  DriverModel({
    required this.id,
    required this.name,
    required this.plate,
    required this.school,
    required this.photoUrl,
    required this.isActive,
  });

  factory DriverModel.fromMap(String id, Map<String, dynamic> map) {
    return DriverModel(
      id: id,
      name: map['name'] ?? '',
      plate: map['plate'] ?? '',
      school: map['school'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      isActive: map['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'plate': plate,
    'school': school,
    'photoUrl': photoUrl,
    'isActive': isActive,
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
