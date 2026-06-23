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
  
  // New constants for offline token caching
  static const String _kOfflineTokenKey = 'pairing_offline_token';
  static const String _kOfflineTokenExpiryKey = 'pairing_offline_token_expiry';
  static const String _kOfflineTokenCreatedAtKey = 'pairing_offline_token_created_at';
  
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
    
    // First check if we have a valid offline token that hasn't expired
    if (await hasValidOfflineToken()) {
      return true;
    }
    
    // Fall back to regular pairing check
    return prefs.getBool(_kPairedKey) ?? false;
  }  Future<String> getOrCreatePairingToken() async {
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
    
    // Create offline token with 6-month expiration
    await _createOfflineToken();
  }

  Future<void> unpair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPairedKey);
    await prefs.remove(_kClientNameKey);
    await prefs.remove(_kPairedAtKey);
    // Also clear local users so the next approved run forces signup again
    await prefs.remove('local_users_v1');
    await rotatePairingToken();
    
    // Clear offline token as well
    await _clearOfflineToken();
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
      
      // Also clear offline token when version changes
      await _clearOfflineToken();
    }
  }

  String _generateToken({int length = 32}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
  
  // New methods for offline token caching
  
  /// Create an offline token with 6-month expiration
  Future<void> _createOfflineToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _generateToken(length: 64); // Longer token for offline use
    final createdAt = DateTime.now();
    final expiryDate = createdAt.add(Duration(days: 180)); // 6 months
    
    await prefs.setString(_kOfflineTokenKey, token);
    await prefs.setString(_kOfflineTokenCreatedAtKey, createdAt.toIso8601String());
    await prefs.setString(_kOfflineTokenExpiryKey, expiryDate.toIso8601String());
  }
  
  /// Check if we have a valid offline token that hasn't expired
  Future<bool> hasValidOfflineToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if all required keys exist
    final token = prefs.getString(_kOfflineTokenKey);
    final createdAtStr = prefs.getString(_kOfflineTokenCreatedAtKey);
    final expiryStr = prefs.getString(_kOfflineTokenExpiryKey);
    
    if (token == null || token.isEmpty || 
        expiryStr == null || expiryStr.isEmpty ||
        createdAtStr == null || createdAtStr.isEmpty) {
      return false;
    }
    
    // Parse dates
    try {
      final createdAt = DateTime.parse(createdAtStr);
      final expiryDate = DateTime.parse(expiryStr);
      final now = DateTime.now();
      
      // Validate that the token makes sense
      // 1. Created at should be in the past
      // 2. Expiry should be in the future
      // 3. Token should not be older than 1 year (sanity check)
      final oneYearAgo = now.subtract(Duration(days: 365));
      
      if (createdAt.isAfter(now) || 
          createdAt.isBefore(oneYearAgo) ||
          expiryDate.isBefore(now)) {
        // Invalid token state, clear it
        await _clearOfflineToken();
        return false;
      }
      
      // Token is valid
      return true;
    } catch (e) {
      // If we can't parse the dates, treat as invalid and clear the token
      await _clearOfflineToken();
      return false;
    }
  }  
  /// Clear offline token
  Future<void> _clearOfflineToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOfflineTokenKey);
    await prefs.remove(_kOfflineTokenExpiryKey);
    await prefs.remove(_kOfflineTokenCreatedAtKey);
  }
}