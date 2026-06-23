import '../models/vehicle.dart';
import '../database/database_helper.dart';
import 'client_activity_service.dart';

class VehicleService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Create a new vehicle
  Future<int> createVehicle(Vehicle vehicle) async {
    final db = await _dbHelper.database;
    final id = await db.insert('vehicles', vehicle.toMap());
    
    // Log activity to Supabase (for mobile app visibility)
    try {
      await ClientActivityService().logVehicleCreated(
        vehicle.name,
        make: vehicle.make,
        model: vehicle.model,
        price: vehicle.priceUSD,
      );
    } catch (e) {
      // Don't fail vehicle creation if activity logging fails
      print('⚠️ Failed to log vehicle creation activity: $e');
    }
    
    return id;
  }

  // Get all vehicles
  Future<List<Vehicle>> getAllVehicles() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  // Get vehicle by ID
  Future<Vehicle?> getVehicleById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Vehicle.fromMap(maps.first);
    }
    return null;
  }

  // Get vehicles by status
  Future<List<Vehicle>> getVehiclesByStatus(VehicleStatus status) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'status = ? AND isActive = 1',
      whereArgs: [status.name],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  // Get available vehicles (in stock)
  Future<List<Vehicle>> getAvailableVehicles() async {
    return getVehiclesByStatus(VehicleStatus.inStock);
  }

  // Update vehicle
  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await _dbHelper.database;
    final result = await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
    
    // Log activity to Supabase (for mobile app visibility)
    try {
      await ClientActivityService().logVehicleUpdated(vehicle.name);
    } catch (e) {
      // Don't fail vehicle update if activity logging fails
      print('⚠️ Failed to log vehicle update activity: $e');
    }
    
    return result;
  }

  // Delete vehicle
  Future<int> deleteVehicle(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search vehicles
  Future<List<Vehicle>> searchVehicles(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: '''
        (name LIKE ? OR make LIKE ? OR model LIKE ? OR color LIKE ?) 
        AND isActive = 1
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  // Get vehicles by make
  Future<List<Vehicle>> getVehiclesByMake(String make) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'make = ? AND isActive = 1',
      whereArgs: [make],
      orderBy: 'model ASC, year DESC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  // Get vehicles by year range
  Future<List<Vehicle>> getVehiclesByYearRange(int startYear, int endYear) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'year >= ? AND year <= ? AND isActive = 1',
      whereArgs: [startYear, endYear],
      orderBy: 'year DESC, name ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  // Get vehicles by price range
  Future<List<Vehicle>> getVehiclesByPriceRange(double minPrice, double maxPrice) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'price >= ? AND price <= ? AND isActive = 1',
      whereArgs: [minPrice, maxPrice],
      orderBy: 'price ASC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  // Update vehicle status
  Future<int> updateVehicleStatus(int id, VehicleStatus status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'vehicles',
      {
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get vehicle statistics
  Future<Map<String, dynamic>> getVehicleStatistics() async {
    final db = await _dbHelper.database;
    
    // Get total vehicles
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM vehicles WHERE isActive = 1');
    final total = totalResult.first['total'] as int;
    
    // Get vehicles by status
    final statusResult = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM vehicles 
      WHERE isActive = 1 
      GROUP BY status
    ''');
    
    Map<String, int> statusCounts = {};
    for (var row in statusResult) {
      statusCounts[row['status'] as String] = row['count'] as int;
    }
    
    // Get average price
    final avgResult = await db.rawQuery('''
      SELECT AVG(price) as avgPrice 
      FROM vehicles 
      WHERE isActive = 1 AND status = 'inStock'
    ''');
    final avgPrice = avgResult.first['avgPrice'] as double? ?? 0.0;
    
    // Get total value
    final valueResult = await db.rawQuery('''
      SELECT SUM(price) as totalValue 
      FROM vehicles 
      WHERE isActive = 1 AND status = 'inStock'
    ''');
    final totalValue = valueResult.first['totalValue'] as double? ?? 0.0;
    
    return {
      'total': total,
      'statusCounts': statusCounts,
      'averagePrice': avgPrice,
      'totalValue': totalValue,
    };
  }

  // Get unique makes
  Future<List<String>> getUniqueMakes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT make 
      FROM vehicles 
      WHERE isActive = 1 
      ORDER BY make ASC
    ''');
    return maps.map((row) => row['make'] as String).toList();
  }

  // Get unique models for a make
  Future<List<String>> getModelsByMake(String make) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT model 
      FROM vehicles 
      WHERE make = ? AND isActive = 1 
      ORDER BY model ASC
    ''', [make]);
    return maps.map((row) => row['model'] as String).toList();
  }
}
