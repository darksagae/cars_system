import 'dart:io';
import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../pdf/pdf_service.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';

class EmailService {
  final PDFService _pdfService = PDFService();
  
  // Email configuration keys
  static const String _smtpHostKey = 'smtp_host';
  static const String _smtpPortKey = 'smtp_port';
  static const String _smtpUsernameKey = 'smtp_username';
  static const String _smtpPasswordKey = 'smtp_password';
  static const String _smtpUseTlsKey = 'smtp_use_tls';
  static const String _fromEmailKey = 'from_email';
  static const String _fromNameKey = 'from_name';

  // Default email templates
  static const String _invoiceSubjectTemplate = 'Invoice #{invoiceNumber} - Payment Due';
  static const String _invoiceBodyTemplate = '''
Dear {customerName},

Thank you for your business! Please find attached your invoice #{invoiceNumber} for the amount of {totalAmount}.

Invoice Details:
- Invoice Number: {invoiceNumber}
- Invoice Date: {invoiceDate}
- Due Date: {dueDate}
- Total Amount: {totalAmount}

Please remit payment by the due date. If you have any questions about this invoice, please don't hesitate to contact us.

Thank you for your prompt payment.

Best regards,
{fromName}
''';

  static const String _reminderSubjectTemplate = 'Payment Reminder - Invoice #{invoiceNumber}';
  static const String _reminderBodyTemplate = '''
Dear {customerName},

This is a friendly reminder that payment for invoice #{invoiceNumber} is now overdue.

Invoice Details:
- Invoice Number: {invoiceNumber}
- Invoice Date: {invoiceDate}
- Due Date: {dueDate}
- Total Amount: {totalAmount}
- Balance Due: {balanceAmount}

Please remit payment as soon as possible to avoid any late fees.

If you have already made payment, please disregard this notice.

Thank you for your attention to this matter.

Best regards,
{fromName}
''';

