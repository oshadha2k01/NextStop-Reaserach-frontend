import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/national_route_service.dart';
import '../../core/theme/app_colors.dart';
import '../modals/route_search_modal.dart';

class AllRoutesScreen extends StatefulWidget {
	const AllRoutesScreen({super.key});

	@override
	State<AllRoutesScreen> createState() => _AllRoutesScreenState();
}

class _AllRoutesScreenState extends State<AllRoutesScreen> {
	final NationalRouteService _routeService = NationalRouteService();
	List<dynamic> _routes = [];
	bool _isLoading = true;

	String _selectedProvince = 'All';
	String _selectedDistrict = 'All';

	final List<String> provinces = [
		'All',
		'Western Province',
		'Central Province',
		'Southern Province',
		'Northern Province',
		'Eastern Province',
		'North Western Province',
		'North Central Province',
		'Uva Province',
		'Sabaragamuwa Province',
	];
  final Map<String, List<String>> provinceToDistricts = {
    'All': [
      'All', 'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
      'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar',
      'Vavuniya', 'Mullaitivu', 'Batticaloa', 'Ampara', 'Trincomalee',
      'Kurunegala', 'Puttalam', 'Anuradhapura', 'Polonnaruwa', 'Badulla',
      'Monaragala', 'Ratnapura', 'Kegalle'
    ],
    'Western Province': ['All', 'Colombo', 'Gampaha', 'Kalutara'],
    'Central Province': ['All', 'Kandy', 'Matale', 'Nuwara Eliya'],
    'Southern Province': ['All', 'Galle', 'Matara', 'Hambantota'],
    'Northern Province': ['All', 'Jaffna', 'Kilinochchi', 'Mannar', 'Vavuniya', 'Mullaitivu'],
    'Eastern Province': ['All', 'Batticaloa', 'Ampara', 'Trincomalee'],
    'North Western Province': ['All', 'Kurunegala', 'Puttalam'],
    'North Central Province': ['All', 'Anuradhapura', 'Polonnaruwa'],
    'Uva Province': ['All', 'Badulla', 'Monaragala'],
    'Sabaragamuwa Province': ['All', 'Ratnapura', 'Kegalle'],
  };

  List<String> get _currentDistricts => provinceToDistricts[_selectedProvince] ?? ['All'];

	@override
	void initState() {
		super.initState();
		_fetchRoutes();
	}

