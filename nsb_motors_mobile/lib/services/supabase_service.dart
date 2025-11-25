import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Authentication
  static Session? get currentSession {
    try {
      return client.auth.currentSession;
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }
  
  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
  
  static bool get isAuthenticated {
    final session = currentSession;
    if (session == null) return false;
    // Check if session is expired
    if (session.expiresAt != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      if (expiresAt.isBefore(DateTime.now())) {
        print('⚠️ Session expired');
        return false;
      }
    }
    return true;
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Desktop Client Management
  static Future<List<Map<String, dynamic>>> getDesktopClients() async {
    try {
      // Use .select() with explicit column list to avoid caching issues
      // Add a timestamp to force fresh data fetch
      final response = await client
          .from('desktop_clients')
          .select('*')
          .or('status.eq.pending_pairing,status.eq.approved,status.eq.active')
          .order('last_seen', ascending: false);
      
      final clients = List<Map<String, dynamic>>.from(response);
      print('📡 Fetched ${clients.length} desktop clients from Supabase');
      if (clients.isNotEmpty) {
        print('   Latest client: ${clients.first['client_name']} - last_seen: ${clients.first['last_seen']}');
      }
      return clients;
    } catch (e) {
      print('❌ Error fetching desktop clients: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDesktopClient(String clientId) async {
    try {
      final response = await client
          .from('desktop_clients')
          .select('*')
          .eq('client_id', clientId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching desktop client: $e');
      return null;
    }
  }

  static Future<bool> registerDesktopClient({
    required String clientId,
    required String clientName,
    required String version,
    required String platform,
    required String ipAddress,
  }) async {
    try {
      await client.from('desktop_clients').upsert({
        'client_id': clientId,
        'client_name': clientName,
        'version': version,
        'platform': platform,
        'ip_address': ipAddress,
        'last_seen': DateTime.now().toIso8601String(),
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error registering desktop client: $e');
      return false;
    }
  }

  // Approve pairing from mobile admin: set status=approved, assign client_name
  static Future<bool> approveDesktopClient({
    required String deviceId,
    required String clientName,
  }) async {
    try {
      await client.from('desktop_clients').upsert({
        'client_id': deviceId,
        'client_name': clientName,
        'status': 'approved',
      });
      return true;
    } catch (e) {
      print('❌ Error approving desktop client: $e');
      return false;
    }
  }

  // Desktop client users management (admin view)
  static Future<List<Map<String, dynamic>>> getClientUsers(String clientId) async {
    try {
      final res = await client
          .from('desktop_client_users')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('❌ Error fetching client users: $e');
      return [];
    }
  }

  static Future<bool> upsertClientUser({
    required String clientId,
    required String username,
    required String passwordHash,
    String role = 'user',
  }) async {
    try {
      await client.rpc('upsert_client_user', params: {
        'p_client_id': clientId,
        'p_username': username,
        'p_password_hash': passwordHash,
        'p_role': role,
      });
      return true;
    } catch (e) {
      print('❌ Error upserting client user: $e');
      return false;
    }
  }

  // Optional maintenance: remove or archive old clients
  static Future<int> deleteAllDesktopClients() async {
    try {
      final resp = await client.from('desktop_clients').delete().neq('client_id', '');
      if (resp is List) return resp.length;
      return 0;
    } catch (e) {
      print('❌ Error deleting clients: $e');
      return 0;
    }
  }

  // Delete a single desktop client by id
  static Future<bool> deleteDesktopClient(String clientId) async {
    try {
      // Hard delete row
      await client
          .from('desktop_clients')
          .delete()
          .eq('client_id', clientId)
          .select();
      return true;
    } catch (e) {
      print('❌ Error deleting desktop client $clientId: $e');
      return false;
    }
  }

  static Future<bool> updateClientStatus(String clientId, String status) async {
    try {
      await client
          .from('desktop_clients')
          .update({
            'status': status,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('client_id', clientId);
      
      return true;
    } catch (e) {
      print('Error updating client status: $e');
      return false;
    }
  }

  // URA Database Management
  static Future<List<Map<String, dynamic>>> getUraDatabaseUpdates() async {
    try {
      // Query without cache - force fresh data
      final response = await client
          .from('ura_database_updates')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);
      
      final updates = List<Map<String, dynamic>>.from(response);
      print('📋 Fetched ${updates.length} URA database updates from Supabase');
      if (updates.isNotEmpty) {
        print('   Latest: ${updates.first['month']} - ${updates.first['file_name']}');
      }
      return updates;
    } catch (e) {
      print('❌ Error fetching URA database updates: $e');
      return [];
    }
  }

  static Future<bool> createUraDatabaseUpdate({
    required String month,
    required String fileName,
    required int recordCount,
    required String fileUrl,
  }) async {
    try {
      print('💾 Creating URA database update record...');
      print('   Month: $month');
      print('   File: $fileName');
      print('   URL: $fileUrl');
      
      await client.from('ura_database_updates').insert({
        'month': month,
        'file_name': fileName,
        'record_count': recordCount,
        'file_url': fileUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ URA database update record created successfully!');
      return true;
    } catch (e) {
      print('Error creating URA database update: $e');
      return false;
    }
  }

  // Exchange Rate Management (dual rates: tax and phase1)
  static Future<Map<String, dynamic>?> getCurrentExchangeRate() async {
    try {
      final response = await client
          .from('exchange_rates')
          .select('*')
          .eq('is_current', true)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching current exchange rate: $e');
      return null;
    }
  }

  static Future<bool> updateExchangeRate({
    required double rate,
    required String source,
    double? phase1Rate,
  }) async {
    try {
      // Mark all rates as not current
      await client
          .from('exchange_rates')
          .update({'is_current': false})
          .eq('is_current', true);
      
      // Insert new rate(s)
      await client.from('exchange_rates').insert({
        'rate': rate,
        'phase1_rate': phase1Rate ?? rate, // Use tax rate as default if phase1 not provided
        'source': source,
        'effective_date': DateTime.now().toIso8601String(),
        'is_current': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error updating exchange rate: $e');
      return false;
    }
  }

  // Remote Control
  static Future<bool> sendRemoteCommand({
    required String clientId,
    required String command,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      print('📤 Sending remote command: $command to client: $clientId');
      
      // Route via Edge Function (runs with service role), requires authenticated caller
      final response = await client.functions.invoke('enqueue_remote_command',
        body: {
          'client_id': clientId,
          'command': command,
          'parameters': parameters ?? {},
        },
      );
      
      print('📥 Edge Function response: status=${response.status}, data=${response.data}');
      
      // functions_client.FunctionResponse has no `error` getter; use status
      if (response.status >= 400) {
        final errorMsg = 'Function error ${response.status}: ${response.data}';
        print('❌ $errorMsg');
        throw Exception(errorMsg);
      }
      
      if (response.data != null && response.data['ok'] == true) {
        print('✅ Command queued successfully: ${response.data['command']}');
        return true;
      }
      
      print('⚠️ Unexpected response format: ${response.data}');
      return false;
    } catch (e) {
      print('❌ Error sending remote command: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getRemoteCommands(
    String clientId, {
    Duration? timeFilter,
    int? limit,
  }) async {
    try {
      var queryBuilder = client
          .from('remote_commands')
          .select('*')
          .eq('client_id', clientId);
      
      // Apply time filter if provided (e.g., last 24 hours, last 7 days)
      if (timeFilter != null) {
        final cutoffTime = DateTime.now().subtract(timeFilter).toIso8601String();
        queryBuilder = queryBuilder.gte('created_at', cutoffTime);
      }
      
      // Chain order and limit
      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit ?? 50);
      
      // Ensure strong typing of map entries
      final List<Map<String, dynamic>> typed = [];
      for (var item in response as List) {
        try {
          final mapItem = item as Map<dynamic, dynamic>;
          final parameters = mapItem['parameters'];
          if (parameters != null && parameters is Map) {
            // Convert parameters to proper type
            mapItem['parameters'] = Map<String, dynamic>.from(parameters as Map<dynamic, dynamic>);
          } else if (parameters != null) {
            print('⚠️ Unexpected parameters type: ${parameters.runtimeType} - $parameters');
            mapItem['parameters'] = <String, dynamic>{};
          } else {
            mapItem['parameters'] = <String, dynamic>{};
          }
          typed.add(Map<String, dynamic>.from(mapItem));
        } catch (itemError, stackTrace) {
          print('❌ Error processing remote command item: $itemError');
          print('   Item data: $item');
          print('   Stack trace: $stackTrace');
        }
      }
      
      return typed;
    } catch (e, stackTrace) {
      print('Error fetching remote commands: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
  
  // Get client activities (user actions from desktop client)
  static Future<List<Map<String, dynamic>>> getClientActivities(
    String clientId, {
    Duration? timeFilter,
    int? limit,
  }) async {
    try {
      var queryBuilder = client
          .from('client_activity')
          .select('*')
          .eq('client_id', clientId);
      
      // Apply time filter if provided
      if (timeFilter != null) {
        final cutoffTime = DateTime.now().subtract(timeFilter).toIso8601String();
        queryBuilder = queryBuilder.gte('created_at', cutoffTime);
      }
      
      // Chain order and limit
      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit ?? 50);
      
      // Ensure strong typing of map entries
      final List<Map<String, dynamic>> typed = [];
      for (var item in response as List) {
        try {
          final mapItem = item as Map<dynamic, dynamic>;
          final metadata = mapItem['metadata'];
          if (metadata != null && metadata is Map) {
            // Convert metadata to proper type
            mapItem['metadata'] = Map<String, dynamic>.from(metadata as Map<dynamic, dynamic>);
          } else if (metadata != null) {
            print('⚠️ Unexpected metadata type: ${metadata.runtimeType} - $metadata');
            mapItem['metadata'] = <String, dynamic>{};
          } else {
            mapItem['metadata'] = <String, dynamic>{};
          }
          typed.add(Map<String, dynamic>.from(mapItem));
        } catch (itemError, stackTrace) {
          print('❌ Error processing client activity item: $itemError');
          print('   Item data: $item');
          print('   Stack trace: $stackTrace');
        }
      }
      
      return typed;
    } catch (e, stackTrace) {
      print('Error fetching client activities: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
  
  // Get WhatsApp messages sent to clients
  static Future<List<Map<String, dynamic>>> getWhatsAppMessages(
    String clientId, {
    Duration? timeFilter,
    int? limit,
  }) async {
    try {
      var queryBuilder = client
          .from('whatsapp_messages')
          .select('*')
          .eq('sent_by_machine_id', clientId);
      
      // Apply time filter if provided
      if (timeFilter != null) {
        final cutoffTime = DateTime.now().subtract(timeFilter).toIso8601String();
        queryBuilder = queryBuilder.gte('sent_at', cutoffTime);
      }
      
      // Chain order and limit
      final response = await queryBuilder
          .order('sent_at', ascending: false)
          .limit(limit ?? 50);
      
      // Ensure strong typing of map entries
      final List<Map<String, dynamic>> typed = [];
      for (var item in response as List) {
        try {
          final mapItem = item as Map<dynamic, dynamic>;
          typed.add(Map<String, dynamic>.from(mapItem));
        } catch (itemError, stackTrace) {
          print('❌ Error processing WhatsApp message item: $itemError');
          print('   Item data: $item');
          print('   Stack trace: $stackTrace');
        }
      }
      
      print('📱 Found ${typed.length} WhatsApp messages for client $clientId');
      if (typed.isNotEmpty) {
        print('   Sample message: ${typed.first}');
      }
      
      return typed;
    } catch (e, stackTrace) {
      print('Error fetching WhatsApp messages: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get unified activities from remote_commands, client_activity, and whatsapp_messages
  static Future<List<Map<String, dynamic>>> getRecentActivities(
    String clientId, {
    Duration timeFilter = const Duration(days: 7),
    int limit = 50,
  }) async {
    try {
      print('📊 Fetching unified activities for client: $clientId');
      
      // Fetch from all tables in parallel
      print('📊 Fetching remote commands...');
      final remoteCommands = await getRemoteCommands(
        clientId,
        timeFilter: timeFilter,
        limit: limit,
      );
      print('✅ Got ${remoteCommands.length} remote commands');
      
      print('📊 Fetching client activities...');
      final clientActivities = await getClientActivities(
        clientId,
        timeFilter: timeFilter,
        limit: limit,
      );
      print('✅ Got ${clientActivities.length} client activities');
      
      print('📊 Fetching WhatsApp messages...');
      final whatsappMessages = await getWhatsAppMessages(
        clientId,
        timeFilter: timeFilter,
        limit: limit,
      );
      print('✅ Got ${whatsappMessages.length} WhatsApp messages');
      
      print('📊 Unified activities for client $clientId:');
      print('   Remote commands: ${remoteCommands.length}');
      print('   Client activities: ${clientActivities.length}');
      print('   WhatsApp messages: ${whatsappMessages.length}');
      
      // Combine and transform all lists into a unified format
      final List<Map<String, dynamic>> unifiedActivities = [];
      
      // Add remote commands (commands sent from mobile to desktop)
      print('📊 Processing remote commands...');
      for (int i = 0; i < remoteCommands.length; i++) {
        try {
          final cmd = remoteCommands[i];
          print('   Processing remote command $i: ${cmd['command']}');
          unifiedActivities.add({
            'type': 'remote_command', // Command sent from mobile
            'id': cmd['id'],
            'client_id': cmd['client_id'],
            'action': cmd['command'],
            'command': cmd['command'],
            'status': cmd['status'] ?? 'pending',
            'parameters': cmd['parameters'] ?? {},
            'metadata': {
              'started_at': cmd['started_at'],
              'completed_at': cmd['completed_at'],
              'error_message': cmd['error_message'],
              'result_summary': cmd['result_summary'],
            },
            'created_at': cmd['created_at'],
            'username': null, // Remote commands don't have username
          });
        } catch (e, stackTrace) {
          print('❌ Error processing remote command at index $i: $e');
          print('   Stack trace: $stackTrace');
        }
      }
      
      // Add client activities (user actions on desktop)
      print('📊 Processing client activities...');
      for (int i = 0; i < clientActivities.length; i++) {
        try {
          final activity = clientActivities[i];
          print('   Processing client activity $i: ${activity['action']}');
          unifiedActivities.add({
            'type': 'client_activity', // User action on desktop
            'id': activity['id'],
            'client_id': activity['client_id'],
            'action': activity['action'],
            'command': activity['action'], // For compatibility
            'status': 'completed', // Client activities are always completed
            'parameters': {},
            'metadata': activity['metadata'] ?? {},
            'created_at': activity['created_at'],
            'username': activity['username'],
          });
        } catch (e, stackTrace) {
          print('❌ Error processing client activity at index $i: $e');
          print('   Stack trace: $stackTrace');
        }
      }
      
      // Add WhatsApp messages (invoices sent to clients)
      print('📊 Processing WhatsApp messages...');
      for (int i = 0; i < whatsappMessages.length; i++) {
        try {
          final message = whatsappMessages[i];
          print('   Processing WhatsApp message $i: ${message['message_type']}');
          unifiedActivities.add({
            'type': 'whatsapp_message', // WhatsApp message sent
            'id': message['id'],
            'client_id': message['sent_by_machine_id'],
            'action': 'send_invoice',
            'command': 'send_invoice',
            'status': message['status'] ?? 'sent',
            'parameters': {},
            'metadata': {
              'client_phone': message['client_phone'],
              'message_type': message['message_type'],
              'message_content': message['message_content'],
              'sent_by_user_name': message['sent_by_user_name'],
            },
            'created_at': message['sent_at'],
            'username': message['sent_by_user_name'],
          });
        } catch (e, stackTrace) {
          print('❌ Error processing WhatsApp message at index $i: $e');
          print('   Stack trace: $stackTrace');
        }
      }
      
      print('📊 Sorting ${unifiedActivities.length} unified activities...');
      
      // Sort by created_at descending (most recent first)
      unifiedActivities.sort((a, b) {
        final aTime = a['created_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? '';
        if (aTime.isEmpty && bTime.isEmpty) return 0;
        if (aTime.isEmpty) return 1;
        if (bTime.isEmpty) return -1;
        try {
          return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
        } catch (e) {
          print('❌ Error sorting activities by date: $e');
          return 0;
        }
      });
      
      // Limit to requested number
      final result = unifiedActivities.take(limit).toList();
      print('   Total unified activities: ${result.length}');
      return result;
    } catch (e, stackTrace) {
      print('Error fetching unified activities: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // File Upload
  static Future<String?> uploadDatabaseFile(String filePath, String fileName) async {
    try {
      // Check authentication first
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please sign in first.');
      }
      
      print('📤 Starting file upload: $fileName');
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileSizeMB = (fileBytes.length / 1024 / 1024).toStringAsFixed(2);
      print('📊 File size: ${fileSizeMB} MB');
      
      // Upload to Supabase Storage
      print('⬆️ Uploading to Supabase Storage...');
      await client.storage
          .from('ura_database_files')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
      
      print('✅ File uploaded successfully to storage');
      
      // Get public URL
      final urlResponse = client.storage
          .from('ura_database_files')
          .getPublicUrl(fileName);
      
      print('🔗 File URL: $urlResponse');
      return urlResponse;
    } catch (e) {
      print('❌ Error uploading file: $e');
      
      // Provide helpful error message based on error type
      String errorMsg = 'Failed to upload file';
      if (e.toString().contains('row-level security') || e.toString().contains('RLS')) {
        errorMsg = 'Storage bucket RLS policy error. Please configure storage policies in Supabase dashboard:\n'
            '1. Go to Storage → ura_database_files bucket\n'
            '2. Add policy: Allow authenticated users to INSERT and SELECT\n'
            '3. Policy: (bucket_id = \'ura_database_files\') AND (auth.role() = \'authenticated\')';
      } else if (e.toString().contains('not found') || e.toString().contains('does not exist')) {
        errorMsg = 'Storage bucket "ura_database_files" does not exist. Please create it in Supabase dashboard.';
      } else if (e.toString().contains('not authenticated')) {
        errorMsg = 'Please sign in to upload files.';
      }
      
      throw Exception('$errorMsg\n\nOriginal error: $e');
    }
  }

  // System Statistics
  static Future<Map<String, dynamic>> getSystemStats() async {
    try {
      // Get client count
      final clientsResponse = await client
          .from('desktop_clients')
          .select('status')
          .eq('status', 'active');
      
      // Get last update
      final updateResponse = await client
          .from('ura_database_updates')
          .select('month, created_at')
          .order('created_at', ascending: false)
          .limit(1);
      
      // Get current exchange rate
      final rateResponse = await getCurrentExchangeRate();
      
      return {
        'active_clients': clientsResponse.length,
        'last_database_update': updateResponse.isNotEmpty ? updateResponse.first['month'] : 'Never',
        'last_update_date': updateResponse.isNotEmpty ? updateResponse.first['created_at'] : null,
        'current_exchange_rate': rateResponse?['rate'] ?? 3700.0,
        'exchange_rate_date': rateResponse?['effective_date'] ?? null,
      };
    } catch (e) {
      print('Error fetching system stats: $e');
      return {
        'active_clients': 0,
        'last_database_update': 'Error',
        'current_exchange_rate': 3700.0,
      };
    }
  }
}
