import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/bus_route_model.dart';
import '../models/bus_stop.dart';
import '../models/people_count_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'prediction_modal.dart';
import 'driver_contact_modal.dart';

// --- ADDED MISSING BUS DATA CLASS ---
class BusData {
  final String busId;
  int currentStopIndex;
  double progress;
  LatLng position;

  BusData({
    required this.busId,
    required this.currentStopIndex,
    required this.progress,
    required this.position,
  });
}

class RealTimeBusScreen extends StatefulWidget {
  const RealTimeBusScreen({super.key});

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
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  Map<String, List<BusData>> _busData = {};
  
  // LIVE BUS TRACKING VARIABLES
  LatLng? _busLocation;
  double _busSpeedMps = 0;
  String _busId = 'ESP32_WROOM_DA_01';
  BitmapDescriptor? _busIcon;
  final ApiService _apiService = ApiService();
  Timer? _sensorPollTimer;
  
  // Optional user location tracking (used for ETA query fallback and map context)
  Position? _currentDevicePosition;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    await _createBusIcon();
    _allRoutes = BusRouteModel.getAllRoutes();
    print('Loaded ${_allRoutes.length} routes'); // DEBUG
    if (_allRoutes.isNotEmpty) {
      _selectedRoute = _allRoutes[0];
      print('Selected route: ${_selectedRoute!.routeName}'); // DEBUG
      _updateMapForRoute();
      _startTrackingDeviceLocation();
      _connectBusSocket();
      _startSensorPolling();
    } else {
      print('ERROR: No routes available!'); // DEBUG
    }
    // Do not use the phone's GPS as the bus marker location.
    // The bus marker will follow the IoT device location from sensor readings.
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _sensorPollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _connectBusSocket() async {
    final socketService = SocketService();
    await socketService.connect();

    socketService.on('bus-location-update', (data) {
      if (data == null || !mounted) return;

      final busId = data['device_id'] ?? data['deviceId'] ?? data['busNumber'] ?? data['busId'] ?? _busId;
      double lat = 0.0;
      double lng = 0.0;
      double speed = 0.0;

      if (data is Map && data.containsKey('gps')) {
        final gps = data['gps'];
        if (gps is Map) {
          final latValue = gps['lat'] ?? gps['latitude'] ?? 0;
          final lngValue = gps['lng'] ?? gps['longitude'] ?? 0;
          final speedValue = gps['speed_kmh'] ?? gps['speed'] ?? 0;

          lat = latValue is num ? latValue.toDouble() : double.tryParse(latValue.toString()) ?? 0.0;
          lng = lngValue is num ? lngValue.toDouble() : double.tryParse(lngValue.toString()) ?? 0.0;
          speed = speedValue is num ? speedValue.toDouble() : double.tryParse(speedValue.toString()) ?? 0.0;
        }
      }

      if (lat == 0.0 && lng == 0.0) {
        final latValue = data['latitude'] ?? data['lat'] ?? 0;
        final lngValue = data['longitude'] ?? data['lng'] ?? 0;
        final speedValue = data['speed'] ?? data['velocity'] ?? 0;

        lat = latValue is num ? latValue.toDouble() : double.tryParse(latValue.toString()) ?? 0.0;
        lng = lngValue is num ? lngValue.toDouble() : double.tryParse(lngValue.toString()) ?? 0.0;
        speed = speedValue is num ? speedValue.toDouble() : double.tryParse(speedValue.toString()) ?? 0.0;
      }

      if (lat == 0.0 && lng == 0.0) return;

      _busId = busId.toString();
      _busSpeedMps = speed;
      _busLocation = LatLng(lat, lng);

      _updateBusMarker(_busLocation!);
    });
  }

