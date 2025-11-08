import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';
import '../models/ura_vehicle.dart';

/// Enhanced URA lookup service with S/N validation and data correction capabilities
class EnhancedUraLookupService {
  static final EnhancedUraLookupService _instance = EnhancedUraLookupService._internal();
  factory EnhancedUraLookupService() => _instance;
  EnhancedUraLookupService._internal();

  /// Search for vehicles with S/N validation
  Future<List<UraVehicle>> searchVehiclesWithSNValidation({
    String? make,
    String? model,
    int? year,
    int? engineCC,
    String? serialNumber,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      
      String query = '''
        SELECT * FROM ura_cif_database 
        WHERE is_active = 1
      ''';
      
      List<dynamic> params = [];
      
      if (make != null && make.isNotEmpty) {
        query += ' AND UPPER(make) LIKE UPPER(?)';
        params.add('%$make%');
      }
      
      if (model != null && model.isNotEmpty) {
        query += ' AND UPPER(model) LIKE UPPER(?)';
        params.add('%$model%');
      }
      
      if (year != null) {
        query += ' AND year = ?';
        params.add(year);
      }
      
      if (engineCC != null) {
        query += ' AND engine_cc = ?';
        params.add(engineCC);
      }
      
      if (serialNumber != null && serialNumber.isNotEmpty) {
        query += ' AND serial_number = ?';
        params.add(serialNumber);
      }
      
      query += ' ORDER BY downloaded_at DESC';
      
      final result = await db.rawQuery(query, params);
      
      return result.map((row) => UraVehicle.fromMap(row)).toList();
    } catch (e) {
      print('Error searching vehicles with S/N validation: $e');
      return [];
    }
  }

  /// Find vehicle by exact S/N match for data validation
  Future<UraVehicle?> findVehicleBySerialNumber(String serialNumber) async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.query(
        'ura_cif_database',
        where: 'serial_number = ? AND is_active = 1',
        whereArgs: [serialNumber],
        orderBy: 'downloaded_at DESC',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return UraVehicle.fromMap(result.first);
      }
      
