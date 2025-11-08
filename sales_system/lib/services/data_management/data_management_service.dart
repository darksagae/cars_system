import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';

class DataManagementService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Backup all data to JSON file
  Future<String> backupAllData() async {
    try {
      final db = await _dbHelper.database;
      
      // Get all data from database
      final customers = await _getAllCustomers(db);
      final vehicles = await _getAllVehicles(db);
      final invoices = await _getAllInvoices(db);
      final payments = await _getAllPayments(db);
      final reminders = await _getAllReminders(db);
      final demandLetters = await _getAllDemandLetters(db);
      
      // Create backup data structure
      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'customers': customers,
          'vehicles': vehicles,
          'invoices': invoices,
          'payments': payments,
          'reminders': reminders,
          'demandLetters': demandLetters,
        },
        'metadata': {
          'totalCustomers': customers.length,
          'totalVehicles': vehicles.length,
          'totalInvoices': invoices.length,
          'totalPayments': payments.length,
          'totalReminders': reminders.length,
          'totalDemandLetters': demandLetters.length,
        }
      };
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'sales_system_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonEncode(backupData));
      return file.path;
    } catch (e) {
      throw Exception('Failed to backup data: $e');
    }
  }

  // Restore data from JSON file
  Future<bool> restoreData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }
      
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString);
      
      if (backupData['version'] != '1.0') {
        throw Exception('Unsupported backup version');
      }
      
      final db = await _dbHelper.database;
      
      // Start transaction
      await db.transaction((txn) async {
        // Clear existing data
        await txn.delete('demand_letters');
        await txn.delete('payment_reminders');
        await txn.delete('payments');
        await txn.delete('invoice_items');
        await txn.delete('invoices');
        await txn.delete('vehicles');
        await txn.delete('customers');
        
        // Restore data
        final data = backupData['data'];
        
        // Restore customers
        for (final customerData in data['customers']) {
          await txn.insert('customers', customerData);
        }
        
        // Restore vehicles
        for (final vehicleData in data['vehicles']) {
          await txn.insert('vehicles', vehicleData);
        }
        
        // Restore invoices
        for (final invoiceData in data['invoices']) {
          await txn.insert('invoices', invoiceData);
        }
        
        // Restore invoice items
        for (final invoice in data['invoices']) {
          if (invoice['items'] != null) {
            for (final item in invoice['items']) {
              item['invoiceId'] = invoice['id'];
              await txn.insert('invoice_items', item);
            }
          }
        }
        
        // Restore payments
        for (final paymentData in data['payments']) {
          await txn.insert('payments', paymentData);
        }
        
        // Restore reminders
        for (final reminderData in data['reminders']) {
          await txn.insert('payment_reminders', reminderData);
        }
        
        // Restore demand letters
        for (final letterData in data['demandLetters']) {
          await txn.insert('demand_letters', letterData);
        }
      });
      
      return true;
    } catch (e) {
      throw Exception('Failed to restore data: $e');
    }
  }

  // Export data to CSV
  Future<String> exportToCSV(String dataType) async {
    try {
      final db = await _dbHelper.database;
      String csvContent = '';
      
      switch (dataType.toLowerCase()) {
        case 'customers':
          csvContent = await _exportCustomersToCSV(db);
          break;
        case 'vehicles':
          csvContent = await _exportVehiclesToCSV(db);
          break;
        case 'invoices':
          csvContent = await _exportInvoicesToCSV(db);
          break;
        case 'payments':
          csvContent = await _exportPaymentsToCSV(db);
          break;
        default:
          throw Exception('Unsupported data type: $dataType');
      }
      
      // Save CSV file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${dataType}_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvContent);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export $dataType: $e');
    }
  }

  // Import data from CSV
  Future<bool> importFromCSV(String filePath, String dataType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('CSV file not found');
      }
      
      final csvContent = await file.readAsString();
      final lines = csvContent.split('\n');
      
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }
      
      final headers = lines[0].split(',');
      final db = await _dbHelper.database;
      
      await db.transaction((txn) async {
        for (int i = 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;
          
          final values = lines[i].split(',');
          if (values.length != headers.length) continue;
          
          final rowData = <String, dynamic>{};
          for (int j = 0; j < headers.length; j++) {
            rowData[headers[j].trim()] = values[j].trim();
          }
          
          switch (dataType.toLowerCase()) {
            case 'customers':
              await txn.insert('customers', rowData);
              break;
            case 'vehicles':
              await txn.insert('vehicles', rowData);
              break;
            case 'invoices':
              await txn.insert('invoices', rowData);
              break;
            case 'payments':
              await txn.insert('payments', rowData);
              break;
          }
        }
      });
      
      return true;
    } catch (e) {
      throw Exception('Failed to import $dataType: $e');
    }
  }

  // Validate data integrity
  Future<Map<String, dynamic>> validateDataIntegrity() async {
    try {
      final db = await _dbHelper.database;
      final issues = <String>[];
      
      // Check for orphaned records
      final orphanedInvoices = await db.rawQuery('''
        SELECT i.id FROM invoices i 
        LEFT JOIN customers c ON i.customerId = c.id 
        WHERE c.id IS NULL
      ''');
      
      if (orphanedInvoices.isNotEmpty) {
        issues.add('Found ${orphanedInvoices.length} invoices with invalid customer references');
      }
      
      // Check for orphaned invoice items
      final orphanedItems = await db.rawQuery('''
        SELECT ii.id FROM invoice_items ii 
        LEFT JOIN invoices i ON ii.invoiceId = i.id 
        WHERE i.id IS NULL
      ''');
      
      if (orphanedItems.isNotEmpty) {
        issues.add('Found ${orphanedItems.length} invoice items with invalid invoice references');
      }
      
      // Check for orphaned payments
      final orphanedPayments = await db.rawQuery('''
        SELECT p.id FROM payments p 
        LEFT JOIN invoices i ON p.invoiceId = i.id 
        WHERE i.id IS NULL
      ''');
      
      if (orphanedPayments.isNotEmpty) {
        issues.add('Found ${orphanedPayments.length} payments with invalid invoice references');
      }
      
      // Check for data consistency
      final inconsistentInvoices = await db.rawQuery('''
        SELECT i.id, i.totalAmount, 
               COALESCE(SUM(ii.quantity * ii.price), 0) as calculatedTotal
        FROM invoices i 
        LEFT JOIN invoice_items ii ON i.id = ii.invoiceId 
        GROUP BY i.id, i.totalAmount 
        HAVING i.totalAmount != calculatedTotal
      ''');
      
      if (inconsistentInvoices.isNotEmpty) {
        issues.add('Found ${inconsistentInvoices.length} invoices with inconsistent totals');
      }
      
      return {
        'isValid': issues.isEmpty,
        'issues': issues,
        'issueCount': issues.length,
      };
    } catch (e) {
      throw Exception('Failed to validate data: $e');
    }
  }

  // Clean up data
  Future<bool> cleanupData() async {
    try {
      final db = await _dbHelper.database;
      
      await db.transaction((txn) async {
        // Remove orphaned records
        await txn.rawDelete('''
          DELETE FROM invoice_items 
          WHERE invoiceId NOT IN (SELECT id FROM invoices)
        ''');
        
        await txn.rawDelete('''
          DELETE FROM payments 
          WHERE invoiceId NOT IN (SELECT id FROM invoices)
        ''');
        
        await txn.rawDelete('''
          DELETE FROM payment_reminders 
          WHERE invoiceId NOT IN (SELECT id FROM invoices)
        ''');
        
        // Update customer statistics
        await txn.rawUpdate('''
          UPDATE customers SET 
            totalSpent = (
              SELECT COALESCE(SUM(totalAmount), 0) 
              FROM invoices 
              WHERE customerId = customers.id
            ),
            totalInvoices = (
              SELECT COUNT(*) 
              FROM invoices 
              WHERE customerId = customers.id
            ),
            balance = (
              SELECT COALESCE(SUM(totalAmount), 0) - COALESCE(SUM(paidAmount), 0)
              FROM invoices 
              WHERE customerId = customers.id
            )
        ''');
      });
      
      return true;
    } catch (e) {
      throw Exception('Failed to cleanup data: $e');
    }
  }

  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    try {
      final db = await _dbHelper.database;
      
      final customerCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM customers')) ?? 0;
      final vehicleCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM vehicles')) ?? 0;
      final invoiceCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM invoices')) ?? 0;
      final paymentCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM payments')) ?? 0;
      final reminderCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM payment_reminders')) ?? 0;
      final letterCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM demand_letters')) ?? 0;
      
      final totalRevenueResult = await db.rawQuery('SELECT SUM(totalAmount) as total FROM invoices');
      final totalRevenue = (totalRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final totalPaidResult = await db.rawQuery('SELECT SUM(amount) as total FROM payments');
      final totalPaid = (totalPaidResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'customerCount': customerCount,
        'vehicleCount': vehicleCount,
        'invoiceCount': invoiceCount,
        'paymentCount': paymentCount,
        'reminderCount': reminderCount,
        'letterCount': letterCount,
        'totalRevenue': totalRevenue,
        'totalPaid': totalPaid,
        'outstanding': totalRevenue - totalPaid,
        'databaseSize': await _getDatabaseSize(),
      };
    } catch (e) {
      throw Exception('Failed to get database statistics: $e');
    }
  }

  // Helper methods
  Future<List<Map<String, dynamic>>> _getAllCustomers(Database db) async {
    return await db.query('customers');
  }

  Future<List<Map<String, dynamic>>> _getAllVehicles(Database db) async {
    return await db.query('vehicles');
  }

  Future<List<Map<String, dynamic>>> _getAllInvoices(Database db) async {
    return await db.query('invoices');
  }

  Future<List<Map<String, dynamic>>> _getAllPayments(Database db) async {
    return await db.query('payments');
  }

  Future<List<Map<String, dynamic>>> _getAllReminders(Database db) async {
    return await db.query('payment_reminders');
  }

  Future<List<Map<String, dynamic>>> _getAllDemandLetters(Database db) async {
    return await db.query('demand_letters');
  }

  Future<String> _exportCustomersToCSV(Database db) async {
    final customers = await db.query('customers');
    if (customers.isEmpty) return 'No customers found';
    
    final headers = customers.first.keys.toList();
    final csvLines = <String>[headers.join(',')];
    
    for (final customer in customers) {
      final values = headers.map((header) => customer[header]?.toString() ?? '').toList();
      csvLines.add(values.join(','));
    }
    
    return csvLines.join('\n');
  }

  Future<String> _exportVehiclesToCSV(Database db) async {
    final vehicles = await db.query('vehicles');
    if (vehicles.isEmpty) return 'No vehicles found';
    
    final headers = vehicles.first.keys.toList();
    final csvLines = <String>[headers.join(',')];
    
    for (final vehicle in vehicles) {
      final values = headers.map((header) => vehicle[header]?.toString() ?? '').toList();
      csvLines.add(values.join(','));
    }
    
    return csvLines.join('\n');
  }

  Future<String> _exportInvoicesToCSV(Database db) async {
    final invoices = await db.query('invoices');
    if (invoices.isEmpty) return 'No invoices found';
    
    final headers = invoices.first.keys.toList();
    final csvLines = <String>[headers.join(',')];
    
    for (final invoice in invoices) {
      final values = headers.map((header) => invoice[header]?.toString() ?? '').toList();
      csvLines.add(values.join(','));
    }
    
    return csvLines.join('\n');
  }

  Future<String> _exportPaymentsToCSV(Database db) async {
    final payments = await db.query('payments');
    if (payments.isEmpty) return 'No payments found';
    
    final headers = payments.first.keys.toList();
    final csvLines = <String>[headers.join(',')];
    
    for (final payment in payments) {
      final values = headers.map((header) => payment[header]?.toString() ?? '').toList();
      csvLines.add(values.join(','));
    }
    
    return csvLines.join('\n');
  }

  Future<int> _getDatabaseSize() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('PRAGMA page_count');
      final pageCount = result.first['page_count'] as int;
      final result2 = await db.rawQuery('PRAGMA page_size');
      final pageSize = result2.first['page_size'] as int;
      return pageCount * pageSize;
    } catch (e) {
      return 0;
    }
  }
}



