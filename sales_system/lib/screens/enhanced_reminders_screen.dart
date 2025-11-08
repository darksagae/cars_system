import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/reminders/payment_reminder_service.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import 'dart:async';
import '../providers/theme_provider.dart';
import 'dart:ui';
import '../widgets/glass_container.dart';
import '../providers/demand_letter_provider.dart';
import '../models/demand_letter.dart';
import '../services/pdf/pdf_service.dart';

class EnhancedRemindersScreen extends StatefulWidget {
  const EnhancedRemindersScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedRemindersScreen> createState() => _EnhancedRemindersScreenState();
}

class _EnhancedRemindersScreenState extends State<EnhancedRemindersScreen> {
  final PaymentReminderService _reminderService = PaymentReminderService();
  final InvoiceService _invoiceService = InvoiceService();
  final CustomerService _customerService = CustomerService();
  
  List<Invoice> _upcomingInvoices = [];
  List<Invoice> _overdueInvoices = [];
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _refreshTimer;
  int? _hoveredUpcomingIndex;
  int? _hoveredOverdueIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
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
      
      final now = DateTime.now();
      // Only include invoices that are not paid/cancelled and have a balance > 0
      final unpaidInvoices = invoices.where((invoice) {
        return invoice.status != InvoiceStatus.paid && 
               invoice.status != InvoiceStatus.cancelled &&
               invoice.balanceAmount > 0;
      }).toList();
      
      // Upcoming: due date is in the future but within the invoice's payment timeframe
      final upcomingInvoices = unpaidInvoices.where((invoice) {
        return invoice.dueDate.isAfter(now);
      }).toList();
      
      // Overdue: due date has passed
      final overdueInvoices = unpaidInvoices.where((invoice) {
        return invoice.dueDate.isBefore(now) || invoice.dueDate.isAtSameMomentAs(now);
      }).toList();
      
