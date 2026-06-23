import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';
import '../models/ura_vehicle.dart';

/// Service for looking up URA CIF values and managing URA database
class UraLookupService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Search for vehicles in URA database
  Future<List<Map<String, dynamic>>> searchVehicles({
    String? make,
    String? model,
    int? year,
    int? engineCC,
    String? databaseMonth,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];
    
    if (make != null && make.isNotEmpty) {
      whereClause += ' AND make LIKE ?';
      whereArgs.add('%$make%');
    }
    
    if (model != null && model.isNotEmpty) {
      whereClause += ' AND model LIKE ?';
      whereArgs.add('%$model%');
    }
    
    if (year != null) {
      whereClause += ' AND year = ?';
      whereArgs.add(year);
    }
    
    if (engineCC != null) {
      whereClause += ' AND engine_cc = ?';
      whereArgs.add(engineCC);
    }
    
    if (databaseMonth != null && databaseMonth.isNotEmpty) {
      whereClause += ' AND database_month = ?';
      whereArgs.add(databaseMonth);
    }
    
    final results = await db.query(
      'ura_cif_database',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'make, model, year DESC',
      limit: 100,
    );
    
    return results;
  }

  /// Get exact match for a vehicle
  Future<Map<String, dynamic>?> getExactMatch({
    required String make,
    required String model,
    required int year,
    int? engineCC,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = 'is_active = 1 AND make = ? AND model = ? AND year = ?';
    List<dynamic> whereArgs = [make, model, year];
    
    if (engineCC != null) {
      whereClause += ' AND engine_cc = ?';
      whereArgs.add(engineCC);
    }
    
    final results = await db.query(
      'ura_cif_database',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }

  /// Get current exchange rate
  Future<double> getCurrentExchangeRate() async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'exchange_rate_cache',
      where: 'is_current = 1',
      orderBy: 'effective_date DESC',
      limit: 1,
    );
    
    if (results.isNotEmpty) {
      return results.first['rate'] as double;
    }
    
    // Default exchange rate if none found
    return 3700.0;
  }

  /// Update exchange rate
  Future<void> updateExchangeRate({
    required double rate,
    required DateTime effectiveDate,
    String? source,
  }) async {
    final db = await _dbHelper.database;
    
    // Mark all existing rates as not current
    await db.update(
      'exchange_rate_cache',
      {'is_current': 0},
      where: 'is_current = 1',
    );
    
    // Insert new rate
    await db.insert('exchange_rate_cache', {
      'rate': rate,
      'effective_date': effectiveDate.toIso8601String(),
      'source': source ?? 'Manual',
      'downloaded_at': DateTime.now().toIso8601String(),
      'is_current': 1,
    });
  }

  /// Import URA database entries (bulk insert)
  Future<int> importUraDatabaseEntries({
    required List<Map<String, dynamic>> entries,
    required String databaseMonth,
  }) async {
    final db = await _dbHelper.database;
    int importedCount = 0;
    
    // Mark old entries for this month as inactive
    await db.update(
      'ura_cif_database',
      {'is_active': 0},
      where: 'database_month = ?',
      whereArgs: [databaseMonth],
    );
    
    // Insert new entries
    final batch = db.batch();
    for (var entry in entries) {
      batch.insert('ura_cif_database', {
        'hsc_code': entry['hsc_code'],
        'country_origin': entry['country_origin'],
        'make': entry['make'],
        'model': entry['model'],
        'year': entry['year'],
        'engine_cc': entry['engine_cc'],
        'description': entry['description'],
        'cif_usd': entry['cif_usd'],
        'database_month': databaseMonth,
        'downloaded_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      });
      importedCount++;
    }
    
    await batch.commit(noResult: true);
    return importedCount;
  }

  /// Delete old URA database entries (older than specified month)
  Future<int> deleteOldEntries(String beforeMonth) async {
    final db = await _dbHelper.database;
    
    final deletedCount = await db.delete(
      'ura_cif_database',
      where: 'database_month < ?',
      whereArgs: [beforeMonth],
    );
    
    return deletedCount;
  }

  /// Get available database months
  Future<List<String>> getAvailableMonths() async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT database_month 
      FROM ura_cif_database 
      WHERE is_active = 1
      ORDER BY database_month DESC
    ''');
    
    return results.map((r) => r['database_month'] as String).toList();
  }

  /// Get statistics about URA database
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await _dbHelper.database;
    
    final totalVehiclesResult = await db.rawQuery('SELECT COUNT(*) as count FROM ura_cif_database WHERE is_active = 1');
    final totalVehicles = totalVehiclesResult.first['count'] as int? ?? 0;
    
    final uniqueMakesResult = await db.rawQuery('SELECT COUNT(DISTINCT make) as count FROM ura_cif_database WHERE is_active = 1');
    final uniqueMakes = uniqueMakesResult.first['count'] as int? ?? 0;
    
    final months = await getAvailableMonths();
    
    final exchangeRate = await getCurrentExchangeRate();
    
    return {
      'total_vehicles': totalVehicles,
      'unique_makes': uniqueMakes,
      'available_months': months,
      'current_exchange_rate': exchangeRate,
      'last_updated': months.isNotEmpty ? months.first : 'Never',
    };
  }

  /// Calculate tax based on CIF value
  Future<Map<String, dynamic>> calculateTax({
    required double cifUsd,
    required int year,
    required int engineCC,
    required double exchangeRate,
    String vehicleType = 'car', // 'car', 'truck', 'bus'
  }) async {
    final currentYear = DateTime.now().year;
    final vehicleAge = currentYear - year;
    
    // Convert CIF to UGX
    final cifUgx = cifUsd * exchangeRate;
    
    // Import Duty: 25%
    final importDuty = cifUgx * 0.25;
    
    // VAT: 18% on (CIF + Import Duty)
    final vatBase = cifUgx + importDuty;
    final vat = vatBase * 0.18;
    
    // Withholding Tax: 6% on (CIF + Import Duty)
    final wht = vatBase * 0.06;
    
    // Environmental Levy (10-year rule: 2015 and below in 2025)
    final environmentalLevyCutoffYear = currentYear - 10;
    double environmentalLevy = 0.0;
    if (year <= environmentalLevyCutoffYear) {
      environmentalLevy = cifUgx * 0.35; // 35% of CIF
    }
    
    // Infrastructure Levy: 1.5% of CIF
    final infrastructureLevy = cifUgx * 0.015;
    
    // Registration Fee
    double registrationFee = 250000.0; // Default for cars
    if (vehicleType == 'truck') {
      if (engineCC > 3000) {
        registrationFee = 650000.0;
      } else {
        registrationFee = 450000.0;
      }
    } else if (vehicleType == 'bus') {
      registrationFee = 450000.0;
    }
    
    // Stamp Duty
    const stampDuty = 50000.0;
    
    // Number Plates (Form Fees)
    const numberPlates = 100000.0;
    
    // Total Tax
    final totalTax = importDuty + vat + wht + environmentalLevy + 
                     infrastructureLevy + registrationFee + 
                     stampDuty + numberPlates;
    
    return {
      'cif_usd': cifUsd,
      'cif_ugx': cifUgx,
      'exchange_rate': exchangeRate,
      'import_duty': importDuty,
      'vat': vat,
      'withholding_tax': wht,
      'environmental_levy': environmentalLevy,
      'infrastructure_levy': infrastructureLevy,
      'registration_fee': registrationFee,
      'stamp_duty': stampDuty,
      'number_plates': numberPlates,
      'total_tax': totalTax,
      'vehicle_age': vehicleAge,
      'has_environmental_levy': year <= environmentalLevyCutoffYear,
      'breakdown': {
        'Customs (Import Duty 25%)': importDuty,
        'VAT (18%)': vat,
        'WHT (6%)': wht,
        'Environmental Levy (35%)': environmentalLevy,
        'Infrastructure Levy (1.5%)': infrastructureLevy,
        'Registration Fee': registrationFee,
        'Stamp Duty': stampDuty,
        'Number Plates': numberPlates,
      },
    };
  }

  /// Get all available makes (for cascading dropdown)
  Future<List<String>> getAvailableMakes() async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT make 
      FROM ura_cif_database 
      WHERE is_active = 1 
      ORDER BY make ASC
    ''');
    
    return results.map((r) => r['make'] as String).toList();
  }

  /// Get all available models for a specific make
  Future<List<String>> getModelsForMake(String make) async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT model 
      FROM ura_cif_database 
      WHERE is_active = 1 AND make = ?
      ORDER BY model ASC
    ''', [make]);
    
    return results.map((r) => r['model'] as String).toList();
  }

  /// Get all available years for a specific make and model
  Future<List<int>> getYearsForModel(String make, String model) async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT year 
      FROM ura_cif_database 
      WHERE is_active = 1 AND make = ? AND model = ?
      ORDER BY year DESC
    ''', [make, model]);
    
    return results.map((r) => r['year'] as int).toList();
  }

  /// Get all available engine sizes for a specific make, model, and year
  Future<List<int>> getEngineSizesForModel(String make, String model, int year) async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT engine_cc 
      FROM ura_cif_database 
      WHERE is_active = 1 AND make = ? AND model = ? AND year = ?
      ORDER BY engine_cc ASC
    ''', [make, model, year]);
    
    return results.map((r) => r['engine_cc'] as int).toList();
  }

  /// Search for vehicles and return as UraVehicle objects
  Future<List<UraVehicle>> searchVehiclesAsObjects({
    String? make,
    String? model,
    int? year,
    int? engineCC,
    String? databaseMonth,
  }) async {
    final results = await searchVehicles(
      make: make,
      model: model,
      year: year,
      engineCC: engineCC,
      databaseMonth: databaseMonth,
    );
    
    return results.map((map) => UraVehicle.fromMap(map)).toList();
  }

  /// Get all available makes (for Magic Lookup Wizard)
  Future<List<String>> getAllMakes() async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT make 
      FROM ura_cif_database 
      WHERE is_active = 1 AND make IS NOT NULL AND make != '' AND make != 'Unknown'
      ORDER BY make ASC
    ''');
    
    return results.map((r) => r['make'] as String).toList();
  }

  /// Get all available models (for Magic Lookup Wizard)
  Future<List<String>> getAllModels() async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT model 
      FROM ura_cif_database 
      WHERE is_active = 1 AND model IS NOT NULL AND model != '' AND model != 'Unknown'
      ORDER BY model ASC
    ''');
    
    return results.map((r) => r['model'] as String).toList();
  }

  /// Get all available years (for Magic Lookup Wizard)
  Future<List<int>> getAllYears() async {
    final db = await _dbHelper.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT year 
      FROM ura_cif_database 
      WHERE is_active = 1 AND year IS NOT NULL AND year > 1990
      ORDER BY year DESC
    ''');
    
    return results.map((r) => r['year'] as int).toList();
  }

  /// Advanced search with multiple criteria (for Magic Lookup Wizard)
  Future<List<UraVehicle>> advancedSearch({
    String? searchQuery,
    String? make,
    String? model,
    int? year,
    double? minPrice,
    double? maxPrice,
    String? country,
    int limit = 100,
  }) async {
    final db = await _dbHelper.database;
    
    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];
    
    // Text search across multiple fields (case-insensitive)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ' AND (UPPER(make) LIKE UPPER(?) OR UPPER(model) LIKE UPPER(?) OR UPPER(description) LIKE UPPER(?) OR UPPER(serial_number) LIKE UPPER(?))';
      final query = '%$searchQuery%';
      whereArgs.addAll([query, query, query, query]);
    }
    
    if (make != null && make.isNotEmpty) {
      whereClause += ' AND make = ?';
      whereArgs.add(make);
    }
    
    if (model != null && model.isNotEmpty) {
      whereClause += ' AND model = ?';
      whereArgs.add(model);
    }
    
    if (year != null) {
      whereClause += ' AND year = ?';
      whereArgs.add(year);
    }
    
    if (minPrice != null) {
      whereClause += ' AND cif_usd >= ?';
      whereArgs.add(minPrice);
    }
    
    if (maxPrice != null) {
      whereClause += ' AND cif_usd <= ?';
      whereArgs.add(maxPrice);
    }
    
    if (country != null && country.isNotEmpty) {
      whereClause += ' AND country_origin LIKE ?';
      whereArgs.add('%$country%');
    }
    
    final results = await db.query(
      'ura_cif_database',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'cif_usd DESC, make ASC, model ASC',
      limit: limit,
    );
    
    return results.map((map) => UraVehicle.fromMap(map)).toList();
  }

  /// Search by serial number
  Future<UraVehicle?> searchBySerialNumber(String serialNumber) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'ura_cif_database',
      where: 'is_active = 1 AND serial_number = ?',
      whereArgs: [serialNumber],
      limit: 1,
    );
    
    if (results.isNotEmpty) {
      return UraVehicle.fromMap(results.first);
    }
    
    return null;
  }

  /// Get vehicles with similar characteristics
  Future<List<UraVehicle>> getSimilarVehicles({
    required String make,
    required String model,
    required int year,
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'ura_cif_database',
      where: 'is_active = 1 AND make = ? AND model = ? AND year = ?',
      whereArgs: [make, model, year],
      orderBy: 'cif_usd DESC',
      limit: limit,
    );
    
    return results.map((map) => UraVehicle.fromMap(map)).toList();
  }

}
