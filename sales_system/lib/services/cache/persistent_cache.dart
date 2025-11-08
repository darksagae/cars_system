import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistentCache {
  static final PersistentCache _instance = PersistentCache._internal();
  factory PersistentCache() => _instance;
  PersistentCache._internal();

  late SharedPreferences _prefs;
  late Directory _cacheDir;
  final Map<String, CacheMetadata> _metadata = {};

  // Initialize cache
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cacheDir = await getApplicationDocumentsDirectory();
    await _loadMetadata();
  }

  // Store data in cache
  Future<void> put(String key, dynamic data, {Duration? ttl}) async {
    try {
      final jsonData = jsonEncode(data);
      final file = File('${_cacheDir.path}/cache_$key.json');
      await file.writeAsString(jsonData);
      
      _metadata[key] = CacheMetadata(
        key: key,
        timestamp: DateTime.now(),
        ttl: ttl ?? const Duration(days: 7),
        size: jsonData.length,
      );
      
      await _saveMetadata();
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  // Get data from cache
  Future<T?> get<T>(String key) async {
    try {
      if (!_metadata.containsKey(key)) return null;
      
      final metadata = _metadata[key]!;
      if (metadata.isExpired) {
        await remove(key);
        return null;
      }
      
      final file = File('${_cacheDir.path}/cache_$key.json');
      if (!await file.exists()) {
        await remove(key);
        return null;
      }
      
      final jsonData = await file.readAsString();
      return jsonDecode(jsonData) as T?;
    } catch (e) {
      print('Error retrieving cached data: $e');
      return null;
    }
  }

  // Check if key exists and is not expired
  Future<bool> contains(String key) async {
    if (!_metadata.containsKey(key)) return false;
    
    final metadata = _metadata[key]!;
    if (metadata.isExpired) {
      await remove(key);
      return false;
    }
    
    return true;
  }

  // Remove a specific key
  Future<void> remove(String key) async {
    try {
      final file = File('${_cacheDir.path}/cache_$key.json');
      if (await file.exists()) {
        await file.delete();
      }
      
      _metadata.remove(key);
      await _saveMetadata();
    } catch (e) {
      print('Error removing cached data: $e');
    }
  }

  // Clear all cache
  Future<void> clear() async {
    try {
      final files = await _cacheDir.list().toList();
      for (final file in files) {
        if (file.path.contains('cache_') && file.path.endsWith('.json')) {
          await file.delete();
        }
      }
      
      _metadata.clear();
      await _saveMetadata();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Clean expired entries
  Future<void> cleanExpired() async {
    final expiredKeys = <String>[];
    
    for (final entry in _metadata.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      await remove(key);
    }
  }

  // Get cache statistics
  CacheStatistics getStatistics() {
    int totalSize = 0;
    int expiredCount = 0;
    
    for (final metadata in _metadata.values) {
      totalSize += metadata.size;
      if (metadata.isExpired) {
        expiredCount++;
      }
    }
    
    return CacheStatistics(
      totalEntries: _metadata.length,
      totalSize: totalSize,
      expiredEntries: expiredCount,
      validEntries: _metadata.length - expiredCount,
    );
  }

  // Load metadata from SharedPreferences
  Future<void> _loadMetadata() async {
    try {
      final metadataJson = _prefs.getString('cache_metadata');
      if (metadataJson != null) {
        final List<dynamic> metadataList = jsonDecode(metadataJson);
        for (final item in metadataList) {
          final metadata = CacheMetadata.fromJson(item);
          _metadata[metadata.key] = metadata;
        }
      }
    } catch (e) {
      print('Error loading cache metadata: $e');
    }
  }

  // Save metadata to SharedPreferences
  Future<void> _saveMetadata() async {
    try {
      final metadataList = _metadata.values.map((m) => m.toJson()).toList();
      final metadataJson = jsonEncode(metadataList);
      await _prefs.setString('cache_metadata', metadataJson);
    } catch (e) {
      print('Error saving cache metadata: $e');
    }
  }

  // Get all keys
  List<String> getKeys() {
    return _metadata.keys.toList();
  }

  // Get cache size
  int get size => _metadata.length;

  // Check if cache is empty
  bool get isEmpty => _metadata.isEmpty;
}

// Cache metadata
class CacheMetadata {
  final String key;
  final DateTime timestamp;
  final Duration ttl;
  final int size;

  CacheMetadata({
    required this.key,
    required this.timestamp,
    required this.ttl,
    required this.size,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inMilliseconds,
      'size': size,
    };
  }

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      key: json['key'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl']),
      size: json['size'],
    );
  }
}

// Cache statistics
class CacheStatistics {
  final int totalEntries;
  final int totalSize;
  final int expiredEntries;
  final int validEntries;

  CacheStatistics({
    required this.totalEntries,
    required this.totalSize,
    required this.expiredEntries,
    required this.validEntries,
  });
}
