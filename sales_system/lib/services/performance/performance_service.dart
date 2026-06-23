import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _performanceHistory = {};
  final Map<String, int> _operationCounts = {};

  // Start timing an operation
  void startTimer(String operationName) {
    if (kDebugMode) {
      _timers[operationName] = Stopwatch()..start();
      developer.log('Started timer for: $operationName');
    }
  }

  // Stop timing and record the duration
  Duration? stopTimer(String operationName) {
    if (kDebugMode) {
      final timer = _timers.remove(operationName);
      if (timer != null) {
        timer.stop();
        final duration = timer.elapsed;
        
        // Record performance history
        _performanceHistory.putIfAbsent(operationName, () => []);
        _performanceHistory[operationName]!.add(duration);
        
        // Keep only last 100 measurements
        if (_performanceHistory[operationName]!.length > 100) {
          _performanceHistory[operationName]!.removeAt(0);
        }
        
        // Update operation count
        _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
        
        developer.log('Timer stopped for: $operationName - Duration: ${duration.inMilliseconds}ms');
        return duration;
      }
    }
    return null;
  }

  // Get performance statistics for an operation
  Map<String, dynamic> getPerformanceStats(String operationName) {
    final history = _performanceHistory[operationName] ?? [];
    if (history.isEmpty) {
      return {
        'operationName': operationName,
        'count': 0,
        'averageMs': 0,
        'minMs': 0,
        'maxMs': 0,
        'totalMs': 0,
      };
    }

    final totalMs = history.fold(0, (sum, duration) => sum + duration.inMilliseconds);
    final averageMs = totalMs / history.length;
    final minMs = history.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final maxMs = history.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

    return {
      'operationName': operationName,
      'count': history.length,
      'averageMs': averageMs.round(),
      'minMs': minMs,
      'maxMs': maxMs,
      'totalMs': totalMs,
    };
  }

  // Get all performance statistics
  Map<String, Map<String, dynamic>> getAllPerformanceStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final operationName in _performanceHistory.keys) {
      stats[operationName] = getPerformanceStats(operationName);
    }
    return stats;
  }

  // Clear performance data
  void clearPerformanceData() {
    _timers.clear();
    _performanceHistory.clear();
    _operationCounts.clear();
  }

  // Check if an operation is taking too long
  bool isOperationSlow(String operationName, {int thresholdMs = 1000}) {
    final history = _performanceHistory[operationName] ?? [];
    if (history.isEmpty) return false;
    
    final recentDuration = history.last;
    return recentDuration.inMilliseconds > thresholdMs;
  }

  // Get slow operations
  List<String> getSlowOperations({int thresholdMs = 1000}) {
    final slowOperations = <String>[];
    for (final operationName in _performanceHistory.keys) {
      if (isOperationSlow(operationName, thresholdMs: thresholdMs)) {
        slowOperations.add(operationName);
      }
    }
    return slowOperations;
  }
}

// Performance monitoring mixin
mixin PerformanceMixin {
  void trackOperation(String operationName, Future<void> Function() operation) async {
    PerformanceService().startTimer(operationName);
    try {
      await operation();
    } finally {
      PerformanceService().stopTimer(operationName);
    }
  }

  Future<T> trackAsyncOperation<T>(String operationName, Future<T> Function() operation) async {
    PerformanceService().startTimer(operationName);
    try {
      return await operation();
    } finally {
      PerformanceService().stopTimer(operationName);
    }
  }

  T trackSyncOperation<T>(String operationName, T Function() operation) {
    PerformanceService().startTimer(operationName);
    try {
      return operation();
    } finally {
      PerformanceService().stopTimer(operationName);
    }
  }
}