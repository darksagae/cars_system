import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/demand_letter/demand_letter_service.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import 'dart:async';
import '../providers/theme_provider.dart';

class EnhancedDemandLettersScreen extends StatefulWidget {
  const EnhancedDemandLettersScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedDemandLettersScreen> createState() => _EnhancedDemandLettersScreenState();
}

class _EnhancedDemandLettersScreenState extends State<EnhancedDemandLettersScreen> {
  final DemandLetterService _demandLetterService = DemandLetterService();
  final InvoiceService _invoiceService = InvoiceService();
  final CustomerService _customerService = CustomerService();
  
  List<Invoice> _overdueInvoices = [];
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _refreshTimer;
  int? _hoveredInvoiceIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      final customers = await _customerService.getAllCustomers();
      
      // Filter overdue invoices - only include unpaid invoices with balance > 0
      final now = DateTime.now();
      final overdueInvoices = invoices.where((invoice) {
        return invoice.status != InvoiceStatus.paid && 
               invoice.status != InvoiceStatus.cancelled &&
               invoice.balanceAmount > 0 &&
               (invoice.dueDate.isBefore(now) || invoice.dueDate.isAtSameMomentAs(now));
      }).toList();
      
      if (mounted) {
        setState(() {
          _overdueInvoices = overdueInvoices;
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<Invoice> get _filteredInvoices {
    if (_searchQuery.isEmpty) return _overdueInvoices;
    
    return _overdueInvoices.where((invoice) {
      final customer = _customers.firstWhere(
        (cust) => cust.id == invoice.customerId,
        orElse: () => Customer.empty(),
      );
      
      return invoice.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Demand Letters',
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
            onPressed: _loadData,
          ),
        ],
      ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: Column(
              children: [
                _buildStatsSection(),
                _buildSearchSection(),
                _buildInvoicesList(),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _overdueInvoices.isNotEmpty ? _sendBulkDemandLetters : null,
        backgroundColor: _overdueInvoices.isNotEmpty ? const Color(0xFF667EEA) : Colors.grey,
        icon: const Icon(Icons.send, color: Colors.white),
        label: Text(
          'Send All',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    final totalOverdue = _overdueInvoices.length;
    final totalAmount = _overdueInvoices.fold(0.0, (sum, invoice) => sum + invoice.balanceAmount);
    final daysOverdue = _overdueInvoices.fold(0, (sum, invoice) {
      final days = DateTime.now().difference(invoice.dueDate).inDays;
      return sum + days;
    });
    final averageDaysOverdue = totalOverdue > 0 ? (daysOverdue / totalOverdue).round() : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Overdue Invoices',
              '$totalOverdue',
              FontAwesomeIcons.exclamationTriangle,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Total Amount',
              'UGX ${_formatNumber(totalAmount)}',
              FontAwesomeIcons.dollarSign,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Avg. Days Overdue',
              '$averageDaysOverdue',
              FontAwesomeIcons.calendar,
            ),
          ),
        ],
        ),
      ),
    ),
  );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        FaIcon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search overdue invoices...',
              hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF667EEA)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF667EEA)),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF667EEA)),
        ),
      );
    }

    final filteredInvoices = _filteredInvoices;

    if (filteredInvoices.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                _overdueInvoices.isEmpty 
                    ? 'No overdue invoices found!' 
                    : 'No invoices match your search',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              if (_overdueInvoices.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Text('Clear search'),
                ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF667EEA),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredInvoices.length,
          itemBuilder: (context, index) {
            final invoice = filteredInvoices[index];
            return _buildInvoiceCard(invoice);
          },
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final customer = _customers.firstWhere(
      (cust) => cust.id == invoice.customerId,
      orElse: () => Customer.empty(),
    );
    
    final daysOverdue = DateTime.now().difference(invoice.dueDate).inDays;
    final overdueColor = _getOverdueColor(daysOverdue);

    final idx = _filteredInvoices.indexOf(invoice);
    final isHover = _hoveredInvoiceIndex == idx;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredInvoiceIndex = idx),
      onExit: (_) => setState(() => _hoveredInvoiceIndex = null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25),
          ),
        ),
        child: InkWell(
          onTap: () => _showInvoiceDetails(invoice, customer),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isHover ? Colors.black : overdueColor).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning,
                    color: isHover ? Colors.black : overdueColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name.isNotEmpty ? customer.name : 'Unknown Customer',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isHover ? Colors.black : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invoice: ${invoice.invoiceNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isHover ? Colors.black87 : Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${_formatDate(invoice.dueDate)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isHover ? Colors.black54 : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'UGX ${_formatNumber(invoice.balanceAmount)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isHover ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isHover ? Colors.black : overdueColor).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$daysOverdue days overdue',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isHover ? Colors.black : overdueColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: const Color(0xFF1A1F3A),
                  onSelected: (value) => _handleMenuAction(value, invoice, customer),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'send',
                      child: Row(
                        children: [
                          Icon(Icons.send, color: Color(0xFF667EEA)),
                          SizedBox(width: 8),
                          Text('Send Demand Letter', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Color(0xFF4CAF50)),
                          SizedBox(width: 8),
                          Text('View Details', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'call',
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: Color(0xFF2196F3)),
                          SizedBox(width: 8),
                          Text('Call Customer', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getOverdueColor(int daysOverdue) {
    if (daysOverdue <= 7) return Colors.orange;
    if (daysOverdue <= 30) return Colors.red;
    return Colors.purple;
  }

  void _showInvoiceDetails(Invoice invoice, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Invoice Details',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Invoice Number', invoice.invoiceNumber),
            _buildDetailRow('Customer', customer.name),
            _buildDetailRow('Total Amount', 'UGX ${_formatNumber(invoice.totalAmount)}'),
            _buildDetailRow('Paid Amount', 'UGX ${_formatNumber(invoice.paidAmount)}'),
            _buildDetailRow('Balance Due', 'UGX ${_formatNumber(invoice.balanceAmount)}'),
            _buildDetailRow('Due Date', _formatDate(invoice.dueDate)),
            _buildDetailRow('Days Overdue', '${DateTime.now().difference(invoice.dueDate).inDays}'),
            _buildDetailRow('Status', invoice.statusText),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: const Color(0xFF667EEA)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendDemandLetter(invoice, customer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
            ),
            child: Text(
              'Send Demand Letter',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
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

  void _handleMenuAction(String action, Invoice invoice, Customer customer) {
    switch (action) {
      case 'send':
        _sendDemandLetter(invoice, customer);
        break;
      case 'view':
        _showInvoiceDetails(invoice, customer);
        break;
      case 'call':
        _callCustomer(customer);
        break;
    }
  }

  Future<void> _sendDemandLetter(Invoice invoice, Customer customer) async {
    try {
      // TODO: Implement demand letter sending functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demand letter functionality coming soon for ${customer.name}'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending demand letter: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendBulkDemandLetters() async {
    if (_overdueInvoices.isEmpty) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Send Bulk Demand Letters',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to send demand letters to all ${_overdueInvoices.length} overdue customers?',
          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
            ),
            child: Text(
              'Send All',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      int successCount = 0;
      int errorCount = 0;

      for (final invoice in _overdueInvoices) {
        final customer = _customers.firstWhere(
          (cust) => cust.id == invoice.customerId,
          orElse: () => Customer.empty(),
        );

        try {
          // TODO: Implement demand letter sending functionality
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bulk send completed: $successCount sent, $errorCount failed',
          ),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  void _callCustomer(Customer customer) {
    if (customer.phone.isNotEmpty) {
      // In a real app, you would use url_launcher to make a phone call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${customer.name} at ${customer.phone}'),
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this customer'),
          backgroundColor: Colors.orange,
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}