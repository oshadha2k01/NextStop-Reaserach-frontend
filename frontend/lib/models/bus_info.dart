class BusInfo {
  final String id;
  final String busNumber;
  final String routeId;
  final int totalSeats;
  final int occupiedSeats;
  final double latitude;
  final double longitude;
  final double speed;
  final String? driverName;
  final String? driverPhone;

  BusInfo({
    required this.id,
    required this.busNumber,
    required this.routeId,
    required this.totalSeats,
    required this.occupiedSeats,
    required this.latitude,
    required this.longitude,
    required this.speed,
    this.driverName,
    this.driverPhone,
  });

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      id: json['_id']?.toString() ?? '',
      busNumber: json['busNumber'] ?? '',
      routeId: json['routeId'] ?? '',
      totalSeats: json['totalSeats'] ?? 52,
      occupiedSeats: json['occupiedSeats'] ?? 0,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      speed: (json['speed'] ?? 0).toDouble(),
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
    );
  }

  bool get isCrowded => occupiedSeats > (totalSeats * 0.8);
}
