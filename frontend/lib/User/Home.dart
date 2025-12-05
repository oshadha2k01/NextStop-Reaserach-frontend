import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bus_route_model.dart';
import '../screens/route_map_screen.dart';
import '../screens/real_time_bus.dart';
import '../screens/crowd_prediction_modal.dart';
import '../screens/ticket_calculator_modal.dart';

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

  // Orange and white color palette matching onboarding
  static const Color primaryColor = Color(0xFFFF6B35); // Orange
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showLocationServiceDialog();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showPermissionDeniedForeverDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        
        // Add marker for current location
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text('Please grant location permission to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('Please enable location permission in your device settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
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
    print('Filter tapped');
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
                color: primaryColor,
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
                      const Text("Hi User", 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          color: Colors.white,
                        )),
                      Text(_getGreeting(), 
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        )),
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
                              color: Colors.black.withOpacity(0.05),
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
                                  color: primaryColor.withOpacity(0.1),
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
                          _buildMenuSquare(Icons.auto_graph, "Predict"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.schedule, "Schedule"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.confirmation_number, "Tickets"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.map, "Route"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.feedback_outlined, "Feedback"),
                          const SizedBox(width: 15),
                          _buildMenuSquare(Icons.report_problem_outlined, "Driver Complains"),
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
                              color: Colors.black.withOpacity(0.1),
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
                                  _mapController = controller;
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
                                  color: Colors.white.withOpacity(0.7),
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
                            color: Colors.black.withOpacity(0.08),
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
        }
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
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
                color: primaryColor.withOpacity(0.1),
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
  const RouteSearchModal({Key? key}) : super(key: key);

  @override
  State<RouteSearchModal> createState() => _RouteSearchModalState();
}

class _RouteSearchModalState extends State<RouteSearchModal> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // Validation state
  bool _fromHasError = false;
  bool _toHasError = false;
  String _fromErrorMessage = '';
  String _toErrorMessage = '';

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

  void _searchRoute() {
    _clearErrors();

    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    // Validation 1: Check if fields are empty
    if (from.isEmpty && to.isEmpty) {
      setState(() {
        _fromHasError = true;
        _toHasError = true;
        _fromErrorMessage = 'Starting location is required';
        _toErrorMessage = 'Destination is required';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both starting point and destination'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (from.isEmpty) {
      setState(() {
        _fromHasError = true;
        _fromErrorMessage = 'Please enter starting location';
      });
      return;
    }

    if (to.isEmpty) {
      setState(() {
        _toHasError = true;
        _toErrorMessage = 'Please enter destination';
      });
      return;
    }

    // Validation 2: Check if same location
    if (from.toLowerCase() == to.toLowerCase()) {
      setState(() {
        _fromHasError = true;
        _toHasError = true;
        _fromErrorMessage = 'Cannot be the same';
        _toErrorMessage = 'Cannot be the same';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting point and destination cannot be the same'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validation 3: Check minimum length
    if (from.length < 3) {
      setState(() {
        _fromHasError = true;
        _fromErrorMessage = 'Enter at least 3 characters';
      });
      return;
    }

    if (to.length < 3) {
      setState(() {
        _toHasError = true;
        _toErrorMessage = 'Enter at least 3 characters';
      });
      return;
    }
    
    // Search for routes
    final routes = BusRouteModel.searchRoutes(from, to);
    
    // Validation 4: Check if route exists
    if (routes.isEmpty) {
      // Check if locations exist in any route
      final allRoutes = BusRouteModel.getAllRoutes();
      bool fromExists = false;
      bool toExists = false;

      for (var route in allRoutes) {
        for (var stop in route.stops) {
          if (stop.name.toLowerCase().contains(from.toLowerCase())) {
            fromExists = true;
          }
          if (stop.name.toLowerCase().contains(to.toLowerCase())) {
            toExists = true;
          }
        }
      }

      // Specific error messages based on what's wrong
      if (!fromExists && !toExists) {
        setState(() {
          _fromHasError = true;
          _toHasError = true;
          _fromErrorMessage = 'Location not found';
          _toErrorMessage = 'Location not found';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Both "$from" and "$to" are not available in our routes'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (!fromExists) {
        setState(() {
          _fromHasError = true;
          _fromErrorMessage = 'Location not found';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$from" is not available in our routes.\nCheck spelling or try nearby locations'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (!toExists) {
        setState(() {
          _toHasError = true;
          _toErrorMessage = 'Location not found';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$to" is not available in our routes.\nCheck spelling or try nearby locations'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Both locations exist but no connecting route
        setState(() {
          _fromHasError = true;
          _toHasError = true;
          _fromErrorMessage = 'No direct route';
          _toErrorMessage = 'No direct route';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No direct bus route found from "$from" to "$to".\nTry reversing the direction or check alternative routes'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    
    // Success - Navigate to route map screen
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteMapScreen(route: routes.first),
      ),
    );
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
                onPressed: _searchRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 2,
                ),
                child: const Text(
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