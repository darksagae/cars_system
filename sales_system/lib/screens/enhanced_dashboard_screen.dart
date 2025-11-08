import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/analytics/analytics_service.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../models/customer.dart';
import 'dart:async';
import '../providers/theme_provider.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAnalytics());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _analyticsService.getSalesAnalytics();
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF667EEA)),
            )
          : _analytics == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load analytics',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  color: const Color(0xFF667EEA),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 24),
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        _buildChartsSection(),
                        const SizedBox(height: 24),
                        _buildRecentActivitySection(),
                        const SizedBox(height: 24),
                        _buildQuickActionsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.8),
            const Color(0xFF764BA2).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your business today',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
              FontAwesomeIcons.chartLine,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = _analytics!['stats'] as Map<String, dynamic>;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Revenue',
          'UGX ${_formatNumber(stats['totalRevenue'])}',
          FontAwesomeIcons.dollarSign,
          const Color(0xFF4CAF50),
          stats['totalRevenue'] > 0 ? '+12.5%' : '0%',
        ),
        _buildStatCard(
          'Total Customers',
          '${stats['totalCustomers']}',
          FontAwesomeIcons.users,
          const Color(0xFF2196F3),
          stats['totalCustomers'] > 0 ? '+8.2%' : '0%',
        ),
        _buildStatCard(
          'Active Invoices',
          '${stats['totalInvoices']}',
          FontAwesomeIcons.fileInvoice,
          const Color(0xFFFF9800),
          stats['totalInvoices'] > 0 ? '+15.3%' : '0%',
        ),
        _buildStatCard(
          'Outstanding Amount',
          'UGX ${_formatNumber(stats['totalOutstanding'])}',
          FontAwesomeIcons.exclamationTriangle,
          const Color(0xFFF44336),
          stats['totalOutstanding'] > 0 ? '+5.1%' : '0%',
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String change) {
    return _DashStatCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      change: change,
    );
  }

  Widget _buildChartsSection() {
    final statusBreakdown = _analytics!['statusBreakdown'] as Map<String, int>;
    final paymentMethodBreakdown = _analytics!['paymentMethodBreakdown'] as Map<String, int>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
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
              child: _buildChartCard(
                'Invoice Status',
                statusBreakdown,
                [
                  const Color(0xFF4CAF50),
                  const Color(0xFFFF9800),
                  const Color(0xFFF44336),
                  const Color(0xFF2196F3),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                'Payment Methods',
                paymentMethodBreakdown,
                [
                  const Color(0xFF9C27B0),
                  const Color(0xFF00BCD4),
                  const Color(0xFF8BC34A),
                  const Color(0xFFFF5722),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, Map<String, int> data, List<Color> colors) {
    final total = data.values.fold(0, (sum, value) => sum + value);
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Center(
              child: Text(
                'No data available',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            )
          else
            ...entries.asMap().entries.map((entry) {
              final index = entry.key;
              final dataEntry = entry.value;
              final percentage = (dataEntry.value / total * 100).round();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dataEntry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Text(
                      '${dataEntry.value} ($percentage%)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final recentInvoices = _analytics!['recentInvoices'] as List<Invoice>;
    final recentPayments = _analytics!['recentPayments'] as List<Payment>;

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildActivityCard(
                'Recent Invoices',
                recentInvoices.take(5).map((invoice) => {
                  'title': 'Invoice ${invoice.invoiceNumber}',
                  'subtitle': 'UGX ${_formatNumber(invoice.totalAmount)}',
                  'date': _formatDate(invoice.invoiceDate),
                  'status': invoice.statusText,
                }).toList(),
                FontAwesomeIcons.fileInvoice,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActivityCard(
                'Recent Payments',
                recentPayments.take(5).map((payment) => {
                  'title': 'Payment ${payment.id}',
                  'subtitle': 'UGX ${_formatNumber(payment.amount)}',
                  'date': _formatDate(payment.paymentDate),
                  'status': payment.statusText,
                }).toList(),
                FontAwesomeIcons.creditCard,
                const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard(String title, List<Map<String, String>> activities, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Center(
              child: Text(
                'No recent activity',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            )
          else
            ...activities.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title']!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          activity['subtitle']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          activity['date']!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard(
              'New Invoice',
              FontAwesomeIcons.plus,
              const Color(0xFF4CAF50),
              () => _navigateToInvoices(),
            ),
            _buildQuickActionCard(
              'Add Customer',
              FontAwesomeIcons.userPlus,
              const Color(0xFF2196F3),
              () => _navigateToCustomers(),
            ),
            _buildQuickActionCard(
              'Record Payment',
              FontAwesomeIcons.creditCard,
              const Color(0xFF9C27B0),
              () => _navigateToPayments(),
            ),
            _buildQuickActionCard(
              'Generate Report',
              FontAwesomeIcons.chartBar,
              const Color(0xFFFF9800),
              () => _navigateToReports(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return _DashActionCard(title: title, icon: icon, color: color, onTap: onTap);
  }

  void _navigateToInvoices() {
    // Navigation logic would go here
  }

  void _navigateToCustomers() {
    // Navigation logic would go here
  }

  void _navigateToPayments() {
    // Navigation logic would go here
  }

  void _navigateToReports() {
    // Navigation logic would go here
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DashStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;

  const _DashStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
  });
}

class _DashStatCardState extends State<_DashStatCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovering ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.08);
    final br = _isHovering ? const Color(0xFFFFE4C7) : Colors.white.withOpacity(0.25);
    final textColor = _isHovering ? Colors.black : Colors.white;
    final subText = _isHovering ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7);
    final iconColor = _isHovering ? Colors.black : widget.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: br),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(_isHovering ? 0.14 : 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(widget.icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.change.startsWith('+')
                        ? Colors.green.withOpacity(_isHovering ? 0.24 : 0.2)
                        : Colors.red.withOpacity(_isHovering ? 0.24 : 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.change,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: widget.change.startsWith('+') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.poppins(fontSize: 14, color: subText),
            ),
            const SizedBox(height: 4),
            Text(
              widget.value,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DashActionCardState extends State<_DashActionCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovering ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.08);
    final br = _isHovering ? const Color(0xFFFFE4C7) : Colors.white.withOpacity(0.25);
    final iconColor = _isHovering ? Colors.black : widget.color;
    final textColor = _isHovering ? Colors.black : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: br),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(_isHovering ? 0.14 : 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(widget.icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}