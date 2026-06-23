import '../../database/database_helper.dart';
import '../../models/demand_letter.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';

class DemandLetterService {
  static const String _tableName = 'demand_letters';
  
  // Create demand letter
  Future<int> createDemandLetter(DemandLetter demandLetter) async {
    final db = await DatabaseHelper().database;
    return await db.insert(_tableName, demandLetter.toMap());
  }

  // Get all demand letters
  Future<List<DemandLetter>> getAllDemandLetters() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => DemandLetter.fromMap(maps[i]));
  }

  // Get demand letter by ID
  Future<DemandLetter?> getDemandLetterById(int id) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DemandLetter.fromMap(maps.first);
    }
    return null;
  }

  // Update demand letter
  Future<int> updateDemandLetter(DemandLetter demandLetter) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      _tableName,
      demandLetter.toMap(),
      where: 'id = ?',
      whereArgs: [demandLetter.id],
    );
  }

  // Delete demand letter
  Future<int> deleteDemandLetter(int id) async {
    final db = await DatabaseHelper().database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get demand letters by invoice
  Future<List<DemandLetter>> getDemandLettersByInvoice(int invoiceId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => DemandLetter.fromMap(maps[i]));
  }

  // Get demand letters by customer
  Future<List<DemandLetter>> getDemandLettersByCustomer(int customerId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => DemandLetter.fromMap(maps[i]));
  }

  // Get overdue demand letters
  Future<List<DemandLetter>> getOverdueDemandLetters() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dueDate < ? AND status != ?',
      whereArgs: [DateTime.now().toIso8601String(), 'paid'],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => DemandLetter.fromMap(maps[i]));
  }

  // Generate demand letter number
  Future<String> generateDemandLetterNumber() async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    final count = result.first['count'] as int;
    final year = DateTime.now().year;
    return 'DL-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  // Generate demand letter content
  Future<String> generateDemandLetterContent({
    required Invoice invoice,
    required Customer customer,
    required DemandLetterTemplate template,
    required double interestRate,
    required int daysOverdue,
    String? customContent,
  }) async {
    if (customContent != null && customContent.isNotEmpty) {
      return customContent;
    }

    final amount = invoice.balanceAmount;
    final interestAmount = amount * interestRate / 100;
    final totalAmount = amount + interestAmount;

    switch (template) {
      case DemandLetterTemplate.firstNotice:
        return '''
Dear ${customer.name},

This is a friendly reminder that your invoice #${invoice.invoiceNumber} for \$${amount.toStringAsFixed(2)} is now $daysOverdue days overdue.

We understand that sometimes payments can be delayed, and we're here to help if you need to discuss payment arrangements.

Please make payment at your earliest convenience.

Thank you for your business.

Best regards,
Your Sales Team
        ''';
      case DemandLetterTemplate.secondNotice:
        return '''
Dear ${customer.name},

We are writing to inform you that your invoice #${invoice.invoiceNumber} for \$${amount.toStringAsFixed(2)} is now $daysOverdue days overdue.

Please remit payment immediately to avoid any further action.

Thank you for your attention to this matter.

Sincerely,
Your Sales Team
        ''';
      case DemandLetterTemplate.finalNotice:
        return '''
Dear ${customer.name},

FINAL NOTICE: Your invoice #${invoice.invoiceNumber} for \$${amount.toStringAsFixed(2)} is now $daysOverdue days overdue.

This is your final notice before we proceed with legal action. Please remit payment immediately.

If payment is not received within 7 days, this matter will be referred to our legal department.

Sincerely,
Your Sales Team
        ''';
      case DemandLetterTemplate.legalNotice:
        return '''
Dear ${customer.name},

LEGAL NOTICE: Your invoice #${invoice.invoiceNumber} for \$${amount.toStringAsFixed(2)} is now $daysOverdue days overdue.

This matter has been referred to our legal department. Please contact our legal team immediately to discuss payment arrangements.

Legal action may be initiated if payment is not received within 3 days.

Sincerely,
Legal Department
        ''';
    }
  }

  // Generate demand letter subject
  String generateDemandLetterSubject({
    required Invoice invoice,
    required DemandLetterTemplate template,
    required int daysOverdue,
  }) {
    switch (template) {
      case DemandLetterTemplate.firstNotice:
        return 'Friendly Reminder - Invoice #${invoice.invoiceNumber}';
      case DemandLetterTemplate.secondNotice:
        return 'Payment Reminder - Invoice #${invoice.invoiceNumber}';
      case DemandLetterTemplate.finalNotice:
        return 'FINAL NOTICE: Overdue Invoice #${invoice.invoiceNumber} - $daysOverdue Days Overdue';
      case DemandLetterTemplate.legalNotice:
        return 'LEGAL NOTICE: Overdue Invoice #${invoice.invoiceNumber} - $daysOverdue Days Overdue';
    }
  }

  // Get demand letter statistics
  Future<Map<String, dynamic>> getDemandLetterStats() async {
    final db = await DatabaseHelper().database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    final overdueResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM $_tableName 
      WHERE dueDate < ? AND status != 'paid'
    ''', [DateTime.now().toIso8601String()]);
    final paidResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM $_tableName 
      WHERE status = 'paid'
    ''');
    final outstandingResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM $_tableName 
      WHERE status != 'paid' AND status != 'cancelled'
    ''');
    final interestResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount * interestRate / 100), 0) as total FROM $_tableName 
      WHERE status != 'paid' AND status != 'cancelled'
    ''');
    
    final total = totalResult.first['count'] as int;
    final overdue = overdueResult.first['count'] as int;
    final paid = paidResult.first['count'] as int;
    final outstanding = outstandingResult.first['total'] as double;
    final interest = interestResult.first['total'] as double;
    final collectionRate = total > 0 ? (paid / total) * 100 : 0.0;
    
    return {
      'totalDemandLetters': total,
      'overdueDemandLetters': overdue,
      'paidDemandLetters': paid,
      'totalOutstanding': outstanding,
      'totalInterest': interest,
      'collectionRate': collectionRate,
    };
  }
}