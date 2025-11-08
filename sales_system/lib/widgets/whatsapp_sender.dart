
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../services/whatsapp_service.dart';
import 'glass_liquid_theme.dart';

class WhatsAppSender extends StatefulWidget {
  final Invoice invoice;
  final Customer? customer;

  const WhatsAppSender({
    super.key,
    required this.invoice,
    this.customer,
  });

  @override
  State<WhatsAppSender> createState() => _WhatsAppSenderState();
}

class _WhatsAppSenderState extends State<WhatsAppSender> {
  final WhatsAppService _whatsappService = WhatsAppService();
  final _messageController = TextEditingController();
  
  bool _isLoading = false;
  bool _isWhatsAppInstalled = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkWhatsAppStatus();
    _initializeMessageContent();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkWhatsAppStatus() async {
    final status = await _whatsappService.getWhatsAppStatus();
    setState(() {
      _isWhatsAppInstalled = status['isInstalled'];
      _statusMessage = status['message'];
    });
  }

  void _initializeMessageContent() {
    _messageController.text = _generateDefaultMessage();
  }

  String _generateDefaultMessage() {
    final customerName = widget.customer?.displayName ?? 'Valued Customer';
    return '''
Hi $customerName! 👋

Thank you for your business! 📄

📋 *Invoice Details:*
• Invoice #: ${widget.invoice.invoiceNumber}
• Date: ${_formatDate(widget.invoice.invoiceDate)}
• Due Date: ${_formatDate(widget.invoice.dueDate)}
• Amount: \$${widget.invoice.totalAmount.toStringAsFixed(2)}

Please find your invoice attached. 📎

If you have any questions, feel free to reach out!

Best regards,
NSB Motors Ug
''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (!_isWhatsAppInstalled) ...[
            _buildInstallationWarning(),
            const SizedBox(height: 24),
          ],
          _buildMessageForm(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.green,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send via WhatsApp',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Share invoice with customer via WhatsApp',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstallationWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp Not Installed',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _statusMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WhatsApp Message',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _messageController,
          label: 'Message',
          hint: 'Enter your WhatsApp message here...',
          maxLines: 8,
        ),
        const SizedBox(height: 16),
        _buildMessagePreview(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.6),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'WhatsApp Preview',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _messageController.text.isEmpty 
                ? 'Enter a message to see preview...'
                : _messageController.text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Send Invoice',
                FontAwesomeIcons.paperPlane,
                Colors.green,
                _sendInvoice,
                isLoading: _isLoading,
                enabled: _isWhatsAppInstalled && widget.customer != null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Send Reminder',
                FontAwesomeIcons.bell,
                Colors.orange,
                _sendReminder,
                isLoading: _isLoading,
                enabled: _isWhatsAppInstalled && widget.customer != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Payment Confirmation',
                FontAwesomeIcons.check,
                GlassLiquidTheme.accentBlue,
                _sendPaymentConfirmation,
                isLoading: _isLoading,
                enabled: _isWhatsAppInstalled && widget.customer != null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Test Message',
                FontAwesomeIcons.flask,
                Colors.purple,
                _sendTestMessage,
                isLoading: _isLoading,
                enabled: _isWhatsAppInstalled,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isLoading = false,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !isLoading ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: enabled 
                ? color.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled 
                  ? color.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 2,
                  ),
                )
              else
                FaIcon(
                  icon,
                  color: enabled ? color : Colors.grey,
                  size: 20,
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.white : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendInvoice() async {
    if (widget.customer == null) {
      _showError('Customer information not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _whatsappService.sendInvoice(
        invoice: widget.invoice,
        customer: widget.customer!,
        customMessage: _messageController.text.trim(),
      );

      _showSuccess('Invoice sent via WhatsApp successfully!');
    } catch (e) {
      _showError('Failed to send invoice: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendReminder() async {
    if (widget.customer == null) {
      _showError('Customer information not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _whatsappService.sendPaymentReminder(
        invoice: widget.invoice,
        customer: widget.customer!,
        customMessage: _messageController.text.trim(),
      );

      _showSuccess('Payment reminder sent via WhatsApp successfully!');
    } catch (e) {
      _showError('Failed to send reminder: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendPaymentConfirmation() async {
    if (widget.customer == null) {
      _showError('Customer information not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _whatsappService.sendPaymentConfirmation(
        invoice: widget.invoice,
        customer: widget.customer!,
        customMessage: _messageController.text.trim(),
      );

      _showSuccess('Payment confirmation sent via WhatsApp successfully!');
    } catch (e) {
      _showError('Failed to send payment confirmation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestMessage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a test customer
      final testCustomer = Customer(
        id: 0,
        name: 'Test Customer',
        email: 'test@example.com',
        phone: '1234567890',
      );

      // Create a test invoice
      final testInvoice = Invoice(
        id: 0,
        invoiceNumber: 'TEST-001',
        customerId: 0,
        invoiceDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        status: InvoiceStatus.draft,
        items: [],
        notes: 'Test invoice',
        terms: 'Test terms',
      );

      await _whatsappService.sendInvoice(
        invoice: testInvoice,
        customer: testCustomer,
        customMessage: 'Test message from NSB Motors Ug! 🚀',
      );

      _showSuccess('Test message sent via WhatsApp successfully!');
    } catch (e) {
      _showError('Failed to send test message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
    );
  }
}

