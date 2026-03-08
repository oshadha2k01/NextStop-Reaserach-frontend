import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/bus_route_model.dart';
import 'bus_details_modal.dart';

class RealTimeBusScreen extends StatefulWidget {
  const RealTimeBusScreen({Key? key}) : super(key: key);

  @override
  State<RealTimeBusScreen> createState() => _RealTimeBusScreenState();
}

class _RealTimeBusScreenState extends State<RealTimeBusScreen> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  GoogleMapController? _mapController;
  BusRouteModel? _selectedRoute;
  List<BusRouteModel> _allRoutes = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Hardcoded IoT bus data - 2 buses per route
  Map<String, List<BusData>> _busData = {};
  Timer? _animationTimer;
  BitmapDescriptor? _busIcon;

  @override
  void initState() {
    super.initState();
    _createBusIcon();
    _allRoutes = BusRouteModel.getAllRoutes();
    if (_allRoutes.isNotEmpty) {
      _selectedRoute = _allRoutes[0];
      _initializeBusData();
      _updateMapForRoute();
      _startBusAnimation();
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _createBusIcon() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = primaryColor;
    
    const double size = 100;
    
    // Draw bus icon
    final path = Path();
    
    // Bus body
    path.addRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 20, 80, 60),
      const Radius.circular(8),
    ));
    
    canvas.drawPath(path, paint);
    
    // Windows
    final windowPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 28, 25, 20),
        const Radius.circular(4),
      ),
      windowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(55, 28, 25, 20),
        const Radius.circular(4),
      ),
      windowPaint,
    );
    
    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF2C3E50);
    canvas.drawCircle(const Offset(30, 80), 8, wheelPaint);
    canvas.drawCircle(const Offset(70, 80), 8, wheelPaint);
    
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();
    
    _busIcon = BitmapDescriptor.fromBytes(uint8List);
    setState(() {});
  }

  void _initializeBusData() {
    _busData.clear();
    
    for (var route in _allRoutes) {
      if (route.stops.length >= 2) {
        _busData[route.routeName] = [
          // Bus 1 - starts at first stop
          BusData(
            busId: '${route.routeName.split(':')[0].trim()}-A',
            currentStopIndex: 0,
            progress: 0.0,
            position: LatLng(route.stops[0].latitude, route.stops[0].longitude),
          ),
          // Bus 2 - starts at middle stop
          BusData(
            busId: '${route.routeName.split(':')[0].trim()}-B',
            currentStopIndex: route.stops.length ~/ 2,
            progress: 0.0,
            position: LatLng(
              route.stops[route.stops.length ~/ 2].latitude,
              route.stops[route.stops.length ~/ 2].longitude,
            ),
          ),
        ];
      }
    }
  }

  void _startBusAnimation() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_selectedRoute == null) return;
      
      setState(() {
        final buses = _busData[_selectedRoute!.routeName];
        if (buses == null) return;

        for (var bus in buses) {
          // Move bus along route - slower speed
          bus.progress += 0.008;

          if (bus.progress >= 1.0) {
            // Move to next stop
            bus.progress = 0.0;
            bus.currentStopIndex++;
            
            if (bus.currentStopIndex >= _selectedRoute!.stops.length - 1) {
              // Reached end, restart from beginning
              bus.currentStopIndex = 0;
            }
          }

          // Calculate interpolated position with exact coordinates
          final currentStop = _selectedRoute!.stops[bus.currentStopIndex];
          final nextStop = _selectedRoute!.stops[bus.currentStopIndex + 1];
          
          // Use precise calculation for accurate positioning
          final lat = currentStop.latitude + 
                     (nextStop.latitude - currentStop.latitude) * bus.progress;
          final lng = currentStop.longitude + 
                     (nextStop.longitude - currentStop.longitude) * bus.progress;
          
          bus.position = LatLng(lat, lng);
        }
        
        _updateBusMarkers();
      });
    });
  }

  void _updateMapForRoute() {
    if (_selectedRoute == null) return;

    _markers.clear();
    _polylines.clear();

    // Add stop markers with better visibility
    for (int i = 0; i < _selectedRoute!.stops.length; i++) {
      final stop = _selectedRoute!.stops[i];
      _markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : 
            i == _selectedRoute!.stops.length - 1 ? BitmapDescriptor.hueRed : 
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: stop.keyLandmark ?? 'Bus Stop',
          ),
          alpha: 0.9,
        ),
      );
    }

    // Add route polyline with better visibility
    final routePoints = _selectedRoute!.stops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();
    
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: primaryColor,
        width: 6,
        patterns: [PatternItem.dash(30), PatternItem.gap(15)],
      ),
    );

    _updateBusMarkers();

    // Move camera to show entire route
    if (_mapController != null && _selectedRoute!.stops.isNotEmpty) {
      _fitMapToRoute();
    }
  }

  void _updateBusMarkers() {
    if (_selectedRoute == null || _busIcon == null) return;

    // Remove old bus markers
    _markers.removeWhere((marker) => marker.markerId.value.contains('bus_'));

    // Add current bus markers with custom bus icon
    final buses = _busData[_selectedRoute!.routeName];
    if (buses != null) {
      for (int i = 0; i < buses.length; i++) {
        final bus = buses[i];
        _markers.add(
          Marker(
            markerId: MarkerId('bus_${bus.busId}'),
            position: bus.position,
            icon: _busIcon!,
            infoWindow: InfoWindow(
              title: '🚌 Bus ${bus.busId}',
              snippet: 'Next: ${_selectedRoute!.stops[bus.currentStopIndex + 1].name}',
            ),
            anchor: const Offset(0.5, 0.5),
            flat: true,
            zIndex: 10,
            onTap: () {
              _showBusDetails(bus);
            },
          ),
        );
      }
    }
  }

  void _showBusDetails(BusData bus) {
    // Get remaining stops from current position
    final remainingStops = _selectedRoute!.stops.sublist(bus.currentStopIndex + 1);
    final currentStop = _selectedRoute!.stops[bus.currentStopIndex];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BusDetailsModal(
        busId: bus.busId,
        currentLocation: currentStop.name,
        remainingStops: remainingStops,
        currentStopIndex: bus.currentStopIndex,
      ),
    );
  }

  void _fitMapToRoute() {
    if (_selectedRoute == null || _selectedRoute!.stops.isEmpty) return;

    double minLat = _selectedRoute!.stops[0].latitude;
    double maxLat = _selectedRoute!.stops[0].latitude;
    double minLng = _selectedRoute!.stops[0].longitude;
    double maxLng = _selectedRoute!.stops[0].longitude;

    for (var stop in _selectedRoute!.stops) {
      if (stop.latitude < minLat) minLat = stop.latitude;
      if (stop.latitude > maxLat) maxLat = stop.latitude;
      if (stop.longitude < minLng) minLng = stop.longitude;
      if (stop.longitude > maxLng) maxLng = stop.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Real-Time Bus Tracking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Route Selector with updated styling
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.route,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Route',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BusRouteModel>(
                      value: _selectedRoute,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: primaryColor, size: 28),
                      style: const TextStyle(
                        fontSize: 15,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _allRoutes.map((route) {
                        return DropdownMenuItem(
                          value: route,
                          child: Text(route.routeName),
                        );
                      }).toList(),
                      onChanged: (BusRouteModel? newRoute) {
                        if (newRoute != null) {
                          setState(() {
                            _selectedRoute = newRoute;
                            _updateMapForRoute();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map with enhanced readability
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedRoute != null && _selectedRoute!.stops.isNotEmpty
                        ? LatLng(_selectedRoute!.stops[0].latitude, _selectedRoute!.stops[0].longitude)
                        : const LatLng(6.9271, 79.8612),
                    zoom: 13,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  trafficEnabled: false,
                  buildingsEnabled: true,
                  indoorViewEnabled: false,
                  minMaxZoomPreference: const MinMaxZoomPreference(10, 18),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _fitMapToRoute();
                  },
                ),
              ),
            ),
          ),

          // Legend with updated styling
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Icons.location_on, 'Start', Colors.green),
                _buildLegendItem(Icons.location_on, 'Stop', Colors.blue),
                _buildLegendItem(Icons.location_on, 'End', Colors.red),
                _buildLegendItem(Icons.directions_bus, 'Bus', primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Bus data model for IoT simulation
class BusData {
  final String busId;
  int currentStopIndex;
  double progress; // 0.0 to 1.0 between stops
  LatLng position;

  BusData({
    required this.busId,
    required this.currentStopIndex,
    required this.progress,
    required this.position,
  });
}