	Future<void> _fetchRoutes() async {
		setState(() => _isLoading = true);

		try {
			final routes = await _routeService.getFilteredRoutes(
				province: _selectedProvince,
				district: _selectedDistrict,
			);

			if (!mounted) return;
			setState(() {
				_routes = routes;
				_isLoading = false;
			});
		} catch (e) {
			if (!mounted) return;
			setState(() => _isLoading = false);
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Error: $e')),
			);
		}
	}

	void _openRouteMap(String routeId, String routeName) {
		showModalBottomSheet(
			context: context,
			isScrollControlled: true,
			backgroundColor: Colors.transparent,
			builder: (context) => RouteMapBottomSheet(
				routeId: routeId,
				routeName: routeName,
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			body: SafeArea(
				child: Column(
					children: [
						// --- Themed Orange Header ---
						Container(
							decoration: const BoxDecoration(
								gradient: LinearGradient(
									begin: Alignment.topLeft,
									end: Alignment.bottomRight,
									colors: [AppColors.primary, AppColors.primaryDeep],
								),
								borderRadius: BorderRadius.only(
									bottomLeft: Radius.circular(30),
									bottomRight: Radius.circular(30),
								),
							),
							padding: const EdgeInsets.fromLTRB(10, 20, 20, 30),
							child: Row(
								children: [
									IconButton(
										icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
										onPressed: () => Navigator.pop(context),
									),
									const Text(
										"NextStop",
										style: TextStyle(
											fontSize: 24,
											fontWeight: FontWeight.bold,
											color: Colors.white,
											letterSpacing: 0.5,
										),
									),
									const Spacer(),
									IconButton(
										icon: const Icon(Icons.search, color: Colors.white),
										onPressed: () {
											showModalBottomSheet(
												context: context,
												isScrollControlled: true,
												backgroundColor: Colors.transparent,
												builder: (context) => const RouteSearchModal(),
											);
										},
									),
									const Column(
										crossAxisAlignment: CrossAxisAlignment.end,
										children: [
											Text(
												"All Routes",
												style: TextStyle(
													fontWeight: FontWeight.bold,
													fontSize: 18,
													color: Colors.white,
												),
											),
											Text(
												"Sri Lanka",
												style: TextStyle(
													color: Colors.white70,
													fontSize: 14,
												),
											),
										],
									)
								],
							),
						),
						const SizedBox(height: 10),
						Container(
						color: Colors.white,
						padding: const EdgeInsets.all(16.0),
						child: Row(
							children: [
								Expanded(
									child: DropdownButtonFormField<String>(
										value: _selectedProvince,
										decoration: InputDecoration(
											labelText: 'Province',
											border: OutlineInputBorder(
												borderRadius: BorderRadius.circular(8),
											),
											contentPadding:
													const EdgeInsets.symmetric(horizontal: 10),
										),
										items: provinces
												.map(
													(province) => DropdownMenuItem<String>(
														value: province,
														child: Text(
															province,
															style: const TextStyle(
																fontSize: 13,
																color: AppColors.textPrimary,
															),
														),
													),
												)
												.toList(),
										onChanged: (val) {
											if (val == null) return;
											setState(() {
												_selectedProvince = val;
												_selectedDistrict = 'All'; // Reset district when province changes
											});
											_fetchRoutes();
										},
									),
								),
								const SizedBox(width: 10),
								Expanded(
									child: DropdownButtonFormField<String>(
										value: _selectedDistrict,
										decoration: InputDecoration(
											labelText: 'District',
											border: OutlineInputBorder(
												borderRadius: BorderRadius.circular(8),
											),
											contentPadding:
													const EdgeInsets.symmetric(horizontal: 10),
										),
										items: _currentDistricts
												.map(
													(district) => DropdownMenuItem<String>(
														value: district,
														child: Text(
															district,
															style: const TextStyle(fontSize: 13),
														),
													),
												)
												.toList(),
										onChanged: (val) {
											if (val == null) return;
											setState(() => _selectedDistrict = val);
											_fetchRoutes();
										},
									),
								),
							],
						),
					),
					Expanded(
						child: _isLoading
								? const Center(child: CircularProgressIndicator(color: AppColors.primary))
								: _routes.isEmpty
										? const Center(child: Text('No routes found.'))
										: ListView.builder(
												itemCount: _routes.length,
												itemBuilder: (context, index) {
													final route = _routes[index] as Map<String, dynamic>;
													return Card(
														margin: const EdgeInsets.symmetric(
															horizontal: 16,
															vertical: 8,
														),
														child: ListTile(
															leading: Container(
																padding: const EdgeInsets.all(10),
																decoration: BoxDecoration(
																	color: AppColors.primary.withOpacity(0.1),
																	borderRadius: BorderRadius.circular(10),
																),
																child: Text(
																	'${route['route_number'] ?? ''}',
																	style: const TextStyle(
																		color: AppColors.primary,
																		fontWeight: FontWeight.bold,
																	),
																),
															),
															title: Text(
																'${route['route_name'] ?? ''}',
																style:
																		const TextStyle(fontWeight: FontWeight.bold),
															),
															subtitle: Text(
																'${route['province'] ?? ''} • ${route['district'] ?? ''}',
																style: const TextStyle(color: AppColors.textSecondary),
															),
															trailing: const Icon(
																Icons.map_outlined,
																color: AppColors.primary,
															),
															onTap: () => _openRouteMap(
																'${route['_id'] ?? ''}',
																'${route['route_name'] ?? ''}',
															),
														),
													);
												},
											),
					),
				],
			),
		),
    );
	}
}

class RouteMapBottomSheet extends StatefulWidget {
	final String routeId;
	final String routeName;

	const RouteMapBottomSheet({
		super.key,
		required this.routeId,
		required this.routeName,
	});

	@override
	State<RouteMapBottomSheet> createState() => _RouteMapBottomSheetState();
}

class _RouteMapBottomSheetState extends State<RouteMapBottomSheet> {
	final NationalRouteService _routeService = NationalRouteService();
	Set<Polyline> _polylines = {};
	Set<Marker> _markers = {};
	GoogleMapController? _mapController;
	bool _isLoading = true;

	@override
	void initState() {
		super.initState();
		_loadRouteData();
	}

