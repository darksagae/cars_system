import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/cloud_api_config.dart';

class CloudControlService {
  static final CloudControlService _instance = CloudControlService._internal();
  factory CloudControlService() => _instance;
  CloudControlService._internal();

  static const _tokenKey = 'cloud_auth_token';
  static const _usernameKey = 'cloud_username';
  static const _roleKey = 'cloud_role';
  static const _displayNameKey = 'cloud_display_name';
  static const _isAdminKey = 'cloud_is_admin';

  String get baseUrl => CloudApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> get isAuthenticated async => (await getToken())?.isNotEmpty == true;

  Future<bool> get isAdmin async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_isAdminKey) == true) return true;
    return prefs.getString(_roleKey) == 'admin';
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    if (token != null) await prefs.setString(_tokenKey, token);
    if (user != null) {
      if (user['username'] != null) {
        await prefs.setString(_usernameKey, user['username'].toString());
      }
      if (user['role'] != null) {
        await prefs.setString(_roleKey, user['role'].toString());
      }
      if (user['displayName'] != null) {
        await prefs.setString(_displayNameKey, user['displayName'].toString());
      }
      final isAdmin = user['isAdmin'] == true || user['role']?.toString() == 'admin';
      await prefs.setBool(_isAdminKey, isAdmin);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_isAdminKey);
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: await _headers(),
          body: jsonEncode({
            'username': username,
            'password': password,
            'source': 'control_panel',
          }),
        )
        .timeout(_timeout);

    final body = _parseJsonMap(res.body);
    if (res.statusCode != 200) {
      throw Exception(body?['error']?.toString() ?? 'Login failed (HTTP ${res.statusCode})');
    }
    if (body == null) throw Exception('Invalid login response');

    await _storeSession(body);
    final user = body['user'] as Map<String, dynamic>?;
    final isAdmin = user?['isAdmin'] == true;
    if (!isAdmin) {
      await clearSession();
      throw Exception('Control panel access required');
    }

    return body;
  }

  static const _timeout = Duration(seconds: 20);

  Map<String, dynamic>? _parseJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  String _apiError(http.Response res, String fallback) {
    if (res.statusCode == 401) {
      return 'Session expired — sign in again';
    }
    final body = _parseJsonMap(res.body);
    return body?['error']?.toString() ?? '$fallback (HTTP ${res.statusCode})';
  }

  Future<Map<String, dynamic>> fetchOverview() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not signed in');
    }

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/admin/overview'),
            headers: await _headers(auth: true),
          )
          .timeout(_timeout);

      if (res.statusCode == 401) {
        await clearSession();
        throw Exception('Session expired — sign in again');
      }
      if (res.statusCode == 403) {
        throw Exception('Admin access required');
      }
      if (res.statusCode == 404) {
        return _buildFallbackOverview(note: 'Overview API not deployed yet — showing basic data');
      }
      if (res.statusCode != 200) {
        throw Exception(_apiError(res, 'Failed to load overview'));
      }

      final data = _parseJsonMap(res.body);
      if (data == null) {
        throw Exception('Invalid response from server');
      }
      return data;
    } catch (e) {
      if (e is Exception && e.toString().contains('Session expired')) rethrow;
      // Fallback when overview missing or server error
      try {
        return await _buildFallbackOverview(
          note: 'Using accounts data (${e.toString().replaceAll('Exception: ', '')})',
        );
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> _buildFallbackOverview({String? note}) async {
    final users = await fetchUsers();
    final activities = await fetchActivities(limit: 8);

    final sessions = users.map((u) {
      final online = u['online'] == true;
      return {
        'userId': u['id'],
        'name': u['displayName'] ?? u['username'],
        'username': u['username'],
        'role': u['role'],
        'isActive': u['isActive'] ?? true,
        'online': online,
        'desktopOnline': online,
        'webOnline': false,
        'channel': online ? 'Desktop' : '—',
        'machine': online ? 'Desktop' : '—',
        'net': online ? 'Online' : 'Offline',
        'lastSeenAt': u['lastSeenAt'],
        'invoiceCount': u['invoiceCount'] ?? 0,
        'lastAction': u['lastActivity'],
      };
    }).toList();

    final live = users.where((u) => u['online'] == true).length;

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'fallback': true,
      'fallbackNote': note,
      'cloud': {
        'status': 'ok',
        'url': baseUrl,
        'invoiceCount': users.fold<int>(0, (s, u) => s + ((u['invoiceCount'] as num?)?.toInt() ?? 0)),
        'invoicesToday': 0,
        'mvDatabaseMonth': null,
        'mvDatabaseLocked': false,
      },
      'fleet': {
        'registered': users.length,
        'liveDesktop': live,
        'liveWeb': 0,
        'liveTotal': live,
        'stale': 0,
        'neverLoggedIn': 0,
        'disabled': users.where((u) => u['isActive'] == false).length,
      },
      'sync': {
        'invoicesToday': 0,
        'totalInvoices': 0,
        'lastActivityAt': activities.isNotEmpty ? activities.first['createdAt'] : null,
      },
      'sessions': sessions,
      'incidents': <Map<String, dynamic>>[],
      'recentActivity': activities,
    };
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/api/admin/users'),
          headers: await _headers(auth: true),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (res.statusCode == 403) {
      throw Exception('Admin access required');
    }
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Failed to load accounts'));
    }
    final data = _parseJsonMap(res.body);
    if (data == null) throw Exception('Invalid response from server');
    return (data['users'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> updateUser(
    int id, {
    String? username,
    String? password,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (username != null) payload['username'] = username;
    if (password != null) payload['password'] = password;
    if (isActive != null) payload['isActive'] = isActive;

    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/users/$id'),
      headers: await _headers(auth: true),
      body: jsonEncode(payload),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(body['error']?.toString() ?? 'Update failed');
    }
    return body;
  }

  Future<String?> requestPasswordReset({
    required String username,
    String source = 'control_panel',
    String? machineName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: await _headers(),
      body: jsonEncode({
        'username': username,
        'source': source,
        if (machineName != null) 'machineName': machineName,
      }),
    );
    final body = _parseJsonMap(res.body);
    if (res.statusCode != 200) {
      return body?['error']?.toString() ?? 'Request failed';
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchActivities({int limit = 50}) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/api/admin/activities?limit=$limit'),
          headers: await _headers(auth: true),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Failed to load activity'));
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> fetchUserDetail(int userId) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/api/admin/users/$userId/detail'),
          headers: await _headers(auth: true),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (res.statusCode == 404) {
      throw Exception('User not found');
    }
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Failed to load account detail'));
    }
    final data = _parseJsonMap(res.body);
    if (data == null) throw Exception('Invalid response from server');
    return data;
  }

  Future<void> deleteUserInvoice(int userId, String invoiceNumber) async {
    final encoded = Uri.encodeComponent(invoiceNumber);
    final res = await http
        .delete(
          Uri.parse('$baseUrl/api/admin/users/$userId/invoices/$encoded'),
          headers: await _headers(auth: true),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Failed to delete invoice'));
    }
  }

  Future<Map<String, dynamic>> fetchUserInvoiceDetail(
    int userId,
    String invoiceNumber,
  ) async {
    final encoded = Uri.encodeComponent(invoiceNumber);
    final res = await http
        .get(
          Uri.parse('$baseUrl/api/admin/users/$userId/invoices/$encoded'),
          headers: await _headers(auth: true),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (res.statusCode == 404) {
      throw Exception('Invoice not found');
    }
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Failed to load invoice'));
    }
    final data = _parseJsonMap(res.body);
    if (data == null) throw Exception('Invalid response from server');
    return data;
  }

  Future<List<int>> fetchUserInvoicePdfBytes(
    int userId,
    String invoiceNumber,
  ) async {
    final encoded = Uri.encodeComponent(invoiceNumber);
    final jsonRes = await http
        .get(
          Uri.parse('$baseUrl/api/admin/users/$userId/invoices/$encoded/pdf?format=json'),
          headers: await _headers(auth: true),
        )
        .timeout(const Duration(seconds: 90));
    if (jsonRes.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (jsonRes.statusCode == 404) {
      throw Exception('PDF not yet uploaded from the sales machine');
    }
    if (jsonRes.statusCode != 200) {
      throw Exception(_apiError(jsonRes, 'Failed to load invoice PDF'));
    }

    final data = _parseJsonMap(jsonRes.body);
    final presigned = data?['pdfUrl']?.toString();
    if (presigned != null && presigned.isNotEmpty) {
      final pdfRes = await http.get(Uri.parse(presigned)).timeout(const Duration(seconds: 90));
      if (pdfRes.statusCode != 200) {
        throw Exception('Failed to download invoice PDF from storage');
      }
      return pdfRes.bodyBytes;
    }

    final res = await http
        .get(
          Uri.parse('$baseUrl/api/admin/users/$userId/invoices/$encoded/pdf'),
          headers: await _headers(auth: true),
        )
        .timeout(const Duration(seconds: 90));
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Failed to load invoice PDF'));
    }
    return res.bodyBytes;
  }

  Future<void> sendUserCommand(
    int userId,
    String command, {
    Map<String, dynamic>? payload,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/admin/users/$userId/commands'),
          headers: await _headers(auth: true),
          body: jsonEncode({
            'command': command,
            if (payload != null) 'payload': payload,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Command failed'));
    }
  }

  Future<Map<String, dynamic>> transferUserMachine(int userId) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/admin/users/$userId/transfer-machine'),
          headers: await _headers(auth: true),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Failed to transfer machine'));
    }
    final data = _parseJsonMap(res.body);
    if (data == null) throw Exception('Invalid response from server');
    return data;
  }

  Future<Map<String, dynamic>> fetchUpdates() async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/api/admin/updates'),
          headers: await _headers(auth: true),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    if (res.statusCode != 200) {
      throw Exception(_apiError(res, 'Failed to load updates'));
    }
    final data = _parseJsonMap(res.body);
    if (data == null) throw Exception('Invalid response from server');
    return data;
  }

  Future<Map<String, dynamic>> uploadMvDatabase({
    required List<int> pdfBytes,
    required String filename,
    required String month,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Getting upload URL…');
    final presignRes = await http.get(
      Uri.parse('$baseUrl/api/mv-database/presign?filename=${Uri.encodeComponent(filename)}'),
      headers: await _headers(auth: true),
    );
    final presign = _parseJsonMap(presignRes.body);
    if (presignRes.statusCode != 200) {
      throw Exception(presign?['error']?.toString() ?? 'Failed to get upload URL');
    }

    final uploadUrl = presign?['uploadUrl'] as String?;
    final key = presign?['key'] as String?;
    if (uploadUrl == null || key == null) {
      throw Exception('Invalid presign response');
    }

    onProgress?.call('Uploading PDF to cloud…');
    final s3Res = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'application/pdf'},
      body: pdfBytes,
    );
    if (s3Res.statusCode < 200 || s3Res.statusCode >= 300) {
      throw Exception('S3 upload failed (HTTP ${s3Res.statusCode})');
    }

    onProgress?.call('Importing tax rates…');
    final importRes = await http.post(
      Uri.parse('$baseUrl/api/mv-database/import'),
      headers: await _headers(auth: true),
      body: jsonEncode({'s3Key': key, 'month': month}),
    );
    final importBody = _parseJsonMap(importRes.body);
    if (importRes.statusCode != 200) {
      throw Exception(importBody?['error']?.toString() ?? 'Import failed');
    }
    return importBody ?? {};
  }

  Future<void> unlockMvDatabase() async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/mv-database/lock'),
      headers: await _headers(auth: true),
      body: jsonEncode({'action': 'unlock'}),
    );
    if (res.statusCode != 200) {
      final body = _parseJsonMap(res.body);
      throw Exception(body?['error']?.toString() ?? 'Unlock failed');
    }
  }

  Future<Map<String, dynamic>> updateExchangeRates({
    required double taxRate,
    required double cnfRate,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/updates/exchange-rates'),
      headers: await _headers(auth: true),
      body: jsonEncode({'taxRate': taxRate, 'cnfRate': cnfRate}),
    );
    if (res.statusCode == 401) {
      await clearSession();
      throw Exception('Session expired — sign in again');
    }
    final body = _parseJsonMap(res.body);
    if (res.statusCode != 200) {
      throw Exception(body?['error']?.toString() ?? 'Failed to update rates');
    }
    return body ?? {};
  }
}
