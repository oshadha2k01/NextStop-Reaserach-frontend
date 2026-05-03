import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/national_route_service.dart';
import '../../models/bus_route_model.dart';
import '../../models/bus_stop.dart';
import '../route_map_screen.dart';

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
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
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
      final routesData = await _routeService.searchRoute(from, to);
      
      if (!mounted) return;

      if (routesData.isNotEmpty) {
        final routeJson = routesData.first;
        final stages = (routeJson['stages'] as List<dynamic>?) ?? 
                       (routeJson['nodes'] as List<dynamic>?) ?? 
                       (routeJson['stops'] as List<dynamic>?) ?? [];
        
        if (stages.isEmpty) {
          setState(() {
            _fromHasError = true;
            _toHasError = true;
            _fromErrorMessage = 'No path found';
            _toErrorMessage = 'No path found';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route exists but has no stops mapped.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final List<BusStop> busStops = [];
        for (var s in stages) {
          double? lat;
          double? lng;

          final coords = s['coordinates'];
          if (coords is Map) {
            lat = _parseCoord(coords['latitude'] ?? coords['lat']);
            lng = _parseCoord(coords['longitude'] ?? coords['lng'] ?? coords['lon']);
          } else {
            lat = _parseCoord(s['latitude'] ?? s['lat']);
            lng = _parseCoord(s['longitude'] ?? s['lng'] ?? s['lon']);
          }

          if (lat != 0.0 && lng != 0.0) {
            busStops.add(BusStop(
              name: s['name'] ?? 'Stop',
              latitude: lat,
              longitude: lng,
            ));
          }
        }

        if (busStops.isEmpty) {
          setState(() {
            _fromHasError = true;
            _toHasError = true;
            _fromErrorMessage = 'No coordinates';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid map coordinates found.'), backgroundColor: Colors.orange),
          );
          return;
        }

        final BusRouteModel routeModel = BusRouteModel(
          id: routeJson['_id']?.toString(),
          routeName: routeJson['route_name'] ?? routeJson['name'] ?? 'Custom Route',
          routeNumber: routeJson['route_number']?.toString(),
          stops: busStops,
        );

        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RouteMapScreen(route: routeModel)),
        );
      } else {
        setState(() {
          _fromHasError = true;
          _toHasError = true;
          _fromErrorMessage = 'Route not found';
          _toErrorMessage = 'Route not found';
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No bus routes found for these locations.'),
            backgroundColor: Colors.redAccent,
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
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text("Find a route", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
          const Text("Enter your origin and destination", style: TextStyle(fontSize: 14, color: textSecondary)),
          const SizedBox(height: 30),
          _buildTextField(_fromController, 'From (e.g., Kaduwela)', Icons.location_on_outlined, _fromHasError, _fromErrorMessage),
          const SizedBox(height: 16),
          _buildTextField(_toController, 'To (e.g., Kollupitiya)', Icons.flag_outlined, _toHasError, _toErrorMessage),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool hasError, String errorMsg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: hasError ? Colors.red : Colors.grey.shade300, width: hasError ? 2 : 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) { if (hasError) _clearErrors(); },
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, color: hasError ? Colors.red : primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          if (hasError) Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(errorMsg, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
