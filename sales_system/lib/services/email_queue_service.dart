import 'postgres_service.dart';
import 'whatsapp_message_tracking_service.dart';

/// Email Queue Service
/// 
/// Stores emails in Neon PostgreSQL queue for mobile app to process.
class EmailQueueService {
  static final EmailQueueService _instance = EmailQueueService._internal();
  factory EmailQueueService() => _instance;
  EmailQueueService._internal();

  /// Add email to queue
  Future<String> queueEmail({
    required String toEmail,
    required String subject,
    required String body,
    String? pdfUrl, // Base64 or URL
  }) async {
    try {
      // Get machine and user info
      final trackingService = WhatsAppMessageTrackingService();
      final machineId = await trackingService.getMachineId();
      final userProfile = await trackingService.getUserProfile();

      // Insert into queue via PostgresService
      final response = await PostgresService.query(
        '''
        INSERT INTO email_queue (to_email, subject, body, pdf_url, sent_by_machine_id, sent_by_user_id, sent_by_user_name, status)
        VALUES (@toEmail, @subject, @body, @pdfUrl, @sentByMachineId, @sentByUserId, @sentByUserName, 'pending')
        RETURNING id
        ''',
        parameters: {
          'toEmail': toEmail,
          'subject': subject,
          'body': body,
          'pdfUrl': pdfUrl,
          'sentByMachineId': machineId,
          'sentByUserId': userProfile['userId'],
          'sentByUserName': userProfile['userName'],
        },
      );

      if (response.isEmpty) {
        throw Exception('Insert returned empty result');
      }

      final queueId = response.first['id'] as String;
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
      final response = await PostgresService.query(
        'SELECT * FROM email_queue WHERE id = @id::uuid LIMIT 1',
        parameters: {'id': queueId},
      );

      if (response.isEmpty) return null;
      return response.first;
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
