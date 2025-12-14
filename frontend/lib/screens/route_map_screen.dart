import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_route_model.dart';
import '../models/bus_stop.dart'; // Add this import

class RouteMapScreen extends StatefulWidget {
  final BusRouteModel route;

  const RouteMapScreen({Key? key, required this.route}) : super(key: key);

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  static const Color primaryColor = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _createMarkersAndPolylines();
  }

  void _createMarkersAndPolylines() {
    // Create markers for each stop
    for (int i = 0; i < widget.route.stops.length; i++) {
      final stop = widget.route.stops[i];
      _markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: stop.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            30, // Light orange (30 degrees on hue wheel)
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${stop.name}',
            snippet: stop.keyLandmark ?? 'Bus Stop',
          ),
          onTap: () {
            // Show stop details when marker is clicked
            _showStopDetails(stop, i + 1);
          },
        ),
      );
    }

    // Create polyline connecting all stops
    final polylineCoordinates = widget.route.stops.map((stop) => stop.location).toList();
    
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_polyline'),
        points: polylineCoordinates,
        color: primaryColor,
        width: 5,
      ),
    );

    setState(() {});
  }

  void _showStopDetails(BusStop stop, int stopNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$stopNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (stop.keyLandmark != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stop.keyLandmark!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        backgroundColor: const Color(0xFFFF6B35),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Navigate',
          textColor: Colors.white,
          onPressed: () {
            // Animate to stop location
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(stop.latitude, stop.longitude),
                  zoom: 17,
                  bearing: 0,
                  tilt: 45,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  LatLngBounds _getBounds() {
    double minLat = widget.route.stops.first.latitude;
    double maxLat = widget.route.stops.first.latitude;
    double minLng = widget.route.stops.first.longitude;
    double maxLng = widget.route.stops.first.longitude;

    for (var stop in widget.route.stops) {
      if (stop.latitude < minLat) minLat = stop.latitude;
      if (stop.latitude > maxLat) maxLat = stop.latitude;
      if (stop.longitude < minLng) minLng = stop.longitude;
      if (stop.longitude > maxLng) maxLng = stop.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Route Details',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Route Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.route.routeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      widget.route.stops.first.name,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    const Icon(Icons.flag, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.route.stops.last.name,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.route.stops.length} stops',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Google Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.route.stops.first.location,
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // Fit bounds to show entire route
                Future.delayed(const Duration(milliseconds: 500), () {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(_getBounds(), 50),
                  );
                });
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),

          // Stops List
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Stops Along the Route',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.route.stops.length,
                    itemBuilder: (context, index) {
                      final stop = widget.route.stops[index];
                      final isFirst = index == 0;
                      final isLast = index == widget.route.stops.length - 1;
                      
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isFirst ? Icons.trip_origin : isLast ? Icons.place : Icons.circle,
                          size: isFirst || isLast ? 20 : 12,
                          color: isFirst ? Colors.green : isLast ? Colors.red : primaryColor,
                        ),
                        title: Text(
                          stop.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: stop.keyLandmark != null
                            ? Text(
                                stop.keyLandmark!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              )
                            : null,
                        onTap: () {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(stop.location, 15),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
