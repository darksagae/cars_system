import 'package:shared_preferences/shared_preferences.dart';
import 'pairing_service.dart';
import 'postgres_service.dart';

/// WhatsApp Message Tracking Service
/// 
/// Tracks sent messages and handles contact forwarding via Neon PostgreSQL
class WhatsAppMessageTrackingService {
  static final WhatsAppMessageTrackingService _instance = WhatsAppMessageTrackingService._internal();
  factory WhatsAppMessageTrackingService() => _instance;
  WhatsAppMessageTrackingService._internal();

  // Keys for SharedPreferences
  static const String _userIdKey = 'whatsapp_user_id';
  static const String _userNameKey = 'whatsapp_user_name';
  static const String _userPhoneKey = 'whatsapp_user_phone';

  // Get machine ID
  Future<String> getMachineId() async {
    final pairingService = PairingService();
    return await pairingService.getOrCreateDeviceId();
  }

  // Get user profile
  Future<Map<String, String?>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_userIdKey),
      'userName': prefs.getString(_userNameKey) ?? 'User',
      'userPhone': prefs.getString(_userPhoneKey),
    };
  }

  // Set user profile
  Future<void> setUserProfile({
    String? userId,
    String? userName,
    String? userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) await prefs.setString(_userIdKey, userId);
    if (userName != null) await prefs.setString(_userNameKey, userName);
    if (userPhone != null) await prefs.setString(_userPhoneKey, userPhone);
    
    // Update machine profile in Neon Postgres
    await updateMachineProfile();
  }

  // Update machine profile in Neon Postgres
  Future<void> updateMachineProfile() async {
    try {
      final machineId = await getMachineId();
      final profile = await getUserProfile();
      
      await PostgresService.execute(
        '''
        INSERT INTO machine_profiles (machine_id, user_id, user_name, user_phone, last_seen, is_active)
        VALUES (@machineId, @userId, @userName, @userPhone, NOW(), true)
        ON CONFLICT (machine_id) DO UPDATE SET
          user_id = EXCLUDED.user_id,
          user_name = EXCLUDED.user_name,
          user_phone = EXCLUDED.user_phone,
          last_seen = NOW(),
          is_active = true;
        ''',
        parameters: {
          'machineId': machineId,
          'userId': profile['userId'],
          'userName': profile['userName'] ?? 'User',
          'userPhone': profile['userPhone'],
        },
      );
    } catch (e) {
      print('Error updating machine profile: $e');
    }
  }

  // Get forwarded contacts for this machine
  Future<List<Map<String, dynamic>>> getForwardedContacts({
    bool unacknowledgedOnly = true,
  }) async {
    try {
      final machineId = await getMachineId();
      
      String query = 'SELECT * FROM whatsapp_contacts WHERE forwarded_to_machine_id = @machineId';
      if (unacknowledgedOnly) {
        query += ' AND acknowledged = false';
      }
      query += ' ORDER BY forwarded_at DESC';

      return await PostgresService.query(query, parameters: {'machineId': machineId});
    } catch (e) {
      print('Error getting forwarded contacts: $e');
      return [];
    }
  }

  // Acknowledge contact (mark as seen)
  Future<void> acknowledgeContact(String contactId) async {
    try {
      await PostgresService.execute(
        '''
        UPDATE whatsapp_contacts
        SET acknowledged = true, acknowledged_at = NOW()
        WHERE id = @id::uuid
        ''',
        parameters: {'id': contactId},
      );
    } catch (e) {
      print('Error acknowledging contact: $e');
    }
  }

  // Mark conversation as started
  Future<void> markConversationStarted(String contactId) async {
    try {
      await PostgresService.execute(
        '''
        UPDATE whatsapp_contacts
        SET conversation_started = true, conversation_started_at = NOW()
        WHERE id = @id::uuid
        ''',
        parameters: {'id': contactId},
      );
    } catch (e) {
      print('Error marking conversation started: $e');
    }
  }

  // Get replies for this machine's clients
  Future<List<Map<String, dynamic>>> getReplies({
    String? clientPhone,
    bool unreadOnly = false,
  }) async {
    try {
      final machineId = await getMachineId();
      
      if (clientPhone != null) {
        String query = 'SELECT * FROM whatsapp_replies WHERE client_phone = @phone';
        if (unreadOnly) {
          query += ' AND read = false'; // if 'read' column exists, otherwise bypass
        }
        query += ' ORDER BY received_at DESC';
        
        return await PostgresService.query(
          query,
          parameters: {'phone': clientPhone},
        );
      } else {
        // Get messages sent by this machine
        final messagesResponse = await PostgresService.query(
          'SELECT DISTINCT client_phone FROM whatsapp_messages WHERE sent_by_machine_id = @machineId',
          parameters: {'machineId': machineId},
        );
        if (messagesResponse.isEmpty) return [];
        final clientPhones = messagesResponse.map((m) => m['client_phone'] as String).toList();
        
        String query = 'SELECT * FROM whatsapp_replies WHERE client_phone = ANY(@phones)';
        if (unreadOnly) {
          query += ' AND read = false';
        }
        query += ' ORDER BY received_at DESC';

        return await PostgresService.query(
          query,
          parameters: {'phones': clientPhones},
        );
      }
    } catch (e) {
      print('Error getting replies: $e');
      return [];
    }
  }

  // Get unread reply count
  Future<int> getUnreadReplyCount() async {
    try {
      final replies = await getReplies(unreadOnly: true);
      return replies.length;
    } catch (e) {
      return 0;
    }
  }
}
