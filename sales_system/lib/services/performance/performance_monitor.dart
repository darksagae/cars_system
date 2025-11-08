import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _measurements = {};
  final List<PerformanceMetric> _metrics = [];
  Timer? _memoryTimer;
  Timer? _cpuTimer;

  // Start monitoring
  void startMonitoring() {
    _startMemoryMonitoring();
    _startCpuMonitoring();
  }

  // Stop monitoring
  void stopMonitoring() {
    _memoryTimer?.cancel();
    _cpuTimer?.cancel();
  }

  // Start timing an operation
  void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  // End timing an operation
  Duration endTimer(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) return Duration.zero;
    
    final duration = DateTime.now().difference(startTime);
    _recordMeasurement(operation, duration);
    return duration;
  }

  // Record a measurement
  void _recordMeasurement(String operation, Duration duration) {
    _measurements.putIfAbsent(operation, () => []);
    _measurements[operation]!.add(duration);
    
    // Keep only last 100 measurements per operation
    if (_measurements[operation]!.length > 100) {
      _measurements[operation]!.removeAt(0);
    }
  }

  // Get average time for an operation
  Duration getAverageTime(String operation) {
    final measurements = _measurements[operation];
    if (measurements == null || measurements.isEmpty) return Duration.zero;
    
    final totalMicroseconds = measurements.fold<int>(
      0, (sum, duration) => sum + duration.inMicroseconds
    );
    return Duration(microseconds: totalMicroseconds ~/ measurements.length);
  }

  // Get performance metrics
  List<PerformanceMetric> getMetrics() {
    return List.from(_metrics);
  }

  // Get operation statistics
  Map<String, OperationStats> getOperationStats() {
    final stats = <String, OperationStats>{};
    
    for (final operation in _measurements.keys) {
      final measurements = _measurements[operation]!;
      if (measurements.isNotEmpty) {
        measurements.sort();
        stats[operation] = OperationStats(
          operation: operation,
          count: measurements.length,
          averageTime: getAverageTime(operation),
          minTime: measurements.first,
          maxTime: measurements.last,
          totalTime: measurements.fold<Duration>(
            Duration.zero, (sum, duration) => sum + duration
          ),
        );
      }
    }
    
    return stats;
  }

  // Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _recordMemoryUsage();
    });
  }

  // Start CPU monitoring
  void _startCpuMonitoring() {
    _cpuTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _recordCpuUsage();
    });
  }

  // Record memory usage
  void _recordMemoryUsage() {
    if (kDebugMode) {
      // In debug mode, we can't get real memory usage
      return;
    }
    
    try {
      final memoryUsage = ProcessInfo.currentRss;
      _addMetric(PerformanceMetric(
        type: MetricType.memory,
        value: memoryUsage.toDouble(),
        timestamp: DateTime.now(),
        unit: 'bytes',
      ));
    } catch (e) {
      // Memory monitoring not available
    }
  }

  // Record CPU usage (simplified)
  void _recordCpuUsage() {
    // CPU monitoring is complex and platform-specific
    // For now, we'll track operation frequency as a proxy
    final totalOperations = _measurements.values
        .fold<int>(0, (sum, list) => sum + list.length);
    
    _addMetric(PerformanceMetric(
      type: MetricType.cpu,
      value: totalOperations.toDouble(),
      timestamp: DateTime.now(),
      unit: 'operations',
    ));
  }

  // Add a performance metric
  void _addMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Keep only last 1000 metrics
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
  }

  // Clear old metrics
  void clearOldMetrics() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
  }

  // Get performance summary
  PerformanceSummary getSummary() {
    final stats = getOperationStats();
    final recentMetrics = _metrics.where((metric) => 
      metric.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 1)))
    ).toList();

    return PerformanceSummary(
      totalOperations: stats.values.fold<int>(0, (sum, stat) => sum + stat.count),
      averageResponseTime: _calculateAverageResponseTime(stats),
      memoryUsage: _getCurrentMemoryUsage(),
      cpuUsage: _getCurrentCpuUsage(),
      slowestOperation: _getSlowestOperation(stats),
      fastestOperation: _getFastestOperation(stats),
      recentMetrics: recentMetrics,
    );
  }

  Duration _calculateAverageResponseTime(Map<String, OperationStats> stats) {
    if (stats.isEmpty) return Duration.zero;
    
    final totalTime = stats.values.fold<Duration>(
      Duration.zero, (sum, stat) => sum + stat.totalTime
    );
    final totalCount = stats.values.fold<int>(
      0, (sum, stat) => sum + stat.count
    );
    
    return totalCount > 0 
        ? Duration(microseconds: totalTime.inMicroseconds ~/ totalCount)
        : Duration.zero;
  }

  double _getCurrentMemoryUsage() {
    try {
      return ProcessInfo.currentRss.toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  double _getCurrentCpuUsage() {
    // Simplified CPU usage calculation
    final recentOperations = _measurements.values
        .fold<int>(0, (sum, list) => sum + list.length);
    return recentOperations.toDouble();
  }

  String? _getSlowestOperation(Map<String, OperationStats> stats) {
    if (stats.isEmpty) return null;
    
    return stats.entries
        .reduce((a, b) => a.value.averageTime > b.value.averageTime ? a : b)
        .key;
  }

  String? _getFastestOperation(Map<String, OperationStats> stats) {
    if (stats.isEmpty) return null;
    
    return stats.entries
        .reduce((a, b) => a.value.averageTime < b.value.averageTime ? a : b)
        .key;
  }
}

// Performance metric data class
class PerformanceMetric {
  final MetricType type;
  final double value;
  final DateTime timestamp;
  final String unit;

  PerformanceMetric({
    required this.type,
    required this.value,
    required this.timestamp,
    required this.unit,
  });
}

// Operation statistics
class OperationStats {
  final String operation;
  final int count;
  final Duration averageTime;
  final Duration minTime;
  final Duration maxTime;
  final Duration totalTime;

  OperationStats({
    required this.operation,
    required this.count,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.totalTime,
  });
}

// Performance summary
class PerformanceSummary {
  final int totalOperations;
  final Duration averageResponseTime;
  final double memoryUsage;
  final double cpuUsage;
  final String? slowestOperation;
  final String? fastestOperation;
  final List<PerformanceMetric> recentMetrics;

  PerformanceSummary({
    required this.totalOperations,
    required this.averageResponseTime,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.slowestOperation,
    required this.fastestOperation,
    required this.recentMetrics,
  });
}

// Metric types
enum MetricType {
  memory,
  cpu,
  database,
  network,
  ui,
}
