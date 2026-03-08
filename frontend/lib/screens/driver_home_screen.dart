import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  String _busNumber = 'NA-1234';
  String _routeName = 'Route 177: Kaduwela - Kollupitiya';
  String _driverName = 'K.M. Silva';
  double _busSpeed = 42.0;
  LatLng _busLocation = const LatLng(6.9442, 79.9866);
  
  int _unreadNotifications = 0;
  final List<Map<String, dynamic>> _notifications = [];
  
  final List<Map<String, dynamic>> _routeStops = [
    {
      'name': 'Kaduwela Bus Stand',
      'location': const LatLng(6.9442, 79.9866),
      'passengersWaiting': 5,
      'distance': 0.0,
      'isPassed': true,
    },
    {
      'name': 'Malabe Junction',
      'location': const LatLng(6.9045, 79.9548),
      'passengersWaiting': 3,
      'distance': 2.1,
      'isPassed': false,
    },
    {
      'name': 'Battaramulla',
      'location': const LatLng(6.8998, 79.9134),
      'passengersWaiting': 8,
      'distance': 4.5,
      'isPassed': false,
    },
    {
      'name': 'Rajagiriya',
      'location': const LatLng(6.9092, 79.8964),
      'passengersWaiting': 2,
      'distance': 6.2,
      'isPassed': false,
    },
    {
      'name': 'Borella',
      'location': const LatLng(6.9142, 79.8778),
      'passengersWaiting': 0,
      'distance': 8.1,
      'isPassed': false,
    },
    {
      'name': 'Kollupitiya',
      'location': const LatLng(6.9114, 79.8488),
      'passengersWaiting': 4,
      'distance': 10.5,
      'isPassed': false,
    },
  ];

  int _currentStopIndex = 1;
  Timer? _movementTimer;
  Timer? _notificationTimer;
  BitmapDescriptor? _busIcon;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    _createBusIcon();
    _updateMarkersAndPolylines();
    _startBusMovement();
    _startNotificationSimulation();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _notificationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startNotificationSimulation() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_currentStopIndex < _routeStops.length) {
        final random = Random();
        final stopIndex = _currentStopIndex + random.nextInt(min(3, _routeStops.length - _currentStopIndex));
        
        if (stopIndex < _routeStops.length) {
          final stop = _routeStops[stopIndex];
          _addNotification(
            'New Passenger Request',
            'Passenger waiting at ${stop['name']}',
            stop['location'] as LatLng,
          );
        }
      }
    });
  }

  void _addNotification(String title, String message, LatLng location) {
    setState(() {
      _unreadNotifications++;
      _notifications.insert(0, {
        'title': title,
        'message': message,
        'location': location,
        'time': DateTime.now(),
        'isRead': false,
      });
    });
  }

  void _showNotifications() {
    setState(() {
      _unreadNotifications = 0;
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Passenger Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final time = notification['time'] as DateTime;
                        final now = DateTime.now();
                        final difference = now.difference(time);
                        
                        String timeAgo;
                        if (difference.inMinutes < 1) {
                          timeAgo = 'Just now';
                        } else if (difference.inMinutes < 60) {
                          timeAgo = '${difference.inMinutes}m ago';
                        } else {
                          timeAgo = '${difference.inHours}h ago';
                        }
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: notification['isRead'] ? Colors.white : primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: notification['isRead'] ? Colors.grey.shade200 : primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.person_pin_circle, color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['message'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.my_location, size: 20),
                                color: primaryColor,
                                onPressed: () {
                                  Navigator.pop(context);
                                  _mapController?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: notification['location'] as LatLng,
                                        zoom: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBusIcon() async {
    _busIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/bus_icon.png',
    ).catchError((_) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    });
    setState(() {});
  }

  Future<void> _loadDriverInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _busNumber = prefs.getString('driver_bus_number') ?? 'NA-1234';
      _routeName = prefs.getString('driver_route') ?? 'Route 177';
      _driverName = prefs.getString('driver_name') ?? 'K.M. Silva';
    });
  }

  void _startBusMovement() {
    _movementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _simulateBusMovement();
    });
  }

  void _simulateBusMovement() {
    if (_currentStopIndex >= _routeStops.length) {
      _movementTimer?.cancel();
      return;
    }

    final random = Random();
    _busSpeed = 35 + random.nextDouble() * 25;

    final targetStop = _routeStops[_currentStopIndex]['location'] as LatLng;
    final currentLat = _busLocation.latitude;
    final currentLng = _busLocation.longitude;
    
    final latDiff = targetStop.latitude - currentLat;
    final lngDiff = targetStop.longitude - currentLng;
    
    final newLat = currentLat + (latDiff * 0.1);
    final newLng = currentLng + (lngDiff * 0.1);
    
    setState(() {
      _busLocation = LatLng(newLat, newLng);
      
      for (int i = _currentStopIndex; i < _routeStops.length; i++) {
        final stopLocation = _routeStops[i]['location'] as LatLng;
        _routeStops[i]['distance'] = _calculateDistance(_busLocation, stopLocation);
      }
      
      if (_routeStops[_currentStopIndex]['distance'] < 0.1) {
        _routeStops[_currentStopIndex]['isPassed'] = true;
        _currentStopIndex++;
      }
    });

    _updateMarkersAndPolylines();
    _animateCamera();
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371;
    final dLat = (end.latitude - start.latitude) * pi / 180;
    final dLon = (end.longitude - start.longitude) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * pi / 180) * cos(end.latitude * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _updateMarkersAndPolylines() {
    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    markers.add(
      Marker(
        markerId: const MarkerId('bus'),
        position: _busLocation,
        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 0.5),
        rotation: _calculateBearing(),
        infoWindow: InfoWindow(
          title: '🚌 Bus $_busNumber',
          snippet: '${_busSpeed.toStringAsFixed(0)} km/h',
        ),
      ),
    );

    List<LatLng> routePath = [_busLocation];
    for (int i = _currentStopIndex; i < _routeStops.length; i++) {
      routePath.add(_routeStops[i]['location'] as LatLng);
    }

    polylines.add(
      Polyline(
        polylineId: const PolylineId('route_path'),
        points: routePath,
        color: primaryColor, // Changed from Color(0xFF4285F4) to primaryColor (orange)
        width: 6,
      ),
    );

    if (_currentStopIndex > 0) {
      List<LatLng> passedPath = [];
      for (int i = 0; i < _currentStopIndex; i++) {
        passedPath.add(_routeStops[i]['location'] as LatLng);
      }
      passedPath.add(_busLocation);

      polylines.add(
        Polyline(
          polylineId: const PolylineId('passed_route'),
          points: passedPath,
          color: Colors.grey,
          width: 5,
        ),
      );
    }

    for (int i = 0; i < _routeStops.length; i++) {
      final stop = _routeStops[i];
      final passengersWaiting = stop['passengersWaiting'] as int;
      final isPassed = stop['isPassed'] as bool;
      
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: stop['location'] as LatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isPassed ? BitmapDescriptor.hueViolet :
            passengersWaiting > 0 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueYellow,
          ),
          infoWindow: InfoWindow(
            title: '${stop['name']}',
            snippet: passengersWaiting > 0 
                ? '👥 $passengersWaiting passengers waiting'
                : '✓ No passengers',
          ),
        ),
      );

      if (passengersWaiting > 0 && !isPassed) {
        _addPassengerAvatars(markers, stop['location'] as LatLng, passengersWaiting, i);
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  void _addPassengerAvatars(Set<Marker> markers, LatLng stopLocation, int count, int stopIndex) {
    const double radius = 0.0005;
    
    for (int i = 0; i < min(count, 8); i++) {
      final angle = (2 * pi * i) / min(count, 8);
      final latOffset = radius * cos(angle);
      final lngOffset = radius * sin(angle);
      
      markers.add(
        Marker(
          markerId: MarkerId('passenger_${stopIndex}_$i'),
          position: LatLng(
            stopLocation.latitude + latOffset,
            stopLocation.longitude + lngOffset,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: '👤 Passenger ${i + 1}',
            snippet: 'Waiting at stop',
          ),
        ),
      );
    }
  }

  void _animateCamera() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _busLocation,
          zoom: 15,
          bearing: _calculateBearing(),
          tilt: 45,
        ),
      ),
    );
  }

  double _calculateBearing() {
    if (_currentStopIndex >= _routeStops.length) return 0;
    
    final target = _routeStops[_currentStopIndex]['location'] as LatLng;
    final lat1 = _busLocation.latitude * pi / 180;
    final lat2 = target.latitude * pi / 180;
    final dLon = (target.longitude - _busLocation.longitude) * pi / 180;
    
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;
    
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final nextStop = _currentStopIndex < _routeStops.length ? _routeStops[_currentStopIndex] : null;
    final distance = nextStop?['distance'] as double? ?? 0;
    final passengersWaiting = nextStop?['passengersWaiting'] as int? ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _busLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Top navigation card (Google Maps style)
          if (nextStop != null)
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
                                '${distance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                nextStop['name'],
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
                        const Icon(Icons.people, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$passengersWaiting waiting',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.speed, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_busSpeed.toStringAsFixed(0)} km/h',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Notification button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Stack(
              children: [
                Container(
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
                    icon: const Icon(Icons.notifications),
                    onPressed: _showNotifications,
                  ),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Back button (top left)
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

          // Bottom info card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem('Bus', _busNumber, Icons.directions_bus),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildInfoItem('Route', _routeName.split(':')[0], Icons.route),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildInfoItem('Stop', '${_currentStopIndex + 1}/${_routeStops.length}', Icons.pin_drop),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
