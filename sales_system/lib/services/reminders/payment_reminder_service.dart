import '../../database/database_helper.dart';
import '../../models/payment_reminder.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../email/email_service.dart';
import '../whatsapp/whatsapp_service.dart';

class PaymentReminderService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final EmailService _emailService = EmailService();
  final WhatsAppService _whatsappService = WhatsAppService();

  // Create a new payment reminder
  Future<int> createReminder(PaymentReminder reminder) async {
    final db = await _dbHelper.database;
    return await db.insert('payment_reminders', reminder.toMap());
  }

  // Get all reminders
  Future<List<PaymentReminder>> getAllReminders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_reminders',
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => PaymentReminder.fromMap(maps[i]));
  }

  // Get reminders by status
  Future<List<PaymentReminder>> getRemindersByStatus(ReminderStatus status) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_reminders',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => PaymentReminder.fromMap(maps[i]));
  }

  // Get reminders by type
  Future<List<PaymentReminder>> getRemindersByType(ReminderType type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_reminders',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => PaymentReminder.fromMap(maps[i]));
  }

  // Get reminders for invoice
  Future<List<PaymentReminder>> getRemindersForInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_reminders',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => PaymentReminder.fromMap(maps[i]));
  }

  // Get reminders for customer
  Future<List<PaymentReminder>> getRemindersForCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_reminders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => PaymentReminder.fromMap(maps[i]));
  }

  // Get overdue reminders
  Future<List<PaymentReminder>> getOverdueReminders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_reminders',
      where: 'status = ? AND scheduled_date < ?',
      whereArgs: [ReminderStatus.scheduled.name, DateTime.now().toIso8601String()],
      orderBy: 'scheduled_date ASC',
    );
    return List.generate(maps.length, (i) => PaymentReminder.fromMap(maps[i]));
  }

  // Update reminder
  Future<int> updateReminder(PaymentReminder reminder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'payment_reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  // Delete reminder
  Future<int> deleteReminder(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'payment_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Send reminder
  Future<bool> sendReminder(PaymentReminder reminder, Invoice invoice, Customer customer) async {
    try {
      bool success = false;
      
      switch (reminder.type) {
        case ReminderType.email:
          success = await _emailService.sendReminderEmail(
            invoice: invoice,
            customer: customer,
          );
          break;
        case ReminderType.whatsapp:
          success = await _whatsappService.sendMessage(
            phoneNumber: customer.phone,
            message: reminder.message,
          );
          break;
        case ReminderType.sms:
          // SMS implementation would go here
          success = false; // Placeholder
          break;
        case ReminderType.phone:
          // Phone call implementation would go here
          success = false; // Placeholder
          break;
        case ReminderType.letter:
          // Letter implementation would go here
          success = false; // Placeholder
          break;
      }

      if (success) {
        // Update reminder status
        final updatedReminder = reminder.copyWith(
          status: ReminderStatus.sent,
          sentDate: DateTime.now(),
        );
        await updateReminder(updatedReminder);
      }

      return success;
    } catch (e) {
      print('Error sending reminder: $e');
      return false;
    }
  }

  // Get reminder template
  String getReminderTemplate(Invoice invoice, Customer customer, ReminderType type) {
    final invoiceDate = invoice.invoiceDate;
    final dueDate = invoice.dueDate;
    final amount = invoice.totalAmount;
    final daysOverdue = DateTime.now().difference(dueDate).inDays;

    switch (type) {
      case ReminderType.email:
        return '''
Dear ${customer.name},

This is a friendly reminder that your invoice #${invoice.invoiceNumber} for \$${amount.toStringAsFixed(2)} is now ${daysOverdue > 0 ? '$daysOverdue days overdue' : 'due'}.

Invoice Details:
- Invoice Number: ${invoice.invoiceNumber}
- Amount: \$${amount.toStringAsFixed(2)}
- Due Date: ${dueDate.toString().split(' ')[0]}

Please make payment at your earliest convenience.

Thank you for your business.

Best regards,
Your Sales Team
        ''';
      case ReminderType.whatsapp:
        return '''
🏢 NSB Motors Ug
⏰ Payment Reminder

Dear ${customer.name},

Friendly reminder about your invoice:
📄 Invoice: ${invoice.invoiceNumber}
💰 Outstanding Amount: UGX ${amount.toStringAsFixed(2)}

This is a friendly reminder that payment is now ${daysOverdue > 0 ? '$daysOverdue days overdue' : 'due'}.

💳 Payment Options:
• Bank Transfer
• Mobile Money (MTN/Airtel)
• Cash Payment

Please arrange payment at your earliest convenience.

If you've already paid, please contact us at +256394836253 to update our records.

Thank you for your prompt attention.

Best regards,
NSB Motors Ug Team
        ''';
      case ReminderType.sms:
        return '''
Hi ${customer.name}, your invoice #${invoice.invoiceNumber} for \$${amount.toStringAsFixed(2)} is ${daysOverdue > 0 ? '$daysOverdue days overdue' : 'due'}. Please pay when convenient. Thank you!
        ''';
      case ReminderType.phone:
        return '''
Hello ${customer.name}, this is a reminder call about your invoice #${invoice.invoiceNumber} for \$${amount.toStringAsFixed(2)} which is ${daysOverdue > 0 ? '$daysOverdue days overdue' : 'due'}. Please make payment when convenient. Thank you!
        ''';
      case ReminderType.letter:
        return '''
Dear ${customer.name},

RE: Overdue Invoice #${invoice.invoiceNumber}

We are writing to inform you that your invoice #${invoice.invoiceNumber} for \$${amount.toStringAsFixed(2)} is now $daysOverdue days overdue.

Please remit payment immediately to avoid any further action.

Thank you for your attention to this matter.

Sincerely,
Your Sales Team
        ''';
    }
  }

  // Get reminder subject
  String getReminderSubject(Invoice invoice, Customer customer, ReminderType type) {
    final daysOverdue = DateTime.now().difference(invoice.dueDate).inDays;
    
    switch (type) {
      case ReminderType.email:
        return daysOverdue > 0 
          ? 'Overdue Invoice #${invoice.invoiceNumber} - ${daysOverdue} Days Overdue'
          : 'Payment Reminder - Invoice #${invoice.invoiceNumber}';
      case ReminderType.whatsapp:
        return 'Payment Reminder';
      case ReminderType.sms:
        return 'Payment Reminder';
      case ReminderType.phone:
        return 'Payment Reminder Call';
      case ReminderType.letter:
        return 'Final Notice - Overdue Invoice #${invoice.invoiceNumber}';
    }
  }

  // Get reminder message
  String getReminderMessage(Invoice invoice, Customer customer, ReminderType type) {
    return getReminderTemplate(invoice, customer, type);
  }

  // Get reminder count by status
  Future<int> getReminderCountByStatus(ReminderStatus status) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payment_reminders WHERE status = ?',
      [status.name]
    );
    return result.first['count'] as int;
  }

  // Get reminder count by type
  Future<int> getReminderCountByType(ReminderType type) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payment_reminders WHERE type = ?',
      [type.name]
    );
    return result.first['count'] as int;
  }

  // Get invoice for reminder
  Future<Invoice?> getInvoiceForReminder(int reminderId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT i.* FROM invoices i
      JOIN payment_reminders pr ON i.id = pr.invoiceId
      WHERE pr.id = ?
    ''', [reminderId]);
    
    if (result.isNotEmpty) {
      return Invoice.fromMap(result.first);
    }
    return null;
  }

  // Get customer for reminder
  Future<Customer?> getCustomerForReminder(int reminderId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT c.* FROM customers c
      JOIN invoices i ON c.id = i.customerId
      JOIN payment_reminders pr ON i.id = pr.invoiceId
      WHERE pr.id = ?
    ''', [reminderId]);
    
    if (result.isNotEmpty) {
      return Customer.fromMap(result.first);
    }
    return null;
  }
}