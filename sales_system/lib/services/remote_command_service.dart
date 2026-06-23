import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'postgres_service.dart';

/// Service for handling remote commands from mobile app using Neon Postgres
class RemoteCommandService {
  static final RemoteCommandService _instance = RemoteCommandService._internal();
  factory RemoteCommandService() => _instance;
  RemoteCommandService._internal();

  static const String _clientIdKey = 'remote_client_id';
  static const String _pairingDeviceIdKey = 'pairing_device_id';
  bool _isInitialized = false;
  bool _isPolling = false;
  static const String _pairingTable = 'desktop_clients';

  /// Initialize Postgres connection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      print('✅ RemoteCommandService initialized (Postgres)');
    } catch (e) {
      print('❌ Error initializing RemoteCommandService: $e');
      rethrow;
    }
  }

  /// Get or generate client ID (unique per machine)
  Future<String> getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    final pairedId = prefs.getString(_pairingDeviceIdKey);
    if (pairedId != null && pairedId.isNotEmpty) {
      await prefs.setString(_clientIdKey, pairedId);
      return pairedId;
    }
    String? clientId = prefs.getString(_clientIdKey);

    if (clientId == null) {
      clientId = _generateClientId();
      await prefs.setString(_clientIdKey, clientId);
    }

    return clientId;
  }

  /// Generate unique client ID
  String _generateClientId() {
    final hostname = Platform.localHostname;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'desktop_${hostname}_$timestamp';
  }

  /// Register this desktop client with Neon Postgres
  Future<bool> registerClient({String? overrideClientName, String? overrideClientId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final clientId = overrideClientId ?? await getClientId();
      final clientName = overrideClientName;
      final platform = Platform.operatingSystem;
      final version = '1.0.0';

      String ipAddress = 'unknown';
      try {
        for (var interface in await NetworkInterface.list()) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              ipAddress = addr.address;
              break;
            }
          }
          if (ipAddress != 'unknown') break;
        }
      } catch (e) {
        print('Could not get IP address: $e');
      }

      // Call register_client_touch function or custom direct upsert
      try {
        await PostgresService.execute(
          'SELECT register_client_touch(@p_client_id, @p_client_name, @p_version, @p_platform, @p_ip)',
          parameters: {
            'p_client_id': clientId,
            'p_client_name': clientName,
            'p_version': version,
            'p_platform': platform,
            'p_ip': ipAddress,
          },
        );
      } catch (e) {
        // Fallback to direct INSERT/UPDATE in case the stored procedure is missing or has a different signature
        print('⚠️ RPC register_client_touch failed, running fallback upsert: $e');
        await PostgresService.execute(
          '''
          INSERT INTO $_pairingTable (client_id, client_name, version, platform, ip_address, last_seen, status)
          VALUES (@clientId, @clientName, @version, @platform, @ipAddress, NOW(), 'pending_pairing')
          ON CONFLICT (client_id) DO UPDATE SET
            client_name = COALESCE(EXCLUDED.client_name, desktop_clients.client_name),
            version = EXCLUDED.version,
            platform = EXCLUDED.platform,
            ip_address = EXCLUDED.ip_address,
            last_seen = NOW();
          ''',
          parameters: {
            'clientId': clientId,
            'clientName': clientName ?? 'Desktop Client',
            'version': version,
            'platform': platform,
            'ipAddress': ipAddress,
          },
        );
      }

      print('✅ Desktop client registered: $clientId');
      return true;
    } catch (e) {
      print('❌ Error registering client: $e');
      return false;
    }
  }

  /// Create or update a pairing request entry for this device
  Future<void> createPairingRequest({
    required String deviceId,
    required String pairingToken,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      await PostgresService.execute(
        '''
        INSERT INTO $_pairingTable (client_id, pairing_token, status, last_seen, created_at)
        VALUES (@clientId, @pairingToken, 'pending_pairing', NOW(), NOW())
        ON CONFLICT (client_id) DO UPDATE SET
          pairing_token = EXCLUDED.pairing_token,
          status = EXCLUDED.status,
          last_seen = NOW();
        ''',
        parameters: {
          'clientId': deviceId,
          'pairingToken': pairingToken,
        },
      );
    } catch (e) {
      print('❌ Error creating pairing request: $e');
    }
  }

  /// Poll for pairing approval and assigned client name
  Future<Map<String, dynamic>?> pollPairingApproval({
    required String deviceId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      final resp = await PostgresService.query(
        'SELECT status, client_name FROM $_pairingTable WHERE client_id = @deviceId LIMIT 1',
        parameters: {'deviceId': deviceId},
      );
      if (resp.isEmpty) return null;
      return resp.first;
    } catch (e) {
      return null;
    }
  }

  /// Update last seen timestamp with retry logic
  Future<void> updateLastSeen({int maxRetries = 3}) async {
    if (!_isInitialized) {
      print('⚠️ Cannot update last_seen: service not initialized');
      return;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final clientId = await getClientId();
        try {
          await PostgresService.execute(
            'SELECT update_last_seen(@p_client_id)',
            parameters: {'p_client_id': clientId},
          );
        } catch (e) {
          // Fallback to direct UPDATE in case stored procedure fails
          await PostgresService.execute(
            'UPDATE $_pairingTable SET last_seen = NOW() WHERE client_id = @clientId',
            parameters: {'clientId': clientId},
          );
        }
        print('✅ Updated last_seen for client: $clientId');
        return;
      } catch (e) {
        final isLastAttempt = attempt >= maxRetries;
        if (isLastAttempt) {
          print('❌ Error updating last_seen after $maxRetries attempts: $e');
          return;
        }
        final delayMs = (1 << (attempt - 1)) * 1000;
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Fetch this client's current status from Neon Postgres
  Future<String?> getCurrentClientStatus() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      final clientId = await getClientId();
      final resp = await PostgresService.query(
        'SELECT status FROM $_pairingTable WHERE client_id = @clientId LIMIT 1',
        parameters: {'clientId': clientId},
      );
      if (resp.isEmpty) return null;
      return (resp.first['status'] as String?)?.toLowerCase();
    } catch (e) {
      print('❌ Error fetching client status: $e');
      return null;
    }
  }

  /// Poll for pending commands
  Future<List<Map<String, dynamic>>> pollCommands() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final clientId = await getClientId();
      print('🔍 Polling for commands (client_id: $clientId)...');
      
      final response = await PostgresService.query(
        'SELECT * FROM remote_commands WHERE client_id = @clientId AND status = \'pending\' ORDER BY created_at ASC LIMIT 10',
        parameters: {'clientId': clientId},
      );

      if (response.isNotEmpty) {
        print('📬 Found ${response.length} pending command(s)');
      }
      return response;
    } catch (e) {
      print('❌ Error polling commands: $e');
      return [];
    }
  }

  /// Update command status
  Future<bool> updateCommandStatus({
    required String commandId,
    required String status,
    String? errorMessage,
    String? resultSummary,
  }) async {
    if (!_isInitialized) return false;

    try {
      final parameters = <String, dynamic>{
        'id': commandId,
        'status': status,
      };

      String query = 'UPDATE remote_commands SET status = @status';

      if (status == 'processing') {
        query += ', started_at = NOW()';
      } else if (status == 'completed' || status == 'failed') {
        query += ', completed_at = NOW()';
        if (errorMessage != null) {
          query += ', error_message = @errorMessage';
          parameters['errorMessage'] = errorMessage;
        }
        if (resultSummary != null) {
          query += ', result_summary = @resultSummary';
          parameters['resultSummary'] = resultSummary;
        }
      }
      query += ' WHERE id = @id::uuid';

      await PostgresService.execute(query, parameters: parameters);
      return true;
    } catch (e) {
      print('Error updating command status: $e');
      return false;
    }
  }

  /// Start polling for commands
  void startPolling({
    required Function(Map<String, dynamic>) onCommandReceived,
    Duration interval = const Duration(seconds: 5),
  }) {
    if (_isPolling) {
      print('⚠️ Polling already active, skipping start');
      return;
    }
    _isPolling = true;
    print('🔄 Starting polling loop (interval: ${interval.inSeconds}s)');

    _pollLoop(onCommandReceived, interval).catchError((error) {
      print('❌ Fatal error in polling loop: $error');
      _isPolling = false;
      Future.delayed(const Duration(seconds: 10), () {
        if (!_isPolling) {
          print('🔄 Attempting to restart polling...');
          startPolling(onCommandReceived: onCommandReceived, interval: interval);
        }
      });
    });
  }

  /// Stop polling
  void stopPolling() {
    _isPolling = false;
  }

  /// Polling loop
  Future<void> _pollLoop(
    Function(Map<String, dynamic>) onCommandReceived,
    Duration interval,
  ) async {
    int pollCount = 0;
    while (_isPolling) {
      try {
        await updateLastSeen();
        final commands = await pollCommands();

        for (final command in commands) {
          print('🔄 Processing command: ${command['command']} (ID: ${command['id']})');
          await onCommandReceived(command);
        }

        pollCount++;
        if (pollCount % 12 == 0) {
          print('🔄 Polling active - poll #$pollCount');
        }
      } catch (e) {
        print('❌ Error in polling loop: $e');
      }

      try {
        await Future.delayed(interval);
      } catch (e) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }
}
