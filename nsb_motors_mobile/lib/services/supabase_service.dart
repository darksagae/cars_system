import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import '../config/postgres_config.dart';

/// Postgres-based SupabaseService drop-in replacement
/// Communicates directly with Neon/Vercel PostgreSQL database
class SupabaseService {
  static Future<void> initialize() async {
    print('🔌 PostgresService initialized (direct connection to Neon)');
    try {
      await _execute('''
        CREATE TABLE IF NOT EXISTS email_messages (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          queue_id UUID,
          to_email TEXT,
          subject TEXT,
          body TEXT,
          pdf_url TEXT,
          sent_by_machine_id TEXT,
          sent_by_user_id TEXT,
          sent_by_user_name TEXT,
          sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          status TEXT
        );
      ''');
      print('✅ email_messages table verified/created.');
    } catch (e) {
      print('⚠️ email_messages table check bypassed: $e');
    }
  }

  // Authentication Mock (Bypassed)
  static bool get isAuthenticated => true;
  static dynamic get currentUser => null;
  static dynamic get currentSession => null;

  static Future<AuthResponseMock> signInWithEmail({required String email, required String password}) async {
    return AuthResponseMock();
  }

  static Future<void> signOut() async {
    print('🔑 Sign out called (mocked)');
  }

  static Future<Connection> _connect() async {
    return await Connection.open(
      Endpoint(
        host: PostgresConfig.host,
        database: PostgresConfig.database,
        username: PostgresConfig.username,
        password: PostgresConfig.password,
        port: PostgresConfig.port,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );
  }

  static Future<List<Map<String, dynamic>>> _query(String query, {Map<String, dynamic>? parameters}) async {
    final conn = await _connect();
    try {
      final result = await conn.execute(Sql.named(query), parameters: parameters);
      final List<Map<String, dynamic>> list = [];
      for (final row in result) {
        final Map<String, dynamic> map = {};
        for (var i = 0; i < result.schema.columns.length; i++) {
          final col = result.schema.columns[i];
          var val = row[i];
          if (val is Map) {
            val = Map<String, dynamic>.from(val);
          }
          map[col.columnName ?? 'column_$i'] = val;
        }
        list.add(map);
      }
      return list;
    } finally {
      await conn.close();
    }
  }

  static Future<void> _execute(String query, {Map<String, dynamic>? parameters}) async {
    final conn = await _connect();
    try {
      await conn.execute(Sql.named(query), parameters: parameters);
    } finally {
      await conn.close();
    }
  }

  // Desktop Client Management
  static Future<List<Map<String, dynamic>>> getDesktopClients() async {
    try {
      return await _query('SELECT * FROM desktop_clients ORDER BY created_at DESC');
    } catch (e) {
      print('❌ Error fetching desktop clients: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDesktopClient(String clientId) async {
    try {
      final res = await _query(
        'SELECT * FROM desktop_clients WHERE client_id = @clientId LIMIT 1',
        parameters: {'clientId': clientId},
      );
      return res.isNotEmpty ? res.first : null;
    } catch (e) {
      print('❌ Error fetching desktop client: $e');
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
      await _execute(
        '''
        INSERT INTO desktop_clients (client_id, client_name, version, platform, ip_address, last_seen, status, created_at)
        VALUES (@clientId, @clientName, @version, @platform, @ipAddress, NOW(), 'active', NOW())
        ON CONFLICT (client_id) DO UPDATE SET
          client_name = EXCLUDED.client_name,
          version = EXCLUDED.version,
          platform = EXCLUDED.platform,
          ip_address = EXCLUDED.ip_address,
          last_seen = NOW(),
          status = 'active';
        ''',
        parameters: {
          'clientId': clientId,
          'clientName': clientName,
          'version': version,
          'platform': platform,
          'ipAddress': ipAddress,
        },
      );
      return true;
    } catch (e) {
      print('Error registering desktop client: $e');
      return false;
    }
  }

  static Future<bool> approveDesktopClient({
    required String deviceId,
    required String clientName,
  }) async {
    try {
      await _execute(
        '''
        INSERT INTO desktop_clients (client_id, client_name, status)
        VALUES (@deviceId, @clientName, 'approved')
        ON CONFLICT (client_id) DO UPDATE SET
          client_name = EXCLUDED.client_name,
          status = 'approved';
        ''',
        parameters: {
          'deviceId': deviceId,
          'clientName': clientName,
        },
      );
      return true;
    } catch (e) {
      print('❌ Error approving desktop client: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getClientUsers(String clientId) async {
    try {
      return await _query(
        'SELECT * FROM desktop_client_users WHERE client_id = @clientId ORDER BY created_at DESC',
        parameters: {'clientId': clientId},
      );
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
      await _execute(
        'SELECT upsert_client_user(@clientId, @username, @passwordHash, @role)',
        parameters: {
          'clientId': clientId,
          'username': username,
          'passwordHash': passwordHash,
          'role': role,
        },
      );
      return true;
    } catch (e) {
      print('❌ Error upserting client user: $e');
      return false;
    }
  }

  static Future<int> deleteAllDesktopClients() async {
    try {
      final res = await _query('DELETE FROM desktop_clients RETURNING *');
      return res.length;
    } catch (e) {
      print('❌ Error deleting clients: $e');
      return 0;
    }
  }

  static Future<bool> deleteDesktopClient(String clientId) async {
    try {
      await _execute(
        'DELETE FROM desktop_clients WHERE client_id = @clientId',
        parameters: {'clientId': clientId},
      );
      return true;
    } catch (e) {
      print('❌ Error deleting desktop client $clientId: $e');
      return false;
    }
  }

  static Future<bool> updateClientStatus(String clientId, String status) async {
    try {
      await _execute(
        '''
        UPDATE desktop_clients
        SET status = @status, last_seen = NOW()
        WHERE client_id = @clientId
        ''',
        parameters: {
          'clientId': clientId,
          'status': status,
        },
      );
      return true;
    } catch (e) {
      print('Error updating client status: $e');
      return false;
    }
  }

  // URA Database Management
  static Future<List<Map<String, dynamic>>> getUraDatabaseUpdates() async {
    try {
      final response = await _query('SELECT * FROM ura_database_updates ORDER BY created_at DESC LIMIT 10');
      final updates = List<Map<String, dynamic>>.from(response);
      print('📋 Fetched ${updates.length} URA database updates from Neon Postgres');
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
      await _execute(
        '''
        INSERT INTO ura_database_updates (month, file_name, record_count, file_url, status, created_at)
        VALUES (@month, @fileName, @recordCount, @fileUrl, 'pending', NOW())
        ''',
        parameters: {
          'month': month,
          'fileName': fileName,
          'recordCount': recordCount,
          'fileUrl': fileUrl,
        },
      );
      return true;
    } catch (e) {
      print('Error creating URA database update: $e');
      return false;
    }
  }

  // Exchange Rate Management
  static Future<Map<String, dynamic>?> getCurrentExchangeRate() async {
    try {
      final response = await _query('SELECT * FROM exchange_rates WHERE is_current = true LIMIT 1');
      return response.isNotEmpty ? response.first : null;
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
      await _execute('UPDATE exchange_rates SET is_current = false WHERE is_current = true');
      await _execute(
        '''
        INSERT INTO exchange_rates (rate, phase1_rate, source, is_current, created_at)
        VALUES (@rate, @phase1Rate, @source, true, NOW())
        ''',
        parameters: {
          'rate': rate,
          'phase1Rate': phase1Rate ?? rate,
          'source': source,
        },
      );
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
      print('📤 Queueing remote command: $command for client: $clientId');
      await _execute(
        '''
        INSERT INTO remote_commands (client_id, command, parameters, status, created_at)
        VALUES (@clientId, @command, @parameters, 'pending', NOW())
        ''',
        parameters: {
          'clientId': clientId,
          'command': command,
          'parameters': jsonEncode(parameters ?? {}),
        },
      );
      return true;
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
      String query = 'SELECT * FROM remote_commands WHERE client_id = @clientId';
      final Map<String, dynamic> params = {'clientId': clientId};
      
      if (timeFilter != null) {
        final cutoffTime = DateTime.now().subtract(timeFilter).toIso8601String();
        query += ' AND created_at >= @cutoffTime';
        params['cutoffTime'] = cutoffTime;
      }
      
      query += ' ORDER BY created_at DESC LIMIT @limit';
      params['limit'] = limit ?? 50;

      final res = await _query(query, parameters: params);
      final List<Map<String, dynamic>> list = [];
      for (final item in res) {
        final Map<String, dynamic> mutable = Map.from(item);
        final paramsVal = mutable['parameters'];
        if (paramsVal is String) {
          try {
            mutable['parameters'] = jsonDecode(paramsVal);
          } catch (_) {
            mutable['parameters'] = {};
          }
        }
        list.add(mutable);
      }
      return list;
    } catch (e) {
      print('Error fetching remote commands: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getClientActivities(
    String clientId, {
    Duration? timeFilter,
    int? limit,
  }) async {
    try {
      String query = 'SELECT * FROM client_activity WHERE client_id = @clientId';
      final Map<String, dynamic> params = {'clientId': clientId};
      
      if (timeFilter != null) {
        final cutoffTime = DateTime.now().subtract(timeFilter).toIso8601String();
        query += ' AND created_at >= @cutoffTime';
        params['cutoffTime'] = cutoffTime;
      }
      
      query += ' ORDER BY created_at DESC LIMIT @limit';
      params['limit'] = limit ?? 50;

      final res = await _query(query, parameters: params);
      final List<Map<String, dynamic>> list = [];
      for (final item in res) {
        final Map<String, dynamic> mutable = Map.from(item);
        final metaVal = mutable['metadata'];
        if (metaVal is String) {
          try {
            mutable['metadata'] = jsonDecode(metaVal);
          } catch (_) {
            mutable['metadata'] = {};
          }
        }
        list.add(mutable);
      }
      return list;
    } catch (e) {
      print('Error fetching client activities: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getWhatsAppMessages(
    String clientId, {
    Duration? timeFilter,
    int? limit,
  }) async {
    try {
      String query = 'SELECT * FROM whatsapp_messages WHERE sent_by_machine_id = @clientId';
      final Map<String, dynamic> params = {'clientId': clientId};
      
      if (timeFilter != null) {
        final cutoffTime = DateTime.now().subtract(timeFilter).toIso8601String();
        query += ' AND sent_at >= @cutoffTime';
        params['cutoffTime'] = cutoffTime;
      }
      
      query += ' ORDER BY sent_at DESC LIMIT @limit';
      params['limit'] = limit ?? 50;

      return await _query(query, parameters: params);
    } catch (e) {
      print('Error fetching WhatsApp messages: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentActivities(
    String clientId, {
    Duration timeFilter = const Duration(days: 7),
    int limit = 50,
  }) async {
    try {
      final remoteCommands = await getRemoteCommands(clientId, timeFilter: timeFilter, limit: limit);
      final clientActivities = await getClientActivities(clientId, timeFilter: timeFilter, limit: limit);
      final whatsappMessages = await getWhatsAppMessages(clientId, timeFilter: timeFilter, limit: limit);

      final List<Map<String, dynamic>> unified = [];

      for (final cmd in remoteCommands) {
        unified.add({
          'type': 'remote_command',
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
          'created_at': cmd['created_at']?.toString(),
          'username': null,
        });
      }

      for (final act in clientActivities) {
        unified.add({
          'type': 'client_activity',
          'id': act['id']?.toString(),
          'client_id': act['client_id'],
          'action': act['action'],
          'command': act['action'],
          'status': 'completed',
          'parameters': {},
          'metadata': act['metadata'] ?? {},
          'created_at': act['created_at']?.toString(),
          'username': act['username'],
        });
      }

      for (final msg in whatsappMessages) {
        unified.add({
          'type': 'whatsapp_message',
          'id': msg['id'],
          'client_id': msg['sent_by_machine_id'],
          'action': 'send_invoice',
          'command': 'send_invoice',
          'status': msg['status'] ?? 'sent',
          'parameters': {},
          'metadata': {
            'client_phone': msg['client_phone'],
            'message_type': msg['message_type'],
            'message_content': msg['message_content'],
            'sent_by_user_name': msg['sent_by_user_name'],
          },
          'created_at': msg['sent_at']?.toString(),
          'username': msg['sent_by_user_name'],
        });
      }

      unified.sort((a, b) {
        final aTime = a['created_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

      return unified.take(limit).toList();
    } catch (e) {
      print('Error fetching unified activities: $e');
      return [];
    }
  }

  // Database URA File Upload (Bypassed bucket via Data URL Base64)
  static Future<String?> uploadDatabaseFile(String filePath, String fileName) async {
    try {
      print('📤 Converting file to Data URL Base64 for database storage...');
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:application/octet-stream;base64,$base64String';
      print('✅ File converted successfully. Data URL Length: ${dataUrl.length}');
      return dataUrl;
    } catch (e) {
      print('❌ Error converting file to Base64: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // System Statistics
  static Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final clients = await _query("SELECT COUNT(*) FROM desktop_clients WHERE status = 'active'");
      final updates = await _query("SELECT month, created_at FROM ura_database_updates ORDER BY created_at DESC LIMIT 1");
      final rate = await getCurrentExchangeRate();

      final activeClients = clients.isNotEmpty ? int.parse(clients.first['count']?.toString() ?? '0') : 0;

      return {
        'active_clients': activeClients,
        'last_database_update': updates.isNotEmpty ? updates.first['month'] : 'Never',
        'last_update_date': updates.isNotEmpty ? updates.first['created_at']?.toString() : null,
        'current_exchange_rate': rate?['rate'] ?? 3700.0,
        'exchange_rate_date': rate?['effective_date'] ?? null,
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

  // Direct Queue insertion methods for compatibility
  static Future<void> insertWhatsAppMessageQueue(Map<String, dynamic> data) async {
    await _execute(
      '''
      INSERT INTO whatsapp_message_queue (phone_number, message_content, message_type, media_path, sent_by_machine_id, sent_by_user_id, sent_by_user_name, status, created_at)
      VALUES (@phoneNumber, @messageContent, @messageType, @mediaPath, @sentByMachineId, @sentByUserId, @sentByUserName, 'pending', NOW())
      ''',
      parameters: {
        'phoneNumber': data['phone_number'],
        'messageContent': data['message_content'],
        'messageType': data['message_type'],
        'mediaPath': data['media_path'],
        'sentByMachineId': data['sent_by_machine_id'],
        'sentByUserId': data['sent_by_user_id'],
        'sentByUserName': data['sent_by_user_name'],
      },
    );
  }

  static Future<void> insertEmailQueue(Map<String, dynamic> data) async {
    await _execute(
      '''
      INSERT INTO email_queue (to_email, subject, body, pdf_url, sent_by_machine_id, sent_by_user_id, sent_by_user_name, status, created_at)
      VALUES (@toEmail, @subject, @body, @pdfUrl, @sentByMachineId, @sentByUserId, @sentByUserName, 'pending', NOW())
      ''',
      parameters: {
        'toEmail': data['to_email'],
        'subject': data['subject'],
        'body': data['body'],
        'pdfUrl': data['pdf_url'],
        'sentByMachineId': data['sent_by_machine_id'],
        'sentByUserId': data['sent_by_user_id'],
        'sentByUserName': data['sent_by_user_name'],
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingWhatsAppMessages({int limit = 10}) async {
    return await _query(
      'SELECT * FROM whatsapp_message_queue WHERE status = \'pending\' ORDER BY created_at ASC LIMIT @limit',
      parameters: {'limit': limit},
    );
  }

  static Future<void> updateWhatsAppQueueStatus(String id, String status, {String? errorMessage, String? messageId}) async {
    if (status == 'processing') {
      await _execute(
        'UPDATE whatsapp_message_queue SET status = @status, updated_at = NOW() WHERE id = @id::uuid',
        parameters: {'id': id, 'status': status},
      );
    } else if (status == 'sent') {
      await _execute(
        'UPDATE whatsapp_message_queue SET status = @status, processed_at = NOW(), updated_at = NOW(), message_id = @messageId WHERE id = @id::uuid',
        parameters: {'id': id, 'status': status, 'messageId': messageId ?? ''},
      );
    } else if (status == 'failed') {
      await _execute(
        'UPDATE whatsapp_message_queue SET status = @status, error_message = @errorMessage, processed_at = NOW(), updated_at = NOW() WHERE id = @id::uuid',
        parameters: {'id': id, 'status': status, 'errorMessage': errorMessage ?? ''},
      );
    }
  }

  static Future<void> storeWhatsAppMessage(Map<String, dynamic> queueMessage) async {
    await _execute(
      '''
      INSERT INTO whatsapp_messages (message_id, client_phone, message_content, message_type, sent_by_machine_id, sent_by_user_id, sent_by_user_name, sent_at, status)
      VALUES (@messageId, @clientPhone, @messageContent, @messageType, @sentByMachineId, @sentByUserId, @sentByUserName, NOW(), \'sent\')
      ''',
      parameters: {
        'messageId': queueMessage['message_id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'clientPhone': queueMessage['phone_number'],
        'messageContent': queueMessage['message_content'],
        'messageType': queueMessage['message_type'] ?? 'message',
        'sentByMachineId': queueMessage['sent_by_machine_id'],
        'sentByUserId': queueMessage['sent_by_user_id'],
        'sentByUserName': queueMessage['sent_by_user_name'],
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingEmailMessages({int limit = 1}) async {
    return await _query(
      'SELECT * FROM email_queue WHERE status = \'pending\' ORDER BY created_at ASC LIMIT @limit',
      parameters: {'limit': limit},
    );
  }

  static Future<void> updateEmailQueueStatus(String id, String status, {String? errorMessage}) async {
    if (status == 'processing') {
      await _execute(
        'UPDATE email_queue SET status = @status, updated_at = NOW() WHERE id = @id::uuid',
        parameters: {'id': id, 'status': status},
      );
    } else if (status == 'sent') {
      await _execute(
        'UPDATE email_queue SET status = @status, processed_at = NOW(), updated_at = NOW() WHERE id = @id::uuid',
        parameters: {'id': id, 'status': status},
      );
    } else if (status == 'failed') {
      await _execute(
        'UPDATE email_queue SET status = @status, error_message = @errorMessage, processed_at = NOW(), updated_at = NOW() WHERE id = @id::uuid',
        parameters: {'id': id, 'status': status, 'errorMessage': errorMessage ?? ''},
      );
    }
  }

  static Future<void> storeEmailMessage(Map<String, dynamic> queueEmail) async {
    try {
      await _execute(
        '''
        INSERT INTO email_messages (queue_id, to_email, subject, body, pdf_url, sent_by_machine_id, sent_by_user_id, sent_by_user_name, sent_at, status)
        VALUES (@queueId::uuid, @toEmail, @subject, @body, @pdfUrl, @sentByMachineId, @sentByUserId, @sentByUserName, NOW(), 'sent')
        ''',
        parameters: {
          'queueId': queueEmail['id'],
          'toEmail': queueEmail['to_email'],
          'subject': queueEmail['subject'],
          'body': queueEmail['body'],
          'pdfUrl': queueEmail['pdf_url'],
          'sentByMachineId': queueEmail['sent_by_machine_id'],
          'sentByUserId': queueEmail['sent_by_user_id'],
          'sentByUserName': queueEmail['sent_by_user_name'],
        },
      );
    } catch (e) {
      print('Error storing email message in db: $e');
    }
  }

  static Future<void> updateMobileServerInfo(String serverIp, int port, bool isRunning) async {
    try {
      await _execute(
        '''
        INSERT INTO machine_profiles (machine_id, machine_name, user_id, user_email, is_active, last_seen)
        VALUES ('mobile_server_mobile_admin', 'Mobile Server (Admin)', 'mobile_admin', 'mobile@nsbmotors.com', @isActive, NOW())
        ON CONFLICT (machine_id) DO UPDATE SET
          is_active = EXCLUDED.is_active,
          last_seen = NOW();
        ''',
        parameters: {'isActive': isRunning},
      );
      
      try {
        await _execute('''
          CREATE TABLE IF NOT EXISTS mobile_server_info (
            id TEXT PRIMARY KEY,
            mobile_ip TEXT,
            mobile_port INTEGER,
            last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            is_active BOOLEAN,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );
        ''');
        await _execute(
          '''
          INSERT INTO mobile_server_info (id, mobile_ip, mobile_port, last_seen, is_active, updated_at)
          VALUES ('mobile_admin', @mobileIp, @mobilePort, NOW(), @isActive, NOW())
          ON CONFLICT (id) DO UPDATE SET
            mobile_ip = EXCLUDED.mobile_ip,
            mobile_port = EXCLUDED.mobile_port,
            is_active = EXCLUDED.is_active,
            last_seen = NOW(),
            updated_at = NOW();
          ''',
          parameters: {
            'mobileIp': serverIp,
            'mobilePort': port,
            'isActive': isRunning,
          },
        );
      } catch (e) {
        print('⚠️ Bypassed mobile_server_info table: $e');
      }
    } catch (e) {
      print('Error updating mobile server info: $e');
    }
  }

  static Future<void> clearMobileServerInfo() async {
    try {
      await _execute(
        '''
        UPDATE machine_profiles
        SET is_active = false, last_seen = NOW()
        WHERE machine_id = 'mobile_server_mobile_admin'
        '''
      );
      try {
        await _execute(
          '''
          UPDATE mobile_server_info
          SET is_active = false, last_seen = NOW(), updated_at = NOW()
          WHERE id = 'mobile_admin'
          '''
        );
      } catch (_) {}
    } catch (e) {
      print('Error clearing mobile server info: $e');
    }
  }
}

class AuthResponseMock {
  final dynamic session = Object();
}
