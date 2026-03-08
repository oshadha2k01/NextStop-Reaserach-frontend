import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/bus_stop.dart';
import '../services/prediction_service.dart';

class PredictionModal extends StatefulWidget {
  final String busId;
  final List<BusStop> allStops;
  final String currentLocation;

  const PredictionModal({
    super.key,
    required this.busId,
    required this.allStops,
    required this.currentLocation,
  });

  @override
  State<PredictionModal> createState() => _PredictionModalState();
}

class _PredictionModalState extends State<PredictionModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color aiColor = Color(0xFF6366F1);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  final TextEditingController _desiredTimeController = TextEditingController();

  BusStop? _selectedBoardingStop;
  BusStop? _selectedDestinationStop;
  LatLng? _userLocation;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
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

    // Add destination stop marker if selected - Red for end
    if (_selectedDestinationStop != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination_stop'),
          position: LatLng(_selectedDestinationStop!.latitude, _selectedDestinationStop!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Destination: ${_selectedDestinationStop!.name}'),
        ),
      );
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

    if (_selectedDestinationStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your destination'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedBoardingStop == _selectedDestinationStop) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boarding stop and destination cannot be the same'),
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

    final predictionService = PredictionService();
    final desiredTime = int.tryParse(_desiredTimeController.text.trim()) ?? 30;

    final response = await predictionService.predictDestination(
      route: widget.busId,
      boardingLocation: _selectedBoardingStop!.name,
      destinationLocation: _selectedDestinationStop!.name,
      userExpectedTime: desiredTime,
    );

    setState(() {
      _isPredicting = false;
    });

    if (response.success && response.data != null) {
      final data = response.data!;
      final prediction = data['prediction'] ?? {};
      final timeComparison = data['time_comparison'] ?? {};

      // Extract from the actual backend response structure
      final predictedTime = (prediction['predicted_time_minutes'] ?? (desiredTime * 0.95)).toDouble();
      final double diffMinutes = predictedTime - desiredTime;

      String alertStatus;
      Color alertColor;

      // Backend status matching logic
      if (diffMinutes <= 0) {
        alertStatus = 'success';
        alertColor = Colors.green;
      } else if (diffMinutes <= 5) {
        alertStatus = 'warning';
        alertColor = Colors.orange;
      } else {
        alertStatus = 'error';
        alertColor = Colors.red;
      }

      setState(() {
        _showPrediction = true;
        _predictionResult = {
          'busId': widget.busId,
          'predictedTimeMinutes': predictedTime.toStringAsFixed(1),
          'desiredTimeMinutes': desiredTime,
          'alertStatus': alertStatus,
          'alertMessage': timeComparison['status'] ?? prediction['recommendation'] ?? 'Prediction processed.',
          'alertColor': alertColor,
          'distanceKm': prediction['journey_distance_km']?.toStringAsFixed(2) ?? 'N/A',
          'trafficCondition': prediction['traffic_analysis'] != null ? prediction['traffic_analysis']['condition'] : 'Unknown',
          'recommendation': prediction['recommendation'] ?? 'No specific route recommendations available.',
        };
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.errorMessage ?? 'Prediction failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                            // Clear destination if it's the same as newly selected boarding stop
                            if (_selectedDestinationStop == stop) {
                              _selectedDestinationStop = null;
                            }
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BusStop>(
                        value: _selectedDestinationStop,
                        isExpanded: true,
                        hint: const Text('Choose your destination stop'),
                        icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                        style: const TextStyle(
                          fontSize: 15,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        items: widget.allStops
                            .where((stop) => stop != _selectedBoardingStop)
                            .map((stop) {
                          return DropdownMenuItem(
                            value: stop,
                            child: Text(stop.name),
                          );
                        }).toList(),
                        onChanged: (BusStop? stop) {
                          setState(() {
                            _selectedDestinationStop = stop;
                          });
                          _updateMap();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Desired Time Input
                  const Text(
                    'Desired Journey Time (Minutes)',
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
                                  'Processing with ML...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.psychology, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  'Predict Journey Time',
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
                                'ML Prediction Result',
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

                          // Additional Info replacing Time in Seconds
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow('Distance', '${_predictionResult!['distanceKm']} km'),
                                const Divider(height: 16),
                                _buildInfoRow('Traffic Analysis', _predictionResult!['trafficCondition']),
                                const Divider(height: 16),
                                _buildInfoRow('Recommendation', _predictionResult!['recommendation']),
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
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}