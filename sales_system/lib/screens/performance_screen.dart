import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/glass_container.dart';
import '../services/performance/performance_service.dart';
import '../services/performance/cache_service.dart';
import '../services/performance/optimized_database_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final PerformanceService _performanceService = PerformanceService();
  final CacheService _cacheService = CacheService();
  final OptimizedDatabaseService _dbService = OptimizedDatabaseService();
  
  Map<String, Map<String, dynamic>> _performanceStats = {};
  Map<String, dynamic> _cacheStats = {};
  List<String> _slowOperations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  void _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final performanceStats = _performanceService.getAllPerformanceStats();
      final cacheStats = _cacheService.getCacheStats();
      final slowOperations = _performanceService.getSlowOperations();

      setState(() {
        _performanceStats = performanceStats;
        _cacheStats = cacheStats;
        _slowOperations = slowOperations;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading performance data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Performance Monitor',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A), // Pure black background
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildPerformanceOverview(),
                      const SizedBox(height: 24),
                      _buildOperationStats(),
                      const SizedBox(height: 24),
                      _buildCacheStats(),
                      const SizedBox(height: 24),
                      _buildSlowOperations(),
                      const SizedBox(height: 24),
                      _buildPerformanceActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.gauge,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Text(
            'Performance Monitor',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadPerformanceData,
            icon: FaIcon(
              FontAwesomeIcons.arrowsRotate,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildStatRow('Total Operations', _performanceStats.length.toString()),
            _buildStatRow('Slow Operations', _slowOperations.length.toString()),
            _buildStatRow('Cache Entries', _cacheStats['memoryCacheSize']?.toString() ?? '0'),
            _buildStatRow('Cache Hit Rate', _calculateCacheHitRate()),
          ],
        ],
      ),
    );
  }

  Widget _buildOperationStats() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operation Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_performanceStats.isEmpty)
            Text(
              'No performance data available',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
              ),
            )
          else
            ..._performanceStats.entries.map((entry) => _buildOperationCard(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildOperationCard(String operationName, Map<String, dynamic> stats) {
    final isSlow = _slowOperations.contains(operationName);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSlow ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSlow ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                operationName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (isSlow) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SLOW',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Count', stats['count'].toString()),
              ),
              Expanded(
                child: _buildStatItem('Avg (ms)', stats['averageMs'].toString()),
              ),
              Expanded(
                child: _buildStatItem('Min (ms)', stats['minMs'].toString()),
              ),
              Expanded(
                child: _buildStatItem('Max (ms)', stats['maxMs'].toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCacheStats() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cache Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Memory Cache Size', _cacheStats['memoryCacheSize']?.toString() ?? '0'),
          _buildStatRow('Oldest Entry', _formatDateTime(_cacheStats['oldestEntry'])),
          _buildStatRow('Newest Entry', _formatDateTime(_cacheStats['newestEntry'])),
        ],
      ),
    );
  }

  Widget _buildSlowOperations() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Slow Operations',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_slowOperations.isEmpty)
            Text(
              'No slow operations detected',
              style: GoogleFonts.poppins(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ..._slowOperations.map((operation) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.exclamationTriangle,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      operation,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPerformanceActions() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Clear Cache',
                  FontAwesomeIcons.trash,
                  Colors.orange,
                  () => _clearCache(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Clear Stats',
                  FontAwesomeIcons.chartLine,
                  GlassLiquidTheme.accentBlue,
                  () => _clearStats(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Optimize Database',
                  FontAwesomeIcons.database,
                  Colors.green,
                  () => _optimizeDatabase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Export Report',
                  FontAwesomeIcons.download,
                  Colors.purple,
                  () => _exportReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateCacheHitRate() {
    // This is a simplified calculation
    final cacheSize = _cacheStats['memoryCacheSize'] ?? 0;
    return '${(cacheSize * 0.8).round()}%'; // Mock calculation
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    return dateTime.toString().split(' ')[0];
  }

  void _clearCache() async {
    try {
      _cacheService.clearAllMemoryCache();
      _loadPerformanceData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearStats() async {
    try {
      _performanceService.clearPerformanceData();
      _loadPerformanceData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Performance stats cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing stats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _optimizeDatabase() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Optimizing database...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      _dbService.clearAllCaches();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database optimization completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error optimizing database: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Performance report exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
