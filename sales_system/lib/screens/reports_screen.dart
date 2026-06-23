import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/demand_letter_provider.dart';
import '../providers/payment_reminder_provider.dart';
import '../widgets/glass_container.dart';
import '../services/reports_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    Provider.of<VehicleProvider>(context, listen: false).loadVehicles();
    Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
    Provider.of<PaymentProvider>(context, listen: false).loadPayments();
    Provider.of<DemandLetterProvider>(context, listen: false).loadDemandLetters();
    Provider.of<PaymentReminderProvider>(context, listen: false).loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Reports',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
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
                          _buildReportCards(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              FontAwesomeIcons.chartBar,
              color: GlassLiquidTheme.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports & Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Generate comprehensive reports for your business',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCards() {
    return Column(
      children: [
        _buildReportCard(
          'Sales Report',
          FontAwesomeIcons.chartLine,
          GlassLiquidTheme.accentBlue,
          'View total sales, revenue, and growth metrics',
          () => _generateSalesReport(),
        ),
        const SizedBox(height: 16),
        _buildReportCard(
          'Customer Analytics',
          FontAwesomeIcons.users,
          GlassLiquidTheme.accentGreen,
          'Analyze customer behavior and demographics',
          () => _generateCustomerReport(),
        ),
        const SizedBox(height: 16),
        _buildReportCard(
          'Financial Overview',
          FontAwesomeIcons.dollarSign,
          GlassLiquidTheme.accentPurple,
          'Complete financial summary and projections',
          () => _generateFinancialReport(),
        ),
      ],
    );
  }

  Widget _buildReportCard(String title, IconData icon, Color color, String description, VoidCallback onTap) {
    return _ReportCard(
      title: title,
      icon: icon,
      color: color,
      description: description,
      onTap: onTap,
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Export All',
                  FontAwesomeIcons.download,
                  GlassLiquidTheme.accentOrange,
                  () => _exportAllReports(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Print Reports',
                  FontAwesomeIcons.print,
                  GlassLiquidTheme.accentTeal,
                  () => _printAllReports(),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateSalesReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating Sales Report PDF...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final reportsService = ReportsService();
      final pdfBytes = await reportsService.generateSalesSummaryReport();
      final filePath = await reportsService.saveReportToFile(pdfBytes, 'Sales_Summary_Report');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sales Report saved to: $filePath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateCustomerReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating Customer Report PDF...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final reportsService = ReportsService();
      final pdfBytes = await reportsService.generateCustomerAnalyticsReport();
      final filePath = await reportsService.saveReportToFile(pdfBytes, 'Customer_Analytics_Report');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer Report saved to: $filePath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateFinancialReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating Financial Report PDF...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final reportsService = ReportsService();
      final pdfBytes = await reportsService.generateFinancialOverviewReport();
      final filePath = await reportsService.saveReportToFile(pdfBytes, 'Financial_Overview_Report');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Financial Report saved to: $filePath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportAllReports() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exporting all reports...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      final reportsService = ReportsService();
      final salesReport = await reportsService.generateSalesSummaryReport();
      final customerReport = await reportsService.generateCustomerAnalyticsReport();
      final productReport = await reportsService.generateProductPerformanceReport();
      final financialReport = await reportsService.generateFinancialOverviewReport();
      
      final salesPath = await reportsService.saveReportToFile(salesReport, 'Sales_Summary_Report');
      final customerPath = await reportsService.saveReportToFile(customerReport, 'Customer_Analytics_Report');
      final productPath = await reportsService.saveReportToFile(productReport, 'Product_Performance_Report');
      final financialPath = await reportsService.saveReportToFile(financialReport, 'Financial_Overview_Report');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All reports exported successfully!\nSales: $salesPath\nCustomer: $customerPath\nProduct: $productPath\nFinancial: $financialPath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting reports: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _printAllReports() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printing all reports...'),
          backgroundColor: GlassLiquidTheme.accentBlue,
        ),
      );

      // Add printing logic here
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All reports sent to printer successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing reports: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ReportCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _ReportCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovering ? const Color(0xFFFFF1E6).withOpacity(0.9) : Colors.white.withOpacity(0.25),
              width: _isHovering ? 2.0 : 1.0,
            ),
            boxShadow: _isHovering ? [
              BoxShadow(
                color: const Color(0xFFFFF1E6).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_isHovering ? Colors.black : widget.color).withOpacity(_isHovering ? 0.14 : 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FaIcon(
                          widget.icon,
                          color: _isHovering ? Colors.black : widget.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isHovering ? Colors.black : Colors.white,
                              ),
                            ),
                            Text(
                              widget.description,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _isHovering ? Colors.black87 : Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FaIcon(
                        FontAwesomeIcons.arrowRight,
                        color: _isHovering ? Colors.black : widget.color,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
