import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/cloud_api_config.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import 'pairing_service.dart';
import 'machine_lock_service.dart';
import 'cloud_command_service.dart';
import 'cloud_sync_notifier.dart';

class CloudLoginResult {
  final bool ok;
  final String? error;
  final String? code;
  final bool freshMachineBind;

  const CloudLoginResult.success({this.freshMachineBind = false})
      : ok = true,
        error = null,
        code = null;
  const CloudLoginResult.failure(this.error, {this.code}) : ok = false, freshMachineBind = false;
}

class CloudApiService {
  static final CloudApiService _instance = CloudApiService._internal();
  factory CloudApiService() => _instance;
  CloudApiService._internal();

  static const _tokenKey = 'cloud_auth_token';
  static const _userIdKey = 'cloud_user_id';
  static const _settingsVersionKey = 'system_settings_version';

  Timer? _presenceTimer;
  bool _presenceEnabled = false;

  String get _base => CloudApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');

  /// True when the cloud API responds (any non-5xx status).
  Future<bool> isServerReachable() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/auth/login'))
          .timeout(const Duration(seconds: 8));
      return res.statusCode < 500;
    } catch (e) {
      print('Cloud reachability check failed: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    if (token != null) await prefs.setString(_tokenKey, token);
    if (user != null && user['id'] != null) {
      await prefs.setInt(_userIdKey, user['id'] as int);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
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

  Future<Map<String, dynamic>> _machinePayload() async {
    final meta = await _deviceMeta();
    return {
      'machineId': await PairingService().getOrCreateDeviceId(),
      'machineName': meta['machineName'],
      'source': 'sales_system',
    };
  }

  Future<bool> register({
    required String username,
    required String password,
    String role = 'user',
    String? displayName,
  }) async {
    try {
      final machine = await _machinePayload();
      final res = await http.post(
        Uri.parse('$_base/api/sync/register'),
        headers: await _headers(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
          'displayName': displayName ?? username,
          ...machine,
        }),
      );
      if (res.statusCode == 201) return true;
      if (res.statusCode == 409) {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        final code = body?['code']?.toString();
        if (code == 'machine_taken') {
          print('Cloud register failed: machine already registered');
          return false;
        }
        return true;
      }
      print('Cloud register failed: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      print('Cloud register error: $e');
      return false;
    }
  }

  Future<CloudLoginResult> login({
    required String username,
    required String password,
    bool activateDevice = false,
  }) async {
    try {
      final machine = await _machinePayload();
      final res = await http.post(
        Uri.parse('$_base/api/auth/login'),
        headers: await _headers(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'source': 'sales_system',
          'activateDevice': activateDevice,
          ...machine,
        }),
      );
      final body = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>?
          : null;
      if (res.statusCode != 200) {
        final msg = body?['error']?.toString() ?? 'Login failed';
        final code = body?['code']?.toString();
        print('Cloud login failed: ${res.statusCode} ${res.body}');
        return CloudLoginResult.failure(msg, code: code);
      }
      if (body == null) {
        return const CloudLoginResult.failure('Invalid login response');
      }
      await _storeSession(body);
      final freshMachineBind = body['freshMachineBind'] == true;
      return CloudLoginResult.success(freshMachineBind: freshMachineBind);
    } catch (e) {
      print('Cloud login error: $e');
      return CloudLoginResult.failure('Could not reach cloud server');
    }
  }

  Future<String?> requestPasswordReset({required String username}) async {
    try {
      final machine = await _machinePayload();
      final res = await http.post(
        Uri.parse('$_base/api/auth/forgot-password'),
        headers: await _headers(),
        body: jsonEncode({
          'username': username,
          'source': 'sales_system',
          ...machine,
        }),
      );
      final body = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>?
          : null;
      if (res.statusCode != 200) {
        return body?['error']?.toString() ?? 'Request failed';
      }
      return null;
    } catch (e) {
      return 'Could not reach cloud server';
    }
  }

  Future<CloudLoginResult> bindThisMachine({
    required String username,
    required String password,
  }) async {
    try {
      final machine = await _machinePayload();
      final res = await http.post(
        Uri.parse('$_base/api/sync/bind-machine'),
        headers: await _headers(),
        body: jsonEncode({
          'username': username,
          'password': password,
          ...machine,
        }),
      );
      final body = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>?
          : null;
      if (res.statusCode != 200) {
        final msg = body?['error']?.toString() ?? 'Could not link this device';
        return CloudLoginResult.failure(msg, code: body?['code']?.toString());
      }
      final freshMachineBind = body?['freshMachineBind'] == true;
      return CloudLoginResult.success(freshMachineBind: freshMachineBind);
    } catch (e) {
      return CloudLoginResult.failure('Could not reach cloud server');
    }
  }

  Future<void> syncProfileToCloud({
    required String displayName,
    String? email,
    String? phone,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/api/sync/profile'),
        headers: await _headers(auth: true),
        body: jsonEncode({
          'displayName': displayName,
          'email': email,
          'phone': phone,
          'source': 'sales_system',
        }),
      );
      if (res.statusCode != 200) {
        print('Cloud profile sync failed: ${res.statusCode}');
      }
    } catch (e) {
      print('Cloud profile sync error: $e');
    }
  }

  Future<void> syncProfileFromCloud() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/sync/profile'),
        headers: await _headers(auth: true),
      );
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      if (data['displayName'] != null) {
        await prefs.setString('user_profile_name', data['displayName'].toString());
      }
      if (data['email'] != null) {
        await prefs.setString('user_profile_email', data['email'].toString());
      }
      if (data['phone'] != null) {
        await prefs.setString('user_profile_phone', data['phone'].toString());
      }
    } catch (e) {
      print('Cloud profile pull error: $e');
    }
  }

  Future<void> pushProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_profile_name');
    if (name == null || name.isEmpty) return;
    await syncProfileToCloud(
      displayName: name,
      email: prefs.getString('user_profile_email'),
      phone: prefs.getString('user_profile_phone'),
    );
  }

  Map<String, dynamic> _invoicePayload(Invoice invoice) {
    final customer = invoice.customer;
    return {
      'id': invoice.id,
      'salesSystemId': invoice.id,
      'invoiceNumber': invoice.invoiceNumber,
      'status': invoice.status.index,
      'vehicleMake': invoice.vehicleMake,
      'vehicleModel': invoice.vehicleModel,
      'vehicleModelSuffix': invoice.vehicleModelSuffix,
      'vehicleYear': invoice.vehicleYear,
      'chassisNo': invoice.chassisNo,
      'engineSize': invoice.engineSize,
      'fuelType': invoice.fuelType,
      'transmission': invoice.transmission,
      'color': invoice.color,
      'countryOfOrigin': invoice.countryOfOrigin,
      'stockNo': invoice.stockNo,
      'carPriceUSD': invoice.carPriceUSD,
      'clearanceFeeUSD': invoice.clearanceFeeUSD,
      'exchangeRate': invoice.exchangeRate,
      'firstInstallmentUGX': invoice.firstInstallmentUGX,
      'taxesURA': invoice.taxesURA,
      'numberPlatesFee': invoice.numberPlatesFee,
      'thirdPartyInsurance': invoice.thirdPartyInsurance,
      'agencyFees': invoice.agencyFees,
      'secondInstallmentUGX': invoice.secondInstallmentUGX,
      'totalAmount': invoice.totalAmount,
      'dueDate': invoice.dueDate.toIso8601String(),
      'notes': invoice.notes,
      'dutyFree': invoice.dutyFree,
      'includeTaxToUra': !invoice.dutyFree && invoice.taxesURA > 0,
      'isFinalized': invoice.isFinalized,
      'machineFinalized': invoice.isFinalized,
      'source': 'sales_system',
      if (customer != null)
        'customer': {
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'city': customer.city,
        },
    };
  }

  Future<void> syncInvoiceToCloud(Invoice invoice) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/api/sync/invoices'),
        headers: await _headers(auth: true),
        body: jsonEncode(_invoicePayload(invoice)),
      );
      if (res.statusCode != 200) {
        print('Cloud invoice sync failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('Cloud invoice sync error: $e');
    }
  }

  /// Upload exact machine PDF bytes via server API (not direct S3 presign).
  /// Returns null on success, or a short error message on failure.
  Future<String?> syncInvoicePdfToCloud({
    required String invoiceNumber,
    required String localPdfPath,
    Invoice? invoice,
  }) async {
    try {
      final file = File(localPdfPath);
      if (!await file.exists()) {
        return 'PDF file not found on disk';
      }

      if (invoice != null) {
        await syncInvoiceToCloud(invoice);
      }

      final token = await getToken();
      if (token == null || token.isEmpty) {
        return 'Not logged in to cloud — sign in on the sales app first';
      }

      final pdfBytes = await file.readAsBytes();
      final url =
          '$_base/api/sync/invoices/${Uri.encodeComponent(invoiceNumber)}/pdf';
      print(
        'Uploading machine PDF via server ($url, ${pdfBytes.length} bytes)...',
      );

      final headers = await _headers(auth: true);
      headers['Content-Type'] = 'application/pdf';

      final uploadRes = await http.post(
        Uri.parse(url),
        headers: headers,
        body: pdfBytes,
      );
      if (uploadRes.statusCode != 200) {
        final msg =
            'Upload failed (${uploadRes.statusCode}): ${uploadRes.body.trim()}';
        print('Invoice PDF cloud upload failed: $msg');
        return msg;
      }

      final body = uploadRes.body.isNotEmpty
          ? jsonDecode(uploadRes.body) as Map<String, dynamic>?
          : null;
      final bytes = body?['bytes'];
      print(
        'Invoice PDF uploaded to cloud: $invoiceNumber'
        '${bytes != null ? ' ($bytes bytes)' : ''}',
      );
      return null;
    } catch (e) {
      final msg = 'Upload error: $e';
      print('Invoice PDF cloud upload error: $msg');
      return msg;
    }
  }

  Future<String?> syncInvoicePdfBytesToCloud({
    required String invoiceNumber,
    required List<int> pdfBytes,
    Invoice? invoice,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/upload_$invoiceNumber.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);
      return syncInvoicePdfToCloud(
        invoiceNumber: invoiceNumber,
        localPdfPath: file.path,
        invoice: invoice,
      );
    } catch (e) {
      print('Invoice PDF bytes upload error: $e');
      return 'Upload error: $e';
    }
  }

  Future<void> syncInvoiceWithPdf(Invoice invoice, {String? localPdfPath}) async {
    await syncInvoiceToCloud(invoice);
    final path = localPdfPath;
    if (path != null && path.isNotEmpty) {
      await syncInvoicePdfToCloud(
        invoiceNumber: invoice.invoiceNumber,
        localPdfPath: path,
        invoice: invoice,
      );
    }
  }

  Future<void> deleteInvoiceFromCloud(String invoiceNumber) async {
    try {
      final encoded = Uri.encodeComponent(invoiceNumber);
      final res = await http.delete(
        Uri.parse('$_base/api/sync/invoices/$encoded'),
        headers: await _headers(auth: true),
      );
      if (res.statusCode != 200 && res.statusCode != 404) {
        print('Cloud invoice delete failed: ${res.statusCode}');
      }
    } catch (e) {
      print('Cloud invoice delete error: $e');
    }
  }

  Future<Map<String, dynamic>> deviceMetaForActivity() => _deviceMeta();

  Future<Map<String, dynamic>> _deviceMeta() async {
    String ip = 'unknown';
    try {
      for (final iface in await NetworkInterface.list()) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ip = addr.address;
            break;
          }
        }
        if (ip != 'unknown') break;
      }
    } catch (_) {}

    return {
      'source': 'sales_system',
      'machineId': await PairingService().getOrCreateDeviceId(),
      'machineName': Platform.localHostname,
      'platform': Platform.operatingSystem,
      'ip': ip,
      'appVersion': '1.0.0',
    };
  }

  Future<void> logActivity(String action, {Map<String, dynamic>? metadata}) async {
    try {
      await http.post(
        Uri.parse('$_base/api/sync/activities'),
        headers: await _headers(auth: true),
        body: jsonEncode({'action': action, 'metadata': metadata ?? {}}),
      );
    } catch (e) {
      print('Cloud activity log error: $e');
    }
  }

  Future<void> sendPresence({bool logActivity = false}) async {
    if (!_presenceEnabled) return;
    try {
      final meta = await _deviceMeta();
      final res = await http.post(
        Uri.parse('$_base/api/sync/presence'),
        headers: await _headers(auth: true),
        body: jsonEncode({
          ...meta,
          'heartbeat': logActivity,
        }),
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        if (body?['banned'] == true) {
          final message = body?['message']?.toString() ??
              'You are temporarily banned. Contact NSB Motors administrator.';
          MachineLockService.instance.lock(message);
        }
      }
      await CloudCommandService.instance.pollAndExecute();
    } catch (e) {
      print('Cloud presence error: $e');
    }
  }

  void startPresenceHeartbeat({Duration interval = const Duration(seconds: 30)}) {
    _presenceEnabled = true;
    stopPresenceHeartbeat();
    _presenceTimer = Timer.periodic(interval, (_) => sendPresence());
  }

  void stopPresenceHeartbeat() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
  }

  /// Stops heartbeats and tells the cloud this desktop session ended.
  Future<void> logoutCloud() async {
    _presenceEnabled = false;
    stopPresenceHeartbeat();
    try {
      await http.post(
        Uri.parse('$_base/api/auth/logout'),
        headers: await _headers(auth: true),
        body: jsonEncode({'source': 'sales_system'}),
      );
    } catch (e) {
      print('Cloud logout error: $e');
    }
    await clearSession();
  }

  Future<Map<String, dynamic>?> fetchPendingCommands() async {
    try {
      final machineId = await PairingService().getOrCreateDeviceId();
      final uri = Uri.parse('$_base/api/sync/commands').replace(
        queryParameters: {'machineId': machineId},
      );
      final res = await http.get(
        uri,
        headers: await _headers(auth: true),
      );
      if (res.statusCode != 200 || res.body.isEmpty) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      print('Cloud commands fetch error: $e');
      return null;
    }
  }

  Future<void> ackCommand(int commandId, {String status = 'completed', String? result}) async {
    try {
      await http.post(
        Uri.parse('$_base/api/sync/commands/$commandId'),
        headers: await _headers(auth: true),
        body: jsonEncode({
          'status': status,
          if (result != null) 'result': result,
        }),
      );
    } catch (e) {
      print('Cloud command ack error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchSystemSettings() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/sync/system-settings'),
        headers: await _headers(auth: true),
      );
      if (res.statusCode != 200 || res.body.isEmpty) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      print('System settings fetch error: $e');
      return null;
    }
  }

  Future<String> getLocalSettingsVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_settingsVersionKey) ?? '0';
  }

  Future<void> setLocalSettingsVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsVersionKey, version);
  }

  Future<bool> isInvoicePdfOnCloud(String invoiceNumber) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/sync/invoices'),
        headers: await _headers(auth: true),
      );
      if (res.statusCode != 200) return false;
      final list = jsonDecode(res.body) as List<dynamic>;
      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        if (raw['invoiceNumber']?.toString() == invoiceNumber) {
          if (raw['pdfReady'] == true) return true;
          final pdfUrl = raw['pdfUrl'];
          return pdfUrl != null && pdfUrl.toString().isNotEmpty;
        }
      }
      return false;
    } catch (e) {
      print('isInvoicePdfOnCloud error: $e');
      return false;
    }
  }

  /// Restart cloud heartbeat if we have a saved session (e.g. after navigation).
  Future<void> ensureCloudConnectionActive() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    if (!_presenceEnabled) {
      startPresenceHeartbeat();
    }
    await sendPresence(logActivity: false);
    await syncInvoicesFromCloud();
  }

  Future<int> syncInvoicesFromCloud() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/api/sync/invoices'),
        headers: await _headers(auth: true),
      );
      if (res.statusCode != 200) return 0;

      final list = jsonDecode(res.body) as List<dynamic>;
      final db = await DatabaseHelper().database;
      var count = 0;

      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        try {
          await _upsertLocalInvoice(db, raw);
          count++;
        } catch (e) {
          final num = raw['invoiceNumber']?.toString() ?? '?';
          print('Cloud invoice upsert failed for $num: $e');
        }
      }
      if (count > 0) {
        CloudSyncNotifier.instance.notifyInvoicesSynced();
      }
      return count;
    } catch (e) {
      print('Cloud invoice pull error: $e');
      return 0;
    }
  }

  Future<void> _upsertLocalInvoice(dynamic db, Map<String, dynamic> raw) async {
    final invoiceNumber = (raw['invoiceNumber'] as String?)?.trim();
    if (invoiceNumber == null || invoiceNumber.isEmpty) return;

    final existing = await db.query(
      'invoices',
      where: 'invoiceNumber = ?',
      whereArgs: [invoiceNumber],
      limit: 1,
    );

    final customerName = (raw['customer']?['name'] ?? raw['consigneeName'] ?? 'N/A').toString();
    int customerId = await _ensureCustomer(db, raw, customerName);

    final statusName = (raw['status'] ?? 'draft').toString();
    final statusIndex = InvoiceStatus.values.indexWhere((s) => s.name == statusName);
    final status = statusIndex >= 0 ? statusIndex : 0;

    final modelRaw = (raw['vehicleModel'] ?? '').toString();
    String vehicleModel = modelRaw;
    String vehicleModelSuffix = '';
    if (modelRaw.contains(' / ')) {
      final parts = modelRaw.split(' / ');
      vehicleModel = parts.first;
      vehicleModelSuffix = parts.sublist(1).join(' / ');
    }

    final map = <String, dynamic>{
      'invoiceNumber': invoiceNumber,
      'invoiceType': 'carSale',
      'customerId': customerId,
      'invoiceDate': DateTime.tryParse(raw['createdAt']?.toString() ?? '')?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'dueDate': DateTime.tryParse(raw['dueDate']?.toString() ?? '')?.toIso8601String() ??
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'status': status,
      'stockNo': raw['stockNo'] ?? raw['refNo'] ?? '',
      'vehicleMake': raw['vehicleMake'] ?? '',
      'vehicleModel': vehicleModel,
      'vehicleModelSuffix': vehicleModelSuffix,
      'vehicleYear': raw['vehicleYear'] ?? 0,
      'chassisNo': raw['chassisNo'] ?? '',
      'engineSize': raw['vehicleEngineCC']?.toString() ?? '',
      'fuelType': raw['fuelType'] ?? raw['vehicleFuelType'] ?? '',
      'transmission': raw['transmission'] ?? raw['vehicleTransmission'] ?? '',
      'color': raw['color'] ?? raw['vehicleColor'] ?? '',
      'countryOfOrigin': raw['consigneeCountry'] ?? raw['countryOfOrigin'] ?? 'JP',
      'carPriceUSD': _toDouble(raw['carPriceUSD'] ?? raw['cifUsd']),
      'clearanceFeeUSD': _toDouble(raw['clearanceFeeUSD'] ?? raw['clearanceFeeUsd']),
      'exchangeRate': _toDouble(raw['exchangeRate'], fallback: 3834.56),
      'firstInstallmentUGX': _toDouble(raw['firstInstallmentUGX'] ?? raw['firstInstallmentUgx']),
      'taxesURA': _toDouble(raw['taxesURA']),
      'numberPlatesFee': _toDouble(raw['numberPlatesFee'], fallback: 714300),
      'thirdPartyInsurance': _toDouble(raw['thirdPartyInsurance']),
      'agencyFees': _toDouble(raw['agencyFees']),
      'secondInstallmentUGX': _toDouble(raw['secondInstallmentUGX'] ?? raw['secondInstallmentUgx']),
      'totalAmount': _toDouble(raw['totalAmount'] ?? raw['grandTotalUgx']),
      'notes': raw['notes'] ?? '',
      'dutyFree': (raw['dutyFree'] == true || raw['dutyFree'] == 1) ? 1 : 0,
      'isFinalized': (raw['machineFinalized'] == true ||
              raw['isFinalized'] == true ||
              raw['isFinalized'] == 1)
          ? 1
          : 0,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      await db.update('invoices', map, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      map['createdAt'] = DateTime.now().toIso8601String();
      map['subtotal'] = 0.0;
      map['taxAmount'] = 0.0;
      map['discountAmount'] = 0.0;
      map['paidAmount'] = 0.0;
      map['balanceAmount'] = map['totalAmount'];
      map['isFinalized'] = 0;
      await db.insert('invoices', map);
    }
  }

  Future<int> _ensureCustomer(dynamic db, Map<String, dynamic> raw, String name) async {
    final customer = raw['customer'] as Map<String, dynamic>?;
    final rawEmail =
        customer?['email']?.toString().trim() ?? raw['consigneeEmail']?.toString().trim() ?? '';
    final phone =
        customer?['phone']?.toString().trim() ?? raw['consigneePhone']?.toString().trim() ?? 'N/A';

    final byName = await db.query(
      'customers',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (byName.isNotEmpty) return byName.first['id'] as int;

    var email = rawEmail;
    final emailLower = email.toLowerCase();
    if (email.isEmpty ||
        emailLower == 'n/a' ||
        emailLower == 'na' ||
        !email.contains('@')) {
      email = 'noemail+${DateTime.now().microsecondsSinceEpoch}@customer.local';
    } else {
      final byEmail = await db.query(
        'customers',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (byEmail.isNotEmpty) return byEmail.first['id'] as int;
    }

    final now = DateTime.now().toIso8601String();
    return await db.insert('customers', {
      'name': name,
      'email': email,
      'phone': phone.isEmpty ? 'N/A' : phone,
      'address': customer?['address'] ?? raw['consigneeAddress'] ?? '',
      'city': customer?['city'] ?? raw['consigneeCity'] ?? '',
      'location': '',
      'company': '',
      'notes': '',
      'profileImage': '',
      'createdAt': now,
      'updatedAt': now,
      'totalSpent': 0.0,
      'totalInvoices': 0,
      'balance': 0.0,
      'isActive': 1,
    });
  }

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }
}
