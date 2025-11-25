import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/local_database_service.dart';
import '../services/invoice_sync_service.dart';
import '../services/supabase_service.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final InvoiceSyncService _syncService = InvoiceSyncService();
  
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _searchQuery = '';
  String? _selectedClientId;
  String _selectedStatus = 'all'; // all, created, sent, paid

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoices = await _localDb.getAllInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading invoices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncInvoices() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final count = await _syncService.syncAllInvoices();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0 
                ? '✅ Synced $count invoice(s)'
                : '✅ No new invoices to sync',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF2D3748),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Reload invoices after sync
      await _loadInvoices();
    } catch (e) {
      print('❌ Error syncing invoices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error syncing invoices: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    var filtered = _invoices;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((invoice) {
        final invoiceNumber = (invoice['invoice_number'] ?? '').toString().toLowerCase();
        final customerName = (invoice['customer_name'] ?? '').toString().toLowerCase();
        return invoiceNumber.contains(_searchQuery.toLowerCase()) ||
               customerName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by client
    if (_selectedClientId != null && _selectedClientId!.isNotEmpty) {
      filtered = filtered.where((invoice) {
        return invoice['client_id']?.toString() == _selectedClientId;
      }).toList();
    }

    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered.where((invoice) {
        return invoice['status']?.toString().toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  Future<void> _showInvoiceDetails(BuildContext context, Map<String, dynamic> invoice) async {
    // Get client machine info
    Map<String, dynamic>? clientInfo;
    final clientId = invoice['client_id']?.toString();
    if (clientId != null && clientId.isNotEmpty) {
      try {
        clientInfo = await SupabaseService.getDesktopClient(clientId);
      } catch (e) {
        print('⚠️ Error fetching client info: $e');
      }
    }

    final hasPdf = invoice['local_pdf_path']?.toString().isNotEmpty ?? false;
    final pdfPath = invoice['local_pdf_path']?.toString() ?? '';
    final customerPhone = invoice['customer_phone']?.toString() ?? '';
    final clientName = clientInfo?['client_name']?.toString() ?? 'Unknown Client';
    final clientPhone = clientInfo?['phone']?.toString() ?? 
                       clientInfo?['contact_phone']?.toString() ?? 
                       'Not available';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _InvoiceDetailSheet(
        invoice: invoice,
        clientName: clientName,
        clientPhone: clientPhone,
        customerPhone: customerPhone,
        hasPdf: hasPdf,
        pdfPath: pdfPath,
        onViewPdf: () {
          Navigator.pop(context);
          _viewInvoicePdf(pdfPath);
        },
        onResendWhatsApp: () => _resendWhatsApp(invoice),
        onResendEmail: () => _resendEmail(invoice),
        onDelete: () {
          Navigator.pop(context);
          _deleteInvoice(invoice);
        },
      ),
    );
  }

  void _viewInvoicePdf(String pdfPath) {
    if (pdfPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF file not available',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF2D3748),
        ),
      );
      return;
    }

    final file = File(pdfPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF file does not exist',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PdfViewerSheet(pdfPath: pdfPath),
    );
  }

  Future<void> _resendWhatsApp(Map<String, dynamic> invoice) async {
    final customerPhone = invoice['customer_phone']?.toString() ?? '';
    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Customer phone number is required',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final invoiceNumber = invoice['invoice_number']?.toString() ?? 'Unknown';
    final customerName = invoice['customer_name']?.toString() ?? 'Customer';
    final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0.0;
    final invoiceDate = _formatDate(invoice['invoice_date']?.toString());
    final pdfUrl = invoice['pdf_url']?.toString();

    // Generate invoice message
    final message = _generateInvoiceMessage(
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      totalAmount: totalAmount,
    );

    try {
      final supabase = SupabaseService.client;
      
      // Queue WhatsApp message
      await supabase.from('whatsapp_message_queue').insert({
        'phone_number': customerPhone,
        'message_content': message,
        'message_type': 'invoice',
        'media_path': pdfUrl,
        'sent_by_machine_id': invoice['client_id']?.toString() ?? 'mobile_app',
        'sent_by_user_id': 'mobile_user',
        'sent_by_user_name': 'Mobile App User',
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ WhatsApp message queued. Mobile app will send it automatically.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error queueing WhatsApp message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error queueing WhatsApp message: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _resendEmail(Map<String, dynamic> invoice) async {
    // For email, we need customer email - check if it's stored
    // For now, we'll show a message that email requires customer email address
    final invoiceNumber = invoice['invoice_number']?.toString() ?? 'Unknown';
    final customerName = invoice['customer_name']?.toString() ?? 'Customer';
    final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0.0;
    final invoiceDate = _formatDate(invoice['invoice_date']?.toString());
    final pdfUrl = invoice['pdf_url']?.toString();

    // Show dialog to enter email address
    final emailController = TextEditingController();
    
    if (!mounted) return;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Resend Invoice via Email',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter customer email address:',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'customer@example.com',
                hintStyle: GoogleFonts.poppins(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2D3748),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                Navigator.pop(context, emailController.text);
              }
            },
            child: Text(
              'Send',
              style: GoogleFonts.poppins(color: const Color(0xFF667EEA)),
            ),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Generate email body
    final emailBody = _generateEmailBody(
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      totalAmount: totalAmount,
    );

    try {
      final supabase = SupabaseService.client;
      
      // Queue email
      await supabase.from('email_queue').insert({
        'to_email': result,
        'subject': 'Invoice $invoiceNumber - NSB Motors',
        'body': emailBody,
        'pdf_url': pdfUrl,
        'sent_by_machine_id': invoice['client_id']?.toString() ?? 'mobile_app',
        'sent_by_user_id': 'mobile_user',
        'sent_by_user_name': 'Mobile App User',
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Email queued. Mobile app will send it automatically.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error queueing email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error queueing email: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _generateInvoiceMessage({
    required String customerName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
  }) {
    return '''
🏢 *NSB Motors*
📄 *Invoice $invoiceNumber*

Dear $customerName,

Your invoice is ready for payment:
💰 Amount: ${_formatAmount(totalAmount)}
📅 Date: $invoiceDate

Thank you for your business!

💳 *Payment Options:*
• Bank Transfer
• Mobile Money (MTN/Airtel)
• Cash Payment

Payment is due within 30 days.

Best regards,
NSB Motors Team
    '''.trim();
  }

  Future<void> _deleteInvoice(Map<String, dynamic> invoice) async {
    final invoiceNumber = invoice['invoice_number']?.toString() ?? 'Unknown';
    final supabaseId = invoice['supabase_id']?.toString();
    
    if (supabaseId == null || supabaseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete invoice: Invalid invoice ID',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Delete Invoice',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete invoice $invoiceNumber?\n\nThis action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from local database
      final localDb = LocalDatabaseService();
      final result = await localDb.deleteInvoice(supabaseId);

      if (result > 0) {
        // Also delete local PDF file if exists
        final pdfPath = invoice['local_pdf_path']?.toString();
        if (pdfPath != null && pdfPath.isNotEmpty) {
          try {
            final file = File(pdfPath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('⚠️ Error deleting PDF file: $e');
            // Continue even if PDF deletion fails
          }
        }

        // Reload invoices
        await _loadInvoices();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Invoice deleted successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Invoice not found or already deleted',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error deleting invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error deleting invoice: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _generateEmailBody({
    required String customerName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .header { background-color: #667EEA; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .invoice-details { background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>NSB Motors</h1>
    <h2>Invoice $invoiceNumber</h2>
  </div>
  <div class="content">
    <p>Dear $customerName,</p>
    <p>Your invoice is ready for payment:</p>
    <div class="invoice-details">
      <p><strong>Invoice Number:</strong> $invoiceNumber</p>
      <p><strong>Date:</strong> $invoiceDate</p>
      <p><strong>Amount:</strong> ${_formatAmount(totalAmount)}</p>
    </div>
    <p>Thank you for your business!</p>
    <p>Payment is due within 30 days.</p>
  </div>
  <div class="footer">
    <p>Best regards,<br>NSB Motors Team</p>
  </div>
</body>
</html>
    ''';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'created':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return 'UGX 0';
    return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Invoices',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncInvoices,
            tooltip: 'Sync invoices',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2D3748),
            child: Column(
              children: [
                // Search bar
                TextField(
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search invoices...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1A1F3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Status filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: GoogleFonts.poppins(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF1A1F3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        dropdownColor: const Color(0xFF1A1F3A),
                        style: GoogleFonts.poppins(color: Colors.white),
                        items: ['all', 'created', 'sent', 'paid']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.poppins(),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value ?? 'all';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Invoice count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF2D3748),
            child: Row(
              children: [
                Text(
                  '${_filteredInvoices.length} invoice(s)',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Invoice list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredInvoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.white38,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No invoices found',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap sync to fetch invoices from client machines',
                              style: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _filteredInvoices[index];
                          final status = invoice['status']?.toString() ?? 'unknown';
                          final hasPdf = invoice['local_pdf_path']?.toString().isNotEmpty ?? false;

                          return Dismissible(
                            key: Key(invoice['supabase_id']?.toString() ?? invoice['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              // Show confirmation dialog
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1A1F3A),
                                  title: Text(
                                    'Delete Invoice',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete invoice ${invoice['invoice_number']}?\n\nThis action cannot be undone.',
                                    style: GoogleFonts.poppins(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.poppins(color: Colors.white70),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.poppins(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              return confirm ?? false;
                            },
                            onDismissed: (direction) {
                              _deleteInvoice(invoice);
                            },
                            child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: const Color(0xFF2D3748),
                            child: InkWell(
                              onTap: () => _showInvoiceDetails(context, invoice),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            invoice['invoice_number']?.toString() ?? 'Unknown',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _getStatusColor(status),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _getStatusColor(status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            invoice['customer_name']?.toString() ?? 'Unknown Customer',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDate(invoice['invoice_date']?.toString()),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _formatAmount(
                                            (invoice['total_amount'] as num?)?.toDouble(),
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Tap for details',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white54,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        if (hasPdf) ...[
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.picture_as_pdf,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'PDF available',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailSheet extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final String clientName;
  final String clientPhone;
  final String customerPhone;
  final bool hasPdf;
  final String pdfPath;
  final VoidCallback onViewPdf;
  final VoidCallback onResendWhatsApp;
  final VoidCallback onResendEmail;
  final VoidCallback onDelete;

  const _InvoiceDetailSheet({
    required this.invoice,
    required this.clientName,
    required this.clientPhone,
    required this.customerPhone,
    required this.hasPdf,
    required this.pdfPath,
    required this.onViewPdf,
    required this.onResendWhatsApp,
    required this.onResendEmail,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final invoiceNumber = invoice['invoice_number']?.toString() ?? 'Unknown';
    final customerName = invoice['customer_name']?.toString() ?? 'Unknown Customer';
    final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0.0;
    final invoiceDate = invoice['invoice_date']?.toString() ?? '';
    final status = invoice['status']?.toString() ?? 'unknown';

    String _formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return 'Unknown';
      try {
        final date = DateTime.parse(dateStr);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return dateStr;
      }
    }

    String _formatAmount(double? amount) {
      if (amount == null) return 'UGX 0';
      return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    }

    Color _getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'sent':
          return Colors.blue;
        case 'paid':
          return Colors.green;
        case 'created':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Invoice Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Invoice Info
          _buildDetailRow('Invoice Number', invoiceNumber),
          _buildDetailRow('Customer Name', customerName),
          _buildDetailRow('Date', _formatDate(invoiceDate)),
          _buildDetailRow('Amount', _formatAmount(totalAmount)),
          _buildDetailRow('Status', status.toUpperCase(), 
            valueColor: _getStatusColor(status)),
          
          const Divider(color: Colors.white24, height: 32),
          
          // Client Machine Info
          Text(
            'Client Machine',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Machine Name', clientName),
          _buildDetailRow('Contact Phone', clientPhone),
          
          const Divider(color: Colors.white24, height: 32),
          
          // Customer Contact
          Text(
            'Customer Contact',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailRow('Phone Number', customerPhone.isEmpty ? 'Not available' : customerPhone),
              ),
              if (customerPhone.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: customerPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Phone number copied to clipboard',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy phone number',
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          if (hasPdf) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onViewPdf,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: Text(
                  'View PDF',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: customerPhone.isNotEmpty ? onResendWhatsApp : null,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: Text(
                    'Resend WhatsApp',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onResendEmail,
                  icon: const Icon(Icons.email, color: Colors.white),
                  label: Text(
                    'Resend Email',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          // Delete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text(
                'Delete Invoice',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: valueColor ?? Colors.white,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfViewerSheet extends StatefulWidget {
  final String pdfPath;

  const _PdfViewerSheet({Key? key, required this.pdfPath}) : super(key: key);

  @override
  State<_PdfViewerSheet> createState() => _PdfViewerSheetState();
}

class _PdfViewerSheetState extends State<_PdfViewerSheet> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Invoice PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Page info
          if (_totalPages > 0)
            Text(
              'Page ${_currentPage + 1} of $_totalPages',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          const SizedBox(height: 8),
          
          // PDF Viewer
          Expanded(
            child: _error
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading PDF',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : PDFView(
                    filePath: widget.pdfPath,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages ?? 0;
                        _isLoading = false;
                      });
                    },
                    onError: (error) {
                      setState(() {
                        _error = true;
                        _isLoading = false;
                      });
                      print('PDF Error: $error');
                    },
                    onPageError: (page, error) {
                      print('PDF Page Error: $error');
                    },
                    onPageChanged: (page, total) {
                      setState(() {
                        _currentPage = page ?? 0;
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

