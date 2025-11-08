import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Helper class to handle database migrations
class MigrationHelper {
  static const int _currentVersion = 2;

  /// Run all necessary migrations
  static Future<void> runMigrations(Database db) async {
    final version = await db.getVersion();
    
    if (version < 2) {
      await _migrateToVersion2(db);
    }
    
    await db.setVersion(_currentVersion);
  }

  /// Migrate to version 2: Add serial_number column to ura_cif_database
  static Future<void> _migrateToVersion2(Database db) async {
    try {
      // Check if serial_number column already exists
      final columns = await db.rawQuery('PRAGMA table_info(ura_cif_database)');
      final hasSerialNumber = columns.any((column) => column['name'] == 'serial_number');
      
      if (!hasSerialNumber) {
        print('Adding serial_number column to ura_cif_database table...');
        await db.execute('ALTER TABLE ura_cif_database ADD COLUMN serial_number TEXT');
        print('✅ Added serial_number column successfully');
      } else {
        print('✅ serial_number column already exists');
      }
    } catch (e) {
      print('❌ Error adding serial_number column: $e');
      // If ALTER TABLE fails, we might need to recreate the table
      // This is a fallback for SQLite versions that don't support ALTER TABLE ADD COLUMN
      await _recreateUraTableWithSerialNumber(db);
    }
  }

  /// Fallback: Recreate the ura_cif_database table with serial_number column
  static Future<void> _recreateUraTableWithSerialNumber(Database db) async {
    try {
      print('Recreating ura_cif_database table with serial_number column...');
      
      // Create backup table
      await db.execute('''
        CREATE TABLE ura_cif_database_backup AS 
        SELECT * FROM ura_cif_database
      ''');
      
      // Drop original table
      await db.execute('DROP TABLE ura_cif_database');
      
      // Create new table with serial_number column
      await db.execute('''
        CREATE TABLE ura_cif_database (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          serial_number TEXT,
          hsc_code TEXT,
          country_origin TEXT,
          make TEXT NOT NULL,
          model TEXT NOT NULL,
          year INTEGER NOT NULL,
          engine_cc INTEGER,
          description TEXT,
          cif_usd REAL NOT NULL,
          database_month TEXT NOT NULL,
          downloaded_at TEXT NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');
      
      // Copy data from backup (serial_number will be NULL for existing records)
      await db.execute('''
        INSERT INTO ura_cif_database (
          id, hsc_code, country_origin, make, model, year, 
          engine_cc, description, cif_usd, database_month, 
          downloaded_at, is_active
        )
        SELECT 
          id, hsc_code, country_origin, make, model, year, 
          engine_cc, description, cif_usd, database_month, 
          downloaded_at, is_active
        FROM ura_cif_database_backup
      ''');
      
      // Drop backup table
      await db.execute('DROP TABLE ura_cif_database_backup');
      
      print('✅ Successfully recreated ura_cif_database table with serial_number column');
    } catch (e) {
      print('❌ Error recreating ura_cif_database table: $e');
      rethrow;
    }
  }

  /// Check if migration is needed
  static Future<bool> isMigrationNeeded(Database db) async {
    final version = await db.getVersion();
    return version < _currentVersion;
  }

  /// Get current database version
  static Future<int> getCurrentVersion(Database db) async {
    return await db.getVersion();
  }
}

