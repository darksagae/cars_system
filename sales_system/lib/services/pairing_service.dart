import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PairingService {
  static const String _kDeviceIdKey = 'pairing_device_id';
  static const String _kPairedKey = 'pairing_is_paired';
  static const String _kPairedAtKey = 'pairing_paired_at';
  static const String _kClientNameKey = 'pairing_client_name';
  static const String _kPairingTokenKey = 'pairing_token';
  static const String _kVersionKey = 'pairing_version';
  static const int _currentVersion = 2; // bumping this forces re-pair on upgrade

  final Uuid _uuid = const Uuid();

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kDeviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await prefs.setString(_kDeviceIdKey, id);
    return id;
  }

  Future<bool> isPaired() async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureVersion(prefs);
    return prefs.getBool(_kPairedKey) ?? false;
  }

  Future<String> getOrCreatePairingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kPairingTokenKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final token = _generateToken();
    await prefs.setString(_kPairingTokenKey, token);
    return token;
  }

  Future<void> rotatePairingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _generateToken();
    await prefs.setString(_kPairingTokenKey, token);
  }

  Future<void> markPaired({required String clientName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPairedKey, true);
    await prefs.setString(_kClientNameKey, clientName);
    await prefs.setString(_kPairedAtKey, DateTime.now().toIso8601String());
    await prefs.remove(_kPairingTokenKey);
  }

  Future<void> unpair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPairedKey);
    await prefs.remove(_kClientNameKey);
    await prefs.remove(_kPairedAtKey);
    // Also clear local users so the next approved run forces signup again
    await prefs.remove('local_users_v1');
    await rotatePairingToken();
  }

  Future<Map<String, dynamic>> buildPairingPayload() async {
    final deviceId = await getOrCreateDeviceId();
    final token = await getOrCreatePairingToken();
    return {
      'device_id': deviceId,
      'token': token,
      'issued_at': DateTime.now().toIso8601String(),
      'version': 1,
      'app': 'NSB Motors Ug',
    };
  }

  Future<void> _ensureVersion(SharedPreferences prefs) async {
    final stored = prefs.getInt(_kVersionKey) ?? 0;
    if (stored != _currentVersion) {
      // Invalidate old pairing to force the new QR flow
      await prefs.remove(_kPairedKey);
      await prefs.remove(_kClientNameKey);
      await prefs.remove(_kPairedAtKey);
      await prefs.setInt(_kVersionKey, _currentVersion);
    }
  }

  String _generateToken({int length = 32}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}


