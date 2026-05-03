import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/national_route_service.dart';
import '../real_time_bus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final NationalRouteService _routeService = NationalRouteService();

  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = false;
  bool _isLoadingResult = false;
  Map<String, dynamic>? _activeRoute;

  double? _parseCoord(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _searchRoute() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both locations')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _activeRoute = null;
      _polylines.clear();
      _markers.clear();
    });

    try {
      final routes = await _routeService.searchRoute(_fromController.text, _toController.text);
      
      if (routes.isNotEmpty) {
        final route = routes.first;
        
        // Show loading spinner while plotting route
        setState(() => _isLoadingResult = true);
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        _plotRouteOnMap(route);
        setState(() => _activeRoute = route);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No direct routes found. Try different stops.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Search Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingResult = false;
      });
    }
  }

  LatLng? _extractLatLng(dynamic stage) {
    if (stage is! Map) return null;

    double? lat;
    double? lng;

    final coords = stage['coordinates'];
    if (coords is Map) {
      lat = _parseCoord(coords['latitude'] ?? coords['lat']);
      lng = _parseCoord(coords['longitude'] ?? coords['lng'] ?? coords['lon']);
    } else if (coords is List && coords.length >= 2) {
      lng = _parseCoord(coords[0]);
      lat = _parseCoord(coords[1]);
    } else {
      lat = _parseCoord(stage['latitude'] ?? stage['lat']);
      lng = _parseCoord(stage['longitude'] ?? stage['lng'] ?? stage['lon']);
    }

    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  void _plotRouteOnMap(Map<String, dynamic> route) {
    final List<LatLng> points = [];
    final Set<Marker> markers = {};
    final stages = route['stages'];

    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;

    if (stages is List) {
      for (final stage in stages) {
        final latLng = _extractLatLng(stage);
        if (latLng == null) continue;
    for (var stage in stages) {
      double? lat;
      double? lng;

      final coords = stage['coordinates'];
      if (coords is Map) {
        lat = (coords['latitude'] ?? coords['lat'])?.toDouble();
        lng = (coords['longitude'] ?? coords['lng'] ?? coords['lon'])?.toDouble();
      } else {
        lat = (stage['latitude'] ?? stage['lat'])?.toDouble();
        lng = (stage['longitude'] ?? stage['lng'] ?? stage['lon'])?.toDouble();
      }
      
      if (lat != null && lng != null) {
        final latLng = LatLng(lat, lng);
        points.add(latLng);
        markers.add(Marker(
          markerId: MarkerId(stage['name'] ?? 'stop_${points.length}'),
          position: latLng,
          infoWindow: InfoWindow(title: stage['name'] ?? 'Stop'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));

        points.add(latLng);
        markers.add(
          Marker(
            markerId: MarkerId(stage is Map && stage['name'] != null ? stage['name'].toString() : 'stop_${points.length}'),
            position: latLng,
            infoWindow: InfoWindow(
              title: stage is Map && stage['name'] != null ? stage['name'].toString() : 'Stop',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );

        final lat = latLng.latitude;
        final lng = latLng.longitude;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
    }

    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId('search_route'),
        points: points,
        color: Colors.blueAccent,
        width: 5,
      ));
      _markers = markers;
    });

    if (points.isNotEmpty && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          60,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RealTimeBusScreen()),
          );
        },
        child: const Icon(Icons.directions_bus),
        tooltip: 'Open Real-Time Bus',
      ),
      body: Stack(
        children: [
          // 1. The Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(7.8731, 80.7718), zoom: 7), // Center of Sri Lanka
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // 2. Search Floating Card
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          hintText: 'From (e.g., Kaduwela)',
                          prefixIcon: const Icon(Icons.my_location, color: Colors.green),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _toController,
                        decoration: InputDecoration(
                          hintText: 'To (e.g., Kollupitiya)',
                          prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _searchRoute,
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                            : const Text('Find Route', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2b. Loading overlay while performing the search network request
          if (_isLoading)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: const CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // 3. Loading spinner while plotting route
          if (_isLoadingResult)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: const CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),

          // 4. Route Result Card at Bottom
          if (_activeRoute != null && !_isLoadingResult)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: Text(_activeRoute!['route_number'], style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(_activeRoute!['route_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Type: ${_activeRoute!['service_type']}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
}
