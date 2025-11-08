import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/uganda_formatters.dart';
import 'whatsapp_message_tracking_service.dart';
import 'whatsapp_queue_service.dart';

/// WhatsApp Auto Service
/// 
/// This service uses a Node.js backend (whatsapp-web.js) to send messages automatically.
/// Requires one-time QR code scan during initial setup, then messages send automatically.
class WhatsAppAutoService {
  static final WhatsAppAutoService _instance = WhatsAppAutoService._internal();
  factory WhatsAppAutoService() => _instance;
  WhatsAppAutoService._internal();

  // Service configuration
  static const String _defaultBaseUrl = 'http://localhost:3001';
  static const int _timeoutSeconds = 30;
  
  // Configuration keys for SharedPreferences
  static const String _serverUrlKey = 'whatsapp_server_url';
  static const String _apiKeyKey = 'whatsapp_api_key';
  
  String? _baseUrl;
  String? _apiKey;

  // Company Information
  static const String _companyName = 'NSB Motors Ug';
  static const String _companyPhone = '+25675128406';

  /// Load configuration from SharedPreferences or discover from Supabase
  Future<void> _loadConfig() async {
    if (_baseUrl != null) return; // Already loaded
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString(_serverUrlKey);
      _apiKey = prefs.getString(_apiKeyKey);
      
      // If no URL configured, try to discover from Supabase
      if (_baseUrl == null || _baseUrl == _defaultBaseUrl) {
        await _discoverMobileServer();
      }
      
      // Fallback to default if still not found
      if (_baseUrl == null) {
        _baseUrl = _defaultBaseUrl;
      }
    } catch (e) {
      _baseUrl = _defaultBaseUrl;
    }
  }
  
  /// Discover mobile server from Supabase
  Future<void> _discoverMobileServer() async {
    try {
      // Check if Supabase is initialized
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        print('Supabase not initialized, skipping mobile server discovery');
        return;
      }
      
      if (supabase == null) return;
      
      // Try to get active mobile server from mobile_server_info table
      try {
        final response = await supabase
            .from('mobile_server_info')
            .select('*')
            .eq('is_active', true)
            .order('last_seen', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (response != null && response['mobile_ip'] != null) {
          final ip = response['mobile_ip'] as String;
          final port = response['mobile_port'] as int? ?? 3001;
          _baseUrl = 'http://$ip:$port';
          
          // Save to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_serverUrlKey, _baseUrl!);
          
          print('✅ Discovered mobile server: $_baseUrl');
        }
      } catch (e) {
        print('⚠️ Error discovering mobile server from mobile_server_info: $e');
      }
      
      // Fallback: Try machine_profiles table
      if (_baseUrl == null || _baseUrl == _defaultBaseUrl) {
        try {
          final response = await supabase
              .from('machine_profiles')
              .select('*')
              .eq('machine_id', 'mobile_server')
              .eq('is_active', true)
              .order('last_seen', ascending: false)
              .limit(1)
              .maybeSingle();
          
          // Note: machine_profiles doesn't have IP, so we'd need to store it differently
          // For now, just use this as a signal that mobile server exists
        } catch (e) {
          // Ignore
        }
      }
    } catch (e) {
      print('⚠️ Error discovering mobile server: $e');
    }
  }
  
  /// Get base URL (loads from config if needed)
  Future<String> get baseUrl async {
    await _loadConfig();
    return _baseUrl ?? _defaultBaseUrl;
  }
  
  /// Configure WhatsApp server URL and API key
  Future<void> configureServer({
    required String serverUrl,
    String? apiKey,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverUrlKey, serverUrl);
      if (apiKey != null) {
        await prefs.setString(_apiKeyKey, apiKey);
      }
      _baseUrl = serverUrl;
      _apiKey = apiKey;
    } catch (e) {
      throw Exception('Failed to save WhatsApp server configuration: $e');
    }
  }
  
  /// Get current server configuration
  Future<Map<String, String?>> getServerConfig() async {
    await _loadConfig();
    return {
      'serverUrl': _baseUrl ?? _defaultBaseUrl,
      'apiKey': _apiKey,
    };
  }
  
  /// Get HTTP headers with API key if configured
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      headers['x-api-key'] = _apiKey!;
    }
    return headers;
  }
  
  /// Check if the WhatsApp service is running
  Future<bool> isServiceRunning() async {
    try {
      final url = await baseUrl;
      final response = await http
          .get(Uri.parse('$url/api/health'))
          .timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get WhatsApp client status
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final url = await baseUrl;
      final response = await http
          .get(
            Uri.parse('$url/api/status'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking WhatsApp status: $e');
    }
  }

  /// Get QR code for initial setup
  Future<Map<String, dynamic>> getQRCode() async {
    try {
      final url = await baseUrl;
      final response = await http
          .get(
            Uri.parse('$url/api/qr'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get QR code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting QR code: $e');
    }
  }

  /// Send WhatsApp message automatically
  /// 
  /// Uses Supabase queue - works from anywhere (no WiFi required)
  Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Use queue service (works from anywhere)
      final queueService = WhatsAppQueueService();
      
      // Add message to queue
      final queueId = await queueService.queueMessage(
        phoneNumber: phoneNumber,
        message: message,
        messageType: 'message',
      );
      
      print('✅ Message queued: $queueId');
      print('📱 Mobile app will process this message automatically');
      
      // Wait for processing (optional - can be async)
      try {
        await queueService.waitForProcessing(queueId, timeout: const Duration(seconds: 30));
        return true;
      } catch (e) {
        // Timeout or error - message is still queued, mobile will process it
        print('⚠️ Message queued but not yet processed: $e');
        print('📱 Mobile app will process it when available');
        return true; // Return true as message is queued
      }
    } catch (e) {
      print('Error queueing WhatsApp message: $e');
      throw Exception('Failed to queue WhatsApp message: $e');
    }
  }

  /// Send WhatsApp message with PDF attachment
  /// 
  /// Uses Supabase queue - works from anywhere (no WiFi required)
  /// Uploads PDF to Supabase Storage and stores URL in queue
  /// Tracks sender machine and user information
  Future<bool> sendMessageWithPDF({
    required String phoneNumber,
    required String message,
    required String pdfPath,
    String? messageType, // e.g., 'invoice', 'payment_reminder', 'demand_letter'
  }) async {
    try {
      // Check if PDF file exists
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }

      // Upload PDF to Supabase Storage
      print('📤 Uploading PDF to Supabase Storage...');
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        throw Exception('Supabase not initialized: $e');
      }
      
      if (supabase == null) {
        throw Exception('Supabase client not available');
      }

      // Read PDF file
      final pdfBytes = await file.readAsBytes();
      final fileName = 'whatsapp_pdfs/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      
      // Upload to Supabase Storage
      await supabase.storage
          .from('whatsapp_attachments')
          .uploadBinary(
            fileName,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false, // Don't overwrite - each file is unique
            ),
          );
      
      // Get public URL
      final pdfUrl = supabase.storage
          .from('whatsapp_attachments')
          .getPublicUrl(fileName);
      
      print('✅ PDF uploaded successfully: $pdfUrl');
      
      final queueService = WhatsAppQueueService();
      
      // Get machine and user info for tracking
      final trackingService = WhatsAppMessageTrackingService();
      final machineId = await trackingService.getMachineId();
      final userProfile = await trackingService.getUserProfile();
      
      // Add message to queue with PDF URL and sender info
      final queueId = await queueService.queueMessage(
        phoneNumber: phoneNumber,
        message: message,
        messageType: messageType ?? 'media', // Use provided type or default to 'media'
        mediaPath: pdfUrl, // Store the public URL
      );
      
      print('📝 Message queued by: ${userProfile['userName']} (Machine: $machineId)');
      
      print('✅ Message with PDF queued: $queueId');
      print('📱 Mobile app will process this message automatically');
      
      // Wait for processing
      try {
        await queueService.waitForProcessing(queueId, timeout: const Duration(seconds: 30));
        return true;
      } catch (e) {
        print('⚠️ Message queued but not yet processed: $e');
        return true; // Return true as message is queued
      }
    } catch (e) {
      print('Error queueing WhatsApp message with PDF: $e');
      throw Exception('Failed to queue WhatsApp message with PDF: $e');
    }
  }

  /// Send invoice WhatsApp message
  Future<bool> sendInvoiceMessage({
    required String phoneNumber,
    required String customerName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
    String? companyName,
    String? pdfPath,
    String? messageType,
  }) async {
    final message = _generateInvoiceMessage(
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      totalAmount: totalAmount,
      companyName: companyName ?? _companyName,
    );

    // Get machine and user info for tracking
    final trackingService = WhatsAppMessageTrackingService();
    final machineId = await trackingService.getMachineId();
    final userProfile = await trackingService.getUserProfile();

    if (pdfPath != null && pdfPath.isNotEmpty) {
      // Send with PDF - pass messageType to track it properly
      final success = await sendMessageWithPDF(
        phoneNumber: phoneNumber,
        message: message,
        pdfPath: pdfPath,
        messageType: messageType ?? 'invoice', // Track as invoice
      );
      
      return success;
    } else {
      // Send message via queue
      final queueService = WhatsAppQueueService();
      
      final queueId = await queueService.queueMessage(
        phoneNumber: phoneNumber,
        message: message,
        messageType: messageType ?? 'invoice',
      );
      
      print('✅ Invoice message queued: $queueId');
      
      try {
        await queueService.waitForProcessing(queueId, timeout: const Duration(seconds: 30));
        return true;
      } catch (e) {
        print('⚠️ Message queued but not yet processed: $e');
        return true;
      }
    }
  }

  /// Send payment reminder WhatsApp message
  Future<bool> sendPaymentReminderMessage({
    required String phoneNumber,
    required String customerName,
    required String invoiceNumber,
    required double amount,
    String? companyName,
    String? pdfPath,
    String? messageType,
  }) async {
    final message = _generatePaymentReminderMessage(
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      amount: amount,
      companyName: companyName ?? _companyName,
    );

    // Get machine and user info for tracking
    final trackingService = WhatsAppMessageTrackingService();
    final machineId = await trackingService.getMachineId();
    final userProfile = await trackingService.getUserProfile();

    if (pdfPath != null && pdfPath.isNotEmpty) {
      // Send with PDF - pass messageType to track it properly
      final success = await sendMessageWithPDF(
        phoneNumber: phoneNumber,
        message: message,
        pdfPath: pdfPath,
        messageType: messageType ?? 'payment_reminder', // Track as payment reminder
      );
      
      return success;
    } else {
      // Send message via queue
      final queueService = WhatsAppQueueService();
      
      final queueId = await queueService.queueMessage(
        phoneNumber: phoneNumber,
        message: message,
        messageType: messageType ?? 'reminder',
      );
      
      print('✅ Reminder message queued: $queueId');
      
      try {
        await queueService.waitForProcessing(queueId, timeout: const Duration(seconds: 30));
        return true;
      } catch (e) {
        print('⚠️ Message queued but not yet processed: $e');
        return true;
      }
    }
  }

  /// Restart WhatsApp service
  Future<bool> restartService() async {
    try {
      final url = await baseUrl;
      final response = await http
          .post(
            Uri.parse('$url/api/restart'),
            headers: _getHeaders(),
          )
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        return result['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error restarting WhatsApp service: $e');
      return false;
    }
  }

  /// Start the Node.js WhatsApp service (if not running)
  Future<bool> startService() async {
    try {
      // Check if already running
      if (await isServiceRunning()) {
        return true;
      }

      // Try to start the service
      // This would require running the Node.js service
      // For now, we'll just check if it's running
      // The user should start it manually or via a script
      throw Exception(
          'WhatsApp service is not running. Please start it using: cd whatsapp_service && npm start');
    } catch (e) {
      throw Exception('Failed to start WhatsApp service: $e');
    }
  }

  /// Generate invoice message
  String _generateInvoiceMessage({
    required String customerName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
    required String companyName,
  }) {
    return '''
🏢 *$companyName*
📄 *Invoice $invoiceNumber*

Dear $customerName,

Your invoice is ready for payment:
💰 Amount: ${UgandaFormatters.formatCurrency(totalAmount)}
📅 Date: $invoiceDate

Thank you for your business!

💳 *Payment Options:*
• Bank Transfer
• Mobile Money (MTN/Airtel)
• Cash Payment

Payment is due within 30 days.

For any questions, please contact us at $_companyPhone.

Best regards,
$companyName Team
    '''.trim();
  }

  /// Generate payment reminder message
  String _generatePaymentReminderMessage({
    required String customerName,
    required String invoiceNumber,
    required double amount,
    required String companyName,
  }) {
    return '''
🏢 *$companyName*
⏰ *Payment Reminder*

Dear $customerName,

Friendly reminder about your invoice:
📄 Invoice: $invoiceNumber
💰 Outstanding Amount: ${UgandaFormatters.formatCurrency(amount)}

This is a friendly reminder that payment is now overdue.

💳 *Payment Options:*
• Bank Transfer
• Mobile Money (MTN/Airtel)
• Cash Payment

Please arrange payment at your earliest convenience.

If you've already paid, please contact us at $_companyPhone to update our records.

Thank you for your prompt attention.

Best regards,
$companyName Team
    '''.trim();
  }

  /// Format phone number for WhatsApp
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Add Uganda country code if not present
    if (digitsOnly.startsWith('0')) {
      digitsOnly = '256' + digitsOnly.substring(1);
    } else if (!digitsOnly.startsWith('256')) {
      digitsOnly = '256' + digitsOnly;
    }

    return digitsOnly;
  }
}

