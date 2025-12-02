import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'notification_preferences_service.dart';
import 'local_database_service.dart';

/// WhatsApp Queue Processor
/// 
/// Polls Supabase for pending messages and processes them.
/// Runs automatically in the background.
class WhatsAppQueueProcessor {
  static final WhatsAppQueueProcessor _instance = WhatsAppQueueProcessor._internal();
  factory WhatsAppQueueProcessor() => _instance;
  WhatsAppQueueProcessor._internal();

  Timer? _pollTimer;
  bool _isProcessing = false;
  bool _isRunning = false;
  RealtimeChannel? _realtimeChannel;
  final NotificationPreferencesService _prefsService = NotificationPreferencesService();

  bool get isRunning => _isRunning;

  /// Start processing queue with realtime notifications
  void start({Duration pollInterval = const Duration(seconds: 5)}) {
    if (_isRunning) {
      print('⚠️ Queue processor already running');
      return;
    }

    _isRunning = true;
    print('✅ WhatsApp queue processor started');

    // Process immediately
    _processQueue();

    // Then poll every N seconds
    _pollTimer = Timer.periodic(pollInterval, (_) {
      _processQueue();
    });

    // Subscribe to realtime changes for instant notifications
    _subscribeToRealtime();
  }

  /// Subscribe to Supabase Realtime for instant notifications
  void _subscribeToRealtime() {
    try {
      final supabase = SupabaseService.client;
      
      // Subscribe to all inserts on the queue table and filter in callback
      _realtimeChannel = supabase
          .channel('whatsapp_queue_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'whatsapp_message_queue',
            callback: (payload) async {
              try {
                final data = payload.newRecord ?? {};
                if ((data['status'] as String?) == 'pending') {
                  print('🔔 New WhatsApp message detected via Realtime!');
                  
                  // Check if push notifications are enabled before showing
                  if (_prefsService.shouldShowNotification()) {
                    await NotificationService().show('WhatsApp message queued', 'Tap to open and send');
                  } else {
                    print('📵 Push notifications disabled - skipping notification');
                  }
                  
                  _processQueue();
                }
              } catch (e) {
                print('⚠️ Realtime callback error: $e');
              }
            },
          )
          .subscribe();

      print('✅ Realtime subscription active - instant notifications enabled');
    } catch (e) {
      print('⚠️ Error setting up realtime subscription: $e');
      // Continue with polling if realtime fails
    }
  }

  /// Stop processing queue
  void stop() {
    _isRunning = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    
    // Unsubscribe from realtime
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    
    print('✅ WhatsApp queue processor stopped');
  }

  /// Static method for background processing (called by WorkManager)
  /// This can run even when the app is closed
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback() async {
    print('🔄 Background WhatsApp queue processing started');
    
    try {
      // Initialize Supabase if needed
      // Note: This might need to be done differently in background isolate
      final processor = WhatsAppQueueProcessor();
      await processor._processQueue();
      
      print('✅ Background processing completed');
    } catch (e) {
      print('❌ Error in background processing: $e');
    }
  }

