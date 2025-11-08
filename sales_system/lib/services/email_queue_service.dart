import 'package:supabase_flutter/supabase_flutter.dart';
import 'whatsapp_message_tracking_service.dart';

/// Email Queue Service
/// 
/// Stores emails in Supabase queue for mobile app to process.
/// Works from anywhere - no SMTP required!
class EmailQueueService {
  static final EmailQueueService _instance = EmailQueueService._internal();
  factory EmailQueueService() => _instance;
  EmailQueueService._internal();

  /// Add email to queue
  Future<String> queueEmail({
    required String toEmail,
    required String subject,
    required String body,
    String? pdfUrl, // Supabase Storage URL
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

      // Insert into queue
      final response = await supabase
          .from('email_queue')
          .insert({
            'to_email': toEmail,
            'subject': subject,
            'body': body,
            'pdf_url': pdfUrl,
            'sent_by_machine_id': machineId,
            'sent_by_user_id': userProfile['userId'],
            'sent_by_user_name': userProfile['userName'],
            'status': 'pending',
          })
          .select('id')
          .single();

      final queueId = response['id'] as String;
      print('✅ Email queued successfully: $queueId');
      print('📱 Mobile app will process this email automatically');
      
      return queueId;
    } catch (e) {
      print('❌ Error queueing email: $e');
      throw Exception('Failed to queue email: $e');
    }
  }

  /// Check email status
  Future<Map<String, dynamic>?> getEmailStatus(String queueId) async {
    try {
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        return null;
      }
      
      if (supabase == null) return null;

      final response = await supabase
          .from('email_queue')
          .select('*')
          .eq('id', queueId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting email status: $e');
      return null;
    }
  }

  /// Wait for email to be processed (with timeout)
  Future<bool> waitForProcessing(
    String queueId, {
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final status = await getEmailStatus(queueId);
      
      if (status == null) {
        await Future.delayed(pollInterval);
        continue;
      }
      
      final emailStatus = status['status'] as String?;
      
      if (emailStatus == 'sent') {
        return true;
      } else if (emailStatus == 'failed') {
        final error = status['error_message'] as String?;
        throw Exception('Email processing failed: $error');
      }
      
      // Still pending or processing
      await Future.delayed(pollInterval);
    }
    
    throw Exception('Email processing timeout');
  }
}


