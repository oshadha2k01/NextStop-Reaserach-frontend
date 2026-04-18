import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type';
  static const String _userIdKey = 'user_id';

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.userRegister),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'phoneNumber': phoneNumber,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      final data = _decodeResponseBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? data['error'] ?? 'Registration failed',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.userVerifyOtp),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': otp,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      final data = _decodeResponseBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['token'] is String && (data['token'] as String).isNotEmpty) {
          await saveToken(data['token'] as String);
        }

        final user = data['user'];
        if (user is Map<String, dynamic>) {
          final userId = user['_id'] ?? user['id'];
          if (userId != null) {
            await saveUserId(userId.toString());
          }
        }

        await saveUserType('user');
        await _markRegistered();

        return {
          'success': true,
          'message': data['message'] ?? 'Verification successful',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? data['error'] ?? 'Invalid OTP',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> resendOTP({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.userResendOtp),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConfig.requestTimeout);

      final data = _decodeResponseBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Verification code resent successfully',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? data['error'] ?? 'Failed to resend OTP',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Failed to resend OTP',
      };
    }
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore malformed response bodies and fall through.
    }
    return <String, dynamic>{};
  }

  Future<void> _markRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_registered', true);
    await prefs.setBool('is_driver', false);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUserType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, type);
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, id);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_userIdKey);
  }
}
