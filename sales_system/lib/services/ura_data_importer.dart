import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';

class UraDataImporter {
  static const String _csvFileName = 'ura_october_2025.csv';
  
  /// Import real URA data from the extracted CSV file
  static Future<Map<String, dynamic>> importRealUraData() async {
    try {
      print('Starting real URA data import...');
      
      // Get the CSV file path
      final documentsDir = await getApplicationDocumentsDirectory();
      final csvFile = File('${documentsDir.path}/$_csvFileName');
      
      // Check if CSV file exists
      if (!await csvFile.exists()) {
        // Try to find the CSV file in the project directory
        final projectCsv = File('$_csvFileName');
        if (await projectCsv.exists()) {
          await projectCsv.copy(csvFile.path);
          print('Copied CSV file to documents directory');
        } else {
          return {
            'success': false,
            'error': 'CSV file not found. Please ensure the URA data extraction completed successfully.',
            'recordsImported': 0
          };
        }
      }
      
      // Read CSV file
      final csvContent = await csvFile.readAsString();
      final csvData = const CsvToListConverter().convert(csvContent);
      
      print('CSV loaded with ${csvData.length} rows');
      
      // Get database instance
      final db = await DatabaseHelper.instance.database;
      
      // Clear existing URA data
      await db.delete('ura_cif_database');
      print('Cleared existing URA data');
      
      // Process and insert data
      int importedCount = 0;
      int skippedCount = 0;
      
      // Skip header row
      for (int i = 1; i < csvData.length; i++) {
        try {
          final row = csvData[i];
          
          // Extract data from the messy CSV structure
          final vehicleData = _extractVehicleData(row);
          
          if (vehicleData != null) {
            // Insert into database
            await db.insert('ura_cif_database', {
              'hsc_code': vehicleData['hsc_code'],
              'country_origin': vehicleData['country'],
              'make': vehicleData['make'],
              'model': vehicleData['model'],
              'year': int.tryParse(vehicleData['year']) ?? 2020,
              'engine_cc': int.tryParse(vehicleData['engine_size']) ?? null,
              'description': vehicleData['description'],
              'cif_usd': double.tryParse(vehicleData['cif_value']) ?? 0.0,
              'database_month': 'October 2025',
              'downloaded_at': DateTime.now().toIso8601String(),
              'is_active': 1,
            });
            importedCount++;
          } else {
            skippedCount++;
          }
          
          // Progress update every 1000 records
          if (importedCount % 1000 == 0) {
            print('Imported $importedCount records...');
          }
          
        } catch (e) {
          print('Error processing row $i: $e');
          skippedCount++;
        }
      }
      
      print('Import completed: $importedCount imported, $skippedCount skipped');
      
      return {
        'success': true,
        'recordsImported': importedCount,
        'recordsSkipped': skippedCount,
        'message': 'Successfully imported $importedCount real URA vehicle records'
      };
      
    } catch (e) {
      print('Error importing URA data: $e');
      return {
        'success': false,
        'error': 'Failed to import URA data: $e',
        'recordsImported': 0
      };
    }
  }
  
