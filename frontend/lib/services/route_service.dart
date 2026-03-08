import '../config/api_config.dart';
import '../models/bus_route_model.dart';
import 'api_service.dart';

class RouteService {
  final ApiService _api = ApiService();

  Future<List<BusRouteModel>> getAllRoutes() async {
    final response = await _api.get(ApiConfig.routes);

    if (response.success && response.data != null) {
      final routesJson =
          response.data!['routes'] ?? response.data!['data'] ?? [];
      if (routesJson is List && routesJson.isNotEmpty) {
        return routesJson
            .map((r) => BusRouteModel.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    }

    return BusRouteModel.getAllRoutes();
  }

  Future<List<BusRouteModel>> searchRoutes(String from, String to) async {
    final response = await _api.get(
      ApiConfig.routes,
      queryParams: {'from': from, 'to': to},
    );

    if (response.success && response.data != null) {
      final routesJson =
          response.data!['routes'] ?? response.data!['data'] ?? [];
      if (routesJson is List && routesJson.isNotEmpty) {
        return routesJson
            .map((r) => BusRouteModel.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    }

    return BusRouteModel.searchRoutes(from, to);
  }
}
