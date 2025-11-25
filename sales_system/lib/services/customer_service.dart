import '../database/database_helper.dart';
import '../models/customer.dart';
import 'client_activity_service.dart';

class CustomerService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Create a new customer
  Future<int> createCustomer(Customer customer) async {
    try {
      print('Creating customer in database: ${customer.name}');
      final rawMap = customer.toMap();
      // Ensure auto-increment works: do not explicitly set id when null or 0
      if (rawMap['id'] == null || rawMap['id'] == 0) {
        rawMap.remove('id');
      }
      print('Customer data (sanitized for insert): $rawMap');
      final db = await _dbHelper.database;
      print('Database connection successful');
      
      final id = await db.insert('customers', rawMap);
      print('Customer created with ID: $id');
      
      // Verify the customer was actually inserted
      final insertedCustomer = await getCustomerById(id);
      if (insertedCustomer != null) {
        print('Customer verification successful: ${insertedCustomer.name}');
      } else {
        print('ERROR: Customer not found after insertion');
      }
      
      // Log activity to Supabase (for mobile app visibility)
      try {
        await ClientActivityService().logCustomerCreated(customer.name);
      } catch (e) {
        // Don't fail customer creation if activity logging fails
        print('⚠️ Failed to log customer creation activity: $e');
      }
      
      return id;
    } catch (e) {
      print('ERROR creating customer: $e');
      rethrow;
    }
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    try {
      print('Getting all customers from database...');
      final db = await _dbHelper.database;
      print('Database connection successful for getAllCustomers');
      
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        orderBy: 'name ASC',
      );
      print('Found ${maps.length} customers in database');
      
      if (maps.isNotEmpty) {
        print('First customer data: ${maps.first}');
      }
      
      return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
    } catch (e) {
      print('ERROR getting all customers: $e');
      rethrow;
    }
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // Get customer by email
  Future<Customer?> getCustomerByEmail(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // Search customers by name or email
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'name LIKE ? OR email LIKE ? OR company LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  // Update customer
  Future<int> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final result = await db.update(
      'customers',
      customer.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    
    // Log activity to Supabase (for mobile app visibility)
    try {
      await ClientActivityService().logCustomerUpdated(customer.name);
    } catch (e) {
      // Don't fail customer update if activity logging fails
      print('⚠️ Failed to log customer update activity: $e');
    }
    
    return result;
  }

  // Delete customer
  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    
    // Get customer name before deletion for logging
    String? customerName;
    try {
      final customer = await getCustomerById(id);
      customerName = customer?.name;
    } catch (e) {
      print('⚠️ Could not get customer name for logging: $e');
    }
    
    // Delete customer (cascade will handle related invoices, payments, etc.)
    final result = await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Log activity to Supabase (for mobile app visibility)
    if (customerName != null && result > 0) {
      try {
        await ClientActivityService().logCustomerDeleted(customerName);
      } catch (e) {
        // Don't fail customer deletion if activity logging fails
        print('⚠️ Failed to log customer deletion activity: $e');
      }
    }
    
    return result;
  }

  // Update customer statistics
  Future<void> updateCustomerStats(int customerId) async {
    final db = await _dbHelper.database;
    
    // Get total spent from invoices
    final totalSpentResult = await db.rawQuery('''
      SELECT COALESCE(SUM(totalAmount), 0) as totalSpent
      FROM invoices 
      WHERE customerId = ? AND status != 4
    ''', [customerId]);
    
    // Get total invoices count
    final invoiceCountResult = await db.rawQuery('''
      SELECT COUNT(*) as totalInvoices
      FROM invoices 
      WHERE customerId = ? AND status != 4
    ''', [customerId]);
    
    // Get total paid amount
    final paidAmountResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as paidAmount
      FROM payments p
      JOIN invoices i ON p.invoiceId = i.id
      WHERE i.customerId = ? AND p.status = 1
    ''', [customerId]);
    
    final totalSpent = (totalSpentResult.first['totalSpent'] as num).toDouble();
    final totalInvoices = invoiceCountResult.first['totalInvoices'] as int;
    final paidAmount = (paidAmountResult.first['paidAmount'] as num).toDouble();
    final balance = totalSpent - paidAmount;
    
    await db.update(
      'customers',
      {
        'totalSpent': totalSpent,
        'totalInvoices': totalInvoices,
        'balance': balance,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  // Get customers with outstanding balance
  Future<List<Customer>> getCustomersWithBalance() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'balance > 0',
      orderBy: 'balance DESC',
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  // Get top customers by total spent
  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'totalSpent DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  // Get customer count
  Future<int> getCustomerCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return result.first['count'] as int;
  }

  // Get customers created in date range
  Future<List<Customer>> getCustomersByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }
}