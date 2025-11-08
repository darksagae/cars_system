import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  RealtimeChannel? _realtimeChannel;

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
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    print('✅ Background service stopped');
  }

  /// Subscribe to Supabase Realtime for instant notifications
  Future<void> _subscribeToRealtime() async {
    try {
      final supabase = SupabaseService.client;
      
      // Subscribe to inserts on the queue table (filter inside callback)
      _realtimeChannel = supabase
          .channel('whatsapp_queue_background')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'whatsapp_message_queue',
            callback: (payload) async {
              final data = payload.newRecord ?? {};
              if ((data['status'] as String?) == 'pending') {
                print('🔔 New WhatsApp message detected in background!');
                await NotificationService().show('WhatsApp message queued', 'Tap to open and send');
                await processMessageFromBackground(data);
              }
            },
          )
          .subscribe();

      print('✅ Background Realtime subscription active');
    } catch (e) {
      print('⚠️ Error setting up background realtime: $e');
    }
  }

  /// Process a single message from realtime or background
  Future<void> processMessageFromBackground(Map<String, dynamic> messageData) async {
    try {
      final supabase = SupabaseService.client;
      final messageId = messageData['id'] as String;
      final phoneNumber = messageData['phone_number'] as String;
      final messageContent = messageData['message_content'] as String;
      final mediaPath = messageData['media_path'] as String?;

      // Mark as processing
      await supabase
          .from('whatsapp_message_queue')
          .update({
            'status': 'processing',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);

      print('📤 Processing message to $phoneNumber in background...');

      // Send WhatsApp message
      final success = mediaPath != null && mediaPath.isNotEmpty
          ? await _sendWhatsAppWithPDF(phoneNumber, messageContent, mediaPath)
          : await _sendWhatsApp(phoneNumber, messageContent);

      if (success) {
        // Mark as sent
        await supabase
            .from('whatsapp_message_queue')
            .update({
              'status': 'sent',
              'processed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', messageId);

        print('✅ Message sent successfully from background: $messageId');
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
      // Download PDF
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF');
      }

      // Save PDF
      final tempDir = await getTemporaryDirectory();
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(response.bodyBytes);

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

