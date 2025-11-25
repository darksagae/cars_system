import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_command_service.dart';

/// Service for logging client activities to Supabase
/// This allows the mobile app to see what users are doing on the desktop client
class ClientActivityService {
  static final ClientActivityService _instance = ClientActivityService._internal();
  factory ClientActivityService() => _instance;
  ClientActivityService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;
  final RemoteCommandService _remoteService = RemoteCommandService();

  /// Initialize Supabase connection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize remote service if needed (it will check internally)
      await _remoteService.initialize();
      _client = Supabase.instance.client;
      _isInitialized = true;
      print('✅ ClientActivityService initialized');
    } catch (e) {
      print('❌ Error initializing ClientActivityService: $e');
      // Don't throw - activities can be logged later when connection is ready
    }
  }

  /// Log a user activity to Supabase
  /// This will be visible in the mobile app's activities view
  Future<bool> logActivity({
    required String action,
    String? username,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Initialize if not already done
      if (!_isInitialized) {
        await initialize();
      }

      if (_client == null) {
        print('⚠️ Cannot log activity: Supabase client not initialized');
        return false;
      }

      // Get client ID
      final clientId = await _remoteService.getClientId();
      
      // Get current username if not provided
      final currentUsername = username ?? await _getCurrentUsername();

      // Log the activity
      await _client!.from('client_activity').insert({
        'client_id': clientId,
        'username': currentUsername,
        'action': action,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Activity logged: $action (user: $currentUsername)');
      return true;
    } catch (e) {
      print('❌ Error logging activity: $e');
      // Don't throw - activity logging failures shouldn't break the app
      return false;
    }
  }

  /// Get current logged-in username (if available)
  Future<String?> _getCurrentUsername() async {
    try {
      // Try to get from auth service or shared preferences
      // This is a placeholder - adjust based on your auth implementation
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_username');
    } catch (_) {
      return null;
    }
  }

  /// Helper methods for common activities
  Future<bool> logInvoiceCreated(String invoiceNumber, {String? customerName, double? amount, String? localPdfPath}) async {
    String? pdfUrl;
    
    // Upload PDF to Supabase Storage if local path is provided
    if (localPdfPath != null && localPdfPath.isNotEmpty) {
      try {
        pdfUrl = await _uploadPdfToStorage(localPdfPath, invoiceNumber);
        if (pdfUrl != null) {
          print('✅ Invoice PDF uploaded to Supabase Storage: $pdfUrl');
        }
      } catch (e) {
        print('⚠️ Failed to upload PDF to Supabase Storage: $e');
        // Continue without PDF URL - invoice will still be logged
      }
    }
    
    return logActivity(
      action: 'create_invoice',
      metadata: {
        'invoice_number': invoiceNumber,
        if (customerName != null) 'customer_name': customerName,
        if (amount != null) 'amount': amount,
        if (localPdfPath != null) 'local_pdf_path': localPdfPath,
        if (pdfUrl != null) 'pdf_url': pdfUrl, // Add PDF URL to metadata
      },
    );
  }

  /// Upload PDF to Supabase Storage
  Future<String?> _uploadPdfToStorage(String localPdfPath, String invoiceNumber) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_client == null) {
        print('⚠️ Cannot upload PDF: Supabase client not initialized');
        return null;
      }

      // Read PDF file
      final file = File(localPdfPath);
      if (!await file.exists()) {
        print('⚠️ PDF file not found: $localPdfPath');
        return null;
      }

      final pdfBytes = await file.readAsBytes();

      // Upload to Supabase Storage
      final fileName = 'invoices/${DateTime.now().millisecondsSinceEpoch}_invoice_$invoiceNumber.pdf';
      
      await _client!.storage
          .from('whatsapp_attachments') // Reuse same bucket
          .uploadBinary(
            fileName,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );
      
      // Get public URL
      final url = _client!.storage
          .from('whatsapp_attachments')
          .getPublicUrl(fileName);
      
      return url;
    } catch (e) {
      print('❌ Error uploading PDF to Supabase Storage: $e');
      return null;
    }
  }

  Future<bool> logInvoiceUpdated(String invoiceNumber) async {
    return logActivity(
      action: 'update_invoice',
      metadata: {
        'invoice_number': invoiceNumber,
      },
    );
  }

  Future<bool> logInvoiceDeleted(String invoiceNumber) async {
    return logActivity(
      action: 'delete_invoice',
      metadata: {
        'invoice_number': invoiceNumber,
      },
    );
  }

  Future<bool> logCustomerCreated(String customerName) async {
    return logActivity(
      action: 'create_customer',
      metadata: {
        'customer_name': customerName,
      },
    );
  }

  Future<bool> logCustomerUpdated(String customerName) async {
    return logActivity(
      action: 'update_customer',
      metadata: {
        'customer_name': customerName,
      },
    );
  }

  Future<bool> logCustomerDeleted(String customerName) async {
    return logActivity(
      action: 'delete_customer',
      metadata: {
        'customer_name': customerName,
      },
    );
  }

  Future<bool> logPaymentReceived(String invoiceNumber, double amount) async {
    return logActivity(
      action: 'receive_payment',
      metadata: {
        'invoice_number': invoiceNumber,
        'amount': amount,
      },
    );
  }

  Future<bool> logUserLogin(String username) async {
    return logActivity(
      action: 'user_login',
      username: username,
    );
  }

  Future<bool> logUserLogout(String username) async {
    return logActivity(
      action: 'user_logout',
      username: username,
    );
  }

  Future<bool> logDatabaseRefresh() async {
    return logActivity(
      action: 'refresh_database',
    );
  }

  Future<bool> logExchangeRateUpdate(double rate) async {
    return logActivity(
      action: 'update_exchange_rate',
      metadata: {
        'rate': rate,
      },
    );
  }

  Future<bool> logVehicleCreated(String vehicleName, {String? make, String? model, double? price}) async {
    return logActivity(
      action: 'create_vehicle',
      metadata: {
        'vehicle_name': vehicleName,
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (price != null) 'price': price,
      },
    );
  }

  Future<bool> logVehicleUpdated(String vehicleName) async {
    return logActivity(
      action: 'update_vehicle',
      metadata: {
        'vehicle_name': vehicleName,
      },
    );
  }
}

