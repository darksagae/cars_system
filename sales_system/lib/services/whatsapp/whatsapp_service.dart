import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../pdf/pdf_service.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';

class WhatsAppService {
  final PDFService _pdfService = PDFService();

  // WhatsApp message templates
  static const String _invoiceMessageTemplate = '''
Hi {customerName}! 👋

Thank you for your business! 📄

Your invoice #{invoiceNumber} is ready:
💰 Amount: {totalAmount}
📅 Due Date: {dueDate}

Please find the invoice attached.

Thank you for your prompt payment! 🙏

Best regards,
Sales Team
''';

  static const String _reminderMessageTemplate = '''
Hi {customerName}! 👋

Friendly reminder: 📢

Your invoice #{invoiceNumber} is now overdue:
💰 Amount: {totalAmount}
📅 Due Date: {dueDate}
💳 Balance Due: {balanceAmount}

Please make payment as soon as possible to avoid any late fees.

Thank you for your attention! 🙏

Best regards,
Sales Team
''';

  static const String _paymentConfirmationMessageTemplate = '''
Hi {customerName}! 👋

Payment Received! ✅

Thank you for your payment of {paymentAmount} for invoice #{invoiceNumber}.

Your account is now up to date.

We appreciate your business! 🙏

Best regards,
Sales Team
''';

