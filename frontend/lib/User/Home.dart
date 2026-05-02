import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_route_model.dart';
import '../screens/routes/route_map_screen.dart';
import '../screens/live/real_time_bus.dart';
import '../screens/modals/crowd_prediction_modal.dart';
import '../screens/modals/ticket_calculator_modal.dart';
import '../screens/routes/all_routes_screen.dart';
import '../screens/modals/feedback_modal.dart';
import '../screens/live/live_tracking_screen.dart';
import '../services/location_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/theme/app_colors.dart';
import '../services/national_route_service.dart';
import '../models/bus_stop.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const LatLng _colomboLocation = LatLng(6.9271, 79.8612);
  
  // --- Live Tracking Variables ---
  final Completer<GoogleMapController> _mapController = Completer();
  io.Socket? socket;
  LatLng? liveBusLocation;
  Map<String, dynamic>? busData;

  @override
  void initState() {
    super.initState();
    initSocketConnection();
    _getCurrentLocation();
    _loadUserName();
    _enableHighAccuracyLocation();
  }

  void initSocketConnection() {
    // ⚠️ CRITICAL: Replace with your laptop's IPv4 address!
    // If using a physical phone: Use your Wi-Fi IP (e.g., 'http://192.168.8.118:5000')
    // If using Android Studio Emulator: Use 'http://10.0.2.2:5000'
    String serverUrl = 'http://192.168.8.118:5000'; 

    socket = io.io(serverUrl, io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket!.connect();

    socket!.onConnect((_) {
      debugPrint('Connected to Node.js live tracking server');
    });

    // Listen for the ESP32 data coming from Node.js
    socket!.on('bus_location_update', (data) {
      debugPrint('Live bus update received: $data');
      
      if (mounted) {
        setState(() {
          liveBusLocation = LatLng(data['lat'], data['lng']);
          busData = data;
        });
        
        // Move the map camera to follow the bus automatically!
        _moveCameraToBus(liveBusLocation!);
      }
    });

    socket!.onDisconnect((_) {
      debugPrint('Disconnected from live tracking server');
    });
  }

  Future<void> _moveCameraToBus(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  void dispose() {
    socket?.disconnect();
    _searchController.dispose();
    _mapControllerBase?.dispose();
    super.dispose();
  }

  // Keep aliases for readability in this large file.
  static const Color primaryColor = AppColors.primary;
  static const Color backgroundColor = AppColors.background;
  static const Color cardColor = AppColors.surface;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;

  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapControllerBase;
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  final Set<Marker> _markers = {};

  String _userName = 'User';
  
  Future<void> _enableHighAccuracyLocation() async {
    await LocationService.enableHighAccuracy();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name.split(' ')[0]; // Get first name only
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      final location = await LocationService.getCurrentLocation();
      
      if (location != null) {
        setState(() {
          _currentPosition = location;
          _isLoadingLocation = false;
          
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: _currentPosition!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );
        });

        _mapControllerBase?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition!,
              zoom: 15,
            ),
          ),
        );

        // Start listening to location updates
        LocationService.getLocationStream().listen((newLocation) {
          if (mounted) {
            setState(() {
              _currentPosition = newLocation;
              _updateLocationMarker(newLocation);
            });
          }
        });
      } else {
        setState(() => _isLoadingLocation = false);
        _showLocationServiceDialog();
      }
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _updateLocationMarker(LatLng newLocation) {
    _markers.removeWhere((m) => m.markerId.value == 'current_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: newLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Function to get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  void _onSearch() {
    // Show the route search modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RouteSearchModal(),
    );
  }

  void _onFilterTap() {
    // Handle filter action
    // TODO: Show filter options
    debugPrint('Filter tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // ---------------- SECTION 1: HEADER ----------------
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDeep],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // NextStop Slogan
                  const Text(
                    "NextStop",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // Greeting Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Hi $_userName", 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getGreeting(), 
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ---------------- SECTION 2: SEARCH BAR ----------------
                    GestureDetector(
                      onTap: _onSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        height: 56,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: primaryColor, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              "Where to go?",
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: _onFilterTap,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.tune, 
                                  color: primaryColor, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---------------- SECTION 3: HORIZONTAL SCROLLING MENU ----------------
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildMenuSquare(Icons.directions_bus, "Bus"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.navigation, "Live"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.auto_graph, "Predict"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.schedule, "Schedule"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.confirmation_number, "Tickets"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.map, "Route"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.feedback_outlined, "Feedback"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---------------- SECTION 4: THE GOOGLE MAP ----------------
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey.shade300,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _currentPosition ?? _colomboLocation,
                                  zoom: 12,
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                zoomControlsEnabled: false,
                                markers: _markers,
                                onMapCreated: (GoogleMapController controller) {
                                  _mapControllerBase = controller;
                                  if (_currentPosition != null) {
                                    controller.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: _currentPosition!,
                                          zoom: 15,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              if (_isLoadingLocation)
                                Container(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ---------------- SECTION 5: BOTTOM BAR ----------------
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBottomIcon(Icons.home_rounded, true),
                          _buildBottomIcon(Icons.explore_outlined, false),
                          _buildBottomIcon(Icons.confirmation_number_outlined, false),
                          _buildBottomIcon(Icons.person_outline, false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the menu squares
  Widget _buildMenuSquare(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (label == "Bus") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RealTimeBusScreen(),
            ),
          );
        } else if (label == "Live") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LiveTrackingScreen(),
            ),
          );
        } else if (label == "Predict") {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CrowdPredictionModal(),
          );
        } else if (label == "Tickets") {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const TicketCalculatorModal(),
          );
        } else if (label == "Route") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AllRoutesScreen(),
            ),
          );
        } else if (label == "Feedback") {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const FeedbackModal(),
          );
        }
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, 
              style: const TextStyle(
                fontSize: 12, 
                color: textPrimary,
                fontWeight: FontWeight.w600,
              )),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the bottom navigation icons
  Widget _buildBottomIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon, 
        color: isActive ? Colors.white : textSecondary,
        size: 26,
      ),
    );
  }
}

