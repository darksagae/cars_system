import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'email_queue_service.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // Email configuration keys for SharedPreferences
  static const String _smtpHostKey = 'smtp_host';
  static const String _smtpPortKey = 'smtp_port';
  static const String _smtpUsernameKey = 'smtp_username';
  static const String _smtpPasswordKey = 'smtp_password';
  static const String _smtpUseTlsKey = 'smtp_use_tls';
  static const String _fromEmailKey = 'from_email';
  static const String _fromNameKey = 'from_name';

  // In-memory cache
  String? _smtpHost;
  int? _smtpPort;
  String? _username;
  String? _password;
  bool? _useTls;
  String? _fromEmail;
  String? _fromName;
  bool? _isConfiguredCache;

  // Load configuration from SharedPreferences
  Future<void> _loadConfig() async {
    if (_isConfiguredCache != null) return; // Already loaded
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _smtpHost = prefs.getString(_smtpHostKey);
      _smtpPort = prefs.getInt(_smtpPortKey) ?? 587;
      _username = prefs.getString(_smtpUsernameKey);
      _password = prefs.getString(_smtpPasswordKey);
      _useTls = prefs.getBool(_smtpUseTlsKey) ?? true;
      _fromEmail = prefs.getString(_fromEmailKey) ?? _username;
      _fromName = prefs.getString(_fromNameKey) ?? 'NSB Motors Ug';
      _isConfiguredCache = _smtpHost != null && _username != null && _password != null;
    } catch (e) {
      _isConfiguredCache = false;
    }
  }

  // Configure email settings (persists to SharedPreferences)
  Future<void> configureEmail({
    required String smtpHost,
    required int smtpPort,
    required String username,
    required String password,
    bool useTls = true,
    String? fromEmail,
    String? fromName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_smtpHostKey, smtpHost);
      await prefs.setInt(_smtpPortKey, smtpPort);
      await prefs.setString(_smtpUsernameKey, username);
      await prefs.setString(_smtpPasswordKey, password);
      await prefs.setBool(_smtpUseTlsKey, useTls);
      await prefs.setString(_fromEmailKey, fromEmail ?? username);
      await prefs.setString(_fromNameKey, fromName ?? 'NSB Motors Ug');
      
      // Update cache
      _smtpHost = smtpHost;
      _smtpPort = smtpPort;
      _username = username;
      _password = password;
      _useTls = useTls;
      _fromEmail = fromEmail ?? username;
      _fromName = fromName ?? 'NSB Motors Ug';
      _isConfiguredCache = true;
    } catch (e) {
      throw Exception('Failed to save email configuration: $e');
    }
  }

  // Check if email is configured (loads from SharedPreferences if needed)
  Future<bool> get isConfigured async {
    await _loadConfig();
    return _isConfiguredCache ?? false;
  }

  // Synchronous getter for backward compatibility (may return false if not loaded yet)
  bool get isConfiguredSync => _isConfiguredCache ?? false;

  // Send invoice email via queue (mobile app will send it)
  Future<bool> sendInvoiceEmail({
    required String recipientEmail,
    required String recipientName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
    required String companyName,
    String? pdfPath,
    Uint8List? pdfBytes,
    bool useQueue = true, // Use queue by default, set to false to use SMTP
  }) async {
    // Use queue system (mobile app sends) by default
    if (useQueue) {
      return await _sendInvoiceEmailViaQueue(
        recipientEmail: recipientEmail,
        recipientName: recipientName,
        invoiceNumber: invoiceNumber,
        invoiceDate: invoiceDate,
        totalAmount: totalAmount,
        companyName: companyName,
        pdfPath: pdfPath,
        pdfBytes: pdfBytes,
      );
    }

    // Fallback to SMTP if queue is disabled
    // Load configuration from SharedPreferences
    await _loadConfig();
    
    if (!(_isConfiguredCache ?? false)) {
      throw Exception('Email not configured. Please configure email settings first.');
    }

    try {
      final smtpServer = SmtpServer(
        _smtpHost!,
        port: _smtpPort!,
        username: _username,
        password: _password,
        allowInsecure: !(_useTls ?? true),
      );

      final message = Message()
        ..from = Address(_fromEmail ?? _username!, _fromName ?? companyName)
        ..recipients.add(recipientEmail)
        ..subject = 'Invoice $invoiceNumber - $companyName'
        ..html = _generateInvoiceEmailHtml(
          recipientName: recipientName,
          invoiceNumber: invoiceNumber,
          invoiceDate: invoiceDate,
          totalAmount: totalAmount,
          companyName: companyName,
        );

      // Attach PDF if provided (either as path or bytes)
      if (pdfPath != null) {
        message.attachments = [
          FileAttachment(File(pdfPath))
        ];
      } else if (pdfBytes != null) {
        // Create temporary file from bytes
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$invoiceNumber.pdf');
        await tempFile.writeAsBytes(pdfBytes);
        message.attachments = [
          FileAttachment(tempFile, fileName: '$invoiceNumber.pdf')
        ];
      }

      await send(message, smtpServer);
      print('Email sent successfully to $recipientEmail');
      return true;
    } catch (e) {
      print('Error sending email: $e');
      throw Exception('Failed to send email: $e');
    }
  }

  // Send invoice email via queue (mobile app will process)
  Future<bool> _sendInvoiceEmailViaQueue({
    required String recipientEmail,
    required String recipientName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
    required String companyName,
    String? pdfPath,
    Uint8List? pdfBytes,
  }) async {
    try {
      String? pdfUrl;

      // Upload PDF to Supabase Storage if provided
      if (pdfPath != null || pdfBytes != null) {
        print('📤 Uploading PDF to Supabase Storage...');
        
        SupabaseClient? supabase;
        try {
          supabase = Supabase.instance.client;
        } catch (e) {
          throw Exception('Supabase not initialized: $e');
        }
        
        if (supabase == null) {
          throw Exception('Supabase client not available');
        }

        // Read PDF bytes
        Uint8List pdfData;
        if (pdfBytes != null) {
          pdfData = pdfBytes;
        } else if (pdfPath != null) {
          final file = File(pdfPath);
          if (!await file.exists()) {
            throw Exception('PDF file not found: $pdfPath');
          }
          pdfData = await file.readAsBytes();
        } else {
          throw Exception('No PDF provided');
        }

        // Upload to Supabase Storage
        final fileName = 'emails/${DateTime.now().millisecondsSinceEpoch}_invoice_$invoiceNumber.pdf';
        
        await supabase.storage
            .from('whatsapp_attachments') // Reuse same bucket
            .uploadBinary(
              fileName,
              pdfData,
              fileOptions: const FileOptions(
                contentType: 'application/pdf',
                upsert: false,
              ),
            );
        
        // Get public URL
        pdfUrl = supabase.storage
            .from('whatsapp_attachments')
            .getPublicUrl(fileName);
        
        print('✅ PDF uploaded successfully: $pdfUrl');
      }

      // Generate email body
      final emailBody = _generateInvoiceEmailHtml(
        recipientName: recipientName,
        invoiceNumber: invoiceNumber,
        invoiceDate: invoiceDate,
        totalAmount: totalAmount,
        companyName: companyName,
      );

      // Queue email
      final queueService = EmailQueueService();
      final queueId = await queueService.queueEmail(
        toEmail: recipientEmail,
        subject: 'Invoice $invoiceNumber - $companyName',
        body: emailBody,
        pdfUrl: pdfUrl,
      );

      print('✅ Email queued successfully: $queueId');
      print('📱 Mobile app will send this email automatically');

      // Wait for processing
      try {
        await queueService.waitForProcessing(queueId, timeout: const Duration(seconds: 30));
        return true;
      } catch (e) {
        print('⚠️ Email queued but not yet processed: $e');
        return true; // Return true as email is queued
      }
    } catch (e) {
      print('Error queueing email: $e');
      throw Exception('Failed to queue email: $e');
    }
  }

  // Send payment reminder email via queue (mobile app will send it)
  Future<bool> sendPaymentReminderEmail({
    required String recipientEmail,
    required String recipientName,
    required String invoiceNumber,
    required double amount,
    required String companyName,
    String? pdfPath,
    Uint8List? pdfBytes,
    bool useQueue = true, // Use queue by default, set to false to use SMTP
  }) async {
    // Use queue system (mobile app sends) by default
    if (useQueue) {
      return await _sendPaymentReminderEmailViaQueue(
        recipientEmail: recipientEmail,
        recipientName: recipientName,
        invoiceNumber: invoiceNumber,
        amount: amount,
        companyName: companyName,
        pdfPath: pdfPath,
        pdfBytes: pdfBytes,
      );
    }

    // Fallback to SMTP if queue is disabled
    // Load configuration from SharedPreferences
    await _loadConfig();
    
    if (!(_isConfiguredCache ?? false)) {
      throw Exception('Email not configured. Please configure email settings first.');
    }

    try {
      final smtpServer = SmtpServer(
        _smtpHost!,
        port: _smtpPort!,
        username: _username,
        password: _password,
        allowInsecure: !(_useTls ?? true),
      );

      final message = Message()
        ..from = Address(_fromEmail ?? _username!, _fromName ?? companyName)
        ..recipients.add(recipientEmail)
        ..subject = 'Payment Reminder - Invoice $invoiceNumber'
        ..html = _generatePaymentReminderEmailHtml(
          recipientName: recipientName,
          invoiceNumber: invoiceNumber,
          amount: amount,
          companyName: companyName,
        );

      // Attach PDF if provided (either as path or bytes)
      if (pdfPath != null) {
        message.attachments = [
          FileAttachment(File(pdfPath))
        ];
      } else if (pdfBytes != null) {
        // Create temporary file from bytes
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${invoiceNumber}_reminder.pdf');
        await tempFile.writeAsBytes(pdfBytes);
        message.attachments = [
          FileAttachment(tempFile, fileName: '${invoiceNumber}_reminder.pdf')
        ];
      }

      await send(message, smtpServer);
      print('Payment reminder email sent successfully to $recipientEmail');
      return true;
    } catch (e) {
      print('Error sending payment reminder email: $e');
      throw Exception('Failed to send reminder email: $e');
    }
  }

  // Send payment reminder email via queue (mobile app will process)
  Future<bool> _sendPaymentReminderEmailViaQueue({
    required String recipientEmail,
    required String recipientName,
    required String invoiceNumber,
    required double amount,
    required String companyName,
    String? pdfPath,
    Uint8List? pdfBytes,
  }) async {
    try {
      String? pdfUrl;

      // Upload PDF to Supabase Storage if provided
      if (pdfPath != null || pdfBytes != null) {
        print('📤 Uploading PDF to Supabase Storage...');
        
        SupabaseClient? supabase;
        try {
          supabase = Supabase.instance.client;
        } catch (e) {
          throw Exception('Supabase not initialized: $e');
        }
        
        if (supabase == null) {
          throw Exception('Supabase client not available');
        }

        // Read PDF bytes
        Uint8List pdfData;
        if (pdfBytes != null) {
          pdfData = pdfBytes;
        } else if (pdfPath != null) {
          final file = File(pdfPath);
          if (!await file.exists()) {
            throw Exception('PDF file not found: $pdfPath');
          }
          pdfData = await file.readAsBytes();
        } else {
          throw Exception('No PDF provided');
        }

        // Upload to Supabase Storage
        final fileName = 'emails/${DateTime.now().millisecondsSinceEpoch}_reminder_$invoiceNumber.pdf';
        
        await supabase.storage
            .from('whatsapp_attachments') // Reuse same bucket
            .uploadBinary(
              fileName,
              pdfData,
              fileOptions: const FileOptions(
                contentType: 'application/pdf',
                upsert: false,
              ),
            );
        
        // Get public URL
        pdfUrl = supabase.storage
            .from('whatsapp_attachments')
            .getPublicUrl(fileName);
        
        print('✅ PDF uploaded successfully: $pdfUrl');
      }

      // Generate email body
      final emailBody = _generatePaymentReminderEmailHtml(
        recipientName: recipientName,
        invoiceNumber: invoiceNumber,
        amount: amount,
        companyName: companyName,
      );

      // Queue email
      final queueService = EmailQueueService();
      final queueId = await queueService.queueEmail(
        toEmail: recipientEmail,
        subject: 'Payment Reminder - Invoice $invoiceNumber',
        body: emailBody,
        pdfUrl: pdfUrl,
      );

      print('✅ Email queued successfully: $queueId');
      print('📱 Mobile app will send this email automatically');

      // Wait for processing
      try {
        await queueService.waitForProcessing(queueId, timeout: const Duration(seconds: 30));
        return true;
      } catch (e) {
        print('⚠️ Email queued but not yet processed: $e');
        return true; // Return true as email is queued
      }
    } catch (e) {
      print('Error queueing email: $e');
      throw Exception('Failed to queue email: $e');
    }
  }

  // Test email configuration
  Future<bool> testEmailConfig({String? testRecipientEmail}) async {
    // Load configuration from SharedPreferences
    await _loadConfig();
    
    if (!(_isConfiguredCache ?? false)) {
      throw Exception('Email not configured. Please configure email settings first.');
    }

    try {
      final smtpServer = SmtpServer(
        _smtpHost!,
        port: _smtpPort!,
        username: _username,
        password: _password,
        allowInsecure: !(_useTls ?? true),
      );

      // Send test email to the configured email or specified recipient
      final recipientEmail = testRecipientEmail ?? _fromEmail ?? _username!;
      
      final message = Message()
        ..from = Address(_fromEmail ?? _username!, _fromName ?? 'NSB Motors Ug')
        ..recipients.add(recipientEmail)
        ..subject = 'Test Email - NSB Motors Ug Email Configuration'
        ..html = '''
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #2c3e50;">✅ Test Email Successful!</h2>
            
            <p>Congratulations! Your email configuration is working correctly.</p>
            
            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h3 style="margin-top: 0;">Configuration Details:</h3>
              <p><strong>SMTP Host:</strong> $_smtpHost</p>
              <p><strong>SMTP Port:</strong> $_smtpPort</p>
              <p><strong>From Email:</strong> ${_fromEmail ?? _username}</p>
              <p><strong>From Name:</strong> ${_fromName ?? 'NSB Motors Ug'}</p>
            </div>
            
            <p>You can now send invoices and payment reminders automatically!</p>
            
            <p style="color: #666; font-size: 12px; margin-top: 30px;">
              Sent at: ${DateTime.now()}<br>
              This is an automated test email from NSB Motors Ug Sales System.
            </p>
          </div>
        </body>
        </html>
        ''';

      await send(message, smtpServer);
      print('Test email sent successfully to $recipientEmail');
      return true;
    } catch (e) {
      print('Error sending test email: $e');
      throw Exception('Test email failed: $e');
    }
  }

  // Generate HTML for invoice email
  String _generateInvoiceEmailHtml({
    required String recipientName,
    required String invoiceNumber,
    required String invoiceDate,
    required double totalAmount,
    required String companyName,
  }) {
    return '''
    <html>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #2c3e50;">Invoice $invoiceNumber</h2>
        
        <p>Dear $recipientName,</p>
        
        <p>Thank you for your business! Please find attached your invoice for the services provided.</p>
        
        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin-top: 0;">Invoice Details</h3>
          <p><strong>Invoice Number:</strong> $invoiceNumber</p>
          <p><strong>Date:</strong> $invoiceDate</p>
          <p><strong>Total Amount:</strong> UGX ${totalAmount.toStringAsFixed(2)}</p>
        </div>
        
        <p>Payment is due within 30 days of the invoice date. You can make payment through:</p>
        <ul>
          <li>Bank Transfer</li>
          <li>Mobile Money (MTN, Airtel)</li>
          <li>Cash Payment</li>
        </ul>
        
        <p>If you have any questions about this invoice, please don't hesitate to contact us.</p>
        
        <p>Thank you for your business!</p>
        
        <hr style="margin: 30px 0;">
        <p style="font-size: 12px; color: #666;">
          $companyName<br>
          This is an automated message. Please do not reply to this email.
        </p>
      </div>
    </body>
    </html>
    ''';
  }

  // Generate HTML for payment reminder email
  String _generatePaymentReminderEmailHtml({
    required String recipientName,
    required String invoiceNumber,
    required double amount,
    required String companyName,
  }) {
    return '''
    <html>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #e74c3c;">Payment Reminder</h2>
        
        <p>Dear $recipientName,</p>
        
        <p>This is a friendly reminder that payment for Invoice <strong>$invoiceNumber</strong> is now overdue.</p>
        
        <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin-top: 0; color: #856404;">Outstanding Amount</h3>
          <p style="font-size: 18px; font-weight: bold; color: #856404;">UGX ${amount.toStringAsFixed(2)}</p>
        </div>
        
        <p>Please arrange payment at your earliest convenience. You can make payment through:</p>
        <ul>
          <li>Bank Transfer</li>
          <li>Mobile Money (MTN, Airtel)</li>
          <li>Cash Payment</li>
        </ul>
        
        <p>If you have already made payment, please ignore this reminder and contact us to update our records.</p>
        
        <p>Thank you for your prompt attention to this matter.</p>
        
        <hr style="margin: 30px 0;">
        <p style="font-size: 12px; color: #666;">
          $companyName<br>
          This is an automated message. Please do not reply to this email.
        </p>
      </div>
    </body>
    </html>
    ''';
  }
}
