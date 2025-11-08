import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../cache/memory_cache.dart';
import '../performance/performance_monitor.dart';

class OptimizedDatabaseService {
  static final OptimizedDatabaseService _instance = OptimizedDatabaseService._internal();
  factory OptimizedDatabaseService() => _instance;
  OptimizedDatabaseService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MemoryCache _cache = MemoryCache();
  final PerformanceMonitor _monitor = PerformanceMonitor();

  // Pagination parameters
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 100;

  // Get customers with pagination
  Future<List<Map<String, dynamic>>> getCustomersPaginated({
    int page = 1,
    int pageSize = _defaultPageSize,
    String? searchQuery,
    String? sortBy,
    bool ascending = true,
  }) async {
    _monitor.startTimer('getCustomersPaginated');
    
    try {
      final cacheKey = 'customers_${page}_${pageSize}_${searchQuery ?? ''}_${sortBy ?? ''}_$ascending';
      
      // Check cache first
      final cachedResult = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cachedResult != null) {
        _monitor.endTimer('getCustomersPaginated');
        return cachedResult;
      }
      
      final db = await _dbHelper.database;
      final offset = (page - 1) * pageSize;
      
      String query = 'SELECT * FROM customers';
      List<dynamic> params = [];
      
      // Add search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query += ' WHERE name LIKE ? OR email LIKE ? OR phone LIKE ?';
        final searchPattern = '%$searchQuery%';
        params.addAll([searchPattern, searchPattern, searchPattern]);
      }
      
      // Add sorting
      if (sortBy != null) {
        query += ' ORDER BY $sortBy ${ascending ? 'ASC' : 'DESC'}';
      } else {
        query += ' ORDER BY created_at DESC';
      }
      
      // Add pagination
      query += ' LIMIT ? OFFSET ?';
      params.addAll([pageSize, offset]);
      
      final result = await db.rawQuery(query, params);
      
      // Cache the result
      _cache.put(cacheKey, result, ttl: const Duration(minutes: 5));
      
