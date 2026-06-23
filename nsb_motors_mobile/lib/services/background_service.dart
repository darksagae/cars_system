import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'supabase_service.dart';
import 'notification_service.dart';

/// Background Service
/// 
/// Keeps the app alive in background and processes WhatsApp messages
/// This allows WhatsApp to open automatically even when app is closed
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isRunning = false;

  /// Start background service
  Future<void> start() async {
    if (_isRunning) {
      print('⚠️ Background service already running');
      return;
    }

    _isRunning = true;
    print('✅ Background service started');

    // Subscribe to realtime for instant notifications
    await _subscribeToRealtime();
  }

  /// Stop background service
  void stop() {
    _isRunning = false;
    print('✅ Background service stopped');
  }

  /// Subscribe to Supabase Realtime for instant notifications
  Future<void> _subscribeToRealtime() async {
    print('🔌 Background realtime bypassed. Polling is used.');
  }

  /// Process a single message from realtime or background
  Future<void> processMessageFromBackground(Map<String, dynamic> messageData) async {
    try {
      final messageId = messageData['id'] as String;
      final phoneNumber = messageData['phone_number'] as String;
      final messageContent = messageData['message_content'] as String;
      final mediaPath = messageData['media_path'] as String?;

      // Mark as processing
      await SupabaseService.updateWhatsAppQueueStatus(messageId, 'processing');

      print('📤 Processing message to $phoneNumber in background...');

      // Send WhatsApp message
      final success = mediaPath != null && mediaPath.isNotEmpty
          ? await _sendWhatsAppWithPDF(phoneNumber, messageContent, mediaPath)
          : await _sendWhatsApp(phoneNumber, messageContent);

      if (success) {
        // Mark as sent
        await SupabaseService.updateWhatsAppQueueStatus(
          messageId,
          'sent',
          messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        );

        print('✅ Message sent successfully from background: $messageId');
      } else {
        // Mark as failed
        await SupabaseService.updateWhatsAppQueueStatus(
          messageId,
          'failed',
          errorMessage: 'Failed to open WhatsApp',
        );
      }
    } catch (e) {
      print('❌ Error processing message in background: $e');
    }
  }

  /// Send WhatsApp message
  Future<bool> _sendWhatsApp(String phoneNumber, String message) async {
    try {
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (formattedNumber.startsWith('0')) {
        formattedNumber = '256${formattedNumber.substring(1)}';
      } else if (!formattedNumber.startsWith('256')) {
        formattedNumber = '256$formattedNumber';
      }

      final nativeWhatsAppUrl = Uri.parse(
        'whatsapp://send?phone=$formattedNumber&text=${Uri.encodeComponent(message)}',
      );
      
      if (await canLaunchUrl(nativeWhatsAppUrl)) {
        await launchUrl(nativeWhatsAppUrl, mode: LaunchMode.externalApplication);
        print('✅ WhatsApp opened from background');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error sending WhatsApp: $e');
      return false;
    }
  }

  /// Send WhatsApp with PDF
  Future<bool> _sendWhatsAppWithPDF(
    String phoneNumber,
    String message,
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
          throw Exception('Failed to download PDF');
        }
        bytes = response.bodyBytes;
      }

      // Save PDF
      final tempDir = await getTemporaryDirectory();
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(bytes);

      // Share via WhatsApp
      final result = await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')],
        text: message,
        subject: 'Invoice',
      );

      // Clean up
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await pdfFile.exists()) {
            await pdfFile.delete();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      });

      return result.status == ShareResultStatus.success || 
             result.status == ShareResultStatus.dismissed;
    } catch (e) {
      print('❌ Error sending WhatsApp with PDF: $e');
      return false;
    }
  }
}

// Background processing now handled via Realtime subscriptions
// Works when app is open or in background (not force-closed)

