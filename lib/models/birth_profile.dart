class BirthProfile {
  final String id;
  final String name;
  final DateTime birthDateTime;
  final int cityId;
  final String cityName;
  final String countryCode;
  final double latitude;
  final double longitude;

  BirthProfile({
    String? id,
    required this.name,
    required this.birthDateTime,
    required this.cityId,
    required this.cityName,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  BirthProfile copyWith({
    String? name,
    DateTime? birthDateTime,
    int? cityId,
    String? cityName,
    String? countryCode,
    double? latitude,
    double? longitude,
  }) => BirthProfile(
    id: id,
    name: name ?? this.name,
    birthDateTime: birthDateTime ?? this.birthDateTime,
    cityId: cityId ?? this.cityId,
    cityName: cityName ?? this.cityName,
    countryCode: countryCode ?? this.countryCode,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthDateTime': birthDateTime.toIso8601String(),
    'cityId': cityId,
    'cityName': cityName,
    'countryCode': countryCode,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory BirthProfile.fromJson(Map<String, dynamic> j) => BirthProfile(
    id: j['id'] as String?,
    name: j['name'] as String,
    birthDateTime: DateTime.parse(j['birthDateTime'] as String),
    cityId: j['cityId'] as int,
    cityName: j['cityName'] as String,
    countryCode: j['countryCode'] as String,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
  );
}
