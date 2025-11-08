import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-refresh every 3 seconds for real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<AppProvider>().refresh();
        _startAutoRefresh(); // Schedule next refresh
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'NSB Motors Management',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.read<AppProvider>().refresh();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading && appProvider.systemStats == null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context),
                const SizedBox(height: 20),
                _buildStatsGrid(appProvider),
                const SizedBox(height: 20),
                _buildQuickActions(context, appProvider),
                const SizedBox(height: 20),
                _buildRecentActivity(appProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 140,
          width: double.infinity,
          child: Image.asset(
            'assets/logo/logo.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.8),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AppProvider appProvider) {
    final stats = appProvider.systemStats ?? {};
    
    // Prepare last update display without year (e.g., "November 2025" -> "November")
    String lastUpdateRaw = '${stats['last_database_update'] ?? 'Never'}';
    String lastUpdateDisplay = lastUpdateRaw;
    if (lastUpdateRaw.contains(' ')) {
      lastUpdateDisplay = lastUpdateRaw.split(' ').first;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Active Clients',
          '${stats['active_clients'] ?? 0}',
          Icons.computer,
          const Color(0xFF667EEA),
        ),
        _buildStatCard(
          'Last Update',
          lastUpdateDisplay,
          Icons.update,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'Exchange Rate',
          'UGX ${(stats['current_exchange_rate'] ?? 3700.0).toStringAsFixed(0)}',
          Icons.currency_exchange,
          const Color(0xFFFF9800),
        ),
        _buildStatCard(
          'Database Status',
          'Online',
          Icons.cloud_done,
          const Color(0xFF2196F3),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Update Database',
                'Upload new URA data',
                Icons.storage,
                const Color(0xFF4CAF50),
                () {
                  Navigator.of(context).pushNamed('/database');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Manage Clients',
                'View all desktop clients',
                Icons.computer,
                const Color(0xFF667EEA),
                () {
                  Navigator.of(context).pushNamed('/clients');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AppProvider appProvider) {
    final clients = appProvider.desktopClients;
    final stats = appProvider.systemStats ?? {};
    
    // Get most recent client activity
    String? mostRecentClientTime;
    String? mostRecentClientName;
    if (clients.isNotEmpty) {
      final latestClient = clients.first;
      mostRecentClientName = latestClient['client_name'] ?? 'Unknown';
      final lastSeen = latestClient['last_seen'] ?? '';
      if (lastSeen.isNotEmpty) {
        mostRecentClientTime = _formatTimeAgo(lastSeen);
      }
    }
    
    // Get exchange rate info
    final exchangeRate = stats['current_exchange_rate'] ?? 3700.0;
    final exchangeRateDate = stats['exchange_rate_date'];
    String? exchangeRateTime;
    if (exchangeRateDate != null) {
      exchangeRateTime = _formatTimeAgo(exchangeRateDate.toString());
    }
    
    // Get last database update
    final lastDbUpdate = stats['last_database_update'];
    final lastDbUpdateDate = stats['last_update_date'];
    String? dbUpdateTime;
    if (lastDbUpdateDate != null && lastDbUpdate != 'Never') {
      dbUpdateTime = _formatTimeAgo(lastDbUpdateDate.toString());
    }
    
    List<Widget> activityItems = [];
    
    // Add client activity if available
    if (mostRecentClientTime != null && mostRecentClientName != null) {
      activityItems.add(
        _buildActivityItem(
          Icons.computer,
          'Desktop Client Active',
          '$mostRecentClientName is online',
          mostRecentClientTime,
          const Color(0xFF4CAF50),
        ),
      );
      if (exchangeRateTime != null || dbUpdateTime != null) {
        activityItems.add(const Divider(color: Colors.white12));
      }
    }
    
    // Add exchange rate update if available
    if (exchangeRateTime != null) {
      activityItems.add(
        _buildActivityItem(
          Icons.update,
          'Exchange Rate',
          'USD to UGX: ${exchangeRate.toStringAsFixed(0)}',
          exchangeRateTime,
          const Color(0xFFFF9800),
        ),
      );
      if (dbUpdateTime != null) {
        activityItems.add(const Divider(color: Colors.white12));
      }
    }
    
    // Add database update if available
    if (dbUpdateTime != null && lastDbUpdate != 'Never') {
      activityItems.add(
        _buildActivityItem(
          Icons.storage,
          'URA Database',
          '$lastDbUpdate database',
          dbUpdateTime,
          const Color(0xFF2196F3),
        ),
      );
    }
    
    // Show empty state if no activity
    if (activityItems.isEmpty) {
      activityItems.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No recent activity',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white54,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(children: activityItems),
        ),
      ],
    );
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

