import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class ConnectedMachine {
  final String id;
  String name;
  String location;
  bool online;
  double? cpu;
  double? mem;
  String? currentUser;
  String? os;
  String? platform;
  String? ip;
  String? lastSeen;

  ConnectedMachine({
    required this.id,
    required this.name,
    this.location = '',
    this.online = false,
    this.cpu,
    this.mem,
    this.currentUser,
    this.os,
    this.platform,
    this.ip,
    this.lastSeen,
  });

  factory ConnectedMachine.fromMap(Map<String, dynamic> m) => ConnectedMachine(
        id: m['id'] as String,
        name: m['name'] as String? ?? m['id'] as String,
        location: m['location'] as String? ?? '',
        online: m['online'] as bool? ?? false,
        cpu: (m['cpu'] as num?)?.toDouble(),
        mem: (m['mem'] as num?)?.toDouble(),
        currentUser: m['current_user'] as String?,
        os: m['os'] as String?,
        platform: m['platform'] as String?,
        ip: m['ip'] as String?,
        lastSeen: m['last_seen'] as String?,
      );

  String get clientId => id;
  String get clientName => name;
  String get ipAddress => ip ?? '';
  bool get isOnline => online;
  String get version => '1.0';
  double? get cpuUsage => cpu;
  double? get memUsage => mem;
  List<MachineActivity> get activities => const [];
}

class MachineActivity {
  final String id;
  final String machineId;
  final String action;
  final String? username;
  final String status;
  final Map<String, dynamic> details;
  final DateTime timestamp;

  MachineActivity({
    required this.id,
    required this.machineId,
    required this.action,
    this.username,
    required this.status,
    Map<String, dynamic>? details,
    DateTime? timestamp,
  })  : details = details ?? {},
        timestamp = timestamp ?? DateTime.now();

