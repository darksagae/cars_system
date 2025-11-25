import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import 'client_activity_service.dart';
import 'pdf/pdf_service.dart';

class InvoiceService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Create a new invoice
  Future<int> createInvoice(Invoice invoice) async {
    try {
      print('=== Starting invoice creation ===');
      print('Invoice details:');
      print('- Invoice Number: ${invoice.invoiceNumber}');
      print('- Customer ID: ${invoice.customerId}');
      print('- Customer Name: ${invoice.customer?.name}');
      print('- Items count: ${invoice.items.length}');
      print('- Total Amount: ${invoice.totalAmount}');
      
      final db = await _dbHelper.database;
      print('Database connection established');
      
      int invoiceId = 0;
      
      // Start transaction
      await db.transaction((txn) async {
        print('Transaction started');
        
        // Insert invoice
        final invoiceMap = invoice.toMap();
        print('Invoice map: $invoiceMap');
        
        // Check if all required fields are present
        if (invoiceMap['customerId'] == null) {
          throw Exception('Customer ID is null');
        }
        if (invoiceMap['invoiceNumber'] == null || invoiceMap['invoiceNumber'].isEmpty) {
          throw Exception('Invoice number is null or empty');
        }
        
        print('Final invoice map for insertion: $invoiceMap');
        
        invoiceId = await txn.insert('invoices', invoiceMap);
        print('Invoice inserted with ID: $invoiceId');
        
        if (invoiceId <= 0) {
          throw Exception('Failed to insert invoice - invalid ID returned');
        }
        
        // Insert invoice items
        for (int i = 0; i < invoice.items.length; i++) {
          final item = invoice.items[i];
          final itemMap = item.toMap();
          itemMap['invoiceId'] = invoiceId;
          print('Inserting item $i: $itemMap');
          
          final itemId = await txn.insert('invoice_items', itemMap);
          print('Item $i inserted with ID: $itemId');
        }
      });
      
      print('Invoice creation completed successfully with ID: $invoiceId');
      
      // Generate and save PDF for mobile app access
      String? localPdfPath;
      try {
        final pdfService = PDFService();
        localPdfPath = await pdfService.savePDFToFile(invoice);
        print('✅ PDF saved to: $localPdfPath');
      } catch (e) {
        print('⚠️ Failed to generate/save PDF: $e');
        // Don't fail invoice creation if PDF generation fails
      }
      
      // Log activity to Supabase (for mobile app visibility) with PDF path
      try {
        await ClientActivityService().logInvoiceCreated(
          invoice.invoiceNumber,
          customerName: invoice.customer?.name,
          amount: invoice.totalAmount,
          localPdfPath: localPdfPath,
        );
      } catch (e) {
        // Don't fail invoice creation if activity logging fails
        print('⚠️ Failed to log invoice creation activity: $e');
      }
      
      return invoiceId;
    } catch (e) {
      print('=== ERROR in invoice creation ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get all invoices
  Future<List<Invoice>> getAllInvoices() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      orderBy: 'createdAt DESC',
    );
    
    List<Invoice> invoices = [];
    for (var map in maps) {
      final invoice = Invoice.fromMap(map);
      if (invoice.id != null) {
        final items = await getInvoiceItems(invoice.id!);
        
        // Load customer data
        Customer? customer;
        if (invoice.customerId > 0) {
          final customerMaps = await db.query(
            'customers',
            where: 'id = ?',
            whereArgs: [invoice.customerId],
          );
          if (customerMaps.isNotEmpty) {
            customer = Customer.fromMap(customerMaps.first);
          }
        }
        
        invoices.add(invoice.copyWith(items: items, customer: customer));
      }
    }
    
    return invoices;
  }

  // Get invoice by ID
  Future<Invoice?> getInvoiceById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      final invoice = Invoice.fromMap(maps.first);
      final items = await getInvoiceItems(id);
      
      // Load customer data
      Customer? customer;
      if (invoice.customerId > 0) {
        final customerMaps = await db.query(
          'customers',
          where: 'id = ?',
          whereArgs: [invoice.customerId],
        );
        if (customerMaps.isNotEmpty) {
          customer = Customer.fromMap(customerMaps.first);
        }
      }
      
      return invoice.copyWith(items: items, customer: customer);
    }
    return null;
  }

  // Get invoice by invoice number
  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'invoiceNumber = ?',
      whereArgs: [invoiceNumber],
    );
    
    if (maps.isNotEmpty) {
      final invoice = Invoice.fromMap(maps.first);
      if (invoice.id != null) {
        final items = await getInvoiceItems(invoice.id!);
        return invoice.copyWith(items: items);
      }
    }
    return null;
  }

  // Get invoices by customer ID
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    
    List<Invoice> invoices = [];
    for (var map in maps) {
      final invoice = Invoice.fromMap(map);
      if (invoice.id != null) {
        final items = await getInvoiceItems(invoice.id!);
        invoices.add(invoice.copyWith(items: items));
      }
    }
    
    return invoices;
  }

  // Get invoice items
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );
    return List.generate(maps.length, (i) => InvoiceItem.fromMap(maps[i]));
  }

  // Get invoices by status
  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'createdAt DESC',
    );
    
    List<Invoice> invoices = [];
    for (var map in maps) {
      final invoice = Invoice.fromMap(map);
      if (invoice.id != null) {
        final items = await getInvoiceItems(invoice.id!);
        invoices.add(invoice.copyWith(items: items));
      }
    }
    
    return invoices;
  }

  // Get overdue invoices
  Future<List<Invoice>> getOverdueInvoices() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'dueDate < ? AND status != ? AND status != ?',
      whereArgs: [now, InvoiceStatus.paid.index, InvoiceStatus.cancelled.index],
      orderBy: 'dueDate ASC',
    );
    
    List<Invoice> invoices = [];
    for (var map in maps) {
      final invoice = Invoice.fromMap(map);
      final items = await getInvoiceItems(invoice.id!);
      invoices.add(invoice.copyWith(items: items));
    }
    
    return invoices;
  }

  // Delete all invoices (and their items)
  Future<void> deleteAllInvoices() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('invoice_items');
      await txn.delete('invoices');
    });
  }

  // Update invoice
  Future<int> updateInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    
    // Start transaction
    await db.transaction((txn) async {
      // Update invoice
      await txn.update(
        'invoices',
        invoice.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );
      
      // Delete existing items
      await txn.delete(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [invoice.id],
      );
      
      // Insert new items
      for (var item in invoice.items) {
        await txn.insert('invoice_items', {
          ...item.toMap(),
          'invoiceId': invoice.id,
        });
      }
    });
    
    // Log activity to Supabase (for mobile app visibility)
    try {
      await ClientActivityService().logInvoiceUpdated(invoice.invoiceNumber);
    } catch (e) {
      // Don't fail invoice update if activity logging fails
      print('⚠️ Failed to log invoice update activity: $e');
    }
    
    return invoice.id ?? 0;
  }

  // Update invoice status
  Future<int> updateInvoiceStatus(int invoiceId, InvoiceStatus status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'invoices',
      {
        'status': status.index,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // Delete invoice
  Future<int> deleteInvoice(int id) async {
    final db = await _dbHelper.database;
    
    // Get invoice number before deletion for logging
    String? invoiceNumber;
    try {
      final invoice = await getInvoiceById(id);
      invoiceNumber = invoice?.invoiceNumber;
    } catch (e) {
      print('⚠️ Could not get invoice number for logging: $e');
    }
    
    // Start transaction
    await db.transaction((txn) async {
      // Delete invoice items first
      await txn.delete(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [id],
      );
      
      // Delete payments
      await txn.delete(
        'payments',
        where: 'invoiceId = ?',
        whereArgs: [id],
      );
      
      // Delete invoice
      await txn.delete(
        'invoices',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    
    // Log activity to Supabase (for mobile app visibility)
    if (invoiceNumber != null) {
      try {
        await ClientActivityService().logInvoiceDeleted(invoiceNumber);
      } catch (e) {
        // Don't fail invoice deletion if activity logging fails
        print('⚠️ Failed to log invoice deletion activity: $e');
      }
    }
    
    return id;
  }

  // Generate next invoice number
  Future<String> generateInvoiceNumber() async {
    final db = await _dbHelper.database;
    
    // Get the highest existing invoice number
    final result = await db.rawQuery('''
      SELECT invoiceNumber 
      FROM invoices 
      WHERE invoiceNumber LIKE 'INV-%'
      ORDER BY CAST(SUBSTR(invoiceNumber, 5) AS INTEGER) DESC
      LIMIT 1
    ''');
    
    int nextNumber = 1;
    if (result.isNotEmpty) {
      final lastInvoiceNumber = result.first['invoiceNumber'] as String;
      final numberPart = lastInvoiceNumber.substring(4); // Remove 'INV-' prefix
      nextNumber = int.tryParse(numberPart) ?? 0;
      nextNumber += 1;
    }
    
    return 'INV-${nextNumber.toString().padLeft(6, '0')}';
  }

  // Get invoice statistics
  Future<Map<String, dynamic>> getInvoiceStats() async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalInvoices,
        COALESCE(SUM(totalAmount), 0) as totalAmount,
        COALESCE(SUM(paidAmount), 0) as paidAmount,
        COALESCE(SUM(balanceAmount), 0) as balanceAmount
      FROM invoices 
      WHERE status != 4
    ''');
    
    final statusResult = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count,
        COALESCE(SUM(totalAmount), 0) as amount
      FROM invoices 
      WHERE status != 4
      GROUP BY status
    ''');
    
    return {
      'totalInvoices': totalResult.first['totalInvoices'],
      'totalAmount': totalResult.first['totalAmount'],
      'paidAmount': totalResult.first['paidAmount'],
      'balanceAmount': totalResult.first['balanceAmount'],
      'statusBreakdown': statusResult,
    };
  }

  // Get invoices by date range
  Future<List<Invoice>> getInvoicesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'invoiceDate BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'invoiceDate DESC',
    );
    
    List<Invoice> invoices = [];
    for (var map in maps) {
      final invoice = Invoice.fromMap(map);
      final items = await getInvoiceItems(invoice.id!);
      invoices.add(invoice.copyWith(items: items));
    }
    
    return invoices;
  }

  // Get invoice count
  Future<int> getInvoiceCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
    return result.first['count'] as int;
  }
}