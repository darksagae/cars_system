import '../database/database_helper.dart';
import '../models/payment.dart';
import '../models/invoice.dart';
import 'package:sqflite/sqflite.dart';
import 'client_activity_service.dart';
import 'invoice_service.dart';

class PaymentService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Create a new payment
  Future<int> createPayment(Payment payment) async {
    try {
      // Validate required fields
      if (payment.invoiceId == null) {
        throw Exception('Invoice ID is required');
      }
      if (payment.amount <= 0) {
        throw Exception('Payment amount must be greater than 0');
      }
      
      final db = await _dbHelper.database;
      int paymentId = 0;
      
      // Prepare payment map for insertion (excludes id for AUTOINCREMENT)
      final paymentMap = payment.toMap();
      
      // Start transaction
      await db.transaction((txn) async {
        // Insert payment
        paymentId = await txn.insert('payments', paymentMap);
        
        if (paymentId <= 0) {
          throw Exception('Failed to insert payment - database returned invalid ID: $paymentId');
        }
        
        // Update invoice paid amount and balance using transaction
        if (payment.invoiceId != null) {
          await _updateInvoicePayment(payment.invoiceId!, payment.amount, txn: txn);
        }
      });
      
      // Log activity to Supabase (for mobile app visibility)
      try {
        // Get invoice number for logging
        String? invoiceNumber;
        if (payment.invoiceId != null) {
          final invoiceService = InvoiceService();
          final invoice = await invoiceService.getInvoiceById(payment.invoiceId!);
          invoiceNumber = invoice?.invoiceNumber;
        }
        
        if (invoiceNumber != null) {
          await ClientActivityService().logPaymentReceived(
            invoiceNumber,
            payment.amount,
          );
        }
      } catch (e) {
        // Don't fail payment creation if activity logging fails
        print('⚠️ Failed to log payment activity: $e');
      }
      
      return paymentId;
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  // Get all payments
  Future<List<Payment>> getAllPayments() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      orderBy: 'paymentDate DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  // Get payment by ID
  Future<Payment?> getPaymentById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }

  // Get payments by invoice ID
  Future<List<Payment>> getPaymentsByInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'paymentDate DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  // Get payments by status
  Future<List<Payment>> getPaymentsByStatus(PaymentStatus status) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'paymentDate DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  // Get payments by method
  Future<List<Payment>> getPaymentsByMethod(PaymentMethod method) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'method = ?',
      whereArgs: [method.index],
      orderBy: 'paymentDate DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  // Update payment
  Future<int> updatePayment(Payment payment) async {
    final db = await _dbHelper.database;
    return await db.update(
      'payments',
      payment.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  // Update payment status
  Future<int> updatePaymentStatus(int paymentId, PaymentStatus status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'payments',
      {
        'status': status.index,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  // Delete payment
  Future<int> deletePayment(int id) async {
    final db = await _dbHelper.database;
    
    // Get payment details first (before transaction to avoid lock)
    final payment = await getPaymentById(id);
    if (payment == null) return 0;
    
    // Start transaction
    await db.transaction((txn) async {
      // Delete payment
      await txn.delete(
        'payments',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Update invoice paid amount and balance using transaction
      // Only update if invoice exists and invoiceId is valid
      if (payment.invoiceId != null && payment.invoiceId! > 0) {
        try {
          await _updateInvoicePayment(payment.invoiceId!, -payment.amount, txn: txn);
        } catch (e) {
          // If invoice doesn't exist or update fails, continue with deletion
          // This handles orphaned payments gracefully
          print('Warning: Could not update invoice for deleted payment: $e');
        }
      }
    });
    
    return id;
  }

  // Update invoice payment amounts
  Future<void> _updateInvoicePayment(int invoiceId, double amount, {DatabaseExecutor? txn}) async {
    // Use transaction if provided, otherwise get new database connection
    final db = txn ?? await _dbHelper.database;
    
    // Get current invoice using the same database connection/transaction
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    
    // If invoice doesn't exist, silently return (handles orphaned payments)
    if (maps.isEmpty) {
      print('Warning: Invoice with ID $invoiceId not found when updating payment');
      return;
    }
    
    final invoiceMap = maps.first;
    final currentPaidAmount = (invoiceMap['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (invoiceMap['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final currentStatus = invoiceMap['status'] as int? ?? InvoiceStatus.draft.index;
    
    // Calculate new paid amount
    final newPaidAmount = (currentPaidAmount + amount).clamp(0.0, double.infinity);
    final newBalance = totalAmount - newPaidAmount;
    
    // Determine new status
    final newStatus = newBalance <= 0 ? InvoiceStatus.paid.index : currentStatus;
    
    // Update invoice using the same database connection/transaction
    await db.update(
      'invoices',
      {
        'paidAmount': newPaidAmount,
        'balanceAmount': newBalance,
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats() async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalPayments,
        COALESCE(SUM(amount), 0) as totalAmount
      FROM payments 
      WHERE status = 1
    ''');
    
    final methodResult = await db.rawQuery('''
      SELECT 
        method,
        COUNT(*) as count,
        COALESCE(SUM(amount), 0) as amount
      FROM payments 
      WHERE status = 1
      GROUP BY method
    ''');
    
    final statusResult = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count,
        COALESCE(SUM(amount), 0) as amount
      FROM payments 
      GROUP BY status
    ''');
    
    return {
      'totalPayments': totalResult.first['totalPayments'],
      'totalAmount': totalResult.first['totalAmount'],
      'methodBreakdown': methodResult,
      'statusBreakdown': statusResult,
    };
  }

  // Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'paymentDate BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'paymentDate DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  // Get payment count
  Future<int> getPaymentCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM payments');
    return result.first['count'] as int;
  }

  // Get total paid amount for invoice
  Future<double> getTotalPaidForInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as totalPaid
      FROM payments 
      WHERE invoiceId = ? AND status = 1
    ''', [invoiceId]);
    return result.first['totalPaid'] as double;
  }

  // Get recent payments
  Future<List<Payment>> getRecentPayments({int limit = 10}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      orderBy: 'paymentDate DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  // Get overdue payments
  Future<List<Payment>> getOverduePayments() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.* FROM payments p
      JOIN invoices i ON p.invoiceId = i.id
      WHERE i.dueDate < ? AND i.status != ?
    ''', [DateTime.now().toIso8601String(), InvoiceStatus.paid.index]);
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }
}