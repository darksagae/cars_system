import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../models/vehicle.dart';
import '../models/demand_letter.dart';
import '../models/payment_reminder.dart';
import '../database/database_helper.dart';

class ReportsService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get sales summary
  Future<Map<String, dynamic>> getSalesSummary() async {
    final db = await _dbHelper.database;
    
    // Get total sales
    final salesResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalInvoices,
        SUM(totalAmount) as totalSales,
        AVG(totalAmount) as averageSale
      FROM invoices
    ''');
    
    // Get customer count
    final customerResult = await db.rawQuery('SELECT COUNT(*) as totalCustomers FROM customers');
    
    // Get payment summary
    final paymentResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalPayments,
        SUM(amount) as totalPaid
      FROM payments
    ''');
    
    return {
      'totalInvoices': salesResult.first['totalInvoices'] ?? 0,
      'totalSales': salesResult.first['totalSales'] ?? 0.0,
      'averageSale': salesResult.first['averageSale'] ?? 0.0,
      'totalCustomers': customerResult.first['totalCustomers'] ?? 0,
      'totalPayments': paymentResult.first['totalPayments'] ?? 0,
      'totalPaid': paymentResult.first['totalPaid'] ?? 0.0,
    };
  }

  // Get customer statistics
  Future<List<Map<String, dynamic>>> getCustomerStats() async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        c.name,
        c.email,
        COUNT(i.id) as invoiceCount,
        COALESCE(SUM(i.totalAmount), 0) as totalSpent,
        COALESCE(SUM(p.amount), 0) as totalPaid
      FROM customers c
      LEFT JOIN invoices i ON c.id = i.customerId
      LEFT JOIN payments p ON i.id = p.invoiceId
      GROUP BY c.id, c.name, c.email
      ORDER BY totalSpent DESC
    ''');
    
    return result;
  }

  // Get monthly sales
  Future<List<Map<String, dynamic>>> getMonthlySales() async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', invoiceDate) as month,
        COUNT(*) as invoiceCount,
        SUM(totalAmount) as totalSales
      FROM invoices
      GROUP BY strftime('%Y-%m', invoiceDate)
      ORDER BY month DESC
      LIMIT 12
    ''');
    
    return result;
  }

  // Get payment status summary
  Future<Map<String, dynamic>> getPaymentStatusSummary() async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count,
        SUM(totalAmount) as totalAmount
      FROM invoices
      GROUP BY status
    ''');
    
    Map<String, dynamic> summary = {};
    for (var row in result) {
      summary[row['status'] as String] = {
        'count': row['count'],
        'totalAmount': row['totalAmount'],
      };
    }
    
    return summary;
  }

  // Get top customers
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        c.name,
        c.email,
        COUNT(i.id) as invoiceCount,
        SUM(i.totalAmount) as totalSpent
      FROM customers c
      JOIN invoices i ON c.id = i.customerId
      GROUP BY c.id, c.name, c.email
      ORDER BY totalSpent DESC
      LIMIT ?
    ''', [limit]);
    
    return result;
  }

  // Get overdue invoices
  Future<List<Map<String, dynamic>>> getOverdueInvoices() async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        i.*,
        c.name as customerName,
        c.email as customerEmail
      FROM invoices i
      JOIN customers c ON i.customerId = c.id
      WHERE i.dueDate < date('now') 
      AND i.status != 'paid'
      ORDER BY i.dueDate ASC
    ''');
    
    return result;
  }

  // Generate PDF reports (placeholder methods)
  Future<List<int>> generateSalesSummaryReport() async {
    // Placeholder - would generate PDF
    return [];
  }

  Future<List<int>> generateCustomerAnalyticsReport() async {
    // Placeholder - would generate PDF
    return [];
  }

  Future<List<int>> generateProductPerformanceReport() async {
    // Placeholder - would generate PDF
    return [];
  }

  Future<List<int>> generateFinancialOverviewReport() async {
    // Placeholder - would generate PDF
    return [];
  }

  Future<String> saveReportToFile(List<int> pdfBytes, String fileName) async {
    // Placeholder - would save to file
    return '/tmp/$fileName.pdf';
  }

  Future<void> printReport(List<int> pdfBytes) async {
    // Placeholder - would print PDF
  }

  // Vehicle Performance Report
  Future<List<int>> generateVehiclePerformanceReport() async {
    final db = await _dbHelper.database;
    
    // Get vehicle sales data
    final vehicleSales = await db.rawQuery('''
      SELECT 
        v.make,
        v.model,
        v.year,
        COUNT(i.id) as salesCount,
        SUM(i.totalAmount) as totalRevenue,
        AVG(i.totalAmount) as averageSale
      FROM vehicles v
      LEFT JOIN invoices i ON v.id = i.vehicleId
      WHERE i.status = 'paid'
      GROUP BY v.id, v.make, v.model, v.year
      ORDER BY totalRevenue DESC
    ''');
    
    // Get vehicle inventory status
    final inventoryStatus = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM vehicles
      GROUP BY status
    ''');
    
    // Generate PDF (placeholder)
    return [];
  }

  // Vehicle Inventory Report
  Future<List<int>> generateVehicleInventoryReport() async {
    final db = await _dbHelper.database;
    
    // Get all vehicles with their details
    final vehicles = await db.rawQuery('''
      SELECT 
        v.*,
        COUNT(i.id) as salesCount
      FROM vehicles v
      LEFT JOIN invoices i ON v.id = i.vehicleId
      GROUP BY v.id
      ORDER BY v.make, v.model
    ''');
    
    // Get inventory summary
    final inventorySummary = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count,
        SUM(price) as totalValue
      FROM vehicles
      GROUP BY status
    ''');
    
    // Generate PDF (placeholder)
    return [];
  }

  // Payment Collection Report
  Future<List<int>> generatePaymentCollectionReport() async {
    final db = await _dbHelper.database;
    
    // Get overdue invoices
    final overdueInvoices = await db.rawQuery('''
      SELECT 
        i.*,
        c.name as customerName,
        c.phone as customerPhone,
        c.email as customerEmail,
        (julianday('now') - julianday(i.dueDate)) as daysOverdue
      FROM invoices i
      JOIN customers c ON i.customerId = c.id
      WHERE i.status != 'paid' 
      AND julianday('now') > julianday(i.dueDate)
      ORDER BY daysOverdue DESC
    ''');
    
    // Get demand letters sent
    final demandLetters = await db.rawQuery('''
      SELECT 
        dl.*,
        c.name as customerName,
        i.invoiceNumber
      FROM demand_letters dl
      JOIN customers c ON dl.customerId = c.id
      JOIN invoices i ON dl.invoiceId = i.id
      ORDER BY dl.createdAt DESC
    ''');
    
    // Get payment reminders
    final reminders = await db.rawQuery('''
      SELECT 
        pr.*,
        c.name as customerName,
        i.invoiceNumber
      FROM payment_reminders pr
      JOIN customers c ON pr.customerId = c.id
      JOIN invoices i ON pr.invoiceId = i.id
      ORDER BY pr.createdAt DESC
    ''');
    
    // Get collection statistics
    final collectionStats = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT i.id) as totalOverdue,
        SUM(i.totalAmount) as totalOverdueAmount,
        COUNT(DISTINCT dl.id) as demandLettersSent,
        COUNT(DISTINCT pr.id) as remindersSent
      FROM invoices i
      LEFT JOIN demand_letters dl ON i.id = dl.invoiceId
      LEFT JOIN payment_reminders pr ON i.id = pr.invoiceId
      WHERE i.status != 'paid' 
      AND julianday('now') > julianday(i.dueDate)
    ''');
    
    // Generate PDF (placeholder)
    return [];
  }

  // Get vehicle sales summary
  Future<Map<String, dynamic>> getVehicleSalesSummary() async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT v.id) as totalVehicles,
        COUNT(i.id) as vehiclesSold,
        SUM(i.totalAmount) as totalVehicleSales,
        AVG(i.totalAmount) as averageVehicleSale
      FROM vehicles v
      LEFT JOIN invoices i ON v.id = i.vehicleId AND i.status = 'paid'
    ''');
    
    return result.first;
  }

  // Get collection statistics
  Future<Map<String, dynamic>> getCollectionStats() async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT i.id) as totalOverdue,
        SUM(i.totalAmount) as totalOverdueAmount,
        COUNT(DISTINCT dl.id) as demandLettersSent,
        COUNT(DISTINCT pr.id) as remindersSent,
        COUNT(DISTINCT p.id) as paymentsReceived
      FROM invoices i
      LEFT JOIN demand_letters dl ON i.id = dl.invoiceId
      LEFT JOIN payment_reminders pr ON i.id = pr.invoiceId
      LEFT JOIN payments p ON i.id = p.invoiceId
      WHERE i.status != 'paid' 
      AND julianday('now') > julianday(i.dueDate)
    ''');
    
    return result.first;
  }
}
