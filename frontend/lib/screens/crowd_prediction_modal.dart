import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../models/bus_route_model.dart';

class CrowdPredictionModal extends StatefulWidget {
  const CrowdPredictionModal({Key? key}) : super(key: key);

  @override
  State<CrowdPredictionModal> createState() => _CrowdPredictionModalState();
}

class _CrowdPredictionModalState extends State<CrowdPredictionModal> {
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  DateTime? _selectedDate;
  BusRouteModel? _matchedRoute;
  bool _isPredicting = false;
  bool _showPrediction = false;
  Map<String, dynamic>? _predictionResult;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _timeController.dispose();
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No route found for these locations'),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _predictCrowd() async {
    if (_matchedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid route first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null || _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPredicting = true;
      _showPrediction = false;
    });

    // Simulate ML API call
    await Future.delayed(const Duration(seconds: 3));

    // Demo prediction logic based on selected date and time
    final selectedDay = _selectedDate!;
    final isWeekend = selectedDay.weekday == DateTime.saturday || selectedDay.weekday == DateTime.sunday;
    
    // Parse the selected time
    final timeParts = _timeController.text.split(':');
    int selectedHour = 0;
    int selectedMinute = 0;
    
    if (timeParts.length >= 2) {
      // Handle AM/PM format
      if (_timeController.text.contains('AM') || _timeController.text.contains('PM')) {
        final isPM = _timeController.text.contains('PM');
        selectedHour = int.parse(timeParts[0].trim());
        selectedMinute = int.parse(timeParts[1].split(' ')[0].trim());
        
        if (isPM && selectedHour != 12) {
          selectedHour += 12;
        } else if (!isPM && selectedHour == 12) {
          selectedHour = 0;
        }
      } else {
        selectedHour = int.parse(timeParts[0].trim());
        selectedMinute = int.parse(timeParts[1].trim());
      }
    }

    int crowdLevel;
    String crowdStatus;
    String recommendation;
    Color statusColor;

    if (isWeekend) {
      // WEEKENDS: Always Normal/Comfortable
      crowdLevel = 25 + (selectedHour % 15);
      crowdStatus = 'Comfortable';
      recommendation = 'Perfect time to travel! Weekend buses are less crowded. Enjoy a comfortable journey with available seats.';
      statusColor = Colors.green;
    } else {
      // WEEKDAYS: Check for peak hours
      
      // Morning Peak: 6:00 AM - 7:00 AM (6:30 AM peak)
      if (selectedHour == 6 && selectedMinute >= 0 || selectedHour == 7 && selectedMinute == 0) {
        crowdLevel = 85 + (selectedMinute ~/ 10);
        crowdStatus = 'Over Crowded';
        recommendation = 'MORNING PEAK HOUR! Not recommended for this time. Bus is heavily over capacity during office commute hours (6:00-7:00 AM). Please choose an earlier or later time.';
        statusColor = Colors.red;
      }
      // Evening Peak: 4:30 PM - 6:00 PM
      else if ((selectedHour == 16 && selectedMinute >= 30) || 
               (selectedHour == 17) || 
               (selectedHour == 18 && selectedMinute == 0)) {
        crowdLevel = 80 + ((selectedHour - 16) * 5);
        crowdStatus = 'Over Crowded';
        recommendation = 'EVENING PEAK HOUR! Not recommended for this time. Bus is over capacity during evening rush hours (4:30-6:00 PM). Consider traveling after 6:30 PM or before 4:00 PM.';
        statusColor = Colors.red;
      }
      // Normal/Off-peak hours on weekdays
      else if (selectedHour >= 9 && selectedHour <= 15) {
        // Mid-day comfortable hours
        crowdLevel = 30 + (selectedHour % 10);
        crowdStatus = 'Comfortable';
        recommendation = 'Good time to travel! Weekday mid-day buses have available seats. Comfortable journey expected during off-peak hours.';
        statusColor = Colors.green;
      }
      else if (selectedHour >= 19 || selectedHour <= 5) {
        // Early morning or late evening
        crowdLevel = 20 + (selectedHour % 15);
        crowdStatus = 'Comfortable';
        recommendation = 'Excellent time to travel! Very few passengers during these hours. Guaranteed comfortable journey with plenty of seats available.';
        statusColor = Colors.green;
      }
      else {
        // Moderate hours (7:00-9:00 AM and 6:00-7:00 PM)
        crowdLevel = 55 + (selectedHour % 15);
        crowdStatus = 'Moderate';
        recommendation = 'Moderate crowd expected on this weekday. You may find seats available but bus could be busy. Consider this time slot or adjust your schedule slightly.';
        statusColor = Colors.orange;
      }
    }

    setState(() {
      _isPredicting = false;
      _showPrediction = true;
      _predictionResult = {
        'crowd_level': crowdStatus.toLowerCase().replaceAll(' ', '_'),
        'date': _selectedDate!.toIso8601String().split('T')[0],
        'day_of_week': _getDayOfWeek(_selectedDate!.weekday),
        'predicted_crowd': crowdLevel,
        'recommendation': recommendation,
        'status': crowdStatus,
        'time': _timeController.text,
        'statusColor': statusColor,
      };
    });
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
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
                          Icons.people_alt,
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
                              'Crowd Prediction',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'AI-powered crowd forecasting',
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
                    'From Location',
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
                    'To Location',
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

                  // Date Selection
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Predict Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedDate != null
                                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                          : 'Select Date',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _selectedDate != null ? textPrimary : Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Planned Time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _timeController.text.isEmpty ? 'Select Time' : _timeController.text,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _timeController.text.isEmpty ? Colors.grey[400] : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Predict Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isPredicting ? null : _predictCrowd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: primaryColor.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isPredicting
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
                                  'Analyzing Crowd Data...',
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
                                Icon(Icons.analytics, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Predict The Crowd',
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
                                'Crowd Prediction Result',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Status Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _predictionResult!['statusColor'].withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _predictionResult!['statusColor'],
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _predictionResult!['status'],
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: _predictionResult!['statusColor'],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_predictionResult!['predicted_crowd']}% Capacity',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _predictionResult!['statusColor'],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _predictionResult!['statusColor'],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _predictionResult!['status'] == 'Over Crowded'
                                            ? Icons.warning
                                            : _predictionResult!['status'] == 'Comfortable'
                                                ? Icons.check_circle
                                                : Icons.info,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: _predictionResult!['predicted_crowd'] / 100,
                                  backgroundColor: Colors.white,
                                  color: _predictionResult!['statusColor'],
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Details
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow('Date', _predictionResult!['date']),
                                const Divider(height: 16),
                                _buildInfoRow('Day', _predictionResult!['day_of_week']),
                                const Divider(height: 16),
                                _buildInfoRow('Time', _predictionResult!['time']),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Recommendation
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lightbulb, color: primaryColor, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Recommendation',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _predictionResult!['recommendation'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                    height: 1.5,
                                  ),
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
