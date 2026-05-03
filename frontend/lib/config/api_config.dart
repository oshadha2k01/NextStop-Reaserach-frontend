class ApiConfig {
  static const String baseUrl = 'https://smartbusstop.me/backend/api';
  static const String socketUrl = 'https://smartbusstop.me/backend';
  static const Duration requestTimeout = Duration(seconds: 15);

  // Auth endpoints
  static const String driverLogin = '$baseUrl/drivers/login';
  static const String driverRegister = '$baseUrl/drivers/register';
  static const String passengerRegister = '$baseUrl/passengers/register';
  static const String verifyOtp = '$baseUrl/drivers/verify-otp';
  static const String resendOtp = '$baseUrl/drivers/resend-otp';
  static const String userRegister = '$baseUrl/user-register/register';
  static const String userVerifyOtp = '$baseUrl/user-register/verify-otp';
  static const String userResendOtp = '$baseUrl/user-register/resend-otp';

  // Route endpoints
  static const String routes = '$baseUrl/routes';
  static const String iotEta = '$baseUrl/eta';
  
  // National routes (map/search/list) endpoints
  static const String nationalRoutesBase = '$baseUrl/national-routes';
  static const String nationalRoutesSearch = '$nationalRoutesBase/search';
  static const String nationalRoutesFilter = '$nationalRoutesBase/filter';
  static const String nationalRouteById = '$nationalRoutesBase/';

  // Bus endpoints
  static const String buses = '$baseUrl/buses';
  static const String busDevice = '$baseUrl/bus-device';

  // Prediction endpoints (ML)
  static const String crowdPrediction = '$baseUrl/predict/route-predict';
  static const String destinationPrediction = '$baseUrl/destination/predict';

  // Fare endpoint
  static const String fareCalculation = '$baseUrl/fare/calculate';

  // Notifications
  static const String notify = '$baseUrl/notify/board';

  // Dashboard
  static const String dashboard = '$baseUrl/dashboard';
}