      if (mounted) {
        setState(() {
          _upcomingInvoices = upcomingInvoices;
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
          SnackBar(content: Text('Error loading reminders: $e')),
        );
      }
    }
  }

  List<Invoice> get _filteredUpcoming {
    if (_searchQuery.isEmpty) return _upcomingInvoices;
    
    return _upcomingInvoices.where((invoice) {
      final customer = _customers.firstWhere(
        (cust) => cust.id == invoice.customerId,
        orElse: () => Customer.empty(),
      );
      
      return invoice.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Invoice> get _filteredOverdue {
    if (_searchQuery.isEmpty) return _overdueInvoices;
    
    return _overdueInvoices.where((invoice) {
      final customer = _customers.firstWhere(
        (cust) => cust.id == invoice.customerId,
        orElse: () => Customer.empty(),
      );
      
      return invoice.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer.name.toLowerCase().contains(_searchQuery.toLowerCase());
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
              'Reminders',
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
                _buildTabsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    final totalUpcoming = _upcomingInvoices.length;
    final totalOverdue = _overdueInvoices.length;
    final totalAmount = (_upcomingInvoices + _overdueInvoices)
        .fold(0.0, (sum, invoice) => sum + invoice.balanceAmount);

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
              'Upcoming',
              '$totalUpcoming',
              FontAwesomeIcons.clock,
              Colors.orange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Overdue',
              '$totalOverdue',
              FontAwesomeIcons.exclamationTriangle,
              Colors.red,
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
              Colors.green,
            ),
          ),
        ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        FaIcon(
          icon,
          color: color,
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
              hintText: 'Search reminders...',
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
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Upcoming (${_upcomingInvoices.length})',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Overdue (${_overdueInvoices.length})',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUpcomingList(),
                  _buildOverdueTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFFAF0)),
      );
    }

    final filteredInvoices = _filteredUpcoming;

    if (filteredInvoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _upcomingInvoices.isEmpty 
                  ? 'No upcoming payments due!' 
                  : 'No upcoming payments match your search',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFFFFAF0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredInvoices.length,
        itemBuilder: (context, index) {
          final invoice = filteredInvoices[index];
          return _buildUpcomingCard(invoice);
        },
      ),
    );
  }

  Widget _buildOverdueList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFFAF0)),
      );
    }

    final filteredInvoices = _filteredOverdue;

    if (filteredInvoices.isEmpty) {
      return Center(
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
                  ? 'No overdue payments!' 
                  : 'No overdue payments match your search',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFFFFAF0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredInvoices.length,
        itemBuilder: (context, index) {
          final invoice = filteredInvoices[index];
          return _buildOverdueCard(invoice);
        },
      ),
    );
  }

  Widget _buildOverdueTab() {
    return Column(
      children: [
        ClipRRect(
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
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildOverdueList()),
      ],
    );
  }

  Widget _buildUpcomingCard(Invoice invoice) {
    final customer = _customers.firstWhere(
      (cust) => cust.id == invoice.customerId,
      orElse: () => Customer.empty(),
    );
    
    final daysUntilDue = invoice.dueDate.difference(DateTime.now()).inDays;
    final urgencyColor = daysUntilDue <= 1 ? Colors.red : Colors.orange;

    final idx = _filteredUpcoming.indexOf(invoice);
    final isHover = _hoveredUpcomingIndex == idx;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredUpcomingIndex = idx),
      onExit: (_) => setState(() => _hoveredUpcomingIndex = null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25)),
        ),
      child: InkWell(
        onTap: () => _showReminderOptions(invoice, customer),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isHover ? Colors.black : urgencyColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule,
                  color: isHover ? Colors.black : urgencyColor,
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
                      color: (isHover ? Colors.black : urgencyColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daysUntilDue <= 1 
                          ? 'Due tomorrow!' 
                          : '$daysUntilDue days left',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isHover ? Colors.black : urgencyColor,
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
                    value: 'remind',
                    child: Row(
                      children: [
                        Icon(Icons.notifications, color: Color(0xFFFFFAF0)),
                        SizedBox(width: 8),
                        Text('Send Reminder', style: TextStyle(color: Colors.white)),
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
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildOverdueCard(Invoice invoice) {
    final customer = _customers.firstWhere(
      (cust) => cust.id == invoice.customerId,
      orElse: () => Customer.empty(),
    );
    
    final daysOverdue = DateTime.now().difference(invoice.dueDate).inDays;

    final idx = _filteredOverdue.indexOf(invoice);
    final isHover = _hoveredOverdueIndex == idx;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredOverdueIndex = idx),
      onExit: (_) => setState(() => _hoveredOverdueIndex = null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25)),
        ),
      child: InkWell(
        onTap: () => _showReminderOptions(invoice, customer),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isHover ? Colors.black : Colors.red).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.red,
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
                      color: (isHover ? Colors.black : Colors.red).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$daysOverdue days overdue',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isHover ? Colors.black : Colors.red,
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
                    value: 'remind',
                    child: Row(
                      children: [
                        Icon(Icons.notifications, color: Color(0xFFFFFAF0)),
                        SizedBox(width: 8),
                        Text('Send Reminder', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'demand',
                    child: Row(
                      children: [
                        Icon(Icons.send, color: Color(0xFFF44336)),
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
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showReminderOptions(Invoice invoice, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Reminder Options',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer: ${customer.name}',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
            ),
            Text(
              'Invoice: ${invoice.invoiceNumber}',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
            ),
            Text(
              'Amount: UGX ${_formatNumber(invoice.balanceAmount)}',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendReminder(invoice, customer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFAF0),
            ),
            child: Text(
              'Send Reminder',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Invoice invoice, Customer customer) {
    switch (action) {
      case 'remind':
        _sendReminder(invoice, customer);
        break;
      case 'demand':
        _sendDemandLetter(invoice, customer);
        break;
      case 'view':
        _showReminderOptions(invoice, customer);
        break;
    }
  }

  Future<void> _sendReminder(Invoice invoice, Customer customer) async {
    try {
      // TODO: Implement payment reminder sending functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment reminder functionality coming soon for ${customer.name}'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendDemandLetter(Invoice invoice, Customer customer) async {
    try {
      final daysOverdue = DateTime.now().difference(invoice.dueDate).inDays;
      final DemandLetterTemplate template;
      if (daysOverdue <= 7) {
        template = DemandLetterTemplate.firstNotice;
      } else if (daysOverdue <= 14) {
        template = DemandLetterTemplate.secondNotice;
      } else if (daysOverdue <= 30) {
        template = DemandLetterTemplate.finalNotice;
      } else {
        template = DemandLetterTemplate.legalNotice;
      }

      // Basic interest rate; can be made configurable
      const double interestRate = 0.0;

      final createdLetter = await context.read<DemandLetterProvider>().createDemandLetter(
        invoice: invoice,
        customer: customer,
        template: template,
        interestRate: interestRate,
        daysOverdue: daysOverdue,
      );

      if (!mounted) return;
      if (createdLetter != null) {
        // Offer to print the demand letter
        await PDFService().printDemandLetterPDF(
          invoice: invoice,
          customer: customer,
          letter: createdLetter,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demand letter sent to ${customer.name}'),
            backgroundColor: const Color(0xFFFFFAF0),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create demand letter'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending demand letter: $e'),
          backgroundColor: Colors.red,
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