      return null;
    } catch (e) {
      print('Error finding vehicle by S/N: $e');
      return null;
    }
  }

  /// Validate and correct vehicle data using S/N
  Future<UraVehicleValidationResult> validateVehicleData({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    required double cifUSD,
    String? serialNumber,
  }) async {
    try {
      // If S/N is provided, use it for exact validation
      if (serialNumber != null && serialNumber.isNotEmpty) {
        final snVehicle = await findVehicleBySerialNumber(serialNumber);
        
        if (snVehicle != null) {
          // Validate all data against S/N record
          final isDataCorrect = _validateDataAgainstSN(
            make: make,
            model: model,
            year: year,
            engineCC: engineCC,
            cifUSD: cifUSD,
            snVehicle: snVehicle,
          );
          
          return UraVehicleValidationResult(
            isValid: isDataCorrect,
            correctedVehicle: isDataCorrect ? null : snVehicle,
            confidence: isDataCorrect ? 1.0 : 0.9,
            validationMethod: 'serial_number',
            serialNumber: serialNumber,
            issues: isDataCorrect ? [] : _identifyDataIssues(
              make: make,
              model: model,
              year: year,
              engineCC: engineCC,
              cifUSD: cifUSD,
              snVehicle: snVehicle,
            ),
          );
        }
      }
      
      // Fallback to fuzzy matching if no S/N or S/N not found
      final fuzzyVehicles = await searchVehiclesWithSNValidation(
        make: make,
        model: model,
        year: year,
        engineCC: engineCC,
      );
      
      if (fuzzyVehicles.isNotEmpty) {
        final bestMatch = fuzzyVehicles.first;
        final confidence = _calculateMatchConfidence(
          make: make,
          model: model,
          year: year,
          engineCC: engineCC,
          cifUSD: cifUSD,
          matchVehicle: bestMatch,
        );
        
        return UraVehicleValidationResult(
          isValid: confidence > 0.8,
          correctedVehicle: confidence > 0.8 ? bestMatch : null,
          confidence: confidence,
          validationMethod: 'fuzzy_match',
          serialNumber: bestMatch.serialNumber,
          issues: confidence > 0.8 ? [] : _identifyDataIssues(
            make: make,
            model: model,
            year: year,
            engineCC: engineCC,
            cifUSD: cifUSD,
            snVehicle: bestMatch,
          ),
        );
      }
      
      return UraVehicleValidationResult(
        isValid: false,
        correctedVehicle: null,
        confidence: 0.0,
        validationMethod: 'no_match',
        serialNumber: serialNumber,
        issues: ['No matching vehicle found in database'],
      );
    } catch (e) {
      print('Error validating vehicle data: $e');
      return UraVehicleValidationResult(
        isValid: false,
        correctedVehicle: null,
        confidence: 0.0,
        validationMethod: 'error',
        serialNumber: serialNumber,
        issues: ['Validation error: $e'],
      );
    }
  }

  /// Validate data against S/N record
  bool _validateDataAgainstSN({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    required double cifUSD,
    required UraVehicle snVehicle,
  }) {
    // Check if all data matches exactly
    return snVehicle.make.toLowerCase() == make.toLowerCase() &&
           snVehicle.model.toLowerCase() == model.toLowerCase() &&
           snVehicle.year == year &&
           snVehicle.engineCC == engineCC &&
           (snVehicle.cifUsd - cifUSD).abs() < 0.01; // Allow small floating point differences
  }

  /// Calculate match confidence for fuzzy matching
  double _calculateMatchConfidence({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    required double cifUSD,
    required UraVehicle matchVehicle,
  }) {
    double confidence = 0.0;
    
    // Make match (40% weight)
    if (matchVehicle.make.toLowerCase().contains(make.toLowerCase()) ||
        make.toLowerCase().contains(matchVehicle.make.toLowerCase())) {
      confidence += 0.4;
    }
    
    // Model match (30% weight)
    if (matchVehicle.model.toLowerCase().contains(model.toLowerCase()) ||
        model.toLowerCase().contains(matchVehicle.model.toLowerCase())) {
      confidence += 0.3;
    }
    
    // Year match (20% weight)
    if (matchVehicle.year == year) {
      confidence += 0.2;
    }
    
    // Engine match (10% weight)
    if (matchVehicle.engineCC == engineCC) {
      confidence += 0.1;
    }
    
    return confidence;
  }

  /// Identify specific data issues
  List<String> _identifyDataIssues({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    required double cifUSD,
    required UraVehicle snVehicle,
  }) {
    final issues = <String>[];
    
    if (snVehicle.make.toLowerCase() != make.toLowerCase()) {
      issues.add('Make mismatch: Expected "${snVehicle.make}", got "$make"');
    }
    
    if (snVehicle.model.toLowerCase() != model.toLowerCase()) {
      issues.add('Model mismatch: Expected "${snVehicle.model}", got "$model"');
    }
    
    if (snVehicle.year != year) {
      issues.add('Year mismatch: Expected ${snVehicle.year}, got $year');
    }
    
    if (snVehicle.engineCC != engineCC) {
      issues.add('Engine size mismatch: Expected ${snVehicle.engineCC}cc, got ${engineCC}cc');
    }
    
    if ((snVehicle.cifUsd - cifUSD).abs() > 0.01) {
      issues.add('CIF value mismatch: Expected \$${snVehicle.cifUsd.toStringAsFixed(2)}, got \$${cifUSD.toStringAsFixed(2)}');
    }
    
    return issues;
  }

  /// Get all available serial numbers for validation
  Future<List<String>> getAllSerialNumbers() async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.rawQuery('''
        SELECT DISTINCT serial_number 
        FROM ura_cif_database 
        WHERE serial_number IS NOT NULL 
        AND serial_number != '' 
        AND is_active = 1
        ORDER BY serial_number
      ''');
      
      return result.map((row) => row['serial_number'] as String).toList();
    } catch (e) {
      print('Error getting serial numbers: $e');
      return [];
    }
  }

  /// Search vehicles by partial S/N
  Future<List<UraVehicle>> searchVehiclesByPartialSN(String partialSN) async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.query(
        'ura_cif_database',
        where: 'serial_number LIKE ? AND is_active = 1',
        whereArgs: ['%$partialSN%'],
        orderBy: 'serial_number ASC',
        limit: 50,
      );
      
      return result.map((row) => UraVehicle.fromMap(row)).toList();
    } catch (e) {
      print('Error searching vehicles by partial S/N: $e');
      return [];
    }
  }
}

/// Result of vehicle data validation
class UraVehicleValidationResult {
  final bool isValid;
  final UraVehicle? correctedVehicle;
  final double confidence;
  final String validationMethod;
  final String? serialNumber;
  final List<String> issues;

  UraVehicleValidationResult({
    required this.isValid,
    this.correctedVehicle,
    required this.confidence,
    required this.validationMethod,
    this.serialNumber,
    required this.issues,
  });

  /// Get a user-friendly validation message
  String getValidationMessage() {
    if (isValid) {
      return '✅ Data validated successfully using ${validationMethod == 'serial_number' ? 'S/N' : 'database matching'}';
    } else if (correctedVehicle != null) {
      return '⚠️ Data issues found. S/N ${serialNumber ?? 'N/A'} suggests corrections needed.';
    } else {
      return '❌ No matching vehicle found in database';
    }
  }

  /// Get detailed correction suggestions
  String getCorrectionSuggestions() {
    if (issues.isEmpty) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('Suggested corrections based on S/N ${serialNumber ?? 'N/A'}:');
    buffer.writeln();
    
    for (final issue in issues) {
      buffer.writeln('• $issue');
    }
    
    if (correctedVehicle != null) {
      buffer.writeln();
      buffer.writeln('Recommended values:');
      buffer.writeln('• Make: ${correctedVehicle!.make}');
      buffer.writeln('• Model: ${correctedVehicle!.model}');
      buffer.writeln('• Year: ${correctedVehicle!.year}');
      buffer.writeln('• Engine: ${correctedVehicle!.engineCC}cc');
      buffer.writeln('• CIF: \$${correctedVehicle!.cifUsd.toStringAsFixed(2)}');
    }
    
    return buffer.toString();
  }
}
