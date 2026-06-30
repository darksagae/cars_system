import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import 'client_activity_service.dart';
import 'cloud_api_service.dart';
import 'machine_relay_service.dart';
import 'pdf/pdf_service.dart';
import 'package:intl/intl.dart';

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
      
      await _dbHelper.repairInvoicesIsFinalizedIfNeeded();
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
      
      // Sync invoice data to cloud (PDF uploads separately when user generates/sends)
      try {
        final invoiceWithId = invoice.copyWith(id: invoiceId);
        MachineRelayService().syncInvoice(invoiceWithId, operation: 'upsert');
        await CloudApiService().syncInvoiceToCloud(invoiceWithId);
      } catch (e) {
        print('⚠️ Failed to sync invoice to cloud: $e');
      }

      // Log activity to relay portal
      try {
        MachineRelayService().reportActivity('create_invoice', details: {
          'invoice_number': invoice.invoiceNumber,
          'customer_name': invoice.customer?.name ?? '',
          'amount': invoice.totalAmount,
        });
      } catch (e) {
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
        
        invoices.add(invoice.copyWith(items: items, customer: customer).calculateTotals());
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
      
      return invoice.copyWith(items: items, customer: customer).calculateTotals();
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
        return invoice.copyWith(items: items, customer: customer).calculateTotals();
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
        invoices.add(invoice.copyWith(items: items).calculateTotals());
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
        invoices.add(invoice.copyWith(items: items).calculateTotals());
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
      invoices.add(invoice.copyWith(items: items).calculateTotals());
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
    await _dbHelper.repairInvoicesIsFinalizedIfNeeded();
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
    
    // Sync updated invoice data to cloud (PDF uploads when user generates/sends)
    try {
      MachineRelayService().syncInvoice(invoice, operation: 'upsert');
      await CloudApiService().syncInvoiceToCloud(invoice);
    } catch (e) {
      print('⚠️ Failed to sync invoice update to cloud: $e');
    }

    try {
      MachineRelayService().reportActivity('update_invoice', details: {
        'invoice_number': invoice.invoiceNumber,
      });
    } catch (e) {
      print('⚠️ Failed to log invoice update activity: $e');
    }

    return invoice.id ?? 0;
  }

  /// Marks invoice as finalized (no further edit/delete from UI after PDF/email/WhatsApp/print).
  /// Also moves status out of [draft] so the record reflects an issued document.
  Future<void> setInvoiceFinalized(int invoiceId) async {
    await _dbHelper.repairInvoicesIsFinalizedIfNeeded();
    final db = await _dbHelper.database;
    await db.update(
      'invoices',
      {
        'isFinalized': 1,
        'status': InvoiceStatus.sent.index,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
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

  Future<String?> getLocalPdfPath(int invoiceId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'invoices',
      columns: ['localPdfPath'],
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['localPdfPath'] as String?;
  }

  Future<void> setLocalPdfPath(int invoiceId, String path) async {
    final db = await _dbHelper.database;
    await db.update(
      'invoices',
      {
        'localPdfPath': path,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // Delete invoice
  Future<int> deleteInvoice(int id) async {
    final db = await _dbHelper.database;
    
    // Get invoice number before deletion for logging; block delete if finalized
    String? invoiceNumber;
    try {
      final invoice = await getInvoiceById(id);
      invoiceNumber = invoice?.invoiceNumber;
      if (invoice?.isFinalized == true) {
        return 0;
      }
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
    
    // Sync deletion to portal relay
    if (invoiceNumber != null) {
      try {
        MachineRelayService().deleteInvoiceSync(invoiceNumber);
        await CloudApiService().deleteInvoiceFromCloud(invoiceNumber);
      } catch (e) {
        print('⚠️ Failed to sync invoice deletion to cloud: $e');
      }
      try {
        MachineRelayService().reportActivity('delete_invoice', details: {
          'invoice_number': invoiceNumber,
        });
      } catch (e) {
        print('⚠️ Failed to log invoice deletion activity: $e');
      }
    }

    return id;
  }

  // Generate next invoice number
  Future<String> generateInvoiceNumber() async {
    final db = await _dbHelper.database;

    // New format: INV-DDMM-FFFFF (example: INV-1002-00001)
    final todaySegment = DateFormat('ddMM').format(DateTime.now());

    // Find highest sequence in invoices already using this format.
    final rows = await db.rawQuery('''
      SELECT invoiceNumber
      FROM invoices
      WHERE invoiceNumber LIKE 'INV-%'
    ''');

    final sequencePattern = RegExp(r'^INV-\d{4}-(\d{5})$');
    int maxSequence = 0;

    for (final row in rows) {
      final invoiceNumber = row['invoiceNumber']?.toString() ?? '';
      final match = sequencePattern.firstMatch(invoiceNumber);
      if (match != null) {
        final sequence = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (sequence > maxSequence) {
          maxSequence = sequence;
        }
      }
    }

    final nextSequence = (maxSequence + 1).toString().padLeft(5, '0');
    return 'INV-$todaySegment-$nextSequence';
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
      invoices.add(invoice.copyWith(items: items).calculateTotals());
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