	double? _parseCoord(dynamic value) {
		if (value == null) return null;
		if (value is num) return value.toDouble();
		if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned);
    }
		return null;
	}

	Future<void> _loadRouteData() async {
		try {
			final routeData = await _routeService.getRouteDetails(widget.routeId);
			// Support different names for the point list
			final stages = (routeData['stages'] as List<dynamic>?) ?? 
						   (routeData['nodes'] as List<dynamic>?) ?? 
						   (routeData['stops'] as List<dynamic>?) ?? [];

			final List<LatLng> points = [];
			final Set<Marker> markers = {};
			double minLat = 90.0;
			double maxLat = -90.0;
			double minLng = 180.0;
			double maxLng = -180.0;

			for (final stage in stages) {
				double? lat;
				double? lng;

				// Try to find coordinates in various common formats
				final coords = stage['coordinates'];
				if (coords is Map) {
					lat = _parseCoord(coords['latitude'] ?? coords['lat']);
					lng = _parseCoord(coords['longitude'] ?? coords['lng'] ?? coords['lon']);
				} else if (coords is List && coords.length >= 2) {
					// Handle GeoJSON style [lng, lat]
					lng = _parseCoord(coords[0]);
					lat = _parseCoord(coords[1]);
				} else {
					// Try direct properties
					lat = _parseCoord(stage['latitude'] ?? stage['lat']);
					lng = _parseCoord(stage['longitude'] ?? stage['lng'] ?? stage['lon']);
				}

				if (lat == null || lng == null) continue;
				final latLng = LatLng(lat, lng);

				points.add(latLng);
				markers.add(
					Marker(
						markerId: MarkerId('${stage['name'] ?? 'stop_${points.length}'}'),
						position: latLng,
						infoWindow: InfoWindow(title: '${stage['name'] ?? 'Stop'}'),
						icon: BitmapDescriptor.defaultMarkerWithHue(
							BitmapDescriptor.hueOrange,
						),
					),
				);

				if (lat < minLat) minLat = lat;
				if (lat > maxLat) maxLat = lat;
				if (lng < minLng) minLng = lng;
				if (lng > maxLng) maxLng = lng;
			}

			if (!mounted) return;
			setState(() {
				_polylines = {
					Polyline(
						polylineId: const PolylineId('map_line'),
						points: points,
						color: AppColors.primary,
						width: 5,
					),
				};
				_markers = markers;
				_isLoading = false;
			});

			if (points.isNotEmpty && _mapController != null) {
				_fitMapToPoints(points);
			}
		} catch (e) {
			if (!mounted) return;
			setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load route: $e')),
      );
		}
	}

	void _fitMapToPoints(List<LatLng> points) {
		if (points.isEmpty || _mapController == null) return;

		double minLat = points.first.latitude;
		double maxLat = points.first.latitude;
		double minLng = points.first.longitude;
		double maxLng = points.first.longitude;

		for (final point in points) {
			if (point.latitude < minLat) minLat = point.latitude;
			if (point.latitude > maxLat) maxLat = point.latitude;
			if (point.longitude < minLng) minLng = point.longitude;
			if (point.longitude > maxLng) maxLng = point.longitude;
		}

		_mapController!.animateCamera(
			CameraUpdate.newLatLngBounds(
				LatLngBounds(
					southwest: LatLng(minLat, minLng),
					northeast: LatLng(maxLat, maxLng),
				),
				60,
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Container(
			height: MediaQuery.of(context).size.height * 0.85,
			decoration: const BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
			),
			child: Column(
				children: [
					const SizedBox(height: 12),
					Container(
						width: 40,
						height: 5,
						decoration: BoxDecoration(
							color: Colors.grey[300],
							borderRadius: BorderRadius.circular(10),
						),
					),
					Padding(
						padding: const EdgeInsets.all(16.0),
						child: Text(
							widget.routeName,
							style: const TextStyle(
								fontSize: 18,
								fontWeight: FontWeight.bold,
							),
						),
					),
					Expanded(
						child: _isLoading
								? const Center(child: CircularProgressIndicator(color: AppColors.primary))
								: _polylines.isEmpty || _polylines.first.points.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No map data available for this route.', 
                            style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ClipRRect(
										borderRadius:
												const BorderRadius.vertical(top: Radius.circular(16)),
										child: GoogleMap(
											initialCameraPosition: const CameraPosition(
												target: LatLng(7.8731, 80.7718),
												zoom: 7,
											),
											polylines: _polylines,
											markers: _markers,
											myLocationEnabled: true,
											onMapCreated: (controller) {
												_mapController = controller;
												if (_polylines.isNotEmpty && _polylines.first.points.isNotEmpty) {
													_fitMapToPoints(_polylines.first.points);
												}
											},
										),
									),
					),
				],
			),
		);
	}
}
