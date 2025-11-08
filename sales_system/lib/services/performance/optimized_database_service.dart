import 'package:sqflite/sqflite.dart';
import '../performance/performance_service.dart';
import '../performance/cache_service.dart';
import '../../database/database_helper.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/invoice.dart';

class OptimizedDatabaseService with PerformanceMixin, CacheMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CacheService _cacheService = CacheService();
  final PerformanceService _performanceService = PerformanceService();

  // Optimized customer operations
  Future<List<Customer>> getCustomersOptimized({int limit = 50, int offset = 0}) async {
    return trackAsyncOperation('getCustomersOptimized', () async {
      final cacheKey = 'customers_${limit}_$offset';
      
      // Check cache first
      final cachedData = getCachedData<List<Customer>>('customers', cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        limit: limit,
        offset: offset,
        orderBy: 'createdAt DESC',
      );

      final customers = maps.map((map) => Customer.fromMap(map)).toList();
      
      // Cache the result
      cacheData('customers', cacheKey, customers, ttl: Duration(minutes: 5));
      
      return customers;
    });
  }

  // Optimized product operations
  Future<List<Product>> getProductsOptimized({int limit = 50, int offset = 0}) async {
    return trackAsyncOperation('getProductsOptimized', () async {
      final cacheKey = 'products_${limit}_$offset';
      
      // Check cache first
      final cachedData = getCachedData<List<Product>>('products', cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        limit: limit,
        offset: offset,
        orderBy: 'createdAt DESC',
      );

      final products = maps.map((map) => Product.fromMap(map)).toList();
      
      // Cache the result
      cacheData('products', cacheKey, products, ttl: Duration(minutes: 5));
      
      return products;
    });
  }

  // Optimized invoice operations with pagination
  Future<List<Invoice>> getInvoicesOptimized({int limit = 20, int offset = 0}) async {
    return trackAsyncOperation('getInvoicesOptimized', () async {
      final cacheKey = 'invoices_${limit}_$offset';
      
      // Check cache first
      final cachedData = getCachedData<List<Invoice>>('invoices', cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'invoices',
        limit: limit,
        offset: offset,
        orderBy: 'createdAt DESC',
      );

      List<Invoice> invoices = [];
      for (var map in maps) {
        final invoice = Invoice.fromMap(map);
        if (invoice.id != null) {
          // Load customer data efficiently
          final customerMaps = await db.query(
            'customers',
            where: 'id = ?',
            whereArgs: [invoice.customerId],
            limit: 1,
          );
          
          Customer? customer;
          if (customerMaps.isNotEmpty) {
            customer = Customer.fromMap(customerMaps.first);
          }

          // Load invoice items efficiently
          final itemMaps = await db.query(
            'invoice_items',
            where: 'invoiceId = ?',
            whereArgs: [invoice.id],
          );
          
          final items = itemMaps.map((itemMap) => InvoiceItem.fromMap(itemMap)).toList();
          
          invoices.add(invoice.copyWith(items: items, customer: customer));
        }
      }
      
      // Cache the result
      cacheData('invoices', cacheKey, invoices, ttl: Duration(minutes: 3));
      
      return invoices;
    });
  }

  // Optimized search with indexing
  Future<List<Customer>> searchCustomersOptimized(String query) async {
    return trackAsyncOperation('searchCustomersOptimized', () async {
      final cacheKey = 'search_customers_$query';
      
      // Check cache first
      final cachedData = getCachedData<List<Customer>>('search', cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'name LIKE ? OR email LIKE ? OR phone LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        limit: 20,
        orderBy: 'name ASC',
      );

      final customers = maps.map((map) => Customer.fromMap(map)).toList();
      
      // Cache the result
      cacheData('search', cacheKey, customers, ttl: Duration(minutes: 2));
      
      return customers;
    });
  }

  // Optimized product search
  Future<List<Product>> searchProductsOptimized(String query) async {
    return trackAsyncOperation('searchProductsOptimized', () async {
      final cacheKey = 'search_products_$query';
      
      // Check cache first
      final cachedData = getCachedData<List<Product>>('search', cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 20,
        orderBy: 'name ASC',
      );

      final products = maps.map((map) => Product.fromMap(map)).toList();
      
      // Cache the result
      cacheData('search', cacheKey, products, ttl: Duration(minutes: 2));
      
      return products;
    });
  }

  // Batch operations for better performance
  Future<void> batchInsertCustomers(List<Customer> customers) async {
    return trackOperation('batchInsertCustomers', () async {
      final db = await _dbHelper.database;
      final batch = db.batch();
      
      for (final customer in customers) {
        batch.insert('customers', customer.toMap());
      }
      
      await batch.commit();
      
      // Clear related caches
      _clearCustomerCaches();
    });
  }

  Future<void> batchInsertProducts(List<Product> products) async {
    return trackOperation('batchInsertProducts', () async {
      final db = await _dbHelper.database;
      final batch = db.batch();
      
      for (final product in products) {
        batch.insert('products', product.toMap());
      }
      
      await batch.commit();
      
      // Clear related caches
      _clearProductCaches();
    });
  }

  // Optimized statistics queries
  Future<Map<String, dynamic>> getDashboardStatsOptimized() async {
    return trackAsyncOperation('getDashboardStatsOptimized', () async {
      final cacheKey = 'dashboard_stats';
      
      // Check cache first
      final cachedData = getCachedData<Map<String, dynamic>>('stats', cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      final db = await _dbHelper.database;
      
      // Use raw queries for better performance
      final customerCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM customers')) ?? 0;
      final productCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products')) ?? 0;
      final invoiceCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM invoices')) ?? 0;
      final paymentCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM payments')) ?? 0;
      
      final totalRevenueResult = await db.rawQuery('SELECT SUM(totalAmount) as total FROM invoices');
      final totalRevenue = (totalRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final totalPaidResult = await db.rawQuery('SELECT SUM(amount) as total FROM payments');
      final totalPaid = (totalPaidResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final stats = {
        'customerCount': customerCount,
        'productCount': productCount,
        'invoiceCount': invoiceCount,
        'paymentCount': paymentCount,
        'totalRevenue': totalRevenue,
        'totalPaid': totalPaid,
        'outstanding': totalRevenue - totalPaid,
      };
      
      // Cache the result
      cacheData('stats', cacheKey, stats, ttl: Duration(minutes: 5));
      
      return stats;
    });
  }

  // Lazy loading for large datasets
  Stream<List<Customer>> getCustomersStream({int pageSize = 20}) async* {
    int offset = 0;
    bool hasMore = true;
    
    while (hasMore) {
      final customers = await getCustomersOptimized(limit: pageSize, offset: offset);
      yield customers;
      
      hasMore = customers.length == pageSize;
      offset += pageSize;
    }
  }

  Stream<List<Product>> getProductsStream({int pageSize = 20}) async* {
    int offset = 0;
    bool hasMore = true;
    
    while (hasMore) {
      final products = await getProductsOptimized(limit: pageSize, offset: offset);
      yield products;
      
      hasMore = products.length == pageSize;
      offset += pageSize;
    }
  }

  // Cache invalidation methods
  void _clearCustomerCaches() {
    _cacheService.clearAllMemoryCache();
  }

  void _clearProductCaches() {
    _cacheService.clearAllMemoryCache();
  }

  void _clearInvoiceCaches() {
    _cacheService.clearAllMemoryCache();
  }

  // Performance monitoring
  Map<String, dynamic> getPerformanceReport() {
    return _performanceService.getAllPerformanceStats();
  }

  List<String> getSlowOperations() {
    return _performanceService.getSlowOperations();
  }

  // Memory management
  void clearAllCaches() {
    _cacheService.clearAllMemoryCache();
  }

  Map<String, dynamic> getCacheStats() {
    return _cacheService.getCacheStats();
  }
}