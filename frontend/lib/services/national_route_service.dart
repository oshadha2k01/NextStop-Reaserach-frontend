import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart'; // Ensure this path matches your project structure

class NationalRouteService {
  
  // 1. Home Page Search (A to B)
  Future<List<dynamic>> searchRoute(String from, String to) async {
    final uri = Uri.parse(ApiConfig.nationalRoutesSearch).replace(queryParameters: {
      'fromLocation': from.trim(),
      'toLocation': to.trim(),
    });
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['routes'] ?? []; 
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search route (${response.statusCode}): ${response.body}');
    }
  }

  // 2. All Routes Filter 
  Future<List<dynamic>> getFilteredRoutes({String province = 'All', String district = 'All'}) async {
    final Map<String, String> queryParams = {};
    
    if (province != 'All') {
      // Remove " Province" if it exists to match backend expected values (e.g., "Western" instead of "Western Province")
      String cleanedProvince = province.replaceAll(' Province', '').trim();
      queryParams['province'] = cleanedProvince;
    }
    
    if (district != 'All') {
      queryParams['district'] = district.trim();
    }

    final uri = Uri.parse(ApiConfig.nationalRoutesFilter).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['routes'] ?? [];
    } else {
      throw Exception('Failed to load filtered routes (${response.statusCode}): ${response.body}');
    }
  }

  // 3. Map View Details (by ID)
  Future<Map<String, dynamic>> getRouteDetails(String routeId) async {
    final encodedId = Uri.encodeComponent(routeId.trim());
    final uri = Uri.parse('${ApiConfig.nationalRouteById}$encodedId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Some endpoints return { "route": { ... } }, others return the route object directly
      return data['route'] ?? data;
    } else {
      throw Exception('Failed to load route details (${response.statusCode}): ${response.body}');
    }
  }
}