  // Save email configuration
  Future<bool> saveEmailConfig({
    required String smtpHost,
    required int smtpPort,
    required String smtpUsername,
    required String smtpPassword,
    required bool useTls,
    required String fromEmail,
    required String fromName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_smtpHostKey, smtpHost);
      await prefs.setInt(_smtpPortKey, smtpPort);
      await prefs.setString(_smtpUsernameKey, smtpUsername);
      await prefs.setString(_smtpPasswordKey, smtpPassword);
      await prefs.setBool(_smtpUseTlsKey, useTls);
      await prefs.setString(_fromEmailKey, fromEmail);
      await prefs.setString(_fromNameKey, fromName);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get email configuration
  Future<Map<String, dynamic>?> getEmailConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final smtpHost = prefs.getString(_smtpHostKey);
      if (smtpHost == null) return null;

      return {
        'smtpHost': smtpHost,
        'smtpPort': prefs.getInt(_smtpPortKey) ?? 587,
        'smtpUsername': prefs.getString(_smtpUsernameKey) ?? '',
        'smtpPassword': prefs.getString(_smtpPasswordKey) ?? '',
        'useTls': prefs.getBool(_smtpUseTlsKey) ?? true,
        'fromEmail': prefs.getString(_fromEmailKey) ?? 'nsbbsolutions@gmail.com',
        'fromName': prefs.getString(_fromNameKey) ?? 'NSB Motors Ug',
      };
    } catch (e) {
      return null;
    }
  }

  // Check if email is configured
  Future<bool> isEmailConfigured() async {
    final config = await getEmailConfig();
    return config != null && 
           config['smtpHost'] != null && 
           config['smtpUsername'] != null && 
           config['fromEmail'] != null;
  }

  // Send invoice email
  Future<bool> sendInvoiceEmail({
    required Invoice invoice,
    required Customer customer,
    String? customSubject,
    String? customBody,
  }) async {
    try {
      final config = await getEmailConfig();
      if (config == null) throw Exception('Email not configured');

      // Generate PDF
      final pdfBytes = await _pdfService.generateInvoicePDF(invoice);
      
      // Create email
      final message = Message()
        ..from = Address(config['fromEmail'], config['fromName'])
        ..recipients = [customer.email]
        ..subject = customSubject ?? _generateInvoiceSubject(invoice)
        ..html = customBody ?? _generateInvoiceBody(invoice, customer, config)
        ..attachments = [
          FileAttachment(
            await _createTempFile(pdfBytes, '${invoice.invoiceNumber}.pdf'),
            fileName: '${invoice.invoiceNumber}.pdf',
            contentType: 'application/pdf',
          ),
        ];

      // Send email
      final smtpServer = SmtpServer(
        config['smtpHost'],
        port: config['smtpPort'],
        username: config['smtpUsername'],
        password: config['smtpPassword'],
        allowInsecure: !config['useTls'],
      );

      await send(message, smtpServer);
      return true;
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  // Send payment reminder
  Future<bool> sendPaymentReminder({
    required Invoice invoice,
    required Customer customer,
    String? customSubject,
    String? customBody,
  }) async {
    try {
      final config = await getEmailConfig();
      if (config == null) throw Exception('Email not configured');

      // Generate PDF
      final pdfBytes = await _pdfService.generateInvoicePDF(invoice);
      
      // Create email
      final message = Message()
        ..from = Address(config['fromEmail'], config['fromName'])
        ..recipients = [customer.email]
        ..subject = customSubject ?? _generateReminderSubject(invoice)
        ..html = customBody ?? _generateReminderBody(invoice, customer, config)
        ..attachments = [
          FileAttachment(
            await _createTempFile(pdfBytes, '${invoice.invoiceNumber}.pdf'),
            fileName: '${invoice.invoiceNumber}.pdf',
            contentType: 'application/pdf',
          ),
        ];

      // Send email
      final smtpServer = SmtpServer(
        config['smtpHost'],
        port: config['smtpPort'],
        username: config['smtpUsername'],
        password: config['smtpPassword'],
        allowInsecure: !config['useTls'],
      );

      await send(message, smtpServer);
      return true;
    } catch (e) {
      throw Exception('Failed to send reminder: $e');
    }
  }

  // Send reminder email (alias for sendPaymentReminder)
  Future<bool> sendReminderEmail({
    required Invoice invoice,
    required Customer customer,
    String? customSubject,
    String? customBody,
  }) async {
    return await sendPaymentReminder(
      invoice: invoice,
      customer: customer,
      customSubject: customSubject,
      customBody: customBody,
    );
  }

  // Send bulk emails
  Future<Map<String, dynamic>> sendBulkEmails({
    required List<Invoice> invoices,
    required List<Customer> customers,
    String? customSubject,
    String? customBody,
  }) async {
    final results = <String, dynamic>{
      'success': <String>[],
      'failed': <String>[],
      'total': invoices.length,
    };

    for (int i = 0; i < invoices.length; i++) {
      try {
        final invoice = invoices[i];
        final customer = customers[i];
        
        await sendInvoiceEmail(
          invoice: invoice,
          customer: customer,
          customSubject: customSubject,
          customBody: customBody,
        );
        
        results['success'].add(invoice.invoiceNumber);
      } catch (e) {
        results['failed'].add('${invoices[i].invoiceNumber}: $e');
      }
    }

    return results;
  }

  // Test email configuration
  Future<bool> testEmailConfig() async {
    try {
      final config = await getEmailConfig();
      if (config == null) throw Exception('Email not configured');

      // Create test message
      final message = Message()
        ..from = Address(config['fromEmail'], config['fromName'])
        ..recipients = [config['fromEmail']]
        ..subject = 'Test Email - NSB Motors Ug'
        ..html = '''
        <h2>Test Email</h2>
        <p>This is a test email from NSB Motors Ug.</p>
        <p>If you received this email, your email configuration is working correctly.</p>
        <p>Sent at: ${DateTime.now()}</p>
        ''';

      // Send test email
      final smtpServer = SmtpServer(
        config['smtpHost'],
        port: config['smtpPort'],
        username: config['smtpUsername'],
        password: config['smtpPassword'],
        allowInsecure: !config['useTls'],
      );

      await send(message, smtpServer);
      return true;
    } catch (e) {
      throw Exception('Test email failed: $e');
    }
  }

  // Generate invoice subject
  String _generateInvoiceSubject(Invoice invoice) {
    return _invoiceSubjectTemplate.replaceAll('{invoiceNumber}', invoice.invoiceNumber);
  }

  // Generate invoice body
  String _generateInvoiceBody(Invoice invoice, Customer customer, Map<String, dynamic> config) {
    return _invoiceBodyTemplate
        .replaceAll('{customerName}', customer.displayName)
        .replaceAll('{invoiceNumber}', invoice.invoiceNumber)
        .replaceAll('{invoiceDate}', _formatDate(invoice.invoiceDate))
        .replaceAll('{dueDate}', _formatDate(invoice.dueDate))
        .replaceAll('{totalAmount}', '\$${invoice.totalAmount.toStringAsFixed(2)}')
        .replaceAll('{fromName}', config['fromName']);
  }

  // Generate reminder subject
  String _generateReminderSubject(Invoice invoice) {
    return _reminderSubjectTemplate.replaceAll('{invoiceNumber}', invoice.invoiceNumber);
  }

  // Generate reminder body
  String _generateReminderBody(Invoice invoice, Customer customer, Map<String, dynamic> config) {
    return _reminderBodyTemplate
        .replaceAll('{customerName}', customer.displayName)
        .replaceAll('{invoiceNumber}', invoice.invoiceNumber)
        .replaceAll('{invoiceDate}', _formatDate(invoice.invoiceDate))
        .replaceAll('{dueDate}', _formatDate(invoice.dueDate))
        .replaceAll('{totalAmount}', '\$${invoice.totalAmount.toStringAsFixed(2)}')
        .replaceAll('{balanceAmount}', '\$${invoice.balanceAmount.toStringAsFixed(2)}')
        .replaceAll('{fromName}', config['fromName']);
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get common SMTP servers
  static Map<String, Map<String, dynamic>> getCommonSMTPServers() {
    return {
      'Gmail': {
        'host': 'smtp.gmail.com',
        'port': 587,
        'useTls': true,
      },
      'Outlook': {
        'host': 'smtp-mail.outlook.com',
        'port': 587,
        'useTls': true,
      },
      'Yahoo': {
        'host': 'smtp.mail.yahoo.com',
        'port': 587,
        'useTls': true,
      },
      'Custom': {
        'host': '',
        'port': 587,
        'useTls': true,
      },
    };
  }

  // Helper method to create temporary file
  Future<File> _createTempFile(Uint8List bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
}