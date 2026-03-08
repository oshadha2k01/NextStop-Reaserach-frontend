import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bus_route_model.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  final TextEditingController _destinationController = TextEditingController();
  
  LatLng? _userLocation;
  LatLng _busLocation = const LatLng(6.9442, 79.9866);
  LatLng? _destinationLocation;
  
  bool _isTripStarted = false;
  bool _isLoadingLocation = true;
  bool _showDestinationSearch = false;
  
  double _distanceToDestination = 0.0;
  double _busSpeed = 45.0;
  int _estimatedTime = 0;
  String _nextTurn = '';
  String _nextTurnDistance = '';
  
  // Demo bus details
  final String _busId = "NA-1234";
  final String _busName = "Route 177 Express";
  final String _driverName = "K.M. Silva";
  final String _driverLicense = "DL-567890";
  
  // Use actual route data
  late List<LatLng> _routePoints;
  late BusRouteModel _currentRoute;
  int _currentRouteIndex = 0;
  Timer? _busMovementTimer;
  Timer? _metricsUpdateTimer;
  BitmapDescriptor? _busIcon;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
    _createBusIcon();
    _initializeTracking();
  }

  void _loadRouteData() {
    // Load Route 177 from bus route model
    final allRoutes = BusRouteModel.getAllRoutes();
    _currentRoute = allRoutes.firstWhere(
      (route) => route.routeName.contains('177'),
      orElse: () => allRoutes.first,
    );
    
    // Extract LatLng points from route stops
    _routePoints = _currentRoute.stops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();
    
    // Start bus at first stop
    _busLocation = _routePoints.first;
  }

  Future<void> _createBusIcon() async {
    _busIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/bus_icon.png',
    ).catchError((_) {
      // Fallback to default marker
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    });
    setState(() {});
  }

  @override
  void dispose() {
    _busMovementTimer?.cancel();
    _metricsUpdateTimer?.cancel();
    _mapController?.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    await _getUserLocation();
    _updateBusMarker();
    _updateUserMarker();
    _drawRoutePolyline();
    setState(() => _isLoadingLocation = false);
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
            _updateUserMarker();
          });
        }
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _updateUserMarker() {
    if (_userLocation == null) return;
    
    _markers.removeWhere((m) => m.markerId.value == 'user_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: '📍 Your Location'),
      ),
    );
    setState(() {});
  }

  void _updateBusMarker() {
    _markers.removeWhere((m) => m.markerId.value == 'bus_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('bus_location'),
        position: _busLocation,
        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 0.5),
        rotation: _calculateBearing(),
        infoWindow: InfoWindow(
          title: '🚌 Bus $_busId',
          snippet: '$_busName',
        ),
      ),
    );
    setState(() {});
  }

  void _drawRoutePolyline() {
    _polylines.clear();
    
    if (_routePoints.isEmpty) return;
    
    // Draw full route in light gray
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('full_route'),
        points: _routePoints,
        color: Colors.grey.shade400,
        width: 4,
        patterns: [PatternItem.dash(15), PatternItem.gap(10)],
      ),
    );
    
    setState(() {});
  }

  void _searchDestination(String query) {
    if (query.isEmpty) return;
    
    // Search in route stops
    for (var stop in _currentRoute.stops) {
      if (stop.name.toLowerCase().contains(query.toLowerCase())) {
        setState(() {
          _destinationLocation = LatLng(stop.latitude, stop.longitude);
          _destinationController.text = stop.name;
          _showDestinationSearch = false;
        });
        _updateDestinationMarker();
        _calculateDistance();
        break;
      }
    }
  }

  void _updateDestinationMarker() {
    if (_destinationLocation == null) return;
    
    _markers.removeWhere((m) => m.markerId.value == 'destination');
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '🏁 Destination'),
      ),
    );
    
    _drawActiveRoute();
    setState(() {});
  }

  void _drawActiveRoute() {
    if (_destinationLocation == null) return;
    
    _polylines.removeWhere((p) => p.polylineId.value == 'active_route');
    _polylines.removeWhere((p) => p.polylineId.value == 'passed_route');
    
    int destinationIndex = _findNearestPointIndex(_destinationLocation!);
    
    if (_currentRouteIndex > 0) {
      List<LatLng> passedPath = [
        ..._routePoints.sublist(0, _currentRouteIndex),
        _busLocation,
      ];
      
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('passed_route'),
          points: passedPath,
          color: Colors.grey,
          width: 5,
        ),
      );
    }
    
    List<LatLng> activePath = [
      _busLocation,
      ..._routePoints.sublist(_currentRouteIndex + 1, destinationIndex + 1),
    ];
    
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('active_route'),
        points: activePath,
        color: primaryColor, // Changed from Color(0xFF4285F4) to primaryColor (orange)
        width: 6,
      ),
    );
    
    setState(() {});
  }

  int _findNearestPointIndex(LatLng point) {
    double minDistance = double.infinity;
    int nearestIndex = _routePoints.length - 1;
    
    for (int i = _currentRouteIndex; i < _routePoints.length; i++) {
      double distance = _calculateDistanceBetween(point, _routePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }
    
    return nearestIndex;
  }

  double _calculateBearing() {
    if (_currentRouteIndex >= _routePoints.length - 1) return 0;
    
    final current = _routePoints[_currentRouteIndex];
    final next = _routePoints[_currentRouteIndex + 1];
    
    final lat1 = current.latitude * pi / 180;
    final lat2 = next.latitude * pi / 180;
    final dLon = (next.longitude - current.longitude) * pi / 180;
    
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;
    
    return (bearing + 360) % 360;
  }

  void _startTrip() {
    if (_destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a destination'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTripStarted = true;
      _currentRouteIndex = 0;
      _updateNavigationInstructions();
    });

    _busMovementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentRouteIndex < _routePoints.length - 1) {
        _animateBusMovement();
      } else {
        _endTrip();
      }
    });

    _metricsUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateTripMetrics();
    });
  }

  void _updateNavigationInstructions() {
    if (_currentRouteIndex < _currentRoute.stops.length - 1) {
      final nextStop = _currentRoute.stops[_currentRouteIndex + 1];
      setState(() {
        _nextTurn = 'toward ${nextStop.name}';
        final distance = _routePoints[_currentRouteIndex + 1];
        final dist = _calculateDistanceBetween(_busLocation, distance);
        _nextTurnDistance = dist < 1 
            ? '${(dist * 1000).toStringAsFixed(0)} m'
            : '${dist.toStringAsFixed(1)} km';
      });
    }
  }

  void _animateBusMovement() {
    final current = _routePoints[_currentRouteIndex];
    final next = _routePoints[_currentRouteIndex + 1];
    
    // Smooth interpolation
    final newLat = current.latitude + (next.latitude - current.latitude) * 0.15;
    final newLng = current.longitude + (next.longitude - current.longitude) * 0.15;
    
    setState(() {
      _busLocation = LatLng(newLat, newLng);
      _updateBusMarker();
      _calculateDistance();
      _drawActiveRoute();
      _updateNavigationInstructions();
      
      // Check if reached next point
      final distance = _calculateDistanceBetween(_busLocation, next);
      if (distance < 0.02) {
        _currentRouteIndex++;
      }
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _busLocation,
          zoom: 16,
          bearing: _calculateBearing(),
          tilt: 45,
        ),
      ),
    );
  }

  void _calculateDistance() {
    if (_destinationLocation == null) return;
    
    _distanceToDestination = _calculateDistanceBetween(_busLocation, _destinationLocation!);
    _estimatedTime = ((_distanceToDestination / _busSpeed) * 60).round();
  }

  double _calculateDistanceBetween(LatLng start, LatLng end) {
    const earthRadius = 6371;
    
    final dLat = (end.latitude - start.latitude) * pi / 180;
    final dLon = (end.longitude - start.longitude) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * pi / 180) * cos(end.latitude * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _updateTripMetrics() {
    final random = Random();
    setState(() {
      _busSpeed = 35 + random.nextDouble() * 20;
    });
  }

  void _endTrip() {
    _busMovementTimer?.cancel();
    _metricsUpdateTimer?.cancel();
    
    setState(() {
      _isTripStarted = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trip Completed'),
        content: const Text('🎉 You have reached your destination!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDriverComplaint() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverComplaintModal(
        busId: _busId,
        busName: _busName,
        driverName: _driverName,
        driverLicense: _driverLicense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? _busLocation,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            compassEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Top navigation instruction (Google Maps style)
          if (_isTripStarted)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F9D58), Color(0xFF0C7C46)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_upward, size: 24, color: Color(0xFF0F9D58)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nextTurnDistance,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _nextTurn,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_estimatedTime min',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.straighten, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_distanceToDestination.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateTime.now().add(Duration(minutes: _estimatedTime)).toString().substring(11, 16),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Destination search bar (when not started)
          if (!_isTripStarted)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        hintText: 'Search destination',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF4285F4)),
                        suffixIcon: _destinationController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _destinationController.clear();
                                    _destinationLocation = null;
                                  });
                                },
                              )
                            : const Icon(Icons.mic, color: Color(0xFF4285F4)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _showDestinationSearch = value.isNotEmpty;
                        });
                      },
                      onSubmitted: _searchDestination,
                    ),
                    if (_showDestinationSearch && _destinationController.text.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _currentRoute.stops.length,
                          itemBuilder: (context, index) {
                            final stop = _currentRoute.stops[index];
                            if (stop.name.toLowerCase().contains(_destinationController.text.toLowerCase())) {
                              return ListTile(
                                leading: const Icon(Icons.location_on, color: Color(0xFF4285F4)),
                                title: Text(stop.name),
                                subtitle: Text(stop.keyLandmark ?? ''),
                                onTap: () {
                                  _searchDestination(stop.name);
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Bottom action button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _isTripStarted
                ? Row(
                    children: [
                      // Re-center button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.my_location, color: Colors.white),
                          onPressed: () {
                            _mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: _busLocation,
                                  zoom: 16,
                                  bearing: _calculateBearing(),
                                  tilt: 45,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // End trip button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _endTrip,
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text(
                            'End Trip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Report button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.report_problem, color: Colors.white),
                          onPressed: _showDriverComplaint,
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _destinationLocation != null ? _startTrip : null,
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: const Text(
                        'Start Navigation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
          ),

          // Close button (top left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoadingLocation)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Driver Complaint Modal Widget
class DriverComplaintModal extends StatefulWidget {
  final String busId;
  final String busName;
  final String driverName;
  final String driverLicense;

  const DriverComplaintModal({
    Key? key,
    required this.busId,
    required this.busName,
    required this.driverName,
    required this.driverLicense,
  }) : super(key: key);

  @override
  State<DriverComplaintModal> createState() => _DriverComplaintModalState();
}

class _DriverComplaintModalState extends State<DriverComplaintModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  final TextEditingController _detailsController = TextEditingController();
  
  String? _selectedComplaintType;
  bool _isSubmitting = false;
  
  final List<Map<String, dynamic>> _complaintTypes = [
    {'title': 'Reckless Driving', 'icon': Icons.car_crash, 'color': Colors.red},
    {'title': 'Overspeeding', 'icon': Icons.speed, 'color': Colors.orange},
    {'title': 'No Seatbelt', 'icon': Icons.airline_seat_recline_normal, 'color': Colors.amber},
    {'title': 'Rude Behavior', 'icon': Icons.person_off, 'color': Colors.purple},
    {'title': 'Using Phone', 'icon': Icons.phone_android, 'color': Colors.blue},
    {'title': 'Smoking', 'icon': Icons.smoke_free, 'color': Colors.brown},
    {'title': 'Skipping Stops', 'icon': Icons.not_listed_location, 'color': Colors.indigo},
    {'title': 'Poor Hygiene', 'icon': Icons.clean_hands, 'color': Colors.teal},
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (_selectedComplaintType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a complaint type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide details about the complaint'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      
      // Show success dialog with escalation info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Complaint Submitted',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your complaint has been registered successfully.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complaint ID: #${123456}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ Escalation Process:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildEscalationStep('1', 'Driver receives warning'),
                    _buildEscalationStep('2', 'Supervisor notified'),
                    _buildEscalationStep('3', 'If repeated: Transport Authority alerted'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEscalationStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.report_problem, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Driver',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Help us ensure passenger safety',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Auto-fetched bus and driver details
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_bus, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.busName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Bus ID: ${widget.busId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driver: ${widget.driverName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'License: ${widget.driverLicense}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Complaint Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Complaint type grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _complaintTypes.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaintTypes[index];
                      final isSelected = _selectedComplaintType == complaint['title'];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedComplaintType = complaint['title'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (complaint['color'] as Color).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? complaint['color'] as Color
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                complaint['icon'] as IconData,
                                color: complaint['color'] as Color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  complaint['title'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? complaint['color'] as Color : textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Provide Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _detailsController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened in detail...\n\nYour complaint will be reviewed and appropriate action will be taken.',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Complaint',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
