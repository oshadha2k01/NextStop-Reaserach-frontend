import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math';
import '../models/bus_route_model.dart';

class TicketCalculatorModal extends StatefulWidget {
  const TicketCalculatorModal({Key? key}) : super(key: key);

  @override
  State<TicketCalculatorModal> createState() => _TicketCalculatorModalState();
}

class _TicketCalculatorModalState extends State<TicketCalculatorModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  BusRouteModel? _matchedRoute;
  bool _isCalculating = false;
  bool _showResult = false;
  Map<String, dynamic>? _ticketResult;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _searchRoute() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    if (from.isEmpty || to.isEmpty) return;

    final routes = BusRouteModel.searchRoutes(from, to);
    
    if (routes.isNotEmpty) {
      setState(() {
        _matchedRoute = routes.first;
      });
      _updateMap();
    }
  }

  void _updateMap() {
    if (_matchedRoute == null) return;

    _markers.clear();
    _polylines.clear();

    // Add from location marker
    if (_matchedRoute!.stops.isNotEmpty) {
      _markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: LatLng(
            _matchedRoute!.stops.first.latitude,
            _matchedRoute!.stops.first.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'From: ${_matchedRoute!.stops.first.name}'),
        ),
      );

      // Add to location marker
      _markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: LatLng(
            _matchedRoute!.stops.last.latitude,
            _matchedRoute!.stops.last.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'To: ${_matchedRoute!.stops.last.name}'),
        ),
      );

      // Add route polyline
      final routePoints = _matchedRoute!.stops
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
    }

    setState(() {});

    if (_mapController != null) {
      _fitMapToRoute();
    }
  }

  void _fitMapToRoute() {
    if (_matchedRoute == null || _matchedRoute!.stops.isEmpty) return;

    double minLat = _matchedRoute!.stops.first.latitude;
    double maxLat = _matchedRoute!.stops.first.latitude;
    double minLng = _matchedRoute!.stops.first.longitude;
    double maxLng = _matchedRoute!.stops.first.longitude;

    for (var stop in _matchedRoute!.stops) {
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

  double _calculateDistance() {
    if (_matchedRoute == null || _matchedRoute!.stops.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < _matchedRoute!.stops.length - 1; i++) {
      final stop1 = _matchedRoute!.stops[i];
      final stop2 = _matchedRoute!.stops[i + 1];
      
      // Haversine formula for distance calculation
      const double earthRadius = 6371; // km
      final lat1 = stop1.latitude * pi / 180;
      final lat2 = stop2.latitude * pi / 180;
      final dLat = (stop2.latitude - stop1.latitude) * pi / 180;
      final dLon = (stop2.longitude - stop1.longitude) * pi / 180;

      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      
      totalDistance += earthRadius * c;
    }

    return totalDistance;
  }

  Future<void> _calculateTicket() async {
    if (_matchedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid route first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _showResult = false;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Calculate distance
    final distance = _calculateDistance();

    // Fare calculation: Rs. 30 base (2km) + Rs. 10 per additional km
    double fare;
    if (distance <= 2) {
      fare = 30;
    } else {
      fare = 30 + ((distance - 2) * 10);
    }

    // Alternative transport methods
    final trainFare = fare * 0.7; // 30% cheaper
    final taxiFare = fare * 5; // 5x more expensive

    setState(() {
      _isCalculating = false;
      _showResult = true;
      _ticketResult = {
        'distance': distance,
        'busFare': fare,
        'trainFare': trainFare,
        'taxiFare': taxiFare,
        'from': _matchedRoute!.stops.first.name,
        'to': _matchedRoute!.stops.last.name,
        'route': _matchedRoute!.routeName,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.confirmation_number,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ticket Calculator',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Calculate your fare instantly',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // From Location
                  const Text(
                    'Boarding Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _fromController,
                      onChanged: (value) => _searchRoute(),
                      decoration: InputDecoration(
                        hintText: 'e.g., Kaduwela, Malabe',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.location_on, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // To Location
                  const Text(
                    'Destination',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _toController,
                      onChanged: (value) => _searchRoute(),
                      decoration: InputDecoration(
                        hintText: 'e.g., Kollupitiya, Pettah',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.flag, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Route Info
                  if (_matchedRoute != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.route, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _matchedRoute!.routeName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Map Display
                  if (_matchedRoute != null) ...[
                    const Text(
                      'Journey Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _matchedRoute!.stops.first.latitude,
                              _matchedRoute!.stops.first.longitude,
                            ),
                            zoom: 12,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          onMapCreated: (controller) {
                            _mapController = controller;
                            _fitMapToRoute();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Calculate Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isCalculating ? null : _calculateTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: primaryColor.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isCalculating
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Calculating Fare...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calculate, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Check Ticket Price',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Results
                  if (_showResult && _ticketResult != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Fare Calculation',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Journey Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.straighten, color: primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Distance',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_ticketResult!['distance'].toStringAsFixed(2)} km',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    const Icon(Icons.payments, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Bus Fare',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Rs. ${_ticketResult!['busFare'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Alternative Transport
                          const Text(
                            'Alternative Transport Options',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildTransportCard(
                                  Icons.train,
                                  'Train',
                                  _ticketResult!['trainFare'],
                                  Colors.blue,
                                  'Recommended',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTransportCard(
                                  Icons.local_taxi,
                                  'Taxi',
                                  _ticketResult!['taxiFare'],
                                  Colors.orange,
                                  'Expensive',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Journey Summary
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: textSecondary),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Journey Summary',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'From: ${_ticketResult!['from']}',
                                  style: const TextStyle(fontSize: 12, color: textSecondary),
                                ),
                                Text(
                                  'To: ${_ticketResult!['to']}',
                                  style: const TextStyle(fontSize: 12, color: textSecondary),
                                ),
                                Text(
                                  'Route: ${_ticketResult!['route']}',
                                  style: const TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(IconData icon, String name, double fare, Color color, String tag) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${fare.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
