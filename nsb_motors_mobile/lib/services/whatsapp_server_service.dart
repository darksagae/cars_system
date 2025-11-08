import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// WhatsApp HTTP Server Service
/// 
/// Runs an HTTP server inside the mobile app to receive requests from desktop machines.
/// Desktop machines send messages via HTTP, and this service handles them.
class WhatsAppServerService {
  static final WhatsAppServerService _instance = WhatsAppServerService._internal();
  factory WhatsAppServerService() => _instance;
  WhatsAppServerService._internal();

  HttpServer? _server;
  bool _isRunning = false;
  int _port = 3001;
  String? _serverIp;
  String? _apiKey;

  bool get isRunning => _isRunning;
  int get port => _port;
  String? get serverIp => _serverIp;
  String? get serverUrl => _serverIp != null ? 'http://$_serverIp:$_port' : null;

  /// Start the HTTP server
  Future<bool> start({int? port, String? apiKey}) async {
    if (_isRunning) {
      print('⚠️ WhatsApp server is already running');
      return true;
    }

    try {
      _port = port ?? 3001;
      _apiKey = apiKey;

      // Get local IP address
      _serverIp = await _getLocalIpAddress();
      if (_serverIp == null) {
        print('❌ Could not determine local IP address');
        return false;
      }

      // Create router
      final router = shelf_router.Router();

      // Middleware for CORS
      final corsMiddleware = _createCorsMiddleware();

      // Middleware for API key authentication (if provided)
      final authMiddleware = _apiKey != null ? _createAuthMiddleware() : null;

      // API routes
      router.get('/api/status', (Request request) async {
        return Response.ok(
          json.encode({
            'success': true,
            'ready': true,
            'status': 'ready',
            'server_ip': _serverIp,
            'port': _port,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      });

      router.post('/api/send', (Request request) async {
        try {
          final body = await request.readAsString();
          final data = json.decode(body) as Map<String, dynamic>;

          final phoneNumber = data['phoneNumber'] as String?;
          final message = data['message'] as String?;
          final messageType = data['messageType'] as String? ?? 'message';
          final sentByMachineId = data['sentByMachineId'] as String? ?? 'unknown';
          final sentByUserId = data['sentByUserId'] as String?;
          final sentByUserName = data['sentByUserName'] as String?;

          if (phoneNumber == null || message == null) {
            return Response.badRequest(
              body: json.encode({
                'success': false,
                'error': 'Phone number and message are required',
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }

          // Send WhatsApp message
          final success = await _sendWhatsAppMessage(phoneNumber, message);

          if (success) {
            // Store in Supabase
            await _storeMessageInSupabase(
              phoneNumber: phoneNumber,
              message: message,
              messageType: messageType,
              sentByMachineId: sentByMachineId,
              sentByUserId: sentByUserId,
              sentByUserName: sentByUserName,
            );

            // Update mobile server info in Supabase
            await _updateMobileServerInfo();

            return Response.ok(
              json.encode({
                'success': true,
                'message': 'Message sent successfully',
                'note': 'Please manually click send in WhatsApp',
              }),
              headers: {'Content-Type': 'application/json'},
            );
          } else {
            return Response.internalServerError(
              body: json.encode({
                'success': false,
                'error': 'Failed to open WhatsApp',
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }
        } catch (e) {
          print('❌ Error handling /api/send: $e');
          return Response.internalServerError(
            body: json.encode({
              'success': false,
              'error': e.toString(),
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      });

      router.post('/api/send-media', (Request request) async {
        try {
          final body = await request.readAsString();
          final data = json.decode(body) as Map<String, dynamic>;

          final phoneNumber = data['phoneNumber'] as String?;
          final message = data['message'] as String?;
          final mediaPath = data['mediaPath'] as String?;
          final messageType = data['messageType'] as String? ?? 'media';
          final sentByMachineId = data['sentByMachineId'] as String? ?? 'unknown';
          final sentByUserId = data['sentByUserId'] as String?;
          final sentByUserName = data['sentByUserName'] as String?;

          if (phoneNumber == null || mediaPath == null) {
            return Response.badRequest(
              body: json.encode({
                'success': false,
                'error': 'Phone number and media path are required',
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }

          // For now, we'll send the message with media path info
          // Note: File transfer from desktop to mobile needs to be handled separately
          final messageWithMedia = message ?? 'Media: $mediaPath';
          final success = await _sendWhatsAppMessage(phoneNumber, messageWithMedia);

          if (success) {
            // Store in Supabase
            await _storeMessageInSupabase(
              phoneNumber: phoneNumber,
              message: messageWithMedia,
              messageType: messageType,
              sentByMachineId: sentByMachineId,
              sentByUserId: sentByUserId,
              sentByUserName: sentByUserName,
            );

            return Response.ok(
              json.encode({
                'success': true,
                'message': 'Media message sent successfully',
                'note': 'Please manually click send in WhatsApp',
              }),
              headers: {'Content-Type': 'application/json'},
            );
          } else {
            return Response.internalServerError(
              body: json.encode({
                'success': false,
                'error': 'Failed to open WhatsApp',
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }
        } catch (e) {
          print('❌ Error handling /api/send-media: $e');
          return Response.internalServerError(
            body: json.encode({
              'success': false,
              'error': e.toString(),
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }
      });

      // Build handler with middleware
      Handler handler = router;
      if (authMiddleware != null) {
        handler = Pipeline().addMiddleware(authMiddleware).addHandler(handler);
      }
      handler = Pipeline().addMiddleware(corsMiddleware).addHandler(handler);

      // Start server
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4, // Listen on all interfaces
        _port,
      );

      _isRunning = true;

      print('✅ WhatsApp HTTP Server started');
      print('   IP: $_serverIp');
      print('   Port: $_port');
      print('   URL: http://$_serverIp:$_port');

      // Update mobile server info in Supabase
      await _updateMobileServerInfo();

      return true;
    } catch (e) {
      print('❌ Error starting WhatsApp server: $e');
      _isRunning = false;
      return false;
    }
  }

  /// Stop the HTTP server
  Future<void> stop() async {
    if (!_isRunning) return;

    try {
      await _server?.close(force: true);
      _server = null;
      _isRunning = false;
      print('✅ WhatsApp HTTP Server stopped');

      // Clear mobile server info from Supabase
      await _clearMobileServerInfo();
    } catch (e) {
      print('❌ Error stopping WhatsApp server: $e');
    }
  }

  /// Send WhatsApp message using URL launcher
  Future<bool> _sendWhatsAppMessage(String phoneNumber, String message) async {
    try {
      // Format phone number
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      
      // Add country code if needed (assuming Uganda +256)
      if (formattedNumber.startsWith('0')) {
        formattedNumber = '256${formattedNumber.substring(1)}';
      } else if (!formattedNumber.startsWith('256')) {
        formattedNumber = '256$formattedNumber';
      }

      // Try native WhatsApp app first (whatsapp:// protocol)
      Uri? whatsappUrl;
      
      // Try whatsapp:// protocol (native app)
      final nativeWhatsAppUrl = Uri.parse(
        'whatsapp://send?phone=$formattedNumber&text=${Uri.encodeComponent(message)}',
      );
      
      if (await canLaunchUrl(nativeWhatsAppUrl)) {
        whatsappUrl = nativeWhatsAppUrl;
        print('✅ Using native WhatsApp app');
      } else {
        // Fallback to https://wa.me (may open WhatsApp Web)
        whatsappUrl = Uri.parse(
          'https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}',
        );
        print('⚠️ Native WhatsApp not available, using web URL');
      }

      // Launch WhatsApp
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl, 
          mode: LaunchMode.externalApplication,
        );
        print('✅ WhatsApp opened for $formattedNumber');
        return true;
      } else {
        print('❌ Cannot launch WhatsApp URL');
        return false;
      }
    } catch (e) {
      print('❌ Error sending WhatsApp message: $e');
      return false;
    }
  }

  /// Store message in Supabase
  Future<void> _storeMessageInSupabase({
    required String phoneNumber,
    required String message,
    required String messageType,
    required String sentByMachineId,
    String? sentByUserId,
    String? sentByUserName,
  }) async {
    try {
      final supabase = SupabaseService.client;
      
      // Format phone number
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (formattedNumber.startsWith('0')) {
        formattedNumber = '256${formattedNumber.substring(1)}';
      } else if (!formattedNumber.startsWith('256')) {
        formattedNumber = '256$formattedNumber';
      }

      await supabase.from('whatsapp_messages').insert({
        'message_id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'client_phone': formattedNumber,
        'message_content': message,
        'message_type': messageType,
        'sent_by_machine_id': sentByMachineId,
        'sent_by_user_id': sentByUserId,
        'sent_by_user_name': sentByUserName,
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'sent',
      });

      print('✅ Message stored in Supabase');
    } catch (e) {
      print('❌ Error storing message in Supabase: $e');
      // Don't throw - non-critical
    }
  }

  /// Get local IP address
  Future<String?> _getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            // Prefer WiFi addresses (usually starts with 192.168 or 10.0)
            if (addr.address.startsWith('192.168.') || 
                addr.address.startsWith('10.0.') ||
                addr.address.startsWith('172.')) {
              return addr.address;
            }
          }
        }
      }
      
      // If no WiFi IP found, return first non-loopback IPv4
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting local IP: $e');
      return null;
    }
  }

  /// Update mobile server info in Supabase
  Future<void> _updateMobileServerInfo() async {
    try {
      final supabase = SupabaseService.client;
      final user = SupabaseService.currentUser;
      
      if (user == null) return;

      // Store in machine_profiles with special marker
      await supabase.from('machine_profiles').upsert({
        'machine_id': 'mobile_server_${user.id}',
        'machine_name': 'Mobile Server (Admin)',
        'user_id': user.id,
        'user_email': user.email,
        'is_active': _isRunning,
        'last_seen': DateTime.now().toIso8601String(),
        // Store server info in custom fields (we'll add these to table)
      });

      // Also store in a dedicated table if it exists
      try {
        await supabase.from('mobile_server_info').upsert({
          'id': user.id,
          'mobile_ip': _serverIp,
          'mobile_port': _port,
          'last_seen': DateTime.now().toIso8601String(),
          'is_active': _isRunning,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Table might not exist yet, that's OK
        print('⚠️ mobile_server_info table not found, using machine_profiles: $e');
      }
    } catch (e) {
      print('❌ Error updating mobile server info: $e');
    }
  }

  /// Clear mobile server info from Supabase
  Future<void> _clearMobileServerInfo() async {
    try {
      final supabase = SupabaseService.client;
      final user = SupabaseService.currentUser;
      
      if (user == null) return;

      await supabase.from('machine_profiles').update({
        'is_active': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('machine_id', 'mobile_server_${user.id}');

      try {
        await supabase.from('mobile_server_info').update({
          'is_active': false,
          'last_seen': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      } catch (e) {
        // Ignore - table might not exist
        print('⚠️ Error updating mobile_server_info: $e');
      }
    } catch (e) {
      print('❌ Error clearing mobile server info: $e');
    }
  }

  /// Create CORS middleware
  Middleware _createCorsMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
            'Access-Control-Max-Age': '86400',
          });
        }
        return null;
      },
      responseHandler: (Response response) {
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
        });
      },
    );
  }

  /// Create API key authentication middleware
  Middleware _createAuthMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return innerHandler(request);
        }

        final apiKey = request.headers['x-api-key'] ?? 
                      request.headers['authorization']?.replaceFirst('Bearer ', '') ??
                      request.url.queryParameters['api_key'];

        if (apiKey != _apiKey) {
          return Response.forbidden(
            json.encode({
              'success': false,
              'error': 'Invalid API key',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }

        return innerHandler(request);
      };
    };
  }
}