      _monitor.endTimer('getCustomersPaginated');
      return result;
    } catch (e) {
      _monitor.endTimer('getCustomersPaginated');
      rethrow;
    }
  }

  // Get vehicles with pagination
  Future<List<Map<String, dynamic>>> getVehiclesPaginated({
    int page = 1,
    int pageSize = _defaultPageSize,
    String? searchQuery,
    String? status,
    String? sortBy,
    bool ascending = true,
  }) async {
    _monitor.startTimer('getVehiclesPaginated');
    
    try {
      final cacheKey = 'vehicles_${page}_${pageSize}_${searchQuery ?? ''}_${status ?? ''}_${sortBy ?? ''}_$ascending';
      
      // Check cache first
      final cachedResult = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cachedResult != null) {
        _monitor.endTimer('getVehiclesPaginated');
        return cachedResult;
      }
      
      final db = await _dbHelper.database;
      final offset = (page - 1) * pageSize;
      
      String query = 'SELECT * FROM vehicles';
      List<dynamic> params = [];
      List<String> conditions = [];
      
      // Add search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions.add('(name LIKE ? OR make LIKE ? OR model LIKE ?)');
        final searchPattern = '%$searchQuery%';
        params.addAll([searchPattern, searchPattern, searchPattern]);
      }
      
      // Add status filter
      if (status != null && status.isNotEmpty) {
        conditions.add('status = ?');
        params.add(status);
      }
      
      if (conditions.isNotEmpty) {
        query += ' WHERE ${conditions.join(' AND ')}';
      }
      
      // Add sorting
      if (sortBy != null) {
        query += ' ORDER BY $sortBy ${ascending ? 'ASC' : 'DESC'}';
      } else {
        query += ' ORDER BY created_at DESC';
      }
      
      // Add pagination
      query += ' LIMIT ? OFFSET ?';
      params.addAll([pageSize, offset]);
      
      final result = await db.rawQuery(query, params);
      
      // Cache the result
      _cache.put(cacheKey, result, ttl: const Duration(minutes: 5));
      
      _monitor.endTimer('getVehiclesPaginated');
      return result;
    } catch (e) {
      _monitor.endTimer('getVehiclesPaginated');
      rethrow;
    }
  }

  // Get invoices with pagination
  Future<List<Map<String, dynamic>>> getInvoicesPaginated({
    int page = 1,
    int pageSize = _defaultPageSize,
    String? searchQuery,
    String? status,
    int? customerId,
    String? sortBy,
    bool ascending = true,
  }) async {
    _monitor.startTimer('getInvoicesPaginated');
    
    try {
      final cacheKey = 'invoices_${page}_${pageSize}_${searchQuery ?? ''}_${status ?? ''}_${customerId ?? ''}_${sortBy ?? ''}_$ascending';
      
      // Check cache first
      final cachedResult = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cachedResult != null) {
        _monitor.endTimer('getInvoicesPaginated');
        return cachedResult;
      }
      
      final db = await _dbHelper.database;
      final offset = (page - 1) * pageSize;
      
      String query = '''
        SELECT i.*, c.name as customer_name, c.email as customer_email
        FROM invoices i
        LEFT JOIN customers c ON i.customer_id = c.id
      ''';
      List<dynamic> params = [];
      List<String> conditions = [];
      
      // Add search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions.add('(i.invoice_number LIKE ? OR c.name LIKE ? OR c.email LIKE ?)');
        final searchPattern = '%$searchQuery%';
        params.addAll([searchPattern, searchPattern, searchPattern]);
      }
      
      // Add status filter
      if (status != null && status.isNotEmpty) {
        conditions.add('i.status = ?');
        params.add(status);
      }
      
      // Add customer filter
      if (customerId != null) {
        conditions.add('i.customer_id = ?');
        params.add(customerId);
      }
      
      if (conditions.isNotEmpty) {
        query += ' WHERE ${conditions.join(' AND ')}';
      }
      
      // Add sorting
      if (sortBy != null) {
        query += ' ORDER BY i.$sortBy ${ascending ? 'ASC' : 'DESC'}';
      } else {
        query += ' ORDER BY i.created_at DESC';
      }
      
      // Add pagination
      query += ' LIMIT ? OFFSET ?';
      params.addAll([pageSize, offset]);
      
      final result = await db.rawQuery(query, params);
      
      // Cache the result
      _cache.put(cacheKey, result, ttl: const Duration(minutes: 5));
      
      _monitor.endTimer('getInvoicesPaginated');
      return result;
    } catch (e) {
      _monitor.endTimer('getInvoicesPaginated');
      rethrow;
    }
  }

  // Get count for pagination
  Future<int> getCount(String table, {Map<String, dynamic>? filters}) async {
    _monitor.startTimer('getCount_$table');
    
    try {
      final cacheKey = 'count_${table}_${filters?.toString() ?? ''}';
      
      // Check cache first
      final cachedResult = _cache.get<int>(cacheKey);
      if (cachedResult != null) {
        _monitor.endTimer('getCount_$table');
        return cachedResult;
      }
      
      final db = await _dbHelper.database;
      String query = 'SELECT COUNT(*) as count FROM $table';
      List<dynamic> params = [];
      
      if (filters != null && filters.isNotEmpty) {
        final conditions = <String>[];
        for (final entry in filters.entries) {
          conditions.add('${entry.key} = ?');
          params.add(entry.value);
        }
        query += ' WHERE ${conditions.join(' AND ')}';
      }
      
      final result = await db.rawQuery(query, params);
      final count = Sqflite.firstIntValue(result) ?? 0;
      
      // Cache the result
      _cache.put(cacheKey, count, ttl: const Duration(minutes: 5));
      
      _monitor.endTimer('getCount_$table');
      return count;
    } catch (e) {
      _monitor.endTimer('getCount_$table');
      rethrow;
    }
  }

  // Search with full-text search
  Future<List<Map<String, dynamic>>> search({
    required String query,
    List<String> tables = const ['customers', 'vehicles', 'invoices'],
    int limit = 20,
  }) async {
    _monitor.startTimer('search');
    
    try {
      final cacheKey = 'search_${query}_${tables.join('_')}_$limit';
      
      // Check cache first
      final cachedResult = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cachedResult != null) {
        _monitor.endTimer('search');
        return cachedResult;
      }
      
      final db = await _dbHelper.database;
      final results = <Map<String, dynamic>>[];
      final searchPattern = '%$query%';
      
      for (final table in tables) {
        String tableQuery;
        List<dynamic> params;
        
        switch (table) {
          case 'customers':
            tableQuery = '''
              SELECT 'customer' as type, id, name, email, phone, created_at
              FROM customers
              WHERE name LIKE ? OR email LIKE ? OR phone LIKE ?
            ''';
            params = [searchPattern, searchPattern, searchPattern];
            break;
            
          case 'vehicles':
            tableQuery = '''
              SELECT 'vehicle' as type, id, name, make, model, year, price, status, created_at
              FROM vehicles
              WHERE name LIKE ? OR make LIKE ? OR model LIKE ?
            ''';
            params = [searchPattern, searchPattern, searchPattern];
            break;
            
          case 'invoices':
            tableQuery = '''
              SELECT 'invoice' as type, i.id, i.invoice_number, i.total_amount, i.status, i.created_at,
                     c.name as customer_name
              FROM invoices i
              LEFT JOIN customers c ON i.customer_id = c.id
              WHERE i.invoice_number LIKE ? OR c.name LIKE ?
            ''';
            params = [searchPattern, searchPattern];
            break;
            
          default:
            continue;
        }
        
        final result = await db.rawQuery(tableQuery, params);
        results.addAll(result);
      }
      
      // Sort by relevance (simplified)
      results.sort((a, b) => a['created_at'].compareTo(b['created_at']));
      
      // Limit results
      final limitedResults = results.take(limit).toList();
      
      // Cache the result
      _cache.put(cacheKey, limitedResults, ttl: const Duration(minutes: 2));
      
      _monitor.endTimer('search');
      return limitedResults;
    } catch (e) {
      _monitor.endTimer('search');
      rethrow;
    }
  }

  // Clear cache
  void clearCache() {
    _cache.clear();
  }

  // Get cache statistics
  CacheStatistics getCacheStatistics() {
    return _cache.getStatistics();
  }

  // Get performance statistics
  Map<String, OperationStats> getPerformanceStatistics() {
    return _monitor.getOperationStats();
  }

  // Optimize database
  Future<void> optimizeDatabase() async {
    _monitor.startTimer('optimizeDatabase');
    
    try {
      final db = await _dbHelper.database;
      
      // Create indexes for better performance
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_make ON vehicles(make)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_model ON vehicles(model)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date)');
      
      // Analyze database for query optimization
      await db.execute('ANALYZE');
      
      _monitor.endTimer('optimizeDatabase');
    } catch (e) {
      _monitor.endTimer('optimizeDatabase');
      rethrow;
    }
  }
}
