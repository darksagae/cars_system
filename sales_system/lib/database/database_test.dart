import 'package:flutter/material.dart';
import 'database_helper.dart';

class DatabaseTest {
  static Future<Map<String, dynamic>> testDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      // Test basic database operations
      final info = await dbHelper.getDatabaseInfo();
      
      // Test inserting a sample customer
      final customerId = await db.insert('customers', {
        'name': 'Test Customer',
        'email': 'test@example.com',
        'phone': '1234567890',
        'address': 'Test Address',
        'city': 'Test City',
        'state': 'Test State',
        'zipCode': '12345',
        'country': 'Test Country',
        'company': 'Test Company',
        'notes': 'Test customer for database verification',
        'totalSpent': 0.0,
        'totalInvoices': 0,
        'balance': 0.0,
        'isActive': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Test inserting a sample product
      final productId = await db.insert('products', {
        'name': 'Test Product',
        'description': 'Test product for database verification',
        'price': 10.0,
        'sku': 'TEST-001',
        'category': 'Test Category',
        'stock': 100,
        'minStock': 10,
        'lowStockThreshold': 5,
        'unit': 'pcs',
        'taxRate': 0.0,
        'isActive': 1,
        'status': 'active',
        'barcode': '123456789',
        'barcodeType': 'CODE128',
        'images': '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Test reading data
      final customers = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
      final products = await db.query('products', where: 'id = ?', whereArgs: [productId]);
      
      // Clean up test data
      await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);
      await db.delete('products', where: 'id = ?', whereArgs: [productId]);
      
      return {
        'status': 'success',
        'message': 'Database is working correctly',
        'databaseInfo': info,
        'testInsert': {
          'customerId': customerId,
          'productId': productId,
        },
        'testRead': {
          'customerFound': customers.isNotEmpty,
          'productFound': products.isNotEmpty,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Database test failed: ${e.toString()}',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  static Future<void> showDatabaseStatus(BuildContext context) async {
    final result = await testDatabase();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Database Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${result['status']}'),
            SizedBox(height: 8),
            Text('Message: ${result['message']}'),
            if (result['status'] == 'success') ...[
              SizedBox(height: 8),
              Text('Database Info:'),
              Text('  - Customers: ${result['databaseInfo']['customerCount']}'),
              Text('  - Products: ${result['databaseInfo']['productCount']}'),
              Text('  - Invoices: ${result['databaseInfo']['invoiceCount']}'),
              Text('  - Payments: ${result['databaseInfo']['paymentCount']}'),
            ],
            SizedBox(height: 8),
            Text('Test completed at: ${result['timestamp']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