  /// Process pending messages from queue
  Future<void> _processQueue() async {
    if (_isProcessing) {
      return; // Already processing
    }

    _isProcessing = true;

    try {
      final supabase = SupabaseService.client;

      // Get pending messages
      final response = await supabase
          .from('whatsapp_message_queue')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .limit(10); // Process up to 10 at a time

      final messages = List<Map<String, dynamic>>.from(response);

      if (messages.isEmpty) {
        _isProcessing = false;
        return;
      }

      print('📬 Found ${messages.length} pending message(s) to process');

      // Process each message
      for (final message in messages) {
        await _processMessage(message);
      }
    } catch (e) {
      print('❌ Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single message
  Future<void> _processMessage(Map<String, dynamic> message) async {
    final messageId = message['id'] as String;
    final phoneNumber = message['phone_number'] as String;
    final messageContent = message['message_content'] as String;
    final mediaPath = message['media_path'] as String?;

    try {
      final supabase = SupabaseService.client;

      // Mark as processing
      await supabase
          .from('whatsapp_message_queue')
          .update({
            'status': 'processing',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);

      print('📤 Processing message to $phoneNumber...');

      // Send WhatsApp message (with PDF if mediaPath is provided)
      final success = mediaPath != null && mediaPath.isNotEmpty
          ? await _sendWhatsAppMessageWithPDF(phoneNumber, messageContent, mediaPath)
          : await _sendWhatsAppMessage(phoneNumber, messageContent);

      if (success) {
        // Mark as sent
        await supabase
            .from('whatsapp_message_queue')
            .update({
              'status': 'sent',
              'processed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'message_id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
            })
            .eq('id', messageId);

        // Also store in whatsapp_messages table for tracking
        await _storeInMessagesTable(message);
        
        // Save invoice locally if it's an invoice message
        await _saveInvoiceLocally(message, mediaPath);

        print('✅ Message sent successfully: $messageId');
      } else {
        // Mark as failed
        await supabase
            .from('whatsapp_message_queue')
            .update({
              'status': 'failed',
              'error_message': 'Failed to open WhatsApp',
              'processed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', messageId);

        print('❌ Failed to send message: $messageId');
      }
    } catch (e) {
      print('❌ Error processing message $messageId: $e');

      // Mark as failed
      try {
        await SupabaseService.client
            .from('whatsapp_message_queue')
            .update({
              'status': 'failed',
              'error_message': e.toString(),
              'processed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', messageId);
      } catch (updateError) {
        print('❌ Error updating message status: $updateError');
      }
    }
  }

  /// Send WhatsApp message using URL launcher
  /// Opens native WhatsApp app on mobile, not WhatsApp Web
  Future<bool> _sendWhatsAppMessage(String phoneNumber, String message) async {
    try {
      // Format phone number
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      
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

  /// Send WhatsApp message with PDF attachment
  /// Downloads PDF from URL and shares it via share_plus
  Future<bool> _sendWhatsAppMessageWithPDF(
    String phoneNumber,
    String message,
    String pdfUrl,
  ) async {
    try {
      print('📥 Downloading PDF from: $pdfUrl');
      
      // Download PDF from URL
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }

      // Save PDF to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(response.bodyBytes);
      
      print('✅ PDF downloaded and saved: ${pdfFile.path}');

      // Format phone number
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (formattedNumber.startsWith('0')) {
        formattedNumber = '256${formattedNumber.substring(1)}';
      } else if (!formattedNumber.startsWith('256')) {
        formattedNumber = '256$formattedNumber';
      }

      // Use share_plus to share PDF to WhatsApp
      // This will open the share sheet with WhatsApp as an option
      final result = await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')],
        text: message,
        subject: 'Invoice',
      );

      print('✅ PDF shared via WhatsApp share sheet');
      
      // Clean up temporary file after a delay (give time for WhatsApp to access it)
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await pdfFile.exists()) {
            await pdfFile.delete();
            print('🗑️ Temporary PDF file deleted');
          }
        } catch (e) {
          print('⚠️ Error deleting temporary file: $e');
        }
      });

      return result.status == ShareResultStatus.success || 
             result.status == ShareResultStatus.dismissed;
    } catch (e) {
      print('❌ Error sending WhatsApp message with PDF: $e');
      return false;
    }
  }

  /// Store message in whatsapp_messages table for tracking
  Future<void> _storeInMessagesTable(Map<String, dynamic> queueMessage) async {
    try {
      final supabase = SupabaseService.client;

      await supabase.from('whatsapp_messages').insert({
        'message_id': queueMessage['message_id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'client_phone': queueMessage['phone_number'],
        'message_content': queueMessage['message_content'],
        'message_type': queueMessage['message_type'] ?? 'message',
        'sent_by_machine_id': queueMessage['sent_by_machine_id'],
        'sent_by_user_id': queueMessage['sent_by_user_id'],
        'sent_by_user_name': queueMessage['sent_by_user_name'],
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'sent',
      });

      print('✅ Message stored in whatsapp_messages table');
    } catch (e) {
      print('⚠️ Error storing message in whatsapp_messages: $e');
      // Non-critical, continue
    }
  }
  
  /// Save invoice locally if it's an invoice message
  Future<void> _saveInvoiceLocally(Map<String, dynamic> message, String? mediaPath) async {
    try {
      // Check if this is an invoice message
      final messageType = message['message_type'] as String?;
      if (messageType != 'invoice') {
        return; // Not an invoice, nothing to save
      }
      
      // Extract invoice information from message content
      final messageContent = message['message_content'] as String;
      final invoiceNumber = _extractInvoiceNumber(messageContent);
      final customerName = _extractCustomerName(messageContent);
      final totalAmount = _extractTotalAmount(messageContent);
      final invoiceDate = _extractInvoiceDate(messageContent);
      
      if (invoiceNumber.isEmpty) {
        print('⚠️ Could not extract invoice information, skipping local save');
        return;
      }
      
      // Download and save PDF permanently if mediaPath is provided
      String? localPdfPath;
      if (mediaPath != null && mediaPath.isNotEmpty) {
        localPdfPath = await _downloadAndSavePdf(mediaPath, invoiceNumber);
      }
      
      // Save to local database
      final localDb = LocalDatabaseService();
      final result = await localDb.saveInvoice(
        supabaseId: message['id'] as String,
        clientId: message['sent_by_machine_id'] as String? ?? 'unknown',
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        customerPhone: message['phone_number'] as String,
        totalAmount: totalAmount,
        invoiceDate: invoiceDate,
        status: 'sent',
        pdfUrl: mediaPath,
        localPdfPath: localPdfPath,
        sentAt: DateTime.now().toIso8601String(),
      );
      
      print('✅ Invoice saved locally with ID: $result');
    } catch (e) {
      print('⚠️ Error saving invoice locally: $e');
    }
  }
  
  /// Download and save PDF permanently to local storage
  Future<String?> _downloadAndSavePdf(String pdfUrl, String invoiceNumber) async {
    try {
      print('📥 Downloading PDF for permanent storage: $pdfUrl');
      
      // Download PDF from URL
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }

      // Save PDF to application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'invoice_${invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File('${appDir.path}/$fileName');
      await pdfFile.writeAsBytes(response.bodyBytes);
      
      print('✅ PDF permanently saved: ${pdfFile.path}');
      return pdfFile.path;
    } catch (e) {
      print('❌ Error downloading and saving PDF: $e');
      return null;
    }
  }
  
  /// Extract invoice number from message content
  String _extractInvoiceNumber(String messageContent) {
    // Look for patterns like "Invoice No: INV-001" or "INV-001"
    final invoiceRegex = RegExp(r'(?:Invoice\s*(?:No\.?|Number)[:\s]*)([A-Z0-9\-]+)', caseSensitive: false);
    final match = invoiceRegex.firstMatch(messageContent);
    if (match != null) {
      return match.group(1) ?? '';
    }
    
    // Fallback: look for any pattern like INV-001
    final fallbackRegex = RegExp(r'\b([A-Z]{3,}-\d{3,})\b');
    final fallbackMatch = fallbackRegex.firstMatch(messageContent);
    return fallbackMatch?.group(1) ?? '';
  }
  
  /// Extract customer name from message content
  String _extractCustomerName(String messageContent) {
    // Look for patterns like "Dear John Doe" or "Customer: John Doe"
    final customerRegex = RegExp(r'(?:Dear|Customer|Client)[:\s]*([A-Za-z\s]+?)(?:,|\n|$)', caseSensitive: false);
    final match = customerRegex.firstMatch(messageContent);
    if (match != null) {
      return match.group(1)?.trim() ?? 'Unknown Customer';
    }
    
    // Fallback: return generic name
    return 'Customer';
  }
  
  /// Extract total amount from message content
  double _extractTotalAmount(String messageContent) {
    // Look for patterns like "Total: UGX 1,000,000" or "UGX 1,000,000"
    final amountRegex = RegExp(r'(?:Total[:\s]*)?[Uu][Gg][Xx][\s:]*([0-9,]+(?:\.[0-9]{2})?)');
    final match = amountRegex.firstMatch(messageContent);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
      return double.tryParse(amountStr) ?? 0.0;
    }
    
    // Fallback: look for any number pattern
    final fallbackRegex = RegExp(r'[\d,]+(?:\.\d{2})?');
    final fallbackMatch = fallbackRegex.firstMatch(messageContent);
    if (fallbackMatch != null) {
      final amountStr = fallbackMatch.group(0)?.replaceAll(',', '') ?? '0';
      return double.tryParse(amountStr) ?? 0.0;
    }
    
    return 0.0;
  }
  
  /// Extract invoice date from message content
  String _extractInvoiceDate(String messageContent) {
    // Look for date patterns like "Date: 2025-01-15" or "2025-01-15"
    final dateRegex = RegExp(r'(?:Date[:\s]*)?(\d{4}-\d{2}-\d{2})');
    final match = dateRegex.firstMatch(messageContent);
    if (match != null) {
      return match.group(1) ?? DateTime.now().toIso8601String();
    }
    
    // Fallback: return current date
    return DateTime.now().toIso8601String();
  }
}