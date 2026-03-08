import '../config/api_config.dart';
import 'api_service.dart';

class PredictionService {
  final ApiService _api = ApiService();

  Future<ApiResponse<Map<String, dynamic>>> predictCrowd({
    required String fromStop,
    required String toStop,
    required String date,
    required String time,
  }) {
    return _api.post(
      ApiConfig.crowdPrediction,
      body: {
        'fromStop': fromStop,
        'toStop': toStop,
        'date': date,
        'time': time,
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
    required String boardingStage,
    required String alightingStage,
  }) {
    return _api.post(
      ApiConfig.fareCalculation,
      body: {
        'boarding_stage': boardingStage,
        'alighting_stage': alightingStage,
      },
    );
  }
}
