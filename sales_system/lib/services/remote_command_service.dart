import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NetworkInterface is in dart:io which is already imported

/// Service for handling remote commands from mobile app
class RemoteCommandService {
  static final RemoteCommandService _instance = RemoteCommandService._internal();
  factory RemoteCommandService() => _instance;
  RemoteCommandService._internal();

  static const String _clientIdKey = 'remote_client_id';
  static const String _pairingDeviceIdKey = 'pairing_device_id';
  SupabaseClient? _client;
  bool _isInitialized = false;
  bool _isPolling = false;
  static const String _pairingTable = 'desktop_clients';

  /// Initialize Supabase connection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      print('✅ RemoteCommandService initialized');
    } catch (e) {
      print('❌ Error initializing RemoteCommandService: $e');
      rethrow;
    }
  }

  /// Get or generate client ID (unique per machine)
  Future<String> getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    // Prefer the pairing device id so desktop uses the QR device_id consistently
    final pairedId = prefs.getString(_pairingDeviceIdKey);
    if (pairedId != null && pairedId.isNotEmpty) {
      // Also mirror into remote_client_id for compatibility
      await prefs.setString(_clientIdKey, pairedId);
      return pairedId;
    }
    String? clientId = prefs.getString(_clientIdKey);

    if (clientId == null) {
      // Generate unique client ID based on machine
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

  /// Register this desktop client with Supabase
  Future<bool> registerClient({String? overrideClientName, String? overrideClientId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final clientId = overrideClientId ?? await getClientId();
      final clientName = overrideClientName; // only set name if explicitly provided
      final platform = Platform.operatingSystem;
      final version = '1.0.0'; // You can get this from pubspec.yaml

      // Get IP address (simplified - may not work on all systems)
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

      // Use server time via RPC to avoid client clock skew
      await _client!.rpc('register_client_touch', params: {
        'p_client_id': clientId,
        'p_client_name': clientName,
        'p_version': version,
        'p_platform': platform,
        'p_ip': ipAddress,
      });

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
      await _client!.from(_pairingTable).upsert({
        'client_id': deviceId,
        'pairing_token': pairingToken,
        'status': 'pending_pairing',
        'last_seen': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
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
      final resp = await _client!
          .from(_pairingTable)
          .select('status, client_name')
          .eq('client_id', deviceId)
          .maybeSingle();
      if (resp == null) return null; // no row yet; keep waiting
      return Map<String, dynamic>.from(resp);
    } catch (e) {
      // Avoid noisy logs while waiting; only log unexpected errors
      // print('❌ Error polling pairing approval: $e');
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
        // Server-side last_seen update via RPC
        await _client!.rpc('update_last_seen', params: {'p_client_id': clientId});
        print('✅ Updated last_seen (server time) for client: $clientId');
        return; // Success, exit retry loop
      } catch (e) {
        final isLastAttempt = attempt >= maxRetries;
        
        // Only log errors on the last attempt to avoid spam
        if (isLastAttempt) {
          print('❌ Error updating last_seen after $maxRetries attempts: $e');
          // Try to re-initialize if connection lost (only on final failure)
          try {
            await initialize();
            await registerClient();
          } catch (reinitError) {
            // Silently fail - will retry on next heartbeat
          }
          return;
        }
        
        // Exponential backoff: wait 1s, 2s before retrying (on attempts 1 and 2)
        final delayMs = (1 << (attempt - 1)) * 1000;
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Fetch this client's current status from Supabase
  Future<String?> getCurrentClientStatus() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      final clientId = await getClientId();
      final resp = await _client!
          .from('desktop_clients')
          .select('status')
          .eq('client_id', clientId)
          .single();
      return (resp['status'] as String?)?.toLowerCase();
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
      
      // First, check if there are ANY commands for this client (for debugging)
      try {
        final allCommands = await _client!
            .from('remote_commands')
            .select('id, command, status, created_at')
            .eq('client_id', clientId)
            .order('created_at', ascending: false)
            .limit(5);
        print('📊 Latest commands for this client: ${allCommands.length} total');
        for (final cmd in allCommands) {
          print('   - ${cmd['command']} (status: ${cmd['status']}, created: ${cmd['created_at']})');
        }
      } catch (e) {
        print('⚠️ Could not check all commands: $e');
      }
      
      // Now get pending commands
      final response = await _client!
          .from('remote_commands')
          .select('*')
          .eq('client_id', clientId)
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .limit(10);

      final commands = List<Map<String, dynamic>>.from(response);
      if (commands.isNotEmpty) {
        print('📬 Found ${commands.length} pending command(s)');
        for (final cmd in commands) {
          print('   - ${cmd['command']} (ID: ${cmd['id']})');
          print('     Parameters: ${cmd['parameters']}');
        }
      } else {
        print('   No pending commands found');
      }
      return commands;
    } catch (e) {
      print('❌ Error polling commands: $e');
      print('   Stack trace: ${StackTrace.current}');
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
      final updateData = <String, dynamic>{
        'status': status,
      };

      if (status == 'processing') {
        updateData['started_at'] = DateTime.now().toIso8601String();
      } else if (status == 'completed' || status == 'failed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        if (errorMessage != null) {
          updateData['error_message'] = errorMessage;
        }
        if (resultSummary != null) {
          updateData['result_summary'] = resultSummary;
        }
      }

      await _client!.from('remote_commands').update(updateData).eq('id', commandId);

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

    // Start polling in background - don't await so it runs independently
    _pollLoop(onCommandReceived, interval).catchError((error) {
      print('❌ Fatal error in polling loop: $error');
      _isPolling = false;
      // Try to restart after a delay
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
        // Update last seen (this is the key update for real-time status)
        await updateLastSeen();

        // Poll for commands
        final commands = await pollCommands();

        if (commands.isNotEmpty) {
          print('📨 Processing ${commands.length} command(s)...');
        }
        
        for (final command in commands) {
          print('🔄 Processing command: ${command['command']} (ID: ${command['id']})');
          await onCommandReceived(command);
        }

        // Log every 12 polls (once per minute if polling every 5 seconds)
        pollCount++;
        if (pollCount % 12 == 0) {
          print('🔄 Polling active - poll #$pollCount');
        }
      } catch (e) {
        print('❌ Error in polling loop: $e');
        // Continue polling even after errors
        print('🔄 Continuing polling despite error...');
      }

      // Wait before next poll - ensure we always wait even if there was an error
      try {
        await Future.delayed(interval);
      } catch (e) {
        print('❌ Error in delay: $e');
        // If delay fails, wait a bit anyway
        await Future.delayed(const Duration(seconds: 5));
      }
    }
    print('⚠️ Polling loop stopped. _isPolling = $_isPolling');
  }
}

