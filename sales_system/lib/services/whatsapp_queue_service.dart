import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'whatsapp_message_tracking_service.dart';

/// WhatsApp Queue Service
/// 
/// Stores messages in Supabase queue for mobile app to process.
/// Works from anywhere - no WiFi requirement!
class WhatsAppQueueService {
  static final WhatsAppQueueService _instance = WhatsAppQueueService._internal();
  factory WhatsAppQueueService() => _instance;
  WhatsAppQueueService._internal();

  /// Add message to queue
  Future<String> queueMessage({
    required String phoneNumber,
    required String message,
    String? messageType,
    String? mediaPath,
  }) async {
    try {
      // Check if Supabase is initialized
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        throw Exception('Supabase not initialized: $e');
      }
      
      if (supabase == null) {
        throw Exception('Supabase client not available');
      }

      // Get machine and user info
      final trackingService = WhatsAppMessageTrackingService();
      final machineId = await trackingService.getMachineId();
      final userProfile = await trackingService.getUserProfile();

      // Format phone number
      String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (formattedNumber.startsWith('0')) {
        formattedNumber = '256${formattedNumber.substring(1)}';
      } else if (!formattedNumber.startsWith('256')) {
        formattedNumber = '256$formattedNumber';
      }

      // Insert into queue
      final response = await supabase
          .from('whatsapp_message_queue')
          .insert({
            'phone_number': formattedNumber,
            'message_content': message,
            'message_type': messageType ?? 'message',
            'media_path': mediaPath,
            'sent_by_machine_id': machineId,
            'sent_by_user_id': userProfile['userId'],
            'sent_by_user_name': userProfile['userName'],
            'status': 'pending',
          })
          .select('id')
          .single();

      final queueId = response['id'] as String;
      print('✅ Message queued successfully: $queueId');
      
      return queueId;
    } catch (e) {
      print('❌ Error queueing message: $e');
      throw Exception('Failed to queue message: $e');
    }
  }

  /// Check message status
  Future<Map<String, dynamic>?> getMessageStatus(String queueId) async {
    try {
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        return null;
      }
      
      if (supabase == null) return null;

      final response = await supabase
          .from('whatsapp_message_queue')
          .select('*')
          .eq('id', queueId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting message status: $e');
      return null;
    }
  }

  /// Get pending messages for this machine
  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    try {
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        return [];
      }
      
      if (supabase == null) return [];

      final trackingService = WhatsAppMessageTrackingService();
      final machineId = await trackingService.getMachineId();

      final response = await supabase
          .from('whatsapp_message_queue')
          .select('*')
          .eq('sent_by_machine_id', machineId)
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pending messages: $e');
      return [];
    }
  }

  /// Wait for message to be processed (with timeout)
  Future<bool> waitForProcessing(
    String queueId, {
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final status = await getMessageStatus(queueId);
      
      if (status == null) {
        await Future.delayed(pollInterval);
        continue;
      }
      
      final messageStatus = status['status'] as String?;
      
      if (messageStatus == 'sent') {
        return true;
      } else if (messageStatus == 'failed') {
        final error = status['error_message'] as String?;
        throw Exception('Message processing failed: $error');
      }
      
      // Still pending or processing
      await Future.delayed(pollInterval);
    }
    
    throw Exception('Message processing timeout');
  }
}





