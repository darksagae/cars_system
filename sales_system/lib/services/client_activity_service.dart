import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_command_service.dart';
import 'postgres_service.dart';

/// Service for logging client activities to Neon PostgreSQL
/// This allows the mobile app to see what users are doing on the desktop client
class ClientActivityService {
  static final ClientActivityService _instance = ClientActivityService._internal();
  factory ClientActivityService() => _instance;
  ClientActivityService._internal();

  bool _isInitialized = false;
  final RemoteCommandService _remoteService = RemoteCommandService();

  /// Initialize Postgres connection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _remoteService.initialize();
      _isInitialized = true;
      print('✅ ClientActivityService initialized (Postgres)');
    } catch (e) {
      print('❌ Error initializing ClientActivityService: $e');
    }
  }

  /// Log a user activity to Neon Postgres
  /// This will be visible in the mobile app's activities view
  Future<bool> logActivity({
    required String action,
    String? username,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Get client ID
      final clientId = await _remoteService.getClientId();
      
      // Get current username if not provided
      final currentUsername = username ?? await _getCurrentUsername();

      // Log the activity to Neon Postgres
      await PostgresService.execute(
        '''
        INSERT INTO client_activity (client_id, username, action, metadata, created_at)
        VALUES (@clientId, @username, @action, @metadata::jsonb, NOW())
        ''',
        parameters: {
          'clientId': clientId,
          'username': currentUsername ?? 'unknown',
          'action': action,
          'metadata': jsonEncode(metadata ?? {}),
        },
      );

      print('✅ Activity logged: $action (user: $currentUsername)');
      return true;
    } catch (e) {
      print('❌ Error logging activity: $e');
      return false;
    }
  }

  /// Get current logged-in username (if available)
  Future<String?> _getCurrentUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_username');
    } catch (_) {
      return null;
    }
  }

  /// Helper methods for common activities
  Future<bool> logInvoiceCreated(String invoiceNumber, {String? customerName, double? amount, String? localPdfPath}) async {
    String? pdfUrl;
    
    // Convert PDF to Base64 data URL if local path is provided
    if (localPdfPath != null && localPdfPath.isNotEmpty) {
      try {
        pdfUrl = await _uploadPdfToStorage(localPdfPath, invoiceNumber);
      } catch (e) {
        print('⚠️ Failed to convert PDF to Base64: $e');
      }
    }
    
    return logActivity(
      action: 'create_invoice',
      metadata: {
        'invoice_number': invoiceNumber,
        if (customerName != null) 'customer_name': customerName,
        if (amount != null) 'amount': amount,
        if (localPdfPath != null) 'local_pdf_path': localPdfPath,
        if (pdfUrl != null) 'pdf_url': pdfUrl,
      },
    );
  }

  /// Convert PDF to Base64 data URL (replacing remote bucket storage)
  Future<String?> _uploadPdfToStorage(String localPdfPath, String invoiceNumber) async {
    try {
      final file = File(localPdfPath);
      if (!await file.exists()) {
        print('⚠️ PDF file not found: $localPdfPath');
        return null;
      }

      final pdfBytes = await file.readAsBytes();
      final base64String = base64Encode(pdfBytes);
      return 'data:application/pdf;base64,$base64String';
    } catch (e) {
      print('❌ Error encoding PDF to Base64: $e');
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