  /// Extract structured vehicle data from a messy CSV row
  static Map<String, dynamic>? _extractVehicleData(List<dynamic> row) {
    try {
      // Convert row to strings and join for analysis
      final rowText = row.map((e) => e?.toString() ?? '').join(' ').trim();
      
      if (rowText.isEmpty) return null;
      
      // Initialize result
      final result = <String, dynamic>{
        'hsc_code': '',
        'country': '',
        'description': '',
        'engine_size': '',
        'cif_value': '',
        'make': '',
        'model': '',
        'year': '',
      };
      
      // Extract HSC code (looks like 8703.xx.xx)
      final hscMatch = RegExp(r'\b(87\d{2}\.\d{2}\.\d{2})\b').firstMatch(rowText);
      if (hscMatch != null) {
        result['hsc_code'] = hscMatch.group(1)!;
      }
      
      // Extract country codes (2-3 letter codes)
      final countryMatch = RegExp(r'\b([A-Z]{2,3})\b').firstMatch(rowText);
      if (countryMatch != null) {
        result['country'] = countryMatch.group(1)!;
      }
      
      // Extract year (4-digit number)
      final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(rowText);
      if (yearMatch != null) {
        result['year'] = yearMatch.group(1)!;
      }
      
      // Extract CIF value (look for dollar amounts)
      final cifMatch = RegExp(r'\$?([0-9,]+\.?\d*)\s*(?:USD|dollar)?').firstMatch(rowText);
      if (cifMatch != null) {
        result['cif_value'] = cifMatch.group(1)!.replaceAll(',', '');
      }
      
      // Extract engine size (cc, liter, hp, kw)
      final engineMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:cc|litre|liter|l|hp|kw|ton)', caseSensitive: false).firstMatch(rowText);
      if (engineMatch != null) {
        result['engine_size'] = engineMatch.group(1)!;
      }
      
      // Extract make and model from description
      final makeModelData = _extractMakeModel(rowText);
      result['make'] = makeModelData['make'];
      result['model'] = makeModelData['model'];
      
      // Set description (first 200 characters)
      result['description'] = rowText.length > 200 ? rowText.substring(0, 200) : rowText;
      
      // Only return if we have meaningful data
      if (result['description'].isNotEmpty && 
          (result['make'].isNotEmpty || result['year'].isNotEmpty || result['cif_value'].isNotEmpty)) {
        return result;
      }
      
      return null;
      
    } catch (e) {
      print('Error extracting vehicle data: $e');
      return null;
    }
  }
  
  /// Extract make and model from vehicle description
  static Map<String, String> _extractMakeModel(String description) {
    final result = {'make': '', 'model': ''};
    
    // Common vehicle makes
    final makes = [
      'Toyota', 'Honda', 'Nissan', 'Mazda', 'Subaru', 'Suzuki', 'Mitsubishi',
      'BMW', 'Mercedes', 'Audi', 'Volkswagen', 'Ford', 'Chevrolet', 'Jeep',
      'Land Rover', 'Lexus', 'Infiniti', 'Acura', 'Hyundai', 'Kia', 'Isuzu',
      'Hino', 'Mitsubishi Fuso', 'Scania', 'MAN', 'Volvo', 'DAF', 'Iveco',
      'Caterpillar', 'Komatsu', 'JCB', 'Benford', 'Bomag', 'Renault',
      'Foden', 'ERF', 'Cardillac', 'Chrysler', 'Dodge', 'Fiat', 'Jaguar',
      'Porsche', 'Lamborghini', 'Ssangyong', 'Trail King', 'SDC', 'Super Doll',
      'Hangcha', 'Howo', 'Liugong', 'Massey Ferguson', 'Fruehauf'
    ];
    
    for (final make in makes) {
      if (description.toLowerCase().contains(make.toLowerCase())) {
        result['make'] = make;
        
        // Try to extract model after make
        final makeIndex = description.toLowerCase().indexOf(make.toLowerCase());
        if (makeIndex != -1) {
          final afterMake = description.substring(makeIndex + make.length, 
              (makeIndex + make.length + 100).clamp(0, description.length));
          
          // Extract potential model (first few words after make)
          final modelParts = afterMake.split(' ').take(3).where((p) => 
              p.isNotEmpty && p.length > 1).toList();
          
          if (modelParts.isNotEmpty) {
            result['model'] = modelParts.join(' ');
          }
        }
        break;
      }
    }
    
    return result;
  }
  
  /// Get statistics about imported URA data
  static Future<Map<String, dynamic>> getUraDataStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Get total count
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM ura_cif_database');
      final totalCount = totalResult.first['count'] as int;
      
      // Get make statistics
      final makeResult = await db.rawQuery('''
        SELECT make, COUNT(*) as count 
        FROM ura_cif_database 
        WHERE make IS NOT NULL AND make != '' 
        GROUP BY make 
        ORDER BY count DESC 
        LIMIT 10
      ''');
      
      // Get year statistics
      final yearResult = await db.rawQuery('''
        SELECT year, COUNT(*) as count 
        FROM ura_cif_database 
        WHERE year IS NOT NULL AND year != '' 
        GROUP BY year 
        ORDER BY year DESC 
        LIMIT 10
      ''');
      
      // Get CIF value range
      final cifResult = await db.rawQuery('''
        SELECT 
          MIN(cif_usd) as min_cif,
          MAX(cif_usd) as max_cif,
          AVG(cif_usd) as avg_cif
        FROM ura_cif_database 
        WHERE cif_usd IS NOT NULL AND cif_usd > 0
      ''');
      
      return {
        'success': true,
        'totalRecords': totalCount,
        'topMakes': makeResult.map((row) => {
          'make': row['make'],
          'count': row['count']
        }).toList(),
        'yearDistribution': yearResult.map((row) => {
          'year': row['year'],
          'count': row['count']
        }).toList(),
        'cifStats': cifResult.isNotEmpty ? {
          'min': cifResult.first['min_cif'],
          'max': cifResult.first['max_cif'],
          'avg': cifResult.first['avg_cif']
        } : null
      };
      
    } catch (e) {
      print('Error getting URA data stats: $e');
      return {
        'success': false,
        'error': 'Failed to get URA data statistics: $e'
      };
    }
  }
}
