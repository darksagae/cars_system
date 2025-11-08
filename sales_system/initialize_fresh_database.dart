import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'lib/database/database_helper.dart';
import 'lib/models/ura_vehicle.dart';

void main() async {
  print('🧹 Initializing fresh database...');
  
  // Initialize FFI for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  try {
    // Get the database helper
    final dbHelper = DatabaseHelper();
    
    // Initialize database (this will create fresh tables)
    final db = await dbHelper.database;
    print('✅ Fresh database initialized successfully');
    
    // Clear existing data
    await db.delete('ura_cif_database');
    print('🧹 Cleared existing data');
    
    // Insert some clean sample data
    final sampleVehicles = [
      UraVehicle(
        id: 1,
        serialNumber: '1.0',
        hscCode: '8709.19.00',
        countryOrigin: 'TH',
        make: 'A35',
        model: 'Folklift',
        year: 2020,
        engineCC: 2500,
        description: 'A35 Folklift, Model 4D27G, 2020',
        cifUsd: 9403.59,
        databaseMonth: 'October 2025',
        downloadedAt: DateTime.now(),
        isActive: true,
      ),
      UraVehicle(
        id: 2,
        serialNumber: '2.0',
        hscCode: '8709.19.00',
        countryOrigin: 'TH',
        make: 'A35',
        model: 'Folklift',
        year: 2020,
        engineCC: 1760,
        description: 'A35 Folklift, Model 4D27G, 2020',
        cifUsd: 8463.23,
        databaseMonth: 'October 2025',
        downloadedAt: DateTime.now(),
        isActive: true,
      ),
      UraVehicle(
        id: 3,
        serialNumber: '72',
        hscCode: '8703.23.90',
        countryOrigin: 'DE',
        make: 'Audi',
        model: 'A1',
        year: 2016,
        engineCC: 1600,
        description: 'Audi A1 Car (Petrol), 2016',
        cifUsd: 5477.17,
        databaseMonth: 'October 2025',
        downloadedAt: DateTime.now(),
        isActive: true,
      ),
      UraVehicle(
        id: 4,
        serialNumber: '688',
        hscCode: '8703.24.90',
        countryOrigin: 'DE',
        make: 'BMW',
        model: '3 Series',
        year: 2019,
        engineCC: 2000,
        description: 'BMW 3 Series, 320D, Sedan, 2019',
        cifUsd: 12815.98,
        databaseMonth: 'October 2025',
        downloadedAt: DateTime.now(),
        isActive: true,
      ),
      UraVehicle(
        id: 5,
        serialNumber: '145',
        hscCode: '8703.23.90',
        countryOrigin: 'JP',
        make: 'Toyota',
        model: 'Camry',
        year: 2018,
        engineCC: 2500,
        description: 'Toyota Camry, Sedan, 2018',
        cifUsd: 8750.00,
        databaseMonth: 'October 2025',
        downloadedAt: DateTime.now(),
        isActive: true,
      ),
    ];
    
    // Insert sample data
    final batch = db.batch();
    
    for (final vehicle in sampleVehicles) {
      batch.insert('ura_cif_database', vehicle.toMap());
    }
    
    await batch.commit();
    print('✅ Inserted ${sampleVehicles.length} sample vehicles');
    
    // Verify the data
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM ura_cif_database');
    print('📊 Total vehicles in database: ${count.first['count']}');
    
    // Show sample data
    final vehicles = await db.rawQuery('''
      SELECT make, model, year, engine_cc, cif_usd, serial_number 
      FROM ura_cif_database 
      ORDER BY make, model
    ''');
    
    print('\n📋 Sample vehicles:');
    for (final vehicle in vehicles) {
      print('  ${vehicle['make']} ${vehicle['model']} (${vehicle['year']}) - ${vehicle['engine_cc']}cc - \$${vehicle['cif_usd']} - S/N: ${vehicle['serial_number']}');
    }
    
    print('\n🎉 Fresh database setup complete!');
    
  } catch (e) {
    print('❌ Error setting up fresh database: $e');
    exit(1);
  }
}
