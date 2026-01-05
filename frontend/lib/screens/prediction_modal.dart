import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/bus_stop.dart';

class PredictionModal extends StatefulWidget {
  final String busId;
  final List<BusStop> allStops;
  final String currentLocation;

  const PredictionModal({
    Key? key,
    required this.busId,
    required this.allStops,
    required this.currentLocation,
  }) : super(key: key);

  @override
  State<PredictionModal> createState() => _PredictionModalState();
}

class _PredictionModalState extends State<PredictionModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color aiColor = Color(0xFF6366F1);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _desiredTimeController = TextEditingController();
  
  BusStop? _selectedBoardingStop;
  LatLng? _userLocation;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  bool _isLoadingLocation = true;
  bool _isPredicting = false;
  bool _showPrediction = false;
  
  Map<String, dynamic>? _predictionResult;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _desiredTimeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _updateMap();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _updateMap() {
    if (_userLocation == null) return;

    _markers.clear();
    _polylines.clear();

    // Add user location marker - Orange theme
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add boarding stop marker if selected - Green for start
    if (_selectedBoardingStop != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('boarding_stop'),
          position: LatLng(_selectedBoardingStop!.latitude, _selectedBoardingStop!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Boarding: ${_selectedBoardingStop!.name}'),
        ),
      );
    }

    // Add destination marker if entered - Red for destination
    final destination = _destinationController.text.trim();
    if (destination.isNotEmpty) {
      final destCoords = _getDestinationCoordinates(destination);
      if (destCoords != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destCoords,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'Destination: $destination'),
          ),
        );
      }
    }

    // Add route polyline - Orange theme
    final routePoints = widget.allStops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();
    
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: primaryColor, // Orange
        width: 6,
        patterns: [PatternItem.dash(30), PatternItem.gap(15)],
      ),
    );

    setState(() {});

    if (_mapController != null) {
      _fitMapToMarkers();
    }
  }

  LatLng? _getDestinationCoordinates(String destination) {
    // Demo hardcoded destinations
    final destinations = {
      'galle face': LatLng(6.9271, 79.8466),
      'lotus tower': LatLng(6.9286, 79.8553),
      'kollupitiya': LatLng(6.9114, 79.8488),
      'fort': LatLng(6.9344, 79.8499),
    };

    final destLower = destination.toLowerCase();
    for (var entry in destinations.entries) {
      if (destLower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty) return;

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

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _predictArrivalTime() async {
    if (_selectedBoardingStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a boarding stop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your destination'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_desiredTimeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter desired arrival time in minutes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPredicting = true;
      _showPrediction = false;
    });

    // Simulate ML prediction API call
    await Future.delayed(const Duration(seconds: 3));

    // Demo prediction based on desired time
    final desiredTime = int.tryParse(_desiredTimeController.text.trim()) ?? 30;
    final predictedTime = (desiredTime * 0.95).toDouble(); // 95% of desired time
    final predictedSeconds = (predictedTime * 60).toInt();
    
    String alertStatus;
    String alertMessage;
    Color alertColor;

    if (predictedTime <= desiredTime) {
      alertStatus = 'success';
      alertMessage = 'SUCCESS: Actual predicted time (${predictedTime.toStringAsFixed(1)} min) is less than or equal to your desired time ($desiredTime min).';
      alertColor = Colors.green;
    } else if (predictedTime <= desiredTime + 5) {
      alertStatus = 'warning';
      alertMessage = 'WARNING: Predicted time (${predictedTime.toStringAsFixed(1)} min) is slightly more than desired time ($desiredTime min). Consider leaving earlier.';
      alertColor = Colors.orange;
    } else {
      alertStatus = 'error';
      alertMessage = 'ALERT: Predicted time (${predictedTime.toStringAsFixed(1)} min) significantly exceeds desired time ($desiredTime min). Plan alternative route.';
      alertColor = Colors.red;
    }

    setState(() {
      _isPredicting = false;
      _showPrediction = true;
      _predictionResult = {
        'busId': widget.busId,
        'predictedTimeMinutes': predictedTime.toStringAsFixed(1),
        'predictedTimeSeconds': predictedSeconds,
        'desiredTimeMinutes': desiredTime,
        'alertStatus': alertStatus,
        'alertMessage': alertMessage,
        'alertColor': alertColor,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                          color: aiColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: aiColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destination Time Prediction',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'ML-powered real time arrival estimates',
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

                  // Boarding Stop Selector
                  const Text(
                    'Select Boarding Stop',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BusStop>(
                        value: _selectedBoardingStop,
                        isExpanded: true,
                        hint: const Text('Choose where you will board'),
                        icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                        style: const TextStyle(
                          fontSize: 15,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        items: widget.allStops.map((stop) {
                          return DropdownMenuItem(
                            value: stop,
                            child: Text(stop.name),
                          );
                        }).toList(),
                        onChanged: (BusStop? stop) {
                          setState(() {
                            _selectedBoardingStop = stop;
                          });
                          _updateMap();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Destination Input
                  const Text(
                    'Your Destination',
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
                      controller: _destinationController,
                      onChanged: (value) => _updateMap(),
                      decoration: InputDecoration(
                        hintText: 'e.g., Galle Face, Lotus Tower',
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

                  // Desired Time Input
                  const Text(
                    'Desired Arrival Time (Minutes)',
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
                      controller: _desiredTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g., 30',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.timer, color: primaryColor),
                        suffixText: 'min',
                        suffixStyle: const TextStyle(color: textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Map Display
                  const Text(
                    'Route Preview',
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
                      child: _userLocation != null
                          ? GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _userLocation!,
                                zoom: 12,
                              ),
                              markers: _markers,
                              polylines: _polylines,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              compassEnabled: true,
                              trafficEnabled: false,
                              buildingsEnabled: true,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                _fitMapToMarkers();
                              },
                            )
                          : Container(
                              color: Colors.grey[50],
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Predict Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isPredicting ? null : _predictArrivalTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: primaryColor.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isPredicting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Processing with AI...',
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
                                Icon(Icons.psychology, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Predict Arrival Time',
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

                  // Prediction Results
                  if (_showPrediction && _predictionResult != null) ...[
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
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'AI Prediction Result',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Time Display
                          Row(
                            children: [
                              Expanded(
                                child: _buildPredictionCard(
                                  'Predicted Time',
                                  '${_predictionResult!['predictedTimeMinutes']} min',
                                  primaryColor,
                                  Icons.schedule,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPredictionCard(
                                  'Desired Time',
                                  '${_predictionResult!['desiredTimeMinutes']} min',
                                  const Color(0xFF10B981),
                                  Icons.access_time,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Alert Message
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _predictionResult!['alertColor'].withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _predictionResult!['alertColor'],
                                width: 2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _predictionResult!['alertStatus'] == 'success'
                                      ? Icons.check_circle
                                      : _predictionResult!['alertStatus'] == 'warning'
                                          ? Icons.warning
                                          : Icons.error,
                                  color: _predictionResult!['alertColor'],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _predictionResult!['alertMessage'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _predictionResult!['alertColor'],
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Additional Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow('Bus ID', _predictionResult!['busId']),
                                const Divider(height: 16),
                                _buildInfoRow('Time in Seconds', '${_predictionResult!['predictedTimeSeconds']} sec'),
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

  Widget _buildPredictionCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
