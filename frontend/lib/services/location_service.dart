import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final Location _location = Location();
  
  // Get high-accuracy location
  static Future<LatLng?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return null;
      }

      // Check permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return null;
      }

      // Get location with high accuracy settings
      final locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        return LatLng(locationData.latitude!, locationData.longitude!);
      }
      
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Stream for continuous location updates
  static Stream<LatLng> getLocationStream() {
    return _location.onLocationChanged.map((locationData) {
      return LatLng(
        locationData.latitude ?? 0.0,
        locationData.longitude ?? 0.0,
      );
    });
  }

  // Get distance between two points (in kilometers)
  static double getDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    ) / 1000; // Convert meters to kilometers
  }

  // Enable high accuracy mode - simplified version
  static Future<void> enableHighAccuracy() async {
    // The location package automatically uses high accuracy by default
  }

  // Enable background location (for live tracking)
  static Future<void> enableBackgroundMode() async {
    try {
      await _location.enableBackgroundMode(enable: true);
    } catch (e) {
      print('Error enabling background mode: $e');
    }
  }
}