  factory MachineActivity.fromMap(Map<String, dynamic> m) => MachineActivity(
        id: m['id'] as String? ?? '',
        machineId: m['machine_id'] as String? ?? '',
        action: m['action'] as String? ?? 'unknown',
        username: m['username'] as String?,
        status: m['status'] as String? ?? 'success',
        details: (m['details'] as Map<String, dynamic>?) ?? {},
        timestamp: m['timestamp'] != null
            ? DateTime.tryParse(m['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  String get clientId => machineId;

  String get displayAction => action
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

enum RelayStatus { disconnected, connecting, connected, error }

// ─── Service ──────────────────────────────────────────────────────────────────

class MachineManagementService extends ChangeNotifier {
  static final MachineManagementService _instance =
      MachineManagementService._internal();
  factory MachineManagementService() => _instance;
  MachineManagementService._internal();

  WebSocket? _ws;
  RelayStatus _status = RelayStatus.disconnected;
  String _relayUrl = '';
  String _adminPassword = '';
  Timer? _reconnectTimer;
  bool _disposed = false;

  final Map<String, ConnectedMachine> _machines = {};
  final List<MachineActivity> _activities = [];

  // ── Public state ──────────────────────────────────────────────────────────

  RelayStatus get status => _status;
  bool get isConnected => _status == RelayStatus.connected;
  bool get isRunning => isConnected;
  int get port => 3002;
  String get relayUrl => _relayUrl;
  String? get serverUrl => _relayUrl.isEmpty ? null : _relayUrl;

  List<ConnectedMachine> get machines =>
      List.unmodifiable(_machines.values.toList());
  List<ConnectedMachine> get onlineMachines =>
      _machines.values.where((m) => m.online).toList();
  int get onlineCount => onlineMachines.length;
  int get totalCount => _machines.length;

  List<MachineActivity> get globalActivities =>
      List.unmodifiable(_activities.take(200).toList());

  ConnectedMachine? getMachine(String id) => _machines[id];

  // ── Connection ────────────────────────────────────────────────────────────

  /// Call once at app start — reads saved URL and reconnects automatically.
  Future<void> loadAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    _relayUrl = prefs.getString('relay_url') ?? '';
    _adminPassword = prefs.getString('relay_password') ?? '';
    if (_relayUrl.isNotEmpty) _doConnect();
  }

  /// Save new relay URL + password and (re)connect.
  Future<bool> startServer({int port = 3002, String? url, String? password}) async {
    if (url != null) {
      final prefs = await SharedPreferences.getInstance();
      _relayUrl = url;
      _adminPassword = password ?? _adminPassword;
      await prefs.setString('relay_url', _relayUrl);
      if (password != null) await prefs.setString('relay_password', _adminPassword);
    }
    if (_relayUrl.isEmpty) return false;
    disconnect();
    _doConnect();
    return true;
  }

  Future<bool> connectToRelay({required String url, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    _relayUrl = url.trim();
    _adminPassword = password.trim();
    await prefs.setString('relay_url', _relayUrl);
    await prefs.setString('relay_password', _adminPassword);
    disconnect();
    _doConnect();
    return true;
  }

  void _doConnect() async {
    if (_disposed || _relayUrl.isEmpty) return;
    if (_status == RelayStatus.connecting) return;

    _setStatus(RelayStatus.connecting);

    try {
      final wsUrl = _relayUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');

      _ws = await WebSocket.connect(wsUrl)
          .timeout(const Duration(seconds: 10));

      _setStatus(RelayStatus.connected);
      debugPrint('[MMSClient] Connected to $wsUrl');

      _ws!.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _handleMessage(data);
          } catch (e) {
            debugPrint('[MMSClient] Parse error: $e');
          }
        },
        onDone: () {
          debugPrint('[MMSClient] Connection closed');
          _ws = null;
          _setStatus(RelayStatus.disconnected);
          _scheduleReconnect();
        },
        onError: (e) {
          debugPrint('[MMSClient] Error: $e');
          _ws = null;
          _setStatus(RelayStatus.error);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _send({'type': 'admin_auth', 'password': _adminPassword});
    } catch (e) {
      debugPrint('[MMSClient] Connect failed: $e');
      _ws = null;
      _setStatus(RelayStatus.error);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_disposed) return;
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      if (!_disposed && _relayUrl.isNotEmpty) _doConnect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _ws?.close();
    _ws = null;
    _setStatus(RelayStatus.disconnected);
  }

  void stopServer() => disconnect();

  // ── Message handling ──────────────────────────────────────────────────────

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    switch (type) {
      case 'admin_ok':
        _updateMachineList(data['machines'] as List<dynamic>? ?? []);
        break;

      case 'machines':
        _updateMachineList(data['machines'] as List<dynamic>? ?? []);
        break;

      case 'activities_snapshot':
        _activities.clear();
        for (final a in (data['activities'] as List<dynamic>? ?? [])) {
          _activities.add(MachineActivity.fromMap(a as Map<String, dynamic>));
        }
        notifyListeners();
        break;

      case 'activity':
        final act =
            MachineActivity.fromMap(data['activity'] as Map<String, dynamic>);
        _activities.insert(0, act);
        if (_activities.length > 500) _activities.removeLast();
        notifyListeners();
        break;

      case 'activities_cleared':
        final mid = data['machine_id'] as String?;
        if (mid != null) {
          _activities.removeWhere((a) => a.machineId == mid);
        } else {
          _activities.clear();
        }
        notifyListeners();
        break;

      case 'error':
        debugPrint('[MMSClient] Relay error: ${data['message']}');
        break;
    }
  }

  void _updateMachineList(List<dynamic> list) {
    _machines.clear();
    for (final item in list) {
      final m = ConnectedMachine.fromMap(item as Map<String, dynamic>);
      _machines[m.id] = m;
    }
    notifyListeners();
  }

  // ── Send helpers ──────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> data) {
    try {
      if (_ws != null) _ws!.add(jsonEncode(data));
    } catch (e) {
      debugPrint('[MMSClient] Send error: $e');
    }
  }

  // ── Commands ──────────────────────────────────────────────────────────────

  Future<bool> sendCommand(
    String machineId,
    String command, {
    Map<String, dynamic>? data,
  }) async {
    if (!isConnected) return false;
    _send({
      'type': 'command',
      'machine_id': machineId,
      'command': command,
      if (data != null) 'data': data,
    });
    return true;
  }

  Future<int> broadcastCommand(
    String command, {
    Map<String, dynamic>? data,
  }) async {
    if (!isConnected) return 0;
    _send({
      'type': 'broadcast',
      'command': command,
      if (data != null) 'data': data,
    });
    return onlineCount;
  }

  Future<bool> restartApplication(String id) =>
      sendCommand(id, 'restart_application');

  Future<bool> refreshDatabase(String id) =>
      sendCommand(id, 'refresh_database');

  Future<bool> lockScreen(String id) => sendCommand(id, 'lock_screen');

  Future<bool> logoutUser(String id) => sendCommand(id, 'logout_user');

  Future<bool> updateExchangeRate(double rate, {double? phase1Rate}) =>
      broadcastCommand('update_exchange_rate', data: {
        'rate': rate,
        if (phase1Rate != null) 'phase1_rate': phase1Rate,
      }).then((n) => n > 0);

  Future<int> updateMvDatabase({
    required String fileUrl,
    required String month,
    int recordCount = 0,
  }) =>
      broadcastCommand('update_mv_database', data: {
        'file_url': fileUrl,
        'month': month,
        'record_count': recordCount,
      });

  Future<bool> sendMvDatabaseToMachine(
    String id, {
    required String fileUrl,
    required String month,
    int recordCount = 0,
  }) =>
      sendCommand(id, 'update_mv_database', data: {
        'file_url': fileUrl,
        'month': month,
        'record_count': recordCount,
      });

  Future<bool> resetUserPassword(
    String id, {
    required String username,
    required String newPassword,
  }) =>
      sendCommand(id, 'reset_password',
          data: {'username': username, 'new_password': newPassword});

  Future<bool> updateEmailConfig(
    String id, {
    required String smtpHost,
    required String smtpPort,
    required String email,
    required String password,
  }) =>
      sendCommand(id, 'update_email_config', data: {
        'smtp_host': smtpHost,
        'smtp_port': smtpPort,
        'email': email,
        'password': password,
      });

  // ── Activity management ───────────────────────────────────────────────────

  void clearActivitiesForMachine(String machineId) {
    _send({'type': 'clear_activities', 'machine_id': machineId});
  }

  void clearAllActivities() {
    _send({'type': 'clear_activities'});
  }

  void removeMachine(String machineId) {
    _machines.remove(machineId);
    notifyListeners();
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

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
