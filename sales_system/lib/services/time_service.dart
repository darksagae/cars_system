import 'dart:convert';
import 'package:http/http.dart' as http;

class TimeService {
  static final TimeService _instance = TimeService._internal();
  factory TimeService() => _instance;
  TimeService._internal();

  // Get current time from internet
  Future<DateTime> getInternetTime() async {
    try {
      // Try multiple time servers for reliability
      final timeServers = [
        'http://worldtimeapi.org/api/timezone/Africa/Kampala',
        'http://worldtimeapi.org/api/timezone/UTC',
        'https://timeapi.io/api/Time/current/zone?timeZone=Africa/Kampala',
      ];

      for (String server in timeServers) {
        try {
          final response = await http.get(Uri.parse(server)).timeout(
            const Duration(seconds: 5),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            // Parse different response formats
            String? dateTimeString;
            if (data['datetime'] != null) {
              dateTimeString = data['datetime'];
            } else if (data['utc_datetime'] != null) {
              dateTimeString = data['utc_datetime'];
            } else if (data['currentDateTime'] != null) {
              dateTimeString = data['currentDateTime'];
            }
            
            if (dateTimeString != null) {
              // Remove timezone info and parse
              String cleanDateTime = dateTimeString.split('.')[0];
              if (cleanDateTime.contains('+')) {
                cleanDateTime = cleanDateTime.split('+')[0];
              }
              if (cleanDateTime.contains('Z')) {
                cleanDateTime = cleanDateTime.replaceAll('Z', '');
              }
              
              return DateTime.parse(cleanDateTime);
            }
          }
        } catch (e) {
          // Try next server
          continue;
        }
      }
      
      // If all servers fail, return system time
      return DateTime.now();
    } catch (e) {
      // Fallback to system time
      return DateTime.now();
    }
  }

  // Get Uganda time specifically
  Future<DateTime> getUgandaTime() async {
    try {
      final response = await http.get(
        Uri.parse('http://worldtimeapi.org/api/timezone/Africa/Kampala'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dateTimeString = data['datetime'];
        
        if (dateTimeString != null) {
          // Remove timezone info and parse
          String cleanDateTime = dateTimeString.split('.')[0];
          if (cleanDateTime.contains('+')) {
            cleanDateTime = cleanDateTime.split('+')[0];
          }
          
          return DateTime.parse(cleanDateTime);
        }
      }
    } catch (e) {
      // Fallback to system time
    }
    
    return DateTime.now();
  }

  // Format date for display
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Format date and time for display
  String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
