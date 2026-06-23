import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/payment_service.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';
import '../models/payment.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import 'payment_form_screen.dart';
import 'dart:async';
import '../providers/theme_provider.dart';
import '../providers/payment_provider.dart';

class EnhancedPaymentsScreen extends StatefulWidget {
  const EnhancedPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedPaymentsScreen> createState() => _EnhancedPaymentsScreenState();
}

class _EnhancedPaymentsScreenState extends State<EnhancedPaymentsScreen> {
  final PaymentService _paymentService = PaymentService();
  final InvoiceService _invoiceService = InvoiceService();
  final CustomerService _customerService = CustomerService();
  
  List<Payment> _payments = [];
  List<Invoice> _invoices = [];
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  PaymentStatus? _filterStatus;
  String? _filterDueDate; // 'overdue', 'upcoming', or null for all
  Timer? _refreshTimer;
  int? _hoveredPaymentIndex;

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
      final payments = await _paymentService.getAllPayments();
      final invoices = await _invoiceService.getAllInvoices();
      final customers = await _customerService.getAllCustomers();
      
      if (mounted) {
        setState(() {
          _payments = payments;
          _invoices = invoices;
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
          SnackBar(content: Text('Error loading payments: $e')),
        );
      }
    }
  }

  List<Payment> get _filteredPayments {
    var filtered = _payments;
    final now = DateTime.now();
    
    // Filter by invoice due date (overdue/upcoming)
    if (_filterDueDate != null) {
      filtered = filtered.where((payment) {
        final invoice = _invoices.firstWhere(
          (inv) => inv.id == payment.invoiceId,
          orElse: () => Invoice.empty(),
        );
        
        if (invoice.id == null) return false; // Skip if invoice not found
        
        // Only apply due date filter to unpaid invoices
        if (invoice.status == InvoiceStatus.paid || 
            invoice.status == InvoiceStatus.cancelled ||
            invoice.balanceAmount <= 0) {
          return false;
        }
        
        if (_filterDueDate == 'overdue') {
          return invoice.dueDate.isBefore(now) || invoice.dueDate.isAtSameMomentAs(now);
        } else if (_filterDueDate == 'upcoming') {
          return invoice.dueDate.isAfter(now);
        }
        return true;
      }).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        final invoice = _invoices.firstWhere(
          (inv) => inv.id == payment.invoiceId,
          orElse: () => Invoice.empty(),
        );
        final customer = _customers.firstWhere(
          (cust) => cust.id == invoice.customerId,
          orElse: () => Customer.empty(),
        );
        
        return payment.id.toString().contains(_searchQuery) ||
               customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               invoice.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_filterStatus != null) {
      filtered = filtered.where((payment) => payment.status == _filterStatus).toList();
    }
    
    // Sort by payment date (newest first)
    filtered.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Payments',
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
                _buildFiltersSection(),
                _buildPaymentsList(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addPayment,
            backgroundColor: const Color(0xFFFFFAF0),
            icon: const Icon(Icons.add, color: Colors.black),
            label: Text(
              'Add Payment',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    final totalPayments = _payments.length;
    final totalAmount = _payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final pendingPayments = _payments.where((p) => p.status == PaymentStatus.pending).length;
    final completedPayments = _payments.where((p) => p.status == PaymentStatus.completed).length;

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
              'Total Payments',
              '$totalPayments',
              FontAwesomeIcons.creditCard,
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
              'Completed',
              '$completedPayments',
              FontAwesomeIcons.checkCircle,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Pending',
              '$pendingPayments',
              FontAwesomeIcons.clock,
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
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
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
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search payments...',
              hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFFFAF0)),
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
                borderSide: const BorderSide(color: Color(0xFFFFFAF0)),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', PaymentStatus.pending),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', PaymentStatus.completed),
                const SizedBox(width: 8),
                _buildFilterChip('Failed', PaymentStatus.failed),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', PaymentStatus.cancelled),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDueDateFilterChip('All Payments', null),
                const SizedBox(width: 8),
                _buildDueDateFilterChip('Overdue Invoices', 'overdue'),
                const SizedBox(width: 8),
                _buildDueDateFilterChip('Upcoming Invoices', 'upcoming'),
              ],
            ),
          ),
        ],
        ),
      ),
    ),
    );
  }

  Widget _buildFilterChip(String label, PaymentStatus? status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateFilterChip(String label, String? filterType) {
    final isSelected = _filterDueDate == filterType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterDueDate = filterType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filterType == 'overdue')
              Icon(Icons.warning, size: 16, color: isSelected ? Colors.black : Colors.red)
            else if (filterType == 'upcoming')
              Icon(Icons.schedule, size: 16, color: isSelected ? Colors.black : Colors.orange)
            else
              const SizedBox.shrink(),
            if (filterType != null) const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.black : Colors.white.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFFAF0)),
        ),
      );
    }

    final filteredPayments = _filteredPayments;

    if (filteredPayments.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payment,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _payments.isEmpty ? 'No payments found' : 'No payments match your filters',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              if (_payments.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterStatus = null;
                      _filterDueDate = null;
                    });
                  },
                  child: Text('Clear filters'),
                ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFFFFAF0),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredPayments.length,
          itemBuilder: (context, index) {
            final payment = filteredPayments[index];
            return _buildPaymentCard(payment);
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final invoice = _invoices.firstWhere(
      (inv) => inv.id == payment.invoiceId,
      orElse: () => Invoice.empty(),
    );
    final customer = _customers.firstWhere(
      (cust) => cust.id == invoice.customerId,
      orElse: () => Customer.empty(),
    );

    final idx = _filteredPayments.indexOf(payment);
    final isHover = _hoveredPaymentIndex == idx;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredPaymentIndex = idx),
      onExit: (_) => setState(() => _hoveredPaymentIndex = null),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25)),
          ),
      child: InkWell(
        onTap: () => _viewPaymentDetails(payment),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isHover ? Colors.black : _getStatusColor(payment.status)).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(payment.status),
                  color: isHover ? Colors.black : _getStatusColor(payment.status),
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
                      'Payment: ${_formatDate(payment.paymentDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isHover ? Colors.black54 : Colors.white.withOpacity(0.5),
                      ),
                    ),
                    if (invoice.id != null && invoice.balanceAmount > 0)
                      Text(
                        'Due: ${_formatDate(invoice.dueDate)} ${invoice.dueDate.isBefore(DateTime.now()) ? "(Overdue)" : ""}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: invoice.dueDate.isBefore(DateTime.now()) 
                              ? Colors.red 
                              : (isHover ? Colors.black54 : Colors.white.withOpacity(0.4)),
                          fontWeight: invoice.dueDate.isBefore(DateTime.now()) 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'UGX ${_formatNumber(payment.amount)}',
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
                      color: (isHover ? Colors.black : _getStatusColor(payment.status)).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      payment.statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isHover ? Colors.black : _getStatusColor(payment.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    ),
    ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.refresh;
    }
  }

  void _addPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentFormScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _viewPaymentDetails(Payment payment) {
    final invoice = _invoices.firstWhere(
      (inv) => inv.id == payment.invoiceId,
      orElse: () => Invoice.empty(),
    );
    
    // Navigate to payment details screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Payment Details',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Payment ID', payment.id.toString()),
            _buildDetailRow('Amount', 'UGX ${_formatNumber(payment.amount)}'),
            _buildDetailRow('Date', _formatDate(payment.paymentDate)),
            _buildDetailRow('Status', payment.statusText),
            _buildDetailRow('Method', payment.method.toString().split('.').last),
            if (invoice.id != null) ...[
              const SizedBox(height: 8),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              _buildDetailRow('Invoice', invoice.invoiceNumber),
              _buildDetailRow('Invoice Due Date', _formatDate(invoice.dueDate)),
              if (invoice.dueDate.isBefore(DateTime.now()) && invoice.balanceAmount > 0)
                _buildDetailRow('Status', 'OVERDUE', color: Colors.red),
              _buildDetailRow('Invoice Balance', 'UGX ${_formatNumber(invoice.balanceAmount)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: const Color(0xFFFFFAF0)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the details dialog first
              _showDeleteConfirmation(payment);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Delete Payment',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this payment of UGX ${_formatNumber(payment.amount)}? This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              
              if (payment.id == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cannot delete payment: Payment ID is missing',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red.withOpacity(0.8),
                    ),
                  );
                }
                return;
              }
              
              try {
                // Try to use PaymentProvider if available, otherwise use PaymentService directly
                final provider = context.read<PaymentProvider>();
                final success = await provider.deletePayment(payment.id!);
                
                if (mounted) {
                  if (success) {
                    // Reload data to refresh the UI
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Payment deleted successfully!',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green.withOpacity(0.8),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete payment',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red.withOpacity(0.8),
                      ),
                    );
                  }
                }
              } catch (e) {
                // Fallback to direct service call if provider is not available
                try {
                  final result = await _paymentService.deletePayment(payment.id!);
                  if (mounted) {
                    if (result > 0) {
                      await _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment deleted successfully!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green.withOpacity(0.8),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete payment',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red.withOpacity(0.8),
                        ),
                      );
                    }
                  }
                } catch (deleteError) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error deleting payment: ${deleteError.toString()}',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red.withOpacity(0.8),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
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
              color: color ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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