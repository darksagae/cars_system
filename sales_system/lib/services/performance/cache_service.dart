import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  SharedPreferences? _prefs;

  // Initialize cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Cache data in memory with TTL
  void setMemoryCache(String key, dynamic value, {Duration? ttl}) {
    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
    
    if (ttl != null) {
      Timer(ttl, () {
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      });
    }
  }

  // Get data from memory cache
  T? getMemoryCache<T>(String key, {Duration? maxAge}) {
    if (!_memoryCache.containsKey(key)) return null;
    
    if (maxAge != null) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && DateTime.now().difference(timestamp) > maxAge) {
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        return null;
      }
    }
    
    return _memoryCache[key] as T?;
  }

  // Cache data persistently
  Future<void> setPersistentCache(String key, dynamic value) async {
    await initialize();
    if (value is String) {
      await _prefs!.setString(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    } else {
      await _prefs!.setString(key, jsonEncode(value));
    }
  }

  // Get data from persistent cache
  Future<T?> getPersistentCache<T>(String key) async {
    await initialize();
    
    if (T == String) {
      return _prefs!.getString(key) as T?;
    } else if (T == int) {
      return _prefs!.getInt(key) as T?;
    } else if (T == double) {
      return _prefs!.getDouble(key) as T?;
    } else if (T == bool) {
      return _prefs!.getBool(key) as T?;
    } else {
      final jsonString = _prefs!.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as T?;
      }
    }
    
    return null;
  }

  // Clear specific cache entry
  void clearMemoryCache(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  // Clear all memory cache
  void clearAllMemoryCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  // Clear persistent cache
  Future<void> clearPersistentCache() async {
    await initialize();
    await _prefs!.clear();
  }

  // Check if cache entry exists and is valid
  bool hasValidCache(String key, {Duration? maxAge}) {
    if (!_memoryCache.containsKey(key)) return false;
    
    if (maxAge != null) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && DateTime.now().difference(timestamp) > maxAge) {
        return false;
      }
    }
    
    return true;
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCacheSize': _memoryCache.length,
      'oldestEntry': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newestEntry': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
}

// Cache mixin for easy integration
mixin CacheMixin {
  final CacheService _cacheService = CacheService();

  // Cache with automatic key generation
  void cacheData(String prefix, String id, dynamic data, {Duration? ttl}) {
    final key = '${prefix}_$id';
    _cacheService.setMemoryCache(key, data, ttl: ttl);
  }

  // Get cached data
  T? getCachedData<T>(String prefix, String id) {
    final key = '${prefix}_$id';
    return _cacheService.getMemoryCache<T>(key);
  }

  // Cache with validation
  T? getCachedDataWithValidation<T>(String prefix, String id, {Duration? maxAge}) {
    final key = '${prefix}_$id';
    if (_cacheService.hasValidCache(key, maxAge: maxAge)) {
      return _cacheService.getMemoryCache<T>(key);
    }
    return null;
  }
}