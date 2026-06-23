import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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
  String _selectedStatus = 'all';

  static const _primary = Color(0xFF1D4ED8);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _bgColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await _localDb.getAllInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading invoices: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncInvoices() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final count = await _syncService.syncAllInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 ? 'Synced $count invoice(s)' : 'No new invoices to sync'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
      await _loadInvoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    var filtered = _invoices;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((inv) {
        final num = (inv['invoice_number'] ?? '').toString().toLowerCase();
        final name = (inv['customer_name'] ?? '').toString().toLowerCase();
        return num.contains(_searchQuery.toLowerCase()) ||
            name.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    if (_selectedStatus != 'all') {
      filtered = filtered
          .where((inv) =>
              inv['status']?.toString().toLowerCase() == _selectedStatus)
          .toList();
    }
    return filtered;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent': return const Color(0xFF3B82F6);
      case 'paid': return const Color(0xFF059669);
      case 'created': return const Color(0xFFD97706);
      default: return const Color(0xFF6B7280);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'sent': return const Color(0xFFEFF6FF);
      case 'paid': return const Color(0xFFECFDF5);
      case 'created': return const Color(0xFFFFFBEB);
      default: return const Color(0xFFF3F4F6);
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: _isSyncing ? null : _syncInvoices,
            tooltip: 'Sync invoices',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCountBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search invoices...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final status in ['all', 'created', 'sent', 'paid'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _statusFilterChip(status),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusFilterChip(String status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCountBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          const Divider(),
          Text(
            '${_filteredInvoices.length} invoice(s)',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filteredInvoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 48, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 16),
            Text('No invoices found',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
            const SizedBox(height: 6),
            Text('Tap sync to fetch from client machines',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredInvoices.length,
      itemBuilder: (context, index) {
        final invoice = _filteredInvoices[index];
        return _buildInvoiceCard(context, invoice);
      },
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Map<String, dynamic> invoice) {
    final status = invoice['status']?.toString() ?? 'unknown';
    final hasPdf = invoice['local_pdf_path']?.toString().isNotEmpty ?? false;
    final amount = (invoice['total_amount'] as num?)?.toDouble();

    return Dismissible(
      key: Key(invoice['supabase_id']?.toString() ?? invoice['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDelete(invoice),
      onDismissed: (_) => _deleteInvoice(invoice),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showInvoiceDetails(context, invoice),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice['invoice_number']?.toString() ?? 'Unknown',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _invoiceInfoRow(Icons.person_outline_rounded,
                    invoice['customer_name']?.toString() ?? 'Unknown Customer'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _invoiceInfoRow(
                        Icons.calendar_today_rounded,
                        _formatDate(invoice['invoice_date']?.toString())),
                    const Spacer(),
                    Text(
                      _formatAmount(amount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                if (hasPdf) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          size: 14, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Text(
                        'PDF available',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: const Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _invoiceInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _textSecondary),
        ),
      ],
    );
  }

  Future<bool?> _confirmDelete(Map<String, dynamic> invoice) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text(
          'Delete invoice ${invoice['invoice_number']}? This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInvoice(Map<String, dynamic> invoice) async {
    final supabaseId = invoice['supabase_id']?.toString();
    if (supabaseId == null || supabaseId.isEmpty) return;
    try {
      final result = await _localDb.deleteInvoice(supabaseId);
      if (result > 0) {
        final pdfPath = invoice['local_pdf_path']?.toString();
        if (pdfPath != null && pdfPath.isNotEmpty) {
          try {
            final file = File(pdfPath);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
        await _loadInvoices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice deleted'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting invoice: $e');
    }
  }

  Future<void> _showInvoiceDetails(
      BuildContext context, Map<String, dynamic> invoice) async {
    Map<String, dynamic>? clientInfo;
    final clientId = invoice['client_id']?.toString();
    if (clientId != null && clientId.isNotEmpty) {
      try {
        clientInfo = await SupabaseService.getDesktopClient(clientId);
      } catch (_) {}
    }

    final hasPdf = invoice['local_pdf_path']?.toString().isNotEmpty ?? false;
    final pdfPath = invoice['local_pdf_path']?.toString() ?? '';
    final customerPhone = invoice['customer_phone']?.toString() ?? '';
    final clientName = clientInfo?['client_name']?.toString() ?? 'Unknown Client';
    final clientPhone = clientInfo?['phone']?.toString() ??
        clientInfo?['contact_phone']?.toString() ??
        'Not available';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
    if (pdfPath.isEmpty || !File(pdfPath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF file not available')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _PdfViewerSheet(pdfPath: pdfPath),
    );
  }

  Future<void> _resendWhatsApp(Map<String, dynamic> invoice) async {
    final customerPhone = invoice['customer_phone']?.toString() ?? '';
    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number required'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }
    try {
      final invoiceNumber = invoice['invoice_number']?.toString() ?? 'Unknown';
      final customerName = invoice['customer_name']?.toString() ?? 'Customer';
      final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0.0;
      final invoiceDate = _formatDate(invoice['invoice_date']?.toString());
      final pdfUrl = invoice['pdf_url']?.toString();

      final message = '''
🏢 *NSB Motors*
📄 *Invoice $invoiceNumber*

Dear $customerName,

Your invoice is ready:
💰 Amount: ${_formatAmount(totalAmount)}
📅 Date: $invoiceDate

Thank you for your business!
NSB Motors Team''';

      await SupabaseService.insertWhatsAppMessageQueue({
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
          const SnackBar(
            content: Text('WhatsApp message queued successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _resendEmail(Map<String, dynamic> invoice) async {
    final emailController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resend via Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter customer email:',
                style: GoogleFonts.plusJakartaSans(color: _textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: 'customer@example.com'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) Navigator.pop(context, emailController.text);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;

    try {
      final invoiceNumber = invoice['invoice_number']?.toString() ?? 'Unknown';
      final customerName = invoice['customer_name']?.toString() ?? 'Customer';
      final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0.0;
      final invoiceDate = _formatDate(invoice['invoice_date']?.toString());
      final pdfUrl = invoice['pdf_url']?.toString();

      await SupabaseService.insertEmailQueue({
        'to_email': result,
        'subject': 'Invoice $invoiceNumber - NSB Motors',
        'body': _emailBody(customerName, invoiceNumber, invoiceDate, totalAmount),
        'pdf_url': pdfUrl,
        'sent_by_machine_id': invoice['client_id']?.toString() ?? 'mobile_app',
        'sent_by_user_id': 'mobile_user',
        'sent_by_user_name': 'Mobile App User',
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email queued successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  String _emailBody(
      String customerName, String invoiceNumber, String invoiceDate, double totalAmount) {
    return '''<!DOCTYPE html><html><body style="font-family:Arial;color:#333">
<div style="background:#1E40AF;color:white;padding:20px;text-align:center">
  <h1>NSB Motors</h1><h2>Invoice $invoiceNumber</h2>
</div>
<div style="padding:20px">
  <p>Dear $customerName,</p>
  <p>Amount: ${_formatAmount(totalAmount)}<br>Date: $invoiceDate</p>
  <p>Thank you for your business!</p>
  <p>Best regards,<br>NSB Motors Team</p>
</div></body></html>''';
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Invoice detail sheet
// ────────────────────────────────────────────────────────────────────────────

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

  static const _primary = Color(0xFF1D4ED8);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent': return const Color(0xFF3B82F6);
      case 'paid': return const Color(0xFF059669);
      case 'created': return const Color(0xFFD97706);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceNumber = invoice['invoice_number']?.toString() ?? 'Unknown';
    final customerName = invoice['customer_name']?.toString() ?? 'Unknown Customer';
    final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0.0;
    final invoiceDate = invoice['invoice_date']?.toString() ?? '';
    final status = invoice['status']?.toString() ?? 'unknown';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Invoice Details',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Invoice summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        invoiceNumber,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800, color: _primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(totalAmount),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, fontWeight: FontWeight.w800, color: _textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(_formatDate(invoiceDate),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Customer'),
            _detailRow('Name', customerName),
            Row(
              children: [
                Expanded(child: _detailRow('Phone', customerPhone.isEmpty ? 'Not available' : customerPhone)),
                if (customerPhone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF3B82F6)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: customerPhone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number copied')),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionTitle('Client Machine'),
            _detailRow('Machine', clientName),
            _detailRow('Phone', clientPhone),

            const SizedBox(height: 24),

            if (hasPdf) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('View PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: customerPhone.isNotEmpty ? onResendWhatsApp : null,
                    icon: const Icon(Icons.chat_rounded, size: 17),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onResendEmail,
                    icon: const Icon(Icons.email_rounded, size: 17),
                    label: const Text('Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete Invoice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _textSecondary),
            ),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PDF viewer sheet
// ────────────────────────────────────────────────────────────────────────────

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
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice PDF',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    if (_totalPages > 0)
                      Text('Page ${_currentPage + 1} of $_totalPages',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _error
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: Color(0xFFDC2626)),
                        const SizedBox(height: 12),
                        Text('Error loading PDF',
                            style: GoogleFonts.plusJakartaSans(fontSize: 15)),
                      ],
                    ),
                  )
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PDFView(
                        filePath: widget.pdfPath,
                        enableSwipe: true,
                        onRender: (_pages) => setState(() {
                          _totalPages = _pages ?? 0;
                          _isLoading = false;
                        }),
                        onError: (_) => setState(() {
                          _error = true;
                          _isLoading = false;
                        }),
                        onPageChanged: (page, _) =>
                            setState(() => _currentPage = page ?? 0),
                      ),
          ),
        ],
      ),
    );
  }
}
