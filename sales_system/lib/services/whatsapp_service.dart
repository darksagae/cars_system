import 'package:url_launcher/url_launcher.dart';
import '../utils/uganda_formatters.dart';

/// WhatsApp Service
/// 
/// IMPORTANT NOTE: This service opens WhatsApp Web/browser and requires manual send.
/// For true automatic sending without manual intervention, you need WhatsApp Business API:
/// - WhatsApp Business API (official, requires approval and costs money)
/// - Twilio WhatsApp API (paid service)
/// - Other third-party services
/// 
/// Current implementation opens WhatsApp with pre-filled message, but user must click send.
class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  // Company Information
  static const String _companyName = 'NSB Motors Ug';
  static const String _companyPhone = '+25675128406';
  static const String _companyAddress = 'Uganda';

  // Send WhatsApp message
  // NOTE: This method opens WhatsApp Web/browser and requires manual send click.
  // For true automation without manual intervention, you need WhatsApp Business API.
  Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Format phone number (remove any non-digits and add country code if needed)
      String formattedNumber = _formatPhoneNumber(phoneNumber);
      
      // Try WhatsApp protocol first (works on mobile/desktop with WhatsApp installed)
      Uri? whatsappUrl;
      
      // Try whatsapp:// protocol first (for desktop/mobile apps)
      final whatsappProtocolUrl = Uri.parse('whatsapp://send?phone=$formattedNumber&text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(whatsappProtocolUrl)) {
        whatsappUrl = whatsappProtocolUrl;
      } else {
        // Fallback to web URL (wa.me)
        whatsappUrl = Uri.parse('https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}');
      }
      
      // Launch WhatsApp
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        // Note: User still needs to manually click send in WhatsApp Web/App
        print('WhatsApp opened. Please manually click send to complete the message.');
        return true;
      } else {
        throw Exception('Cannot launch WhatsApp. Please ensure WhatsApp is installed or use WhatsApp Web.');
      }
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      throw Exception('Failed to open WhatsApp: $e');
    }
  }

  // Send invoice WhatsApp message
  Future<bool> sendInvoiceMessage({
    required String phoneNumber,
    required String customerName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
    String? companyName,
  }) async {
    final message = _generateInvoiceMessage(
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      totalAmount: totalAmount,
      companyName: companyName ?? _companyName,
    );

    return await sendMessage(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Send payment reminder WhatsApp message
  Future<bool> sendPaymentReminderMessage({
    required String phoneNumber,
    required String customerName,
    required String invoiceNumber,
    required double amount,
    String? companyName,
  }) async {
    final message = _generatePaymentReminderMessage(
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      amount: amount,
      companyName: companyName ?? _companyName,
    );

    return await sendMessage(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Format phone number for WhatsApp
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add Uganda country code if not present
    if (digitsOnly.startsWith('0')) {
      digitsOnly = '256' + digitsOnly.substring(1);
    } else if (!digitsOnly.startsWith('256')) {
      digitsOnly = '256' + digitsOnly;
    }
    
    return digitsOnly;
  }

  // Generate invoice WhatsApp message
  String _generateInvoiceMessage({
    required String customerName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
    required String companyName,
  }) {
    return '''
🏢 *$companyName*
📄 *Invoice $invoiceNumber*

Dear $customerName,

Your invoice is ready for payment:
💰 Amount: ${UgandaFormatters.formatCurrency(totalAmount)}
📅 Date: $invoiceDate

Thank you for your business!

💳 *Payment Options:*
• Bank Transfer
• Mobile Money (MTN/Airtel)
• Cash Payment

Payment is due within 30 days.

For any questions, please contact us at $_companyPhone.

Best regards,
$companyName Team
    '''.trim();
  }

  // Generate payment reminder WhatsApp message
  String _generatePaymentReminderMessage({
    required String customerName,
    required String invoiceNumber,
    required double amount,
    required String companyName,
  }) {
    return '''
🏢 *$companyName*
⏰ *Payment Reminder*

Dear $customerName,

Friendly reminder about your invoice:
📄 Invoice: $invoiceNumber
💰 Outstanding Amount: ${UgandaFormatters.formatCurrency(amount)}

This is a friendly reminder that payment is now overdue.

💳 *Payment Options:*
• Bank Transfer
• Mobile Money (MTN/Airtel)
• Cash Payment

Please arrange payment at your earliest convenience.

If you've already paid, please contact us at $_companyPhone to update our records.

Thank you for your prompt attention.

Best regards,
$companyName Team
    '''.trim();
  }
}