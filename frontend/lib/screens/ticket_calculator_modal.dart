import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../models/bus_stop.dart';
import '../models/bus_route_model.dart';
import '../services/prediction_service.dart';

class TicketCalculatorModal extends StatefulWidget {
  const TicketCalculatorModal({super.key});

  @override
  State<TicketCalculatorModal> createState() => _TicketCalculatorModalState();
}

class _TicketCalculatorModalState extends State<TicketCalculatorModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  late final List<BusStop> _allStops;
  BusStop? _selectedBoardingStop;
  BusStop? _selectedDestinationStop;

  bool _isCalculating = false;
  bool _showResult = false;
  Map<String, dynamic>? _ticketResult;

  // 100% Match with the new 20-stop Backend JSON
  final Map<String, double> _fareMatrix = {
    "0_to_1": 30.0, "0_to_2": 39.0, "0_to_3": 39.0, "0_to_4": 50.0, "0_to_5": 50.0, "0_to_6": 62.0, "0_to_7": 62.0, "0_to_8": 74.0, "0_to_9": 85.0, "0_to_10": 85.0, "0_to_11": 97.0, "0_to_12": 97.0, "0_to_13": 101.0, "0_to_14": 101.0, "0_to_15": 101.0, "0_to_16": 109.0, "0_to_17": 109.0, "0_to_18": 116.0, "0_to_19": 116.0,
    "1_to_2": 30.0, "1_to_3": 30.0, "1_to_4": 39.0, "1_to_5": 39.0, "1_to_6": 50.0, "1_to_7": 50.0, "1_to_8": 62.0, "1_to_9": 74.0, "1_to_10": 74.0, "1_to_11": 85.0, "1_to_12": 85.0, "1_to_13": 97.0, "1_to_14": 97.0, "1_to_15": 97.0, "1_to_16": 101.0, "1_to_17": 101.0, "1_to_18": 109.0, "1_to_19": 109.0,
    "2_to_3": 30.0, "2_to_4": 30.0, "2_to_5": 30.0, "2_to_6": 39.0, "2_to_7": 39.0, "2_to_8": 50.0, "2_to_9": 62.0, "2_to_10": 62.0, "2_to_11": 74.0, "2_to_12": 74.0, "2_to_13": 85.0, "2_to_14": 85.0, "2_to_15": 85.0, "2_to_16": 97.0, "2_to_17": 97.0, "2_to_18": 101.0, "2_to_19": 101.0,
    "3_to_4": 30.0, "3_to_5": 30.0, "3_to_6": 39.0, "3_to_7": 39.0, "3_to_8": 50.0, "3_to_9": 62.0, "3_to_10": 62.0, "3_to_11": 74.0, "3_to_12": 74.0, "3_to_13": 85.0, "3_to_14": 85.0, "3_to_15": 85.0, "3_to_16": 97.0, "3_to_17": 97.0, "3_to_18": 101.0, "3_to_19": 101.0,
    "4_to_5": 30.0, "4_to_6": 30.0, "4_to_7": 30.0, "4_to_8": 39.0, "4_to_9": 50.0, "4_to_10": 50.0, "4_to_11": 62.0, "4_to_12": 62.0, "4_to_13": 74.0, "4_to_14": 74.0, "4_to_15": 74.0, "4_to_16": 85.0, "4_to_17": 85.0, "4_to_18": 97.0, "4_to_19": 97.0,
    "5_to_6": 30.0, "5_to_7": 30.0, "5_to_8": 39.0, "5_to_9": 50.0, "5_to_10": 50.0, "5_to_11": 62.0, "5_to_12": 62.0, "5_to_13": 74.0, "5_to_14": 74.0, "5_to_15": 74.0, "5_to_16": 85.0, "5_to_17": 85.0, "5_to_18": 97.0, "5_to_19": 97.0,
    "6_to_7": 30.0, "6_to_8": 30.0, "6_to_9": 39.0, "6_to_10": 39.0, "6_to_11": 50.0, "6_to_12": 50.0, "6_to_13": 62.0, "6_to_14": 62.0, "6_to_15": 62.0, "6_to_16": 74.0, "6_to_17": 74.0, "6_to_18": 85.0, "6_to_19": 85.0,
    "7_to_8": 30.0, "7_to_9": 39.0, "7_to_10": 39.0, "7_to_11": 50.0, "7_to_12": 50.0, "7_to_13": 62.0, "7_to_14": 62.0, "7_to_15": 62.0, "7_to_16": 74.0, "7_to_17": 74.0, "7_to_18": 85.0, "7_to_19": 85.0,
    "8_to_9": 30.0, "8_to_10": 30.0, "8_to_11": 39.0, "8_to_12": 39.0, "8_to_13": 50.0, "8_to_14": 50.0, "8_to_15": 50.0, "8_to_16": 62.0, "8_to_17": 62.0, "8_to_18": 74.0, "8_to_19": 74.0,
    "9_to_10": 30.0, "9_to_11": 30.0, "9_to_12": 30.0, "9_to_13": 39.0, "9_to_14": 39.0, "9_to_15": 39.0, "9_to_16": 50.0, "9_to_17": 50.0, "9_to_18": 62.0, "9_to_19": 62.0,
    "10_to_11": 30.0, "10_to_12": 30.0, "10_to_13": 39.0, "10_to_14": 39.0, "10_to_15": 39.0, "10_to_16": 50.0, "10_to_17": 50.0, "10_to_18": 62.0, "10_to_19": 62.0,
    "11_to_12": 30.0, "11_to_13": 30.0, "11_to_14": 30.0, "11_to_15": 30.0, "11_to_16": 39.0, "11_to_17": 39.0, "11_to_18": 50.0, "11_to_19": 50.0,
    "12_to_13": 30.0, "12_to_14": 30.0, "12_to_15": 30.0, "12_to_16": 39.0, "12_to_17": 39.0, "12_to_18": 50.0, "12_to_19": 50.0,
    "13_to_14": 30.0, "13_to_15": 30.0, "13_to_16": 30.0, "13_to_17": 30.0, "13_to_18": 39.0, "13_to_19": 39.0,
    "14_to_15": 30.0, "14_to_16": 30.0, "14_to_17": 30.0, "14_to_18": 39.0, "14_to_19": 39.0,
    "15_to_16": 30.0, "15_to_17": 30.0, "15_to_18": 39.0, "15_to_19": 39.0,
    "16_to_17": 30.0, "16_to_18": 30.0, "16_to_19": 30.0,
    "17_to_18": 30.0, "17_to_19": 30.0,
    "18_to_19": 30.0
  };

  @override
  void initState() {
    super.initState();
    final routes = BusRouteModel.getAllRoutes();
    _allStops = routes.first.stops;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onStopSelected() {
    if (_selectedBoardingStop == null || _selectedDestinationStop == null) return;
    _updateMap();
  }

  void _updateMap() {
    if (_selectedBoardingStop == null || _selectedDestinationStop == null) return;

    _markers.clear();
    _polylines.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId('from'),
        position: LatLng(
          _selectedBoardingStop!.latitude,
          _selectedBoardingStop!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'From: ${_selectedBoardingStop!.name}'),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('to'),
        position: LatLng(
          _selectedDestinationStop!.latitude,
          _selectedDestinationStop!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'To: ${_selectedDestinationStop!.name}'),
      ),
    );

    final fromIndex = _allStops.indexOf(_selectedBoardingStop!);
    final toIndex = _allStops.indexOf(_selectedDestinationStop!);
    final startIdx = fromIndex < toIndex ? fromIndex : toIndex;
    final endIdx = fromIndex < toIndex ? toIndex : fromIndex;
    final routeStops = _allStops.sublist(startIdx, endIdx + 1);

    final routePoints = routeStops
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

    setState(() {});

    if (_mapController != null) {
      _fitMapToRoute();
    }
  }

  void _fitMapToRoute() {
    if (_selectedBoardingStop == null || _selectedDestinationStop == null) return;

    final stops = [_selectedBoardingStop!, _selectedDestinationStop!];
    double minLat = stops.first.latitude;
    double maxLat = stops.first.latitude;
    double minLng = stops.first.longitude;
    double maxLng = stops.first.longitude;

    for (var stop in stops) {
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

  double _calculateExactFareLocal(int startIdx, int endIdx) {
    if (startIdx == endIdx) return 0.00;

    int firstStage = math.min(startIdx, endIdx);
    int secondStage = math.max(startIdx, endIdx);
    String fareKey = "${firstStage}_to_${secondStage}";

    return _fareMatrix[fareKey] ?? 0.00;
  }

  Future<void> _calculateTicket() async {
    if (_selectedBoardingStop == null || _selectedDestinationStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select boarding and destination locations'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedBoardingStop!.name == _selectedDestinationStop!.name) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boarding and destination cannot be the same'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _showResult = false;
    });

    final predictionService = PredictionService();
    final fromIdx = _allStops.indexOf(_selectedBoardingStop!);
    final toIdx = _allStops.indexOf(_selectedDestinationStop!);

    final response = await predictionService.calculateFare(
      boardingStage: _selectedBoardingStop!.name,
      alightingStage: _selectedDestinationStop!.name,
    );

    setState(() {
      _isCalculating = false;
    });

    if (response.success && response.data != null) {
      final data = response.data!;
      setState(() {
        _showResult = true;
        _ticketResult = {
          'fare': (data['fare'] ?? 0).toDouble(),
          'currency': data['currency'] ?? 'LKR',
          'route_number': data['route_number'] ?? '177',
          'route_name': data['route_name'] ?? 'Kaduwela - Kollupitiya',
          'service_type': data['service_type'] ?? 'Normal',
          'stages_traveled': data['stages_traveled'] ?? (toIdx - fromIdx).abs(),
          'boarding_stage': data['boarding_stage'] ?? _selectedBoardingStop!.name,
          'alighting_stage': data['alighting_stage'] ?? _selectedDestinationStop!.name,
          'boarding_stage_sinhala': data['boarding_stage_sinhala'] ?? '',
          'alighting_stage_sinhala': data['alighting_stage_sinhala'] ?? '',
        };
      });
    } else {
      double exactFare = _calculateExactFareLocal(fromIdx, toIdx);

      setState(() {
        _showResult = true;
        _ticketResult = {
          'fare': exactFare,
          'currency': 'LKR',
          'route_number': '177',
          'route_name': _allStops.isNotEmpty ? 'Kaduwela - Kollupitiya' : '',
          'service_type': 'Normal',
          'stages_traveled': (toIdx - fromIdx).abs(),
          'boarding_stage': _selectedBoardingStop!.name,
          'alighting_stage': _selectedDestinationStop!.name,
          'boarding_stage_sinhala': '',
          'alighting_stage_sinhala': '',
        };
      });
    }
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BusStop>(
                        isExpanded: true,
                        value: _selectedBoardingStop,
                        hint: Row(
                          children: [
                            const Icon(Icons.location_on, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Select boarding stop',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        items: _allStops
                            .where((stop) => stop.name != _selectedDestinationStop?.name)
                            .map((stop) => DropdownMenuItem<BusStop>(
                                  value: stop,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: primaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          stop.name,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBoardingStop = value;
                            _showResult = false;
                          });
                          _onStopSelected();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BusStop>(
                        isExpanded: true,
                        value: _selectedDestinationStop,
                        hint: Row(
                          children: [
                            const Icon(Icons.flag, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Select destination stop',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        items: _allStops
                            .where((stop) => stop.name != _selectedBoardingStop?.name)
                            .map((stop) => DropdownMenuItem<BusStop>(
                                  value: stop,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.flag, color: primaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          stop.name,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDestinationStop = value;
                            _showResult = false;
                          });
                          _onStopSelected();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_selectedBoardingStop != null && _selectedDestinationStop != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.route, color: primaryColor, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Route 177: Kaduwela - Kollupitiya',
                              style: TextStyle(
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

                  if (_selectedBoardingStop != null && _selectedDestinationStop != null) ...[
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
                              _selectedBoardingStop!.latitude,
                              _selectedBoardingStop!.longitude,
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

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Bus Fare',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_ticketResult!['currency']} ${_ticketResult!['fare'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                if (_ticketResult!['route_number'].toString().isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_bus, color: primaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Route Number',
                                        style: TextStyle(fontSize: 14, color: textSecondary),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _ticketResult!['route_number'].toString(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                ],
                                if (_ticketResult!['route_name'].toString().isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.route, color: primaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Route Name',
                                        style: TextStyle(fontSize: 14, color: textSecondary),
                                      ),
                                      const Spacer(),
                                      Flexible(
                                        child: Text(
                                          _ticketResult!['route_name'].toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                ],
                                Row(
                                  children: [
                                    const Icon(Icons.category, color: primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Service Type',
                                      style: TextStyle(fontSize: 14, color: textSecondary),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _ticketResult!['service_type'].toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    const Icon(Icons.pin_drop, color: primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Stages Traveled',
                                      style: TextStyle(fontSize: 14, color: textSecondary),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_ticketResult!['stages_traveled']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: textSecondary),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Journey Details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _ticketResult!['boarding_stage'].toString(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                          if (_ticketResult!['boarding_stage_sinhala'].toString().isNotEmpty)
                                            Text(
                                              _ticketResult!['boarding_stage_sinhala'].toString(),
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
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Column(
                                    children: [
                                      Container(width: 2, height: 16, color: primaryColor.withOpacity(0.3)),
                                      Icon(Icons.arrow_downward, size: 16, color: primaryColor.withOpacity(0.5)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.flag, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _ticketResult!['alighting_stage'].toString(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                          if (_ticketResult!['alighting_stage_sinhala'].toString().isNotEmpty)
                                            Text(
                                              _ticketResult!['alighting_stage_sinhala'].toString(),
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
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}