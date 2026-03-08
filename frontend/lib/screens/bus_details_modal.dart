import 'package:flutter/material.dart';
import '../models/bus_route_model.dart';
import '../models/bus_stop.dart';
import '../models/people_count_model.dart';
import '../services/api_service.dart';
import 'route_stops_map.dart';
import 'arrival_details_modal.dart';
import 'driver_contact_modal.dart';
import 'prediction_modal.dart';
import 'dart:async';

class BusDetailsModal extends StatefulWidget {
  final String busId;
  final String currentLocation;
  final List<BusStop> remainingStops;
  final List<BusStop> allRouteStops;
  final int currentStopIndex;

  const BusDetailsModal({
    super.key,
    required this.busId,
    required this.currentLocation,
    required this.remainingStops,
    required this.allRouteStops,
    required this.currentStopIndex,
  });

  @override
  State<BusDetailsModal> createState() => _BusDetailsModalState();
}

class _BusDetailsModalState extends State<BusDetailsModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color lightOrange = Color(0xFFFFB399); // Light orange for markers
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  
  final TextEditingController _locationController = TextEditingController();
  String? _calculatedTime;
  bool _hasError = false;
  
  // Live API data
  PeopleCountModel? _liveData;
  bool _isLoading = true;
  Timer? _refreshTimer;
  
  // Constants
  static const int totalSeats = 55;

  @override
  void initState() {
    super.initState();
    _fetchLiveData();
    _startAutoRefresh();
  }
  
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchLiveData();
    });
  }
  
  Future<void> _fetchLiveData() async {
    final data = await ApiService.fetchPeopleCount();
    if (mounted) {
      setState(() {
        _liveData = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  int get occupiedSeats => _liveData?.totalPeople ?? 0;
  int get availableSeats => totalSeats - occupiedSeats;
  bool get isCrowded => occupiedSeats > (totalSeats * 0.7);
  int get passengersIn => _liveData?.inCount ?? 0;
  int get passengersOut => _liveData?.outCount ?? 0;

  void _calculateTime() {
    final location = _locationController.text.trim();
    
    if (location.isEmpty) {
      setState(() {
        _hasError = true;
        _calculatedTime = null;
      });
      return;
    }

    // Find the stop in remaining stops
    int stopIndex = -1;
    BusStop? targetStop;
    for (int i = 0; i < widget.remainingStops.length; i++) {
      if (widget.remainingStops[i].name.toLowerCase().contains(location.toLowerCase())) {
        stopIndex = i;
        targetStop = widget.remainingStops[i];
        break;
      }
    }

    if (stopIndex == -1) {
      setState(() {
        _hasError = true;
        _calculatedTime = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location "$location" not found on this route'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Calculate estimated time (2-3 minutes per stop)
    final minutes = (stopIndex + 1) * 2 + (stopIndex % 2);
    final distance = (stopIndex + 1) * 1.2; // Approximate distance in km
    
    setState(() {
      _hasError = false;
      _calculatedTime = '$minutes min';
    });

    // Show arrival details modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArrivalDetailsModal(
        busId: widget.busId,
        currentLocation: widget.currentLocation,
        destinationLocation: targetStop!.name,
        estimatedTime: minutes,
        distance: distance,
        currentSpeed: 0,
        stopsAway: stopIndex + 1,
        destinationLatitude: targetStop.latitude,
        destinationLongitude: targetStop.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                  // Bus Header with Driver Icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bus ${widget.busId}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current: ${widget.currentLocation}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Driver Contact Button
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DriverContactModal(
                              busId: widget.busId,
                              currentLocation: widget.currentLocation,
                              allStops: widget.remainingStops,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Speed & Location Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                Icons.speed,
                                'Speed',
                                'N/A',
                                primaryColor,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                Icons.location_on,
                                'Location',
                                widget.remainingStops.isNotEmpty
                                    ? '${widget.remainingStops[0].latitude.toStringAsFixed(4)}, ${widget.remainingStops[0].longitude.toStringAsFixed(4)}'
                                    : 'N/A',
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Seats Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Seating Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_liveData != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.circle, size: 6, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('LIVE', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSeatInfo(
                                'Total Seats',
                                '$totalSeats',
                                Colors.grey,
                              ),
                            ),
                            Expanded(
                              child: _buildSeatInfo(
                                'Occupied',
                                _isLoading ? '...' : '$occupiedSeats',
                                Colors.red,
                              ),
                            ),
                            Expanded(
                              child: _buildSeatInfo(
                                'Available',
                                _isLoading ? '...' : '$availableSeats',
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _isLoading ? 0 : (occupiedSeats / totalSeats),
                          backgroundColor: Colors.grey[300],
                          color: isCrowded ? Colors.red : primaryColor,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              isCrowded ? Icons.warning : Icons.check_circle,
                              size: 16,
                              color: isCrowded ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isLoading ? 'Loading...' : (isCrowded ? 'Crowded' : 'Comfortable'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCrowded ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Passenger Movement Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Passenger Movement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_liveData != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.circle, size: 6, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('LIVE', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPassengerInfo(
                                Icons.login,
                                'Boarded',
                                _isLoading ? '...' : '$passengersIn',
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPassengerInfo(
                                Icons.logout,
                                'Alighted',
                                _isLoading ? '...' : '$passengersOut',
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Calculate Time Section
                  const Text(
                    'Calculate Arrival Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Location Input
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hasError ? Colors.red : Colors.grey.shade300,
                        width: _hasError ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _locationController,
                      onChanged: (value) {
                        if (_hasError) {
                          setState(() => _hasError = false);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter boarding location',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: _hasError ? Colors.red : primaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  if (_calculatedTime != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: primaryColor),
                          const SizedBox(width: 12),
                          Text(
                            'Estimated arrival: $_calculatedTime',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Calculate Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _calculateTime,
                      icon: const Icon(Icons.access_time, color: Colors.white),
                      label: const Text(
                        'Calculate Time to Onboarding Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Show All Stops Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteStopsMapScreen(
                              busId: widget.busId,
                              allStops: [...widget.remainingStops],
                              currentLocation: widget.currentLocation,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined, color: primaryColor),
                      label: const Text(
                        'View All Bus Stops on Map',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Predict Arrival Time Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => PredictionModal(
                            busId: widget.busId,
                            allStops: widget.allRouteStops,
                            currentLocation: widget.currentLocation,
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                      label: const Text(
                        'Predict Time to Destination',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:primaryColor  , // Purple/Indigo for AI
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
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

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
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
      ],
    );
  }

  Widget _buildSeatInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerInfo(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
