import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/bus_stop.dart';

class RouteStopsMapScreen extends StatefulWidget {
  final String busId;
  final List<BusStop> allStops;
  final String currentLocation;

  const RouteStopsMapScreen({
    Key? key,
    required this.busId,
    required this.allStops,
    required this.currentLocation,
  }) : super(key: key);

  @override
  State<RouteStopsMapScreen> createState() => _RouteStopsMapScreenState();
}

class _RouteStopsMapScreenState extends State<RouteStopsMapScreen> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color darkOrange = Color(0xFFCC5529);
  static const Color textPrimary = Color(0xFF1F2937);
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _busStopIcon;

  @override
  void initState() {
    super.initState();
    _createBusStopIcon();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _createBusStopIcon() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    const double size = 120;
    
    // Draw bus stop sign with orange color
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    // Post/pole
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(55, 40, 10, 60),
        const Radius.circular(2),
      ),
      paint,
    );
    
    // Sign board
    final signPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 20, 80, 35),
        const Radius.circular(6),
      ),
      signPaint,
    );
    
    // White border for sign
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 20, 80, 35),
        const Radius.circular(6),
      ),
      borderPaint,
    );
    
    // Bus icon on sign (white)
    final busIconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(48, 28, 24, 18),
        const Radius.circular(3),
      ),
      busIconPaint,
    );
    
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();
    
    _busStopIcon = BitmapDescriptor.fromBytes(uint8List);
    
    _setupMap();
  }

  void _setupMap() {
    if (_busStopIcon == null) return;
    
    _markers.clear();
    _polylines.clear();

    // Add markers for all bus stops
    for (int i = 0; i < widget.allStops.length; i++) {
      final stop = widget.allStops[i];
      _markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: _busStopIcon!,
          infoWindow: InfoWindow(
            title: '🚏 ${stop.name}',
            snippet: stop.keyLandmark ?? 'Bus Stop',
          ),
          anchor: const Offset(0.5, 0.9),
        ),
      );
    }

    // Add route polyline
    final routePoints = widget.allStops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();
    
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: darkOrange,
        width: 6,
        patterns: [PatternItem.dash(30), PatternItem.gap(15)],
      ),
    );

    setState(() {});
    
    if (_mapController != null) {
      _fitMapToStops();
    }
  }

  void _fitMapToStops() {
    if (widget.allStops.isEmpty) return;

    double minLat = widget.allStops[0].latitude;
    double maxLat = widget.allStops[0].latitude;
    double minLng = widget.allStops[0].longitude;
    double maxLng = widget.allStops[0].longitude;

    for (var stop in widget.allStops) {
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

  void _createMarkers() {
    _markers.clear();
    
    for (int i = 0; i < widget.allStops.length; i++) {
      final stop = widget.allStops[i];
      
      _markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Light orange
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: stop.keyLandmark ?? 'Bus Stop ${i + 1}',
          ),
          onTap: () {
            // Show location name when marker is clicked
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (stop.keyLandmark != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        stop.keyLandmark!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                backgroundColor: const Color(0xFFFFB399), // Light orange background
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            
            // Animate camera to clicked location
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(stop.latitude, stop.longitude),
                  zoom: 16,
                  bearing: 0,
                  tilt: 45,
                ),
              ),
            );
          },
        ),
      );
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bus ${widget.busId}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'All Bus Stops',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route Overview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Currently at: ${widget.currentLocation}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.allStops.length} Stops',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.allStops.isNotEmpty
                    ? LatLng(widget.allStops[0].latitude, widget.allStops[0].longitude)
                    : const LatLng(6.9271, 79.8612),
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              trafficEnabled: false,
              buildingsEnabled: true,
              minMaxZoomPreference: const MinMaxZoomPreference(10, 18),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _fitMapToStops();
              },
            ),
          ),

          // Legend
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Bus Stop',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: darkOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 3,
                        decoration: BoxDecoration(
                          color: darkOrange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Route',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
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
