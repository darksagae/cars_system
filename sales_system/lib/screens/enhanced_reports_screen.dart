import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/analytics/analytics_service.dart';
// import '../services/reports/reports_service.dart'; // Service not available
import '../models/invoice.dart';
import '../models/payment.dart';
import '../models/customer.dart';
import 'dart:async';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_liquid_theme.dart';
import '../services/pdf/pdf_service.dart';
import '../services/pdf/reports_pdf_service.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class EnhancedReportsScreen extends StatefulWidget {
  const EnhancedReportsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedReportsScreen> createState() => _EnhancedReportsScreenState();
}

class _EnhancedReportsScreenState extends State<EnhancedReportsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  // final ReportsService _reportsService = ReportsService(); // Service not available
  
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedReportType = 'Sales Summary';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _analyticsService.getSalesAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Reports',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadAnalytics,
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SafeArea(
              child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFFAF0)),
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
                        'Failed to load reports',
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateRangeSelector(),
                      const SizedBox(height: 24),
                      _buildReportTypeSelector(),
                      const SizedBox(height: 24),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildDetailedReport(),
                      const SizedBox(height: 24),
                      _buildExportOptions(),
                    ],
                  ),
                ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSelector() {
    return _HoverPanel(builder: (isHover) {
      final panelBg = isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08);
      final panelBr = isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25);
      final headingColor = isHover ? Colors.black : Colors.white;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: panelBr,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: isHover ? Colors.black : const Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              Text(
                'Date Range',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  'Start Date',
                  _startDate,
                  (date) => setState(() {
                    _startDate = date;
                    _loadAnalytics();
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  'End Date',
                  _endDate,
                  (date) => setState(() {
                    _endDate = date;
                    _loadAnalytics();
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    });
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onChanged) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFFFFFAF0),
                  onPrimary: Colors.white,
                  surface: Color(0xFF1A1F3A),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFFFFAF0), size: 16),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    final reportTypes = [
      'Sales Summary',
      'Customer Analysis',
      'Payment Analysis',
      'Invoice Analysis',
      'Tax Analysis',
    ];

    return _HoverPanel(builder: (isHover) {
      final panelBg = isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08);
      final panelBr = isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25);
      final headingColor = isHover ? Colors.black : Colors.white;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: panelBr,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: isHover ? Colors.black : const Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              Text(
                'Report Type',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: reportTypes.map((type) {
              final isSelected = _selectedReportType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedReportType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
    });
  }

  Widget _buildSummaryCards() {
    final stats = _analytics!['stats'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
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
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              'Total Revenue',
              'UGX ${_formatNumber(stats['totalRevenue'])}',
              FontAwesomeIcons.dollarSign,
              const Color(0xFF4CAF50),
            ),
            _buildSummaryCard(
              'Total Invoices',
              '${stats['totalInvoices']}',
              FontAwesomeIcons.fileInvoice,
              const Color(0xFF2196F3),
            ),
            _buildSummaryCard(
              'Total Customers',
              '${stats['totalCustomers']}',
              FontAwesomeIcons.users,
              const Color(0xFF9C27B0),
            ),
            _buildSummaryCard(
              'Outstanding',
              'UGX ${_formatNumber(stats['totalOutstanding'])}',
              FontAwesomeIcons.exclamationTriangle,
              const Color(0xFFFF9800),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return _HoverPanel(builder: (isHover) {
      final panelBg = isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08);
      final panelBr = isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25);
      final headingColor = isHover ? Colors.black : Colors.white;
      final subColor = isHover ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7);
      final iconColor = isHover ? Colors.black : color;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: panelBr,
          ),
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
                  color: iconColor.withOpacity(isHover ? 0.14 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: subColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
        ],
      ),
    );
    });
  }

  Widget _buildDetailedReport() {
    return _HoverPanel(builder: (isHover) {
      final panelBg = isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08);
      final panelBr = isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25);
      final headingColor = isHover ? Colors.black : Colors.white;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: panelBr,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: isHover ? Colors.black : const Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              Text(
                'Detailed Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAnalysisSection(),
        ],
      ),
    );
    });
  }

  Widget _buildAnalysisSection() {
    switch (_selectedReportType) {
      case 'Sales Summary':
        return _buildSalesSummary();
      case 'Customer Analysis':
        return _buildCustomerAnalysis();
      case 'Payment Analysis':
        return _buildPaymentAnalysis();
      case 'Invoice Analysis':
        return _buildInvoiceAnalysis();
      case 'Tax Analysis':
        return _buildTaxAnalysis();
      default:
        return _buildSalesSummary();
    }
  }

  Widget _buildSalesSummary() {
    final stats = _analytics!['stats'] as Map<String, dynamic>;
    final statusBreakdown = _analytics!['statusBreakdown'] as Map<String, int>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricRow('Total Revenue', 'UGX ${_formatNumber(stats['totalRevenue'])}'),
        _buildMetricRow('Total Paid', 'UGX ${_formatNumber(stats['totalPaid'])}'),
        _buildMetricRow('Outstanding Amount', 'UGX ${_formatNumber(stats['totalOutstanding'])}'),
        _buildMetricRow('Average Invoice Value', 'UGX ${_formatNumber(stats['averageInvoiceValue'])}'),
        const SizedBox(height: 20),
        Text(
          'Invoice Status Breakdown',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...statusBreakdown.entries.map((entry) => _buildBreakdownRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildCustomerAnalysis() {
    final customers = _analytics!['customers'] as List<Customer>;
    final topCustomers = customers.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Customers by Revenue',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...topCustomers.map((customer) => _buildCustomerRow(customer)),
      ],
    );
  }

  Widget _buildPaymentAnalysis() {
    final paymentMethodBreakdown = _analytics!['paymentMethodBreakdown'] as Map<String, int>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...paymentMethodBreakdown.entries.map((entry) => _buildBreakdownRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildInvoiceAnalysis() {
    final invoices = _analytics!['recentInvoices'] as List<Invoice>;
    final totalInvoices = invoices.length;
    final paidInvoices = invoices.where((inv) => inv.status == InvoiceStatus.paid).length;
    final pendingInvoices = invoices.where((inv) => inv.status == InvoiceStatus.pending).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricRow('Total Invoices', '$totalInvoices'),
        _buildMetricRow('Paid Invoices', '$paidInvoices'),
        _buildMetricRow('Pending Invoices', '$pendingInvoices'),
        _buildMetricRow('Payment Rate', '${totalInvoices > 0 ? (paidInvoices / totalInvoices * 100).toStringAsFixed(1) : 0}%'),
      ],
    );
  }

  Widget _buildTaxAnalysis() {
    final invoices = _analytics!['recentInvoices'] as List<Invoice>;
    final totalTax = invoices.fold(0.0, (sum, invoice) => sum + invoice.taxAmount);
    final averageTax = invoices.isNotEmpty ? totalTax / invoices.length : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricRow('Total Tax Collected', 'UGX ${_formatNumber(totalTax)}'),
        _buildMetricRow('Average Tax per Invoice', 'UGX ${_formatNumber(averageTax)}'),
        _buildMetricRow('Tax Rate', '18%'),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(Customer customer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFFAF0).withOpacity(0.2),
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name.isNotEmpty ? customer.name : 'Unknown Customer',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  customer.email.isNotEmpty ? customer.email : 'No email',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return _HoverPanel(builder: (isHover) {
      final panelBg = isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08);
      final panelBr = isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25);
      final headingColor = isHover ? Colors.black : Colors.white;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: panelBr,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: isHover ? Colors.black : const Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              Text(
                'Export Options',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  'PDF Report',
                  FontAwesomeIcons.filePdf,
                  const Color(0xFFF44336),
                  () => _exportPDF(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(
                  'Excel Report',
                  FontAwesomeIcons.fileExcel,
                  const Color(0xFF4CAF50),
                  () => _exportExcel(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    });
  }

  Widget _buildExportButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: FaIcon(icon, color: Colors.white),
      label: Text(
        title,
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _exportPDF() async {
    try {
      if (_analytics == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No analytics data to export'), backgroundColor: Colors.red),
        );
        return;
      }

      final pdfService = PDFService();
      final bytes = await pdfService.generateAnalyticsReport(
        analytics: _analytics!,
        startDate: _startDate,
        endDate: _endDate,
        reportTitle: _selectedReportType,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'NSB_${_selectedReportType.replaceAll(' ', '_')}_${_startDate.year}${_startDate.month}${_startDate.day}-${_endDate.year}${_endDate.month}${_endDate.day}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportExcel() async {
    try {
      if (_analytics == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No analytics data to export'), backgroundColor: Colors.red),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating Excel report...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Create Excel file
      final excel = Excel.createExcel();
      excel.delete('Sheet1'); // Delete default sheet
      final sheet = excel[_selectedReportType.replaceAll(' ', '_')];

      // Get data
      final stats = _analytics!['stats'] as Map<String, dynamic>;
      final statusBreakdown = _analytics!['statusBreakdown'] as Map<String, dynamic>;
      final paymentMethodBreakdown = _analytics!['paymentMethodBreakdown'] as Map<String, dynamic>;
      final recentInvoices = _analytics!['recentInvoices'] as List<Invoice>;
      final customers = _analytics!['customers'] as List<Customer>;
      final topCustomers = _analytics!['topCustomers'] as List<dynamic>;

      int rowIndex = 0;

      // Header
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('NSB Motors Uganda');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
      );
      rowIndex++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(_selectedReportType);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
      );
      rowIndex++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(
          'Period: ${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}');
      rowIndex++;
      rowIndex++; // Empty row

      // Summary Section
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Summary');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
      );
      rowIndex++;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Total Revenue');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 
          TextCellValue('UGX ${_formatNumber(stats['totalRevenue'] ?? 0.0)}');
      rowIndex++;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Total Invoices');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = IntCellValue(stats['totalInvoices'] ?? 0);
      rowIndex++;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Total Customers');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = IntCellValue(stats['totalCustomers'] ?? 0);
      rowIndex++;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Outstanding');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = 
          TextCellValue('UGX ${_formatNumber(stats['totalOutstanding'] ?? 0.0)}');
      rowIndex++;
      rowIndex++; // Empty row

      // Status Breakdown
      if (statusBreakdown.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Invoice Status Breakdown');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
        );
        rowIndex++;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Status');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Count');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
        rowIndex++;
        
        statusBreakdown.forEach((key, value) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(key);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = IntCellValue(value);
          rowIndex++;
        });
        rowIndex++; // Empty row
      }

      // Payment Method Breakdown
      if (paymentMethodBreakdown.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Payment Methods');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
        );
        rowIndex++;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Method');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Count');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
        rowIndex++;
        
        paymentMethodBreakdown.forEach((key, value) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(key);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = IntCellValue(value);
          rowIndex++;
        });
        rowIndex++; // Empty row
      }

      // Recent Invoices
      if (recentInvoices.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Recent Invoices');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
        );
        rowIndex++;
        
        // Headers
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue('Invoice #');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Customer');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue('Amount');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue('Status');
        for (int i = 0; i < 4; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).cellStyle = CellStyle(bold: true);
        }
        rowIndex++;
        
        // Data rows
        for (final invoice in recentInvoices.take(20)) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(invoice.invoiceNumber);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(invoice.customer?.name ?? 'N/A');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue('UGX ${_formatNumber(invoice.totalAmount)}');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(invoice.status.name);
          rowIndex++;
        }
      }

      // Save Excel file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'NSB_${_selectedReportType.replaceAll(' ', '_')}_${_startDate.year}${_startDate.month}${_startDate.day}-${_endDate.year}${_endDate.month}${_endDate.day}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        if (!mounted) return;
        
        // Open the file
        try {
          await OpenFilex.open(filePath);
        } catch (e) {
          // If opening fails, just show the path
          print('Could not open file automatically: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel report saved to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to generate Excel file');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}

class _HoverPanel extends StatefulWidget {
  final Widget Function(bool isHover) builder;
  const _HoverPanel({required this.builder});
  @override
  State<_HoverPanel> createState() => _HoverPanelState();
}

class _HoverPanelState extends State<_HoverPanel> {
  bool _isHover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: widget.builder(_isHover),
    );
  }
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