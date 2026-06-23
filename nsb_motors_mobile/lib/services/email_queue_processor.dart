import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'notification_preferences_service.dart';

/// Email Queue Processor
/// 
/// Polls Supabase for pending emails and processes them.
/// Opens email client with PDF attachment or link.
class EmailQueueProcessor {
  static final EmailQueueProcessor _instance = EmailQueueProcessor._internal();
  factory EmailQueueProcessor() => _instance;
  EmailQueueProcessor._internal();

  Timer? _pollTimer;
  bool _isRunning = false;
  final NotificationPreferencesService _prefsService = NotificationPreferencesService();

  /// Start processing email queue with realtime notifications
  void start({Duration pollInterval = const Duration(seconds: 10)}) {
    if (_isRunning) {
      print('⚠️ Email queue processor already running');
      return;
    }

    _isRunning = true;
    print('📧 Starting email queue processor...');

    // Process immediately
    _processQueue();

    // Then poll periodically (fallback if realtime fails)
    _pollTimer = Timer.periodic(pollInterval, (_) {
      _processQueue();
    });

    // Subscribe to realtime changes for instant notifications
    _subscribeToRealtime();
  }

  /// Subscribe to Supabase Realtime (Disabled, relying on polling)
  void _subscribeToRealtime() {
    print('🔌 Email realtime bypassed. Polling active.');
  }

  /// Stop processing email queue
  void stop() {
    _isRunning = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    print('🛑 Email queue processor stopped');
  }

  /// Check if processor is running
  bool get isRunning => _isRunning;

  /// Process pending emails from queue
  Future<void> _processQueue() async {
    if (!_isRunning) return;

    try {
      // Get pending emails
      final response = await SupabaseService.getPendingEmailMessages(limit: 1);

      if (response.isEmpty) {
        return; // No pending emails
      }

      final email = response.first;
      final emailId = email['id'] as String;
      final toEmail = email['to_email'] as String;
      final subject = email['subject'] as String;
      final body = email['body'] as String;
      final pdfUrl = email['pdf_url'] as String?;

      print('📧 Processing email to $toEmail...');
      
      // Note: Notifications are shown via realtime subscription
      // This polling method is just a fallback for processing

      // Mark as processing
      await SupabaseService.updateEmailQueueStatus(emailId, 'processing');

      // Send email (with PDF if provided)
      final success = pdfUrl != null && pdfUrl.isNotEmpty
          ? await _sendEmailWithPDF(toEmail, subject, body, pdfUrl)
          : await _sendEmail(toEmail, subject, body);

      if (success) {
        // Mark as sent
        await SupabaseService.updateEmailQueueStatus(emailId, 'sent');

        // Store in email_messages table for tracking
        await _storeInMessagesTable(email);

        print('✅ Email sent successfully: $emailId');
      } else {
        // Mark as failed
        await SupabaseService.updateEmailQueueStatus(emailId, 'failed', errorMessage: 'Failed to open email client');

        print('❌ Failed to send email: $emailId');
      }
    } catch (e) {
      print('❌ Error processing email queue: $e');
    }
  }

  /// Send email using mailto URL (no attachment)
  Future<bool> _sendEmail(String toEmail, String subject, String body) async {
    try {
      // Create mailto URL
      final emailUri = Uri(
        scheme: 'mailto',
        path: toEmail,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        print('✅ Email client opened for $toEmail');
        return true;
      } else {
        print('❌ Cannot launch email URL');
        return false;
      }
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }

  /// Send email with PDF attachment
  /// Downloads PDF from URL and shares via share_plus
  Future<bool> _sendEmailWithPDF(
    String toEmail,
    String subject,
    String body,
    String pdfUrl,
  ) async {
    try {
      // Download PDF from URL or decode Base64 data URI
      Uint8List bytes;
      if (pdfUrl.startsWith('data:')) {
        final base64String = pdfUrl.substring(pdfUrl.indexOf(',') + 1);
        bytes = base64.decode(base64String);
      } else {
        final response = await http.get(Uri.parse(pdfUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
        }
        bytes = response.bodyBytes;
      }

      // Save PDF to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(bytes);
      
      print('✅ PDF downloaded and saved: ${pdfFile.path}');

      // Use share_plus to share PDF to email app
      // This will open the share sheet with email apps as options
      final result = await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')],
        text: '$subject\n\n$body',
        subject: subject,
      );

      print('✅ PDF shared via email share sheet');
      
      // Clean up temporary file after a delay (give time for email app to access it)
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
      print('❌ Error sending email with PDF: $e');
      return false;
    }
  }

  /// Store email in email_messages table for tracking
  Future<void> _storeInMessagesTable(Map<String, dynamic> queueEmail) async {
    try {
      await SupabaseService.storeEmailMessage(queueEmail);
      print('✅ Email stored in email_messages table');
    } catch (e) {
      print('⚠️ Error storing email in email_messages: $e');
      // Non-critical, continue
    }
  }
}


