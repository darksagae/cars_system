import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart' as crypto;

class AuthService {
  static const String _kUsersKey = 'local_users_v1';
  static final String _kCurrentUserKey = 'current_user';

  // Stored as: { username: {"hash": "...", "role": "user" } }
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

  Future<bool> hasAnyUser() async {
    final users = await _loadUsers();
    return users.isNotEmpty;
  }

  Future<void> createUser({required String username, required String password, String role = 'user'}) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw Exception('Username cannot be empty');
    }
    final users = await _loadUsers();
    if (users.containsKey(trimmed)) {
      throw Exception('Username already exists');
    }
    final hash = _hash(password);
    users[trimmed] = { 'hash': hash, 'role': role };
    await _saveUsers(users);
  }

  Future<bool> validateLogin({required String username, required String password}) async {
    final users = await _loadUsers();
    final rec = users[username.trim()];
    if (rec == null) return false;
    final stored = rec['hash'] ?? '';
    return stored == _hash(password);
  }

  Future<bool> isAdmin(String username) async {
    final users = await _loadUsers();
    final rec = users[username.trim()];
    return (rec != null && (rec['role'] == 'admin'));
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
      current[uname] = { 'hash': hash, 'role': role };
    }
    await _saveUsers(current);
  }

  String _hash(String password) {
    final bytes = utf8.encode(password);
    return crypto.sha256.convert(bytes).toString();
  }
}



