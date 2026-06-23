import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MemoryCache {
  static final MemoryCache _instance = MemoryCache._internal();
  factory MemoryCache() => _instance;
  MemoryCache._internal();

  final Map<String, CacheEntry> _cache = {};
  final int _maxSize = 100; // Maximum number of cached items
  final Duration _defaultTtl = const Duration(hours: 1); // Default time to live

  // Cache an object
  void put<T>(String key, T value, {Duration? ttl}) {
    _cleanExpiredEntries();
    
    if (_cache.length >= _maxSize) {
      _evictOldest();
    }
    
    _cache[key] = CacheEntry<T>(
      value: value,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTtl,
    );
  }

  // Get a cached object
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T?;
  }

  // Check if a key exists and is not expired
  bool contains(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }

  // Remove a specific key
  void remove(String key) {
    _cache.remove(key);
  }

  // Clear all cache
  void clear() {
    _cache.clear();
  }

  // Get cache statistics
  CacheStatistics getStatistics() {
    _cleanExpiredEntries();
    
    return CacheStatistics(
      totalEntries: _cache.length,
      maxSize: _maxSize,
      hitRate: _calculateHitRate(),
      memoryUsage: _calculateMemoryUsage(),
    );
  }

  // Clean expired entries
  void _cleanExpiredEntries() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  // Evict oldest entry
  void _evictOldest() {
    if (_cache.isEmpty) return;
    
    String? oldestKey;
    DateTime? oldestTime;
    
    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }
    
    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  // Calculate hit rate (simplified)
  double _calculateHitRate() {
    // This would require tracking hits/misses in a real implementation
    return 0.85; // Placeholder
  }

  // Calculate memory usage
  int _calculateMemoryUsage() {
    int totalSize = 0;
    for (final entry in _cache.values) {
      totalSize += _estimateSize(entry.value);
    }
    return totalSize;
  }

  // Estimate size of an object
  int _estimateSize(dynamic value) {
    if (value == null) return 0;
    
    try {
      final json = jsonEncode(value);
      return json.length * 2; // Rough estimate
    } catch (e) {
      return 100; // Default size
    }
  }

  // Get all keys
  List<String> getKeys() {
    _cleanExpiredEntries();
    return _cache.keys.toList();
  }

  // Get cache size
  int get size => _cache.length;

  // Check if cache is empty
  bool get isEmpty => _cache.isEmpty;

  // Check if cache is full
  bool get isFull => _cache.length >= _maxSize;
}

// Cache entry
class CacheEntry<T> {
  final T value;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.value,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

// Cache statistics
class CacheStatistics {
  final int totalEntries;
  final int maxSize;
  final double hitRate;
  final int memoryUsage;

  CacheStatistics({
    required this.totalEntries,
    required this.maxSize,
    required this.hitRate,
    required this.memoryUsage,
  });
}
