import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'pairing_service.dart';

class AuthCheckResult {
  final bool ok;
  final String? error;

  const AuthCheckResult._(this.ok, this.error);
  static const success = AuthCheckResult._(true, null);
  static const invalidCredentials = AuthCheckResult._(false, 'Invalid username or password');
  static const wrongMachine = AuthCheckResult._(false, 'Invalid user for this machine');
}

class AuthService {
  static const String _kUsersKey = 'local_users_v1';
  static const String _kCurrentUserKey = 'current_user';

  // Stored as: { username: {"hash": "...", "role": "user", "machineId": "..." } }
  Future<Map<String, Map<String, String>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kUsersKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    final Map<String, dynamic> raw = json.decode(jsonStr);
    final Map<String, Map<String, String>> out = {};
    raw.forEach((k, v) {
      if (v is String) {
        out[k] = { 'hash': v, 'role': 'user' };
      } else if (v is Map) {
        final m = <String,String>{};
        v.forEach((kk, vv){ m[kk.toString()] = vv?.toString() ?? ''; });
        if (!m.containsKey('hash')) m['hash'] = '';
        if (!m.containsKey('role')) m['role'] = 'user';
        out[k] = m;
      }
    });
    return out;
  }

  Future<void> _saveUsers(Map<String, Map<String, String>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsersKey, json.encode(users));
  }

  Future<String> getThisMachineId() async {
    return PairingService().getOrCreateDeviceId();
  }

  Future<bool> hasAnyUser() async {
    final users = await _loadUsers();
    return users.isNotEmpty;
  }

  Future<void> createUser({
    required String username,
    required String password,
    String role = 'user',
    String? machineId,
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw Exception('Username cannot be empty');
    }
    final users = await _loadUsers();
    if (users.containsKey(trimmed)) {
      throw Exception('Username already exists');
    }
    final hash = _hash(password);
    final boundMachine = machineId ?? await getThisMachineId();
    users[trimmed] = {
      'hash': hash,
      'role': role,
      'machineId': boundMachine,
    };
    await _saveUsers(users);
  }

  Future<bool> validateLogin({required String username, required String password}) async {
    final result = await checkLogin(username: username, password: password);
    return result.ok;
  }

  Future<AuthCheckResult> checkLogin({required String username, required String password}) async {
    final users = await _loadUsers();
    final rec = users[username.trim()];
    if (rec == null) return AuthCheckResult.invalidCredentials;
    final stored = rec['hash'] ?? '';
    if (stored != _hash(password)) return AuthCheckResult.invalidCredentials;

    final boundMachine = rec['machineId']?.trim();
    if (boundMachine != null && boundMachine.isNotEmpty) {
      final thisMachine = await getThisMachineId();
      if (boundMachine != thisMachine) return AuthCheckResult.wrongMachine;
    }
    return AuthCheckResult.success;
  }

  Future<bool> isAdmin(String username) async {
    final users = await _loadUsers();
    final rec = users[username.trim()];
    return (rec != null && (rec['role'] == 'admin'));
  }

  Future<void> bindUserToThisMachine(String username) async {
    final users = await _loadUsers();
    final rec = users[username.trim()];
    if (rec == null) return;
    rec['machineId'] = await getThisMachineId();
    users[username.trim()] = rec;
    await _saveUsers(users);
  }

  Future<void> clearMachineBinding(String username) async {
    final users = await _loadUsers();
    final rec = users[username.trim()];
    if (rec == null) return;
    rec.remove('machineId');
    users[username.trim()] = rec;
    await _saveUsers(users);
  }

  Future<void> upsertLocalPassword({
    required String username,
    required String password,
    String? role,
  }) async {
    final users = await _loadUsers();
    final trimmed = username.trim();
    final existing = users[trimmed] ?? <String, String>{'role': role ?? 'user'};
    existing['hash'] = _hash(password);
    if (role != null) existing['role'] = role;
    if (!existing.containsKey('machineId') || (existing['machineId'] ?? '').isEmpty) {
      existing['machineId'] = await getThisMachineId();
    }
    users[trimmed] = existing;
    await _saveUsers(users);
  }

  Future<void> setCurrentUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentUserKey, username);
  }

  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentUserKey);
  }

  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUserKey);
  }

  /// Clears local login state so the app shows first-time setup (signup) again.
  Future<void> factoryResetAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsersKey);
    await prefs.remove(_kCurrentUserKey);
    await prefs.remove('user_profile_name');
    await prefs.remove('user_profile_email');
    await prefs.remove('user_profile_phone');
    await prefs.remove('user_profile_image_path');
    await prefs.remove('cloud_auth_token');
    await prefs.remove('cloud_user_id');
  }

  Future<bool> isCurrentUserAdmin() async {
    final u = await getCurrentUser();
    if (u == null || u.isEmpty) return false;
    return isAdmin(u);
  }

  Future<void> applyUserSync(List<Map<String, dynamic>> users) async {
    final current = await _loadUsers();
    for (final u in users) {
      final uname = (u['username'] as String?)?.trim();
      final hash = (u['password_hash'] as String?) ?? '';
      final role = (u['role'] as String?) ?? 'user';
      if (uname == null || uname.isEmpty) continue;
      if (hash.isEmpty) continue;
      // Admin sync adds credentials only — machine binding happens on the user's own PC.
      current[uname] = { 'hash': hash, 'role': role };
    }
    await _saveUsers(current);
  }

  String _hash(String password) {
    final bytes = utf8.encode(password);
    return crypto.sha256.convert(bytes).toString();
  }
}


