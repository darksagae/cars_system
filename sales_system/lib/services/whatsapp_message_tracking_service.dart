import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pairing_service.dart';

/// WhatsApp Message Tracking Service
/// 
/// Tracks sent messages and handles contact forwarding via Supabase
class WhatsAppMessageTrackingService {
  static final WhatsAppMessageTrackingService _instance = WhatsAppMessageTrackingService._internal();
  factory WhatsAppMessageTrackingService() => _instance;
  WhatsAppMessageTrackingService._internal();

  // Keys for SharedPreferences
  static const String _userIdKey = 'whatsapp_user_id';
  static const String _userNameKey = 'whatsapp_user_name';
  static const String _userPhoneKey = 'whatsapp_user_phone';

  // Get machine ID (use the same ID as the pairing service for consistency)
  Future<String> getMachineId() async {
    // Use the same client ID as the pairing service to ensure consistency
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
    
    // Update machine profile in Supabase
    await updateMachineProfile();
  }

  // Update machine profile in Supabase
  Future<void> updateMachineProfile() async {
    try {
      final machineId = await getMachineId();
      final profile = await getUserProfile();
      
      // Check if Supabase is initialized
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        // Supabase not initialized, skip update
        print('Supabase not initialized, skipping machine profile update');
        return;
      }
      
      // Upsert machine profile
      if (supabase != null) {
        await supabase.from('machine_profiles').upsert({
        'machine_id': machineId,
        'user_id': profile['userId'],
        'user_name': profile['userName'],
        'user_phone': profile['userPhone'],
        'last_seen': DateTime.now().toIso8601String(),
        'is_active': true,
        });
      }
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
      
      // Check if Supabase is initialized
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        print('Supabase not initialized');
        return [];
      }
      
      if (supabase == null) return [];
      
      var queryBuilder = supabase!
          .from('whatsapp_contacts')
          .select('*')
          .eq('forwarded_to_machine_id', machineId);
      
      if (unacknowledgedOnly) {
        queryBuilder = queryBuilder.eq('acknowledged', false);
      }
      
      final response = await queryBuilder.order('forwarded_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting forwarded contacts: $e');
      return [];
    }
  }

  // Acknowledge contact (mark as seen)
  Future<void> acknowledgeContact(String contactId) async {
    try {
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        print('Supabase not initialized');
        return;
      }
      if (supabase == null) return;
      
      await supabase
          .from('whatsapp_contacts')
          .update({
            'acknowledged': true,
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contactId);
    } catch (e) {
      print('Error acknowledging contact: $e');
    }
  }

  // Mark conversation as started
  Future<void> markConversationStarted(String contactId) async {
    try {
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        print('Supabase not initialized');
        return;
      }
      if (supabase == null) return;
      
      await supabase
          .from('whatsapp_contacts')
          .update({
            'conversation_started': true,
            'conversation_started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contactId);
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
      
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        print('Supabase not initialized');
        return [];
      }
      if (supabase == null) return [];
      
      // Get messages sent by this machine
      final messagesResponse = await supabase!
          .from('whatsapp_messages')
          .select('client_phone')
          .eq('sent_by_machine_id', machineId);
      
      if (messagesResponse.isEmpty) return [];
      
      final clientPhones = messagesResponse.map((m) => m['client_phone'] as String).toSet();
      
      // Get replies for these clients
      // Use 'or' with multiple 'eq' calls instead of 'in_'
      var repliesQueryBuilder = supabase!
          .from('whatsapp_replies')
          .select('*');
      
      if (clientPhone != null) {
        repliesQueryBuilder = repliesQueryBuilder.eq('client_phone', clientPhone);
      } else if (clientPhones.isNotEmpty) {
        // Build OR condition for multiple phone numbers
        final orConditions = clientPhones.map((phone) => 'client_phone.eq.$phone').join(',');
        repliesQueryBuilder = repliesQueryBuilder.or(orConditions);
      }
      
      final replies = await repliesQueryBuilder.order('received_at', ascending: false);
      return List<Map<String, dynamic>>.from(replies);
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
