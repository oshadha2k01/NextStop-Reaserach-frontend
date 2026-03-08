import '../config/api_config.dart';
import 'api_service.dart';

class PredictionService {
  final ApiService _api = ApiService();

  Future<ApiResponse<Map<String, dynamic>>> predictCrowd({
    required String routeName,
    required String date,
    required String time,
    String? fromStop,
    String? toStop,
  }) {
    return _api.post(
      ApiConfig.crowdPrediction,
      body: {
        'route': routeName,
        'date': date,
        'time': time,
        if (fromStop != null) 'from': fromStop,
        if (toStop != null) 'to': toStop,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> predictDestination({
    required String route,
    required String boardingLocation,
    required String destinationLocation,
    required int userExpectedTime,
  }) {
    return _api.post(
      ApiConfig.destinationPrediction,
      body: {
        'route': route,
        'boardingLocation': boardingLocation,
        'destinationLocation': destinationLocation,
        'userExpectedTime': userExpectedTime,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> calculateFare({
    required String from,
    required String to,
    String? routeName,
  }) {
    return _api.post(
      ApiConfig.fareCalculation,
      body: {
        'from': from,
        'to': to,
        if (routeName != null) 'route': routeName,
      },
    );
  }
}
