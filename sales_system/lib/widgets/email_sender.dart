
import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../services/email_service.dart';
import 'glass_liquid_theme.dart';

class EmailSender extends StatefulWidget {
  final Invoice invoice;
  final Customer? customer;

  const EmailSender({
    super.key,
    required this.invoice,
    this.customer,
  });

  @override
  State<EmailSender> createState() => _EmailSenderState();
}

class _EmailSenderState extends State<EmailSender> {
  final EmailService _emailService = EmailService();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEmailConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkEmailConfiguration();
    _initializeEmailContent();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailConfiguration() async {
    final isConfigured = await _emailService.isEmailConfigured();
    setState(() {
      _isEmailConfigured = isConfigured;
    });
  }

  void _initializeEmailContent() {
    _subjectController.text = 'Invoice #${widget.invoice.invoiceNumber} - Payment Due';
    _bodyController.text = _generateDefaultBody();
  }

  String _generateDefaultBody() {
    final customerName = widget.customer?.displayName ?? 'Valued Customer';
    return '''
Dear $customerName,

Thank you for your business! Please find attached your invoice #${widget.invoice.invoiceNumber} for the amount of \$${widget.invoice.totalAmount.toStringAsFixed(2)}.

Invoice Details:
- Invoice Number: ${widget.invoice.invoiceNumber}
- Invoice Date: ${_formatDate(widget.invoice.invoiceDate)}
- Due Date: ${_formatDate(widget.invoice.dueDate)}
- Total Amount: \$${widget.invoice.totalAmount.toStringAsFixed(2)}

Please remit payment by the due date. If you have any questions about this invoice, please don't hesitate to contact us.

Thank you for your prompt payment.

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
          if (!_isEmailConfigured) ...[
            _buildConfigurationWarning(),
            const SizedBox(height: 24),
          ],
          _buildEmailForm(),
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
            color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const FaIcon(
            FontAwesomeIcons.envelope,
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
                'Send Invoice Email',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Send invoice to customer via email',
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

  Widget _buildConfigurationWarning() {
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
                  'Email Not Configured',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Please configure your email settings first.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _navigateToEmailConfig(),
            child: Text(
              'Configure',
              style: GoogleFonts.poppins(
                color: GlassLiquidTheme.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Content',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _subjectController,
          label: 'Subject',
          hint: 'Invoice #${widget.invoice.invoiceNumber} - Payment Due',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bodyController,
          label: 'Message',
          hint: 'Enter your message here...',
          maxLines: 8,
        ),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Send Email',
            FontAwesomeIcons.paperPlane,
            GlassLiquidTheme.accentBlue,
            _sendEmail,
            isLoading: _isLoading,
            enabled: _isEmailConfigured,
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
            enabled: _isEmailConfigured,
          ),
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

  Future<void> _sendEmail() async {
    if (widget.customer == null) {
      _showError('Customer information not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _emailService.sendInvoiceEmail(
        invoice: widget.invoice,
        customer: widget.customer!,
        customSubject: _subjectController.text.trim(),
        customBody: _bodyController.text.trim(),
      );

      _showSuccess('Invoice email sent successfully!');
    } catch (e) {
      _showError('Failed to send email: $e');
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
      await _emailService.sendPaymentReminder(
        invoice: widget.invoice,
        customer: widget.customer!,
        customSubject: _subjectController.text.trim(),
        customBody: _bodyController.text.trim(),
      );

      _showSuccess('Payment reminder sent successfully!');
    } catch (e) {
      _showError('Failed to send reminder: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToEmailConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailConfigScreen(),
      ),
    ).then((_) {
      _checkEmailConfiguration();
    });
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