// New Route Search Modal Widget
class RouteSearchModal extends StatefulWidget {
  const RouteSearchModal({super.key});

  @override
  State<RouteSearchModal> createState() => _RouteSearchModalState();
}

class _RouteSearchModalState extends State<RouteSearchModal> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  static const Color primaryColor = AppColors.primary;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  bool _fromHasError = false;
  bool _toHasError = false;
  String _fromErrorMessage = '';
  String _toErrorMessage = '';
  bool _isLoading = false;
  final NationalRouteService _routeService = NationalRouteService();

  double _parseCoord(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _fromHasError = false;
      _toHasError = false;
      _fromErrorMessage = '';
      _toErrorMessage = '';
    });
  }

  Future<void> _searchRoute() async {
    _clearErrors();
    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    // Validation: Check if fields are empty
    if (from.isEmpty || to.isEmpty) {
      setState(() {
        if (from.isEmpty) {
          _fromHasError = true;
          _fromErrorMessage = 'Starting location is required';
        }
        if (to.isEmpty) {
          _toHasError = true;
          _toErrorMessage = 'Destination is required';
        }
      });
      return;
    }

    if (from.toLowerCase() == to.toLowerCase()) {
      setState(() {
        _fromHasError = true;
        _toHasError = true;
        _fromErrorMessage = 'Cannot be the same';
        _toErrorMessage = 'Cannot be the same';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Search for routes using the Backend Service
      final routesData = await _routeService.searchRoute(from, to);
      
      if (!mounted) return;

      if (routesData.isNotEmpty) {
        final routeJson = routesData.first;
        final stages = (routeJson['stages'] as List<dynamic>?) ?? [];
        
        if (stages.isEmpty) {
          setState(() {
            _fromHasError = true;
            _toHasError = true;
            _fromErrorMessage = 'No path found';
            _toErrorMessage = 'No path found';
            _isLoading = false;
          });
          return;
        }

        // Map Backend JSON to BusRouteModel
        final List<BusStop> busStops = stages.map((s) {
          final coords = s['coordinates'] ?? {};
          return BusStop(
            name: s['name'] ?? 'Stop',
            latitude: _parseCoord(coords['latitude'] ?? coords['lat']),
            longitude: _parseCoord(coords['longitude'] ?? coords['lng'] ?? coords['lon']),
          );
        }).toList();

        final BusRouteModel routeModel = BusRouteModel(
          id: routeJson['_id']?.toString(),
          routeName: routeJson['route_name'] ?? routeJson['name'] ?? 'Custom Route',
          routeNumber: routeJson['route_number']?.toString(),
          stops: busStops,
        );

        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteMapScreen(route: routeModel),
          ),
        );
      } else {
        // No routes found in backend
        setState(() {
          _fromHasError = true;
          _toHasError = true;
          _fromErrorMessage = 'Location not found';
          _toErrorMessage = 'Location not found';
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No bus routes found for these locations in the database.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          
          const Spacer(),
          
          // Title
          const Text(
            "Find a route",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Let's make a journey",
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // From field with error state
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _fromHasError ? Colors.red : Colors.grey.shade300,
                      width: _fromHasError ? 2.5 : 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _fromController,
                    onChanged: (value) {
                      if (_fromHasError) {
                        _clearErrors();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'From (e.g., Kaduwela, Malabe)',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: _fromHasError ? Colors.red : primaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (_fromHasError && _fromErrorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      _fromErrorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // To field with error state
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _toHasError ? Colors.red : Colors.grey.shade300,
                      width: _toHasError ? 2.5 : 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _toController,
                    onChanged: (value) {
                      if (_toHasError) {
                        _clearErrors();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'To (e.g., Kollupitiya, Pettah)',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.flag_outlined,
                        color: _toHasError ? Colors.red : primaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (_toHasError && _toErrorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      _toErrorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Search button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 2,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}