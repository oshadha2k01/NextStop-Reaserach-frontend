import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_route_model.dart';

class AllRoutesScreen extends StatefulWidget {
  const AllRoutesScreen({Key? key}) : super(key: key);

  @override
  State<AllRoutesScreen> createState() => _AllRoutesScreenState();
}

class _AllRoutesScreenState extends State<AllRoutesScreen> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  String? _selectedProvince;
  BusRouteModel? _selectedRoute;
  List<BusRouteModel> _filteredRoutes = [];
  List<BusRouteModel> _allRoutes = [];

  // Province definitions based on major cities in routes
  final Map<String, List<String>> _provinces = {
    'Western Province': ['Colombo', 'Kaduwela', 'Kollupitiya', 'Pettah', 'Malabe', 'Battaramulla', 
                         'Rajagiriya', 'Borella', 'Nugegoda', 'Pannipitiya', 'Maharagama', 
                         'Meegoda', 'Homagama', 'Panadura', 'Dehiwala'],
    'Central Province': ['Kandy', 'Nittambuwa'],
  };

  @override
  void initState() {
    super.initState();
    _allRoutes = BusRouteModel.getAllRoutes();
    _filteredRoutes = _allRoutes;
    _showAllRoutes();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _showAllRoutes() {
    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};
    
    // Add markers for all routes with different colors
    int colorIndex = 0;
    final colors = [
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueBlue,
      BitmapDescriptor.hueGreen,
    ];

    for (var route in _filteredRoutes) {
      final hue = colors[colorIndex % colors.length];
      
      for (var stop in route.stops) {
        markers.add(
          Marker(
            markerId: MarkerId('${route.routeName}_${stop.name}'),
            position: LatLng(stop.latitude, stop.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: stop.name,
              snippet: route.routeName,
            ),
          ),
        );
      }
      
      // Add polyline for route
      final points = route.stops.map((stop) => 
        LatLng(stop.latitude, stop.longitude)
      ).toList();
      
      polylines.add(
        Polyline(
          polylineId: PolylineId(route.routeName),
          points: points,
          color: _getColorFromHue(hue),
          width: 3,
        ),
      );
      
      colorIndex++;
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Adjust camera to show all markers
    if (_filteredRoutes.isNotEmpty && _mapController != null) {
      _fitMapToRoutes();
    }
  }

  void _showSelectedRoute() {
    if (_selectedRoute == null) return;

    final Set<Marker> markers = {};
    final List<LatLng> points = [];

    for (int i = 0; i < _selectedRoute!.stops.length; i++) {
      final stop = _selectedRoute!.stops[i];
      points.add(LatLng(stop.latitude, stop.longitude));
      
      markers.add(
        Marker(
          markerId: MarkerId(stop.name),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(30), // Light orange hue (30 degrees)
          infoWindow: InfoWindow(
            title: '${i + 1}. ${stop.name}',
            snippet: stop.keyLandmark ?? 'Stop on ${_selectedRoute!.routeName}',
          ),
          onTap: () {
            // Show location details when clicked
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${stop.name}',
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
                backgroundColor: const Color(0xFFFFB399),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      );
    }

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: PolylineId(_selectedRoute!.routeName),
        points: points,
        color: primaryColor,
        width: 5,
      ),
    };

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    _fitMapToRoutes();
  }

  void _fitMapToRoutes() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );
  }

  Color _getColorFromHue(double hue) {
    if (hue == BitmapDescriptor.hueOrange) return primaryColor;
    if (hue == BitmapDescriptor.hueRed) return Colors.red;
    if (hue == BitmapDescriptor.hueBlue) return Colors.blue;
    if (hue == BitmapDescriptor.hueGreen) return Colors.green;
    return primaryColor;
  }

  void _onProvinceChanged(String? province) {
    setState(() {
      _selectedProvince = province;
      _selectedRoute = null;
      
      if (province == null) {
        _filteredRoutes = _allRoutes;
      } else {
        final provinceCities = _provinces[province] ?? [];
        _filteredRoutes = _allRoutes.where((route) {
          return route.stops.any((stop) => 
            provinceCities.any((city) => 
              stop.name.toLowerCase().contains(city.toLowerCase())
            )
          );
        }).toList();
      }
    });
    
    _showAllRoutes();
  }

  void _onRouteChanged(BusRouteModel? route) {
    setState(() {
      _selectedRoute = route;
    });
    
    if (route != null) {
      _showSelectedRoute();
    } else {
      _showAllRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Routes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Routes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Province Dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedProvince,
                      hint: const Text('Select Province'),
                      icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Provinces'),
                        ),
                        ..._provinces.keys.map((province) {
                          return DropdownMenuItem<String>(
                            value: province,
                            child: Text(province),
                          );
                        }).toList(),
                      ],
                      onChanged: _onProvinceChanged,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Route Dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BusRouteModel>(
                      isExpanded: true,
                      value: _selectedRoute,
                      hint: Text('Select Route (${_filteredRoutes.length} available)'),
                      icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                      items: [
                        const DropdownMenuItem<BusRouteModel>(
                          value: null,
                          child: Text('Show All Routes'),
                        ),
                        ..._filteredRoutes.map((route) {
                          return DropdownMenuItem<BusRouteModel>(
                            value: route,
                            child: Text(
                              route.routeName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: _onRouteChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Route Info Card (only shown when route is selected)
          if (_selectedRoute != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedRoute!.routeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_selectedRoute!.stops.length} stops',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.route, color: primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_selectedRoute!.stops.first.name} → ${_selectedRoute!.stops.last.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(6.9271, 79.8612), // Colombo
                    zoom: 11,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _fitMapToRoutes();
                  },
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