  // Optional user location tracking helper.
  Future<void> _startTrackingDeviceLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final initialPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      _updateUserLocationMarker(initialPosition);
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (mounted) {
        _updateUserLocationMarker(position);
      }
    });
  }

  void _startSensorPolling() {
    _sensorPollTimer?.cancel();
    _sensorPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollLatestSensorLocation();
    });
    _pollLatestSensorLocation();
  }

  Future<void> _pollLatestSensorLocation() async {
    try {
      final fallbackLocation = _selectedRoute != null && _selectedRoute!.stops.isNotEmpty
          ? LatLng(_selectedRoute!.stops.first.latitude, _selectedRoute!.stops.first.longitude)
          : const LatLng(6.9271, 79.8612);

      final userLat = (_currentDevicePosition?.latitude ?? fallbackLocation.latitude).toString();
      final userLng = (_currentDevicePosition?.longitude ?? fallbackLocation.longitude).toString();

      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/eta',
        queryParams: {
          'busId': _busId,
          'userLat': userLat,
          'userLng': userLng,
        },
      );

      if (!mounted) return;
      if (!response.success || response.data == null) {
        debugPrint('Backend eta polling failed: ${response.errorMessage}');
        return;
      }

      final data = response.data!;
      final busLocation = data['bus_location'];
      if (busLocation == null) {
        debugPrint('Backend response did not include bus_location.');
        return;
      }

      final lat = _toDouble(busLocation['lat']);
      final lng = _toDouble(busLocation['lng']);
      final speed = _toDouble(data['live_status']?['speed_kmh']) ?? _busSpeedMps;

      if (lat == null || lng == null) {
        debugPrint('Invalid bus_location coordinates from backend: $busLocation');
        return;
      }

      _busLocation = LatLng(lat, lng);
      _busSpeedMps = speed / 3.6;
      _updateBusMarker(_busLocation!);

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_busLocation!));
      }
    } catch (e) {
      debugPrint('Error polling backend ETA for live location: $e');
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // Your custom bus drawing
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
    debugPrint('Bus icon created.');

    if (_busLocation != null) {
      _updateBusMarker(_busLocation!);
    } else {
      setState(() {});
    }
  }

  void _updateMapForRoute() {
    if (_selectedRoute == null) return;

    _markers.clear();
    _polylines.clear();

    // Add stop markers
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

    if (_busLocation != null) {
      _updateBusMarker(_busLocation!);
    }

    if (_mapController != null && _selectedRoute!.stops.isNotEmpty) {
      _fitMapToRoute();
    }
  }

  void _updateUserLocationMarker(Position position) {
    _currentDevicePosition = position;

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'user_location_pin');

      _markers.add(
        Marker(
          markerId: const MarkerId('user_location_pin'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
          zIndex: 1,
        ),
      );
    });
  }

  void _updateBusMarker(LatLng position) {
    _busLocation = position;
    if (_busIcon == null) return;

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'device_live_bus');
      _markers.add(
        Marker(
          markerId: const MarkerId('device_live_bus'),
          position: position,
          icon: _busIcon!,
          anchor: const Offset(0.5, 0.5),
          zIndex: 10,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DeviceBusLiveDetailsModal(
                latitude: position.latitude,
                longitude: position.longitude,
                speedInMps: _busSpeedMps,
                busId: _busId,
                allStops: _selectedRoute?.stops ?? [],
                currentLocation: 'ESP32 Bus Device',
              ),
            );
          },
        ),
      );
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin_circle, color: Colors.white, size: 28),
            onPressed: () {
              print('Person icon tapped'); // DEBUG
              print('Selected route: $_selectedRoute'); // DEBUG
              if (_selectedRoute != null) {
                print('Opening driver contact modal...'); // DEBUG
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DriverContactModal(
                    busId: 'ESP32_WROOM_DA_01',
                    currentLocation: 'Your Location',
                    allStops: _selectedRoute!.stops,
                  ),
                );
              } else {
                print('ERROR: No route selected!'); // DEBUG
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a route first'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Route Selector
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

          // Map
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
                  myLocationEnabled: true,
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

          // Legend
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
            style: const TextStyle(
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

// ======================================================================
// LIVE DEVICE-AS-BUS DETAILS MODAL (API-DRIVEN, NO TEXT BOX)
// ======================================================================
class DeviceBusLiveDetailsModal extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double speedInMps;
  final String busId;
  final List<BusStop> allStops;
  final String currentLocation;

  const DeviceBusLiveDetailsModal({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.speedInMps,
    required this.busId,
    required this.allStops,
    required this.currentLocation,
  });

  @override
  State<DeviceBusLiveDetailsModal> createState() => _DeviceBusLiveDetailsModalState();
}

class _DeviceBusLiveDetailsModalState extends State<DeviceBusLiveDetailsModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  
  bool _isLoadingEta = false;
  Map<String, dynamic>? _etaResult;
  String _errorMessage = '';
  
  // People count state
  PeopleCountModel? _peopleCountData;
  bool _isLoadingPeopleCount = true;
  Timer? _peopleCountTimer;
  static const int totalSeats = 52;

  double get speedKmh => widget.speedInMps * 3.6;
  
  @override
  void initState() {
    super.initState();
    _fetchPeopleCount();
    // Fetch people count every 3 seconds for real-time updates
    _peopleCountTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchPeopleCount();
    });
  }
  
  @override
  void dispose() {
    _peopleCountTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPeopleCount() async {
    try {
      final url = 'https://smartbusstop.me/backend/api/dl/peopleConut';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _peopleCountData = PeopleCountModel.fromJson(data);
            _isLoadingPeopleCount = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingPeopleCount = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPeopleCount = false;
        });
      }
    }
  }

  Future<void> _fetchEtaFromBackend() async {
    setState(() {
      _isLoadingEta = true;
      _errorMessage = '';
    });

    try {
      final url = '${ApiConfig.iotEta}?busId=ESP32_WROOM_DA_01&userLat=${widget.latitude}&userLng=${widget.longitude}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success') {
          setState(() {
            _etaResult = data['eta'];
            _isLoadingEta = false;
          });
        } else {
          setState(() {
            _errorMessage = "Could not fetch arrival time.";
            _isLoadingEta = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server returned an error.";
          _isLoadingEta = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error occurred. Check connection.";
        _isLoadingEta = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, 
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.directions_bus, color: primaryColor, size: 30),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bus Route 177-A", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("Current: Kaduwela Bus Stand", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DriverContactModal(
                        busId: widget.busId,
                        currentLocation: widget.currentLocation,
                        allStops: widget.allStops,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.support_agent,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Connect Driver',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.speed, color: primaryColor, size: 24),
                        const SizedBox(height: 5),
                        const Text("Speed", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text("${speedKmh.toStringAsFixed(0)} km/h", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 24),
                        const SizedBox(height: 5),
                        const Text("Location", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text("${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _isLoadingPeopleCount
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: primaryColor),
                ))
              : Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Seating Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(children: [Text("$totalSeats", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)), const Text("Total Seats", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                      Column(children: [Text("${_peopleCountData?.totalPeople ?? 0}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)), const Text("Occupied", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                      Column(children: [Text("${totalSeats - (_peopleCountData?.totalPeople ?? 0)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)), const Text("Available", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                    ]
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: (_peopleCountData?.totalPeople ?? 0) / totalSeats, 
                      minHeight: 8, 
                      backgroundColor: Colors.grey.shade200, 
                      valueColor: const AlwaysStoppedAnimation(primaryColor)
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(
                      (_peopleCountData?.totalPeople ?? 0) < totalSeats * 0.5 ? Icons.check_circle : 
                      (_peopleCountData?.totalPeople ?? 0) < totalSeats * 0.8 ? Icons.info : Icons.warning,
                      color: (_peopleCountData?.totalPeople ?? 0) < totalSeats * 0.5 ? Colors.green : 
                             (_peopleCountData?.totalPeople ?? 0) < totalSeats * 0.8 ? Colors.orange : Colors.red,
                      size: 16
                    ),
                    const SizedBox(width: 5),
                    Text(
                      (_peopleCountData?.totalPeople ?? 0) < totalSeats * 0.5 ? "Comfortable" : 
                      (_peopleCountData?.totalPeople ?? 0) < totalSeats * 0.8 ? "Moderate" : "Crowded",
                      style: TextStyle(
                        color: (_peopleCountData?.totalPeople ?? 0) < totalSeats * 0.5 ? Colors.green : 
                               (_peopleCountData?.totalPeople ?? 0) < totalSeats * 0.8 ? Colors.orange : Colors.red,
                        fontWeight: FontWeight.bold
                      )
                    )
                  ])
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text("Passenger Movement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _isLoadingPeopleCount
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: primaryColor),
                ))
              : Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.login, color: Colors.green),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${_peopleCountData?.inCount ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)), 
                            const Text("Boarded", style: TextStyle(fontSize: 12, color: Colors.green))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.orange),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${_peopleCountData?.outCount ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18)), 
                            const Text("Alighted", style: TextStyle(fontSize: 12, color: Colors.orange))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            const Text("Calculate Arrival Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            if (_isLoadingEta)
              const Center(child: CircularProgressIndicator(color: primaryColor))
            else if (_etaResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text("Predicted Arrival Time:", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text("${_etaResult!['total_minutes']} Minutes", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Traffic: ${_etaResult!['google_traffic_minutes']}m", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(width: 15),
                        Text("Stops: ${_etaResult!['ai_predicted_stop_delay_minutes']}m", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              )
            else ...[
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _fetchEtaFromBackend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text("Calculate Time to Onboarding Location", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor, side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined),
                    SizedBox(width: 10),
                    Text("View All Bus Stops on Map", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PredictionModal(
                      busId: widget.busId,
                      allStops: widget.allStops,
                      currentLocation: widget.currentLocation,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text("Predict Time to Destination", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}