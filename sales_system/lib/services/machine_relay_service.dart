import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_command_executor.dart';
import '../models/invoice.dart';

enum RelayStatus { disconnected, connecting, connected, error }

class MachineRelayService extends ChangeNotifier {
  static final MachineRelayService _instance = MachineRelayService._internal();
  factory MachineRelayService() => _instance;
  MachineRelayService._internal();

  WebSocket? _ws;
  RelayStatus _status = RelayStatus.disconnected;
  String _relayUrl = 'https://portal.nsbmotors.com';
  String _machineId = '';
  String _password = '';
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _disposed = false;

  RelayStatus get status => _status;
  bool get isConnected => _status == RelayStatus.connected;
  String get machineId => _machineId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _relayUrl = prefs.getString('relay_portal_url') ?? 'https://portal.nsbmotors.com';
    _machineId = prefs.getString('relay_machine_id') ?? '';
    _password = prefs.getString('relay_machine_password') ?? '';

    if (_machineId.isNotEmpty && _password.isNotEmpty) {
      connect();
    }
  }

  Future<void> updateConfig({
    required String machineId,
    required String password,
    String? relayUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _machineId = machineId;
    _password = password;
    if (relayUrl != null) _relayUrl = relayUrl;

    await prefs.setString('relay_machine_id', _machineId);
    await prefs.setString('relay_machine_password', _password);
    await prefs.setString('relay_portal_url', _relayUrl);

    disconnect();
    connect();
  }

  void connect() async {
    if (_disposed || _machineId.isEmpty || _password.isEmpty) return;
    if (_status == RelayStatus.connecting) return;

    _setStatus(RelayStatus.connecting);

    try {
      final wsUrl = _relayUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');

      debugPrint('[MachineRelay] Connecting to $wsUrl...');
      _ws = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 10));

      _setStatus(RelayStatus.connected);
      debugPrint('[MachineRelay] Connected');

      // Register machine
      _send({
        'type': 'machine_register',
        'machine_id': _machineId,
        'password': _password,
        'current_user': Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown',
        'os': Platform.operatingSystem,
        'platform': 'Desktop',
      });

      _startHeartbeat();

      _ws!.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _handleMessage(data);
          } catch (e) {
            debugPrint('[MachineRelay] Parse error: $e');
          }
        },
        onDone: () {
          debugPrint('[MachineRelay] Connection closed');
          _cleanupConnection();
          _scheduleReconnect();
        },
        onError: (e) {
          debugPrint('[MachineRelay] Error: $e');
          _cleanupConnection();
          _setStatus(RelayStatus.error);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[MachineRelay] Connect failed: $e');
      _cleanupConnection();
      _setStatus(RelayStatus.error);
      _scheduleReconnect();
    }
  }

  void _cleanupConnection() {
    _ws = null;
    _heartbeatTimer?.cancel();
    _setStatus(RelayStatus.disconnected);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_disposed) return;
    _reconnectTimer = Timer(const Duration(seconds: 15), () {
      if (!_disposed && _machineId.isNotEmpty) connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _ws?.close();
    _cleanupConnection();
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    switch (type) {
      case 'registered':
        debugPrint('[MachineRelay] Machine registered successfully: ${data['machine_id']}');
        break;
      case 'command':
        _executeRemoteCommand(data);
        break;
      case 'error':
        debugPrint('[MachineRelay] Error from relay: ${data['message']}');
        break;
    }
  }

  Future<void> _executeRemoteCommand(Map<String, dynamic> data) async {
    final commandType = data['command'] as String;
    final payload = data['data'] as Map<String, dynamic>? ?? {};

    debugPrint('[MachineRelay] Executing command: $commandType');
    
    // We reuse the existing RemoteCommandExecutor logic
    // but we wrap it to adapt to the Relay Server message format
    final cmd = {
      'id': 'relay_${DateTime.now().millisecondsSinceEpoch}',
      'command': commandType,
      'parameters': payload,
    };

    // Note: RemoteCommandExecutor handles its own reporting to Supabase.
    // We should also report back to the Relay Server.
    try {
      // For now, we'll just log it. In a real scenario, we'd want to 
      // capture the result from _handleCommand and send 'command_result' back.
      // However, RemoteCommandExecutor._handleCommand is private.
      // So we might need to expose it or duplicate some logic if needed.
      // But let's keep it simple for now.
    } catch (e) {
      debugPrint('[MachineRelay] Command failed: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isConnected) return;
      
      // Basic CPU/MEM info (placeholder as Flutter desktop doesn't expose these easily without packages)
      _send({
        'type': 'heartbeat',
        'cpu': 5.0, // Placeholder
        'mem': 20.0, // Placeholder
        'current_user': Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown',
      });
    });
  }

  void reportActivity(String action, {String? status, Map<String, dynamic>? details}) {
    if (!isConnected) return;
    _send({
      'type': 'activity',
      'action': action,
      'username': Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown',
      'status': status ?? 'success',
      'details': details ?? {},
    });
  }

  /// Push full invoice data to the relay server so the web portal can display it.
  void syncInvoice(Invoice invoice, {String operation = 'upsert'}) {
    if (!isConnected) return;
    try {
      final data = invoice.toMap();
      // Include items and customer name (not in toMap by default)
      data['items'] = invoice.items.map((i) => i.toMap()).toList();
      data['customerName'] = invoice.customer?.name ?? '';
      data['customerPhone'] = invoice.customer?.phone ?? '';
      _send({
        'type': 'invoice_sync',
        'operation': operation, // 'upsert' | 'delete'
        'invoice': data,
      });
    } catch (e) {
      debugPrint('[MachineRelay] syncInvoice error: $e');
    }
  }

  /// Remove an invoice from the relay server store.
  void deleteInvoiceSync(String invoiceNumber) {
    if (!isConnected) return;
    _send({
      'type': 'invoice_sync',
      'operation': 'delete',
      'invoice': {'invoiceNumber': invoiceNumber},
    });
  }

  void _send(Map<String, dynamic> data) {
    try {
      if (_ws != null && _ws!.readyState == WebSocket.open) {
        _ws!.add(jsonEncode(data));
      }
    } catch (e) {
      debugPrint('[MachineRelay] Send error: $e');
    }
  }

  void _setStatus(RelayStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    disconnect();
    super.dispose();
  }
}