  // Send invoice via WhatsApp
  Future<bool> sendInvoice({
    required Invoice invoice,
    required Customer customer,
    String? customMessage,
  }) async {
    try {
      // Generate PDF
      final pdfBytes = await _pdfService.generateInvoicePDF(invoice);
      
      // Save PDF to temporary directory
      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/${invoice.invoiceNumber}.pdf');
      await pdfFile.writeAsBytes(pdfBytes);
      
      // Generate message
      final message = customMessage ?? _generateInvoiceMessage(invoice, customer);
      
      // Create WhatsApp URL
      final whatsappUrl = 'whatsapp://send?phone=${_formatPhoneNumber(customer.phone)}&text=${Uri.encodeComponent(message)}';
      
      // Launch WhatsApp
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        return true;
      } else {
        throw Exception('Cannot launch WhatsApp');
      }
    } catch (e) {
      throw Exception('Failed to send invoice via WhatsApp: $e');
    }
  }

  // Send payment reminder via WhatsApp
  Future<bool> sendPaymentReminder({
    required Invoice invoice,
    required Customer customer,
    String? customMessage,
  }) async {
    try {
      // Generate PDF
      final pdfBytes = await _pdfService.generateInvoicePDF(invoice);
      
      // Save PDF to temporary directory
      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/${invoice.invoiceNumber}_reminder.pdf');
      await pdfFile.writeAsBytes(pdfBytes);
      
      // Generate message
      final message = customMessage ?? _generateReminderMessage(invoice, customer);
      
      // Create WhatsApp URL
      final whatsappUrl = 'whatsapp://send?phone=${_formatPhoneNumber(customer.phone)}&text=${Uri.encodeComponent(message)}';
      
      // Launch WhatsApp
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        return true;
      } else {
        throw Exception('Cannot launch WhatsApp');
      }
    } catch (e) {
      throw Exception('Failed to send reminder via WhatsApp: $e');
    }
  }

  // Send payment confirmation via WhatsApp
  Future<bool> sendPaymentConfirmation({
    required Invoice invoice,
    required Customer customer,
    required double paymentAmount,
    String? customMessage,
  }) async {
    try {
      // Generate message
      final message = customMessage ?? _generatePaymentConfirmationMessage(invoice, customer, paymentAmount);
      
      // Create WhatsApp URL
      final whatsappUrl = 'whatsapp://send?phone=${_formatPhoneNumber(customer.phone)}&text=${Uri.encodeComponent(message)}';
      
      // Launch WhatsApp
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        return true;
      } else {
        throw Exception('Cannot launch WhatsApp');
      }
    } catch (e) {
      throw Exception('Failed to send payment confirmation via WhatsApp: $e');
    }
  }

  // Send bulk messages
  Future<Map<String, dynamic>> sendBulkMessages({
    required List<Invoice> invoices,
    required List<Customer> customers,
    String? customMessage,
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
        
        await sendInvoice(
          invoice: invoice,
          customer: customer,
          customMessage: customMessage,
        );
        
        results['success'].add(invoice.invoiceNumber);
      } catch (e) {
        results['failed'].add('${invoices[i].invoiceNumber}: $e');
      }
    }

    return results;
  }

  // Send message (generic method)
  Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Create WhatsApp URL
      final whatsappUrl = 'whatsapp://send?phone=${_formatPhoneNumber(phoneNumber)}&text=${Uri.encodeComponent(message)}';
      
      // Launch WhatsApp
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        return true;
      } else {
        throw Exception('Cannot launch WhatsApp');
      }
    } catch (e) {
      throw Exception('Failed to send message via WhatsApp: $e');
    }
  }

  // Check if WhatsApp is available
  Future<bool> isWhatsAppAvailable() async {
    try {
      return await canLaunchUrl(Uri.parse('whatsapp://send?phone=1234567890&text=test'));
    } catch (e) {
      return false;
    }
  }

  // Generate invoice message
  String _generateInvoiceMessage(Invoice invoice, Customer customer) {
    return _invoiceMessageTemplate
        .replaceAll('{customerName}', customer.displayName)
        .replaceAll('{invoiceNumber}', invoice.invoiceNumber)
        .replaceAll('{totalAmount}', '\$${invoice.totalAmount.toStringAsFixed(2)}')
        .replaceAll('{dueDate}', _formatDate(invoice.dueDate));
  }

  // Generate reminder message
  String _generateReminderMessage(Invoice invoice, Customer customer) {
    return _reminderMessageTemplate
        .replaceAll('{customerName}', customer.displayName)
        .replaceAll('{invoiceNumber}', invoice.invoiceNumber)
        .replaceAll('{totalAmount}', '\$${invoice.totalAmount.toStringAsFixed(2)}')
        .replaceAll('{dueDate}', _formatDate(invoice.dueDate))
        .replaceAll('{balanceAmount}', '\$${invoice.balanceAmount.toStringAsFixed(2)}');
  }

  // Generate payment confirmation message
  String _generatePaymentConfirmationMessage(Invoice invoice, Customer customer, double paymentAmount) {
    return _paymentConfirmationMessageTemplate
        .replaceAll('{customerName}', customer.displayName)
        .replaceAll('{invoiceNumber}', invoice.invoiceNumber)
        .replaceAll('{paymentAmount}', '\$${paymentAmount.toStringAsFixed(2)}');
  }

  // Format phone number for WhatsApp
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add country code if not present (assuming US +1)
    if (digits.length == 10) {
      return '1$digits';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return digits;
    } else {
      return digits;
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get WhatsApp business URL
  String getWhatsAppBusinessUrl(String phoneNumber) {
    return 'https://wa.me/${_formatPhoneNumber(phoneNumber)}';
  }

  // Get WhatsApp web URL
  String getWhatsAppWebUrl(String phoneNumber, String message) {
    return 'https://web.whatsapp.com/send?phone=${_formatPhoneNumber(phoneNumber)}&text=${Uri.encodeComponent(message)}';
  }

  // Generate WhatsApp URL (used by widgets)
  String _generateWhatsAppUrl(String phoneNumber, String message) {
    return 'https://wa.me/${_formatPhoneNumber(phoneNumber)}?text=${Uri.encodeComponent(message)}';
  }

  // Get WhatsApp status (placeholder implementation)
  Future<String> getWhatsAppStatus() async {
    try {
      // This would typically check if WhatsApp is installed and available
      // For now, return a placeholder status
      return 'available';
    } catch (e) {
      return 'error';
    }
  }

}