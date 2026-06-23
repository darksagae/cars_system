import 'postgres_service.dart';
import 'whatsapp_message_tracking_service.dart';

/// WhatsApp Queue Service
/// 
/// Stores messages in Neon PostgreSQL queue for mobile app to process.
class WhatsAppQueueService {
  static final WhatsAppQueueService _instance = WhatsAppQueueService._internal();
  factory WhatsAppQueueService() => _instance;
  WhatsAppQueueService._internal();

  /// Add message to queue
  Future<String> queueMessage({
    required String phoneNumber,
    required String message,
    String? messageType,
    String? mediaPath, // Base64 Data URI or URL
  }) async {
    try {
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

      // Insert into queue via PostgresService
      final response = await PostgresService.query(
        '''
        INSERT INTO whatsapp_message_queue (phone_number, message_content, message_type, media_path, sent_by_machine_id, sent_by_user_id, sent_by_user_name, status)
        VALUES (@phone, @message, @type, @media, @machineId, @userId, @userName, 'pending')
        RETURNING id
        ''',
        parameters: {
          'phone': formattedNumber,
          'message': message,
          'type': messageType ?? 'message',
          'media': mediaPath,
          'machineId': machineId,
          'userId': userProfile['userId'],
          'userName': userProfile['userName'],
        },
      );

      if (response.isEmpty) {
        throw Exception('Insert returned empty result');
      }

      final queueId = response.first['id'] as String;
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
      final response = await PostgresService.query(
        'SELECT * FROM whatsapp_message_queue WHERE id = @id::uuid LIMIT 1',
        parameters: {'id': queueId},
      );

      if (response.isEmpty) return null;
      return response.first;
    } catch (e) {
      print('Error getting message status: $e');
      return null;
    }
  }

  /// Get pending messages for this machine
  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    try {
      final trackingService = WhatsAppMessageTrackingService();
      final machineId = await trackingService.getMachineId();

      final response = await PostgresService.query(
        'SELECT * FROM whatsapp_message_queue WHERE sent_by_machine_id = @machineId AND status = \'pending\' ORDER BY created_at ASC',
        parameters: {'machineId': machineId},
      );

      return response;
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
