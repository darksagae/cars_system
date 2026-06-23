import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to fetch current date from internet APIs
/// Provides fallback to local date if internet is unavailable
class DateService {
  static const String _worldTimeApiUrl = 'http://worldtimeapi.org/api/timezone/Africa/Kampala';
  static const String _timeApiUrl = 'http://timeapi.io/api/Time/current/zone?timeZone=Africa/Kampala';
  
  /// Fetch current date from internet with fallback to local date
  static Future<DateTime> getCurrentDate() async {
    try {
      // Try WorldTime API first
      final response = await http.get(
        Uri.parse(_worldTimeApiUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dateTimeString = data['datetime'] as String;
        final dateTime = DateTime.parse(dateTimeString);
        return dateTime;
      }
    } catch (e) {
      print('WorldTime API failed: $e');
    }
    
    try {
      // Try Time API as fallback
      final response = await http.get(
        Uri.parse(_timeApiUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dateTimeString = data['dateTime'] as String;
        final dateTime = DateTime.parse(dateTimeString);
        return dateTime;
      }
    } catch (e) {
      print('Time API failed: $e');
    }
    
    // Fallback to local date
    print('Using local date as fallback');
    return DateTime.now();
  }
  
  /// Get current date with specific timezone offset
  static Future<DateTime> getCurrentDateWithTimezone() async {
    final dateTime = await getCurrentDate();
    // Ensure we're working with Uganda time (UTC+3)
    return dateTime.toUtc().add(const Duration(hours: 3));
  }
  
  /// Check if internet date is available
  static Future<bool> isInternetDateAvailable() async {
    try {
      final response = await http.get(
        Uri.parse(_worldTimeApiUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

