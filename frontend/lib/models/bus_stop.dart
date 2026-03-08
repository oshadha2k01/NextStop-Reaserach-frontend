import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusStop {
  final String name;
  final double latitude;
  final double longitude;
  final String? keyLandmark;

  BusStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.keyLandmark,
  });

  LatLng get location => LatLng(latitude, longitude);
}
