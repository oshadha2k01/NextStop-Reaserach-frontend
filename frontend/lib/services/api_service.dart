import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/people_count_model.dart';

class ApiService {
  static const String peopleCountUrl = 'https://smartbusstop.me/backend/api/dl/peopleConut';
  
  /// Fetch the latest people count data from the backend
  static Future<PeopleCountModel?> fetchPeopleCount() async {
    try {
      print('🔵 Fetching from: $peopleCountUrl');
      
      final response = await http.get(
        Uri.parse(peopleCountUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle both single object and array responses
        if (data is List && data.isNotEmpty) {
          final model = PeopleCountModel.fromJson(data.first);
          print('✅ Data loaded: in=${model.inCount}, out=${model.outCount}, total=${model.totalPeople}');
          return model;
        } else if (data is Map<String, dynamic>) {
          final model = PeopleCountModel.fromJson(data);
          print('✅ Data loaded: in=${model.inCount}, out=${model.outCount}, total=${model.totalPeople}');
          return model;
        }
      } else {
        print('❌ Error: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      print('❌ Error fetching people count: $e');
      return null;
    }
  }
}
