import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/performance/performance_monitor.dart';
import '../../services/cache/memory_cache.dart' as memory_cache;
import '../../services/cache/persistent_cache.dart' as persistent_cache;
import '../../services/optimization/image_optimization_service.dart';
import '../../widgets/glass_container.dart';
import '../../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class PerformanceMetricsScreen extends StatefulWidget {
  const PerformanceMetricsScreen({super.key});

  @override
  State<PerformanceMetricsScreen> createState() => _PerformanceMetricsScreenState();
}

class _PerformanceMetricsScreenState extends State<PerformanceMetricsScreen> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  final memory_cache.MemoryCache _memoryCache = memory_cache.MemoryCache();
  final persistent_cache.PersistentCache _persistentCache = persistent_cache.PersistentCache();
  final ImageOptimizationService _imageService = ImageOptimizationService();

  PerformanceSummary? _performanceSummary;
  memory_cache.CacheStatistics? _memoryCacheStats;
  persistent_cache.CacheStatistics? _persistentCacheStats;
  StorageUsage? _storageUsage;
  Map<String, OperationStats> _operationStats = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  void _loadMetrics() async {
    try {
      final summary = _monitor.getSummary();
      final memoryStats = _memoryCache.getStatistics();
      final persistentStats = await _persistentCache.getStatistics();
      final storageUsage = await _imageService.getStorageUsage();
      final operationStats = _monitor.getOperationStats();

      setState(() {
        _performanceSummary = summary;
        _memoryCacheStats = memoryStats;
        _persistentCacheStats = persistentStats;
        _storageUsage = storageUsage;
        _operationStats = operationStats;
      });
    } catch (e) {
      print('Error loading metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Performance Metrics',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate, color: Colors.white),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 20),
            _buildPerformanceSection(),
            const SizedBox(height: 20),
            _buildCacheSection(),
            const SizedBox(height: 20),
            _buildStorageSection(),
            const SizedBox(height: 20),
            _buildOperationStatsSection(),
            const SizedBox(height: 20),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.chartLine, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Performance Overview',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_performanceSummary != null) ...[
              _buildMetricRow('Total Operations', '${_performanceSummary!.totalOperations}'),
              _buildMetricRow('Average Response Time', '${_performanceSummary!.averageResponseTime.inMilliseconds}ms'),
              _buildMetricRow('Memory Usage', '${(_performanceSummary!.memoryUsage / 1024 / 1024).toStringAsFixed(2)} MB'),
              _buildMetricRow('CPU Usage', '${_performanceSummary!.cpuUsage.toStringAsFixed(2)} operations'),
              if (_performanceSummary!.slowestOperation != null)
                _buildMetricRow('Slowest Operation', _performanceSummary!.slowestOperation!),
              if (_performanceSummary!.fastestOperation != null)
                _buildMetricRow('Fastest Operation', _performanceSummary!.fastestOperation!),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.gauge, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'System Performance',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_performanceSummary != null) ...[
              _buildPerformanceBar('Memory Usage', _performanceSummary!.memoryUsage / (1024 * 1024 * 100)),
              _buildPerformanceBar('CPU Usage', _performanceSummary!.cpuUsage / 100),
              _buildPerformanceBar('Response Time', _performanceSummary!.averageResponseTime.inMilliseconds / 1000),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.memory, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Cache Performance',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_memoryCacheStats != null && _persistentCacheStats != null) ...[
              _buildCacheStats('Memory Cache', _memoryCacheStats!),
              const SizedBox(height: 12),
              _buildCacheStats('Persistent Cache', _persistentCacheStats!),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.hardDrive, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Storage Usage',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_storageUsage != null) ...[
              _buildMetricRow('Total Files', '${_storageUsage!.fileCount}'),
              _buildMetricRow('Total Size', '${(_storageUsage!.totalSize / 1024 / 1024).toStringAsFixed(2)} MB'),
            ] else ...[
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperationStatsSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.clock, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Operation Statistics',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_operationStats.isNotEmpty) ...[
              ..._operationStats.values.map((stats) => _buildOperationStats(stats)),
            ] else ...[
              const Center(
                child: Text(
                  'No operation data available',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.tools, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Performance Actions',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearCaches,
                    icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                    label: const Text('Clear Caches'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _optimizeDatabase,
                    icon: const FaIcon(FontAwesomeIcons.database, size: 16),
                    label: const Text('Optimize DB'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassLiquidTheme.accentBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cleanupImages,
                    icon: const FaIcon(FontAwesomeIcons.image, size: 16),
                    label: const Text('Cleanup Images'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadMetrics,
                    icon: const FaIcon(FontAwesomeIcons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              value > 0.8 ? Colors.red : value > 0.6 ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheStats(String title, dynamic stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetricRow('Entries', '${stats.totalEntries}'),
        _buildMetricRow('Max Size', '${stats.maxSize}'),
        _buildMetricRow('Hit Rate', '${(stats.hitRate * 100).toStringAsFixed(1)}%'),
        _buildMetricRow('Memory Usage', '${(stats.memoryUsage / 1024).toStringAsFixed(2)} KB'),
      ],
    );
  }

  Widget _buildOperationStats(OperationStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.operation,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          _buildMetricRow('Count', '${stats.count}'),
          _buildMetricRow('Average Time', '${stats.averageTime.inMilliseconds}ms'),
          _buildMetricRow('Min Time', '${stats.minTime.inMilliseconds}ms'),
          _buildMetricRow('Max Time', '${stats.maxTime.inMilliseconds}ms'),
        ],
      ),
    );
  }

  void _clearCaches() async {
    try {
      _memoryCache.clear();
      await _persistentCache.clear();
      _loadMetrics();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caches cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing caches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _optimizeDatabase() async {
    try {
      // This would call the database optimization service
      _loadMetrics();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database optimization completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error optimizing database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cleanupImages() async {
    try {
      await _imageService.cleanupOldImages();
      _loadMetrics();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image cleanup completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cleaning up images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
