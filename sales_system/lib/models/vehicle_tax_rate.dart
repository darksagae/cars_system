import '../database/database_helper.dart';
import '../utils/uganda_formatters.dart';

class VehicleTaxRate {
  final int? id;
  final String make;
  final String model;
  final String? modelCode;
  final String? bodyType;
  final int yearFrom;
  final int yearTo;
  final int engineSizeCC;
  final String fuelType;
  
  // Tax components (all in UGX)
  final double fobValue;
  final double customsValue;
  final double importDuty;
  final double exciseDuty;
  final double vat;
  final double infrastructureLevy;
  final double environmentalLevy;
  final double withholdingTax;
  final double registrationFee;
  
  // Total tax
  final double totalTaxUGX;
  
  // Metadata
  final String databaseMonth;
  final DateTime importedAt;
  final String? importedBy;
  final String? sourceFile;
  final bool isActive;
  final String? notes;

  VehicleTaxRate({
    this.id,
    required this.make,
    required this.model,
    this.modelCode,
    this.bodyType,
    required this.yearFrom,
    required this.yearTo,
    required this.engineSizeCC,
    required this.fuelType,
    required this.fobValue,
    required this.customsValue,
    required this.importDuty,
    required this.exciseDuty,
    required this.vat,
    this.infrastructureLevy = 0.0,
    this.environmentalLevy = 0.0,
    this.withholdingTax = 0.0,
    this.registrationFee = 0.0,
    required this.totalTaxUGX,
    required this.databaseMonth,
    required this.importedAt,
    this.importedBy,
    this.sourceFile,
    this.isActive = true,
    this.notes,
  });

  // Convert from database map
  factory VehicleTaxRate.fromMap(Map<String, dynamic> map) {
    return VehicleTaxRate(
      id: map['id'] as int?,
      make: map['make'] as String,
      model: map['model'] as String,
      modelCode: map['modelCode'] as String?,
      bodyType: map['bodyType'] as String?,
      yearFrom: map['yearFrom'] as int,
      yearTo: map['yearTo'] as int,
      engineSizeCC: map['engineSizeCC'] as int,
      fuelType: map['fuelType'] as String,
      fobValue: (map['fobValue'] as num).toDouble(),
      customsValue: (map['customsValue'] as num).toDouble(),
      importDuty: (map['importDuty'] as num).toDouble(),
      exciseDuty: (map['exciseDuty'] as num).toDouble(),
      vat: (map['vat'] as num).toDouble(),
      infrastructureLevy: (map['infrastructureLevy'] as num?)?.toDouble() ?? 0.0,
      environmentalLevy: (map['environmentalLevy'] as num?)?.toDouble() ?? 0.0,
      withholdingTax: (map['withholdingTax'] as num?)?.toDouble() ?? 0.0,
      registrationFee: (map['registrationFee'] as num?)?.toDouble() ?? 0.0,
      totalTaxUGX: (map['totalTaxUGX'] as num).toDouble(),
      databaseMonth: map['databaseMonth'] as String,
      importedAt: DateTime.parse(map['importedAt'] as String),
      importedBy: map['importedBy'] as String?,
      sourceFile: map['sourceFile'] as String?,
      isActive: (map['isActive'] as int) == 1,
      notes: map['notes'] as String?,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'modelCode': modelCode,
      'bodyType': bodyType,
      'yearFrom': yearFrom,
      'yearTo': yearTo,
      'engineSizeCC': engineSizeCC,
      'fuelType': fuelType,
      'fobValue': fobValue,
      'customsValue': customsValue,
      'importDuty': importDuty,
      'exciseDuty': exciseDuty,
      'vat': vat,
      'infrastructureLevy': infrastructureLevy,
      'environmentalLevy': environmentalLevy,
      'withholdingTax': withholdingTax,
      'registrationFee': registrationFee,
      'totalTaxUGX': totalTaxUGX,
      'databaseMonth': databaseMonth,
      'importedAt': importedAt.toIso8601String(),
      'importedBy': importedBy,
      'sourceFile': sourceFile,
      'isActive': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  // Display formatted tax breakdown
  String get taxBreakdown {
    final buffer = StringBuffer();
    buffer.writeln('📊 Tax Breakdown for $make $model ($yearFrom-$yearTo)');
    buffer.writeln('Engine: ${engineSizeCC} CC • Fuel: $fuelType');
    if (modelCode != null) buffer.writeln('Model Code: $modelCode');
    buffer.writeln('');
    buffer.writeln('FOB Value: ${UgandaFormatters.formatCurrency(fobValue)}');
    buffer.writeln('Customs Value: ${UgandaFormatters.formatCurrency(customsValue)}');
    buffer.writeln('Import Duty: ${UgandaFormatters.formatCurrency(importDuty)}');
    buffer.writeln('Excise Duty: ${UgandaFormatters.formatCurrency(exciseDuty)}');
    buffer.writeln('VAT (18%): ${UgandaFormatters.formatCurrency(vat)}');
    if (infrastructureLevy > 0) {
      buffer.writeln('Infrastructure Levy: ${UgandaFormatters.formatCurrency(infrastructureLevy)}');
    }
    if (environmentalLevy > 0) {
      buffer.writeln('Environmental Levy: ${UgandaFormatters.formatCurrency(environmentalLevy)}');
    }
    if (withholdingTax > 0) {
      buffer.writeln('Withholding Tax: ${UgandaFormatters.formatCurrency(withholdingTax)}');
    }
    if (registrationFee > 0) {
      buffer.writeln('Registration Fee: ${UgandaFormatters.formatCurrency(registrationFee)}');
    }
    buffer.writeln('');
    buffer.writeln('═══════════════════════════════');
    buffer.writeln('TOTAL TAX: ${UgandaFormatters.formatCurrency(totalTaxUGX)}');
    buffer.writeln('Database: $databaseMonth');
    return buffer.toString();
  }

  // Formatted display name
  String get displayName {
    final code = modelCode != null ? ' ($modelCode)' : '';
    return '$make $model$code - $yearFrom-$yearTo - ${engineSizeCC}CC';
  }

  // Year range display
  String get yearRange {
    if (yearFrom == yearTo) return yearFrom.toString();
    return '$yearFrom-$yearTo';
  }

  // Copy with method
  VehicleTaxRate copyWith({
    int? id,
    String? make,
    String? model,
    String? modelCode,
    String? bodyType,
    int? yearFrom,
    int? yearTo,
    int? engineSizeCC,
    String? fuelType,
    double? fobValue,
    double? customsValue,
    double? importDuty,
    double? exciseDuty,
    double? vat,
    double? infrastructureLevy,
    double? environmentalLevy,
    double? withholdingTax,
    double? registrationFee,
    double? totalTaxUGX,
    String? databaseMonth,
    DateTime? importedAt,
    String? importedBy,
    String? sourceFile,
    bool? isActive,
    String? notes,
  }) {
    return VehicleTaxRate(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      modelCode: modelCode ?? this.modelCode,
      bodyType: bodyType ?? this.bodyType,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      engineSizeCC: engineSizeCC ?? this.engineSizeCC,
      fuelType: fuelType ?? this.fuelType,
      fobValue: fobValue ?? this.fobValue,
      customsValue: customsValue ?? this.customsValue,
      importDuty: importDuty ?? this.importDuty,
      exciseDuty: exciseDuty ?? this.exciseDuty,
      vat: vat ?? this.vat,
      infrastructureLevy: infrastructureLevy ?? this.infrastructureLevy,
      environmentalLevy: environmentalLevy ?? this.environmentalLevy,
      withholdingTax: withholdingTax ?? this.withholdingTax,
      registrationFee: registrationFee ?? this.registrationFee,
      totalTaxUGX: totalTaxUGX ?? this.totalTaxUGX,
      databaseMonth: databaseMonth ?? this.databaseMonth,
      importedAt: importedAt ?? this.importedAt,
      importedBy: importedBy ?? this.importedBy,
      sourceFile: sourceFile ?? this.sourceFile,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  // Database operations
  
  /// Lookup tax rate by vehicle details
  static Future<VehicleTaxRate?> findTaxRate({
    required String make,
    required String model,
    required int year,
    required int engineSizeCC,
    String? modelCode,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      
      // Build query with flexible matching
      String query = '''
        SELECT * FROM vehicle_tax_rates
        WHERE UPPER(make) = UPPER(?)
        AND UPPER(model) = UPPER(?)
        AND yearFrom <= ?
        AND yearTo >= ?
        AND engineSizeCC = ?
        AND isActive = 1
      ''';
      
      List<dynamic> params = [make, model, year, year, engineSizeCC];
      
      // Add model code if provided
      if (modelCode != null && modelCode.isNotEmpty) {
        query += ' AND UPPER(modelCode) = UPPER(?)';
        params.add(modelCode);
      }
      
      query += ' ORDER BY importedAt DESC LIMIT 1';
      
      final result = await db.rawQuery(query, params);
      
      if (result.isNotEmpty) {
        return VehicleTaxRate.fromMap(result.first);
      }
      
      // If exact match not found, try without model code
      if (modelCode != null) {
        return await findTaxRate(
          make: make,
          model: model,
          year: year,
          engineSizeCC: engineSizeCC,
        );
      }
      
      return null;
    } catch (e) {
      print('Error finding tax rate: $e');
      return null;
    }
  }

  /// Find closest matching tax rate (fuzzy search)
  static Future<VehicleTaxRate?> findClosestTaxRate({
    required String make,
    required String model,
    required int year,
    required int engineSizeCC,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      
      // Try exact match first
      var taxRate = await findTaxRate(
        make: make,
        model: model,
        year: year,
        engineSizeCC: engineSizeCC,
      );
      
      if (taxRate != null) return taxRate;
      
      // Try with engine size tolerance (±100 CC)
      final query = '''
        SELECT * FROM vehicle_tax_rates
        WHERE UPPER(make) = UPPER(?)
        AND UPPER(model) = UPPER(?)
        AND yearFrom <= ?
        AND yearTo >= ?
        AND engineSizeCC BETWEEN ? AND ?
        AND isActive = 1
        ORDER BY ABS(engineSizeCC - ?) ASC, importedAt DESC
        LIMIT 1
      ''';
      
      final result = await db.rawQuery(query, [
        make,
        model,
        year,
        year,
        engineSizeCC - 100,
        engineSizeCC + 100,
        engineSizeCC,
      ]);
      
      if (result.isNotEmpty) {
        return VehicleTaxRate.fromMap(result.first);
      }
      
      return null;
    } catch (e) {
      print('Error finding closest tax rate: $e');
      return null;
    }
  }

  /// Get all tax rates for a specific vehicle make/model
  static Future<List<VehicleTaxRate>> getAllRatesForVehicle({
    required String make,
    required String model,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      
      final result = await db.rawQuery('''
        SELECT * FROM vehicle_tax_rates
        WHERE UPPER(make) = UPPER(?)
        AND UPPER(model) = UPPER(?)
        AND isActive = 1
        ORDER BY yearFrom DESC, engineSizeCC ASC
      ''', [make, model]);
      
      return result.map((map) => VehicleTaxRate.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all rates for vehicle: $e');
      return [];
    }
  }

  /// Insert tax rate into database
  Future<int?> insert() async {
    try {
      final db = await DatabaseHelper().database;
      final id = await db.insert('vehicle_tax_rates', toMap());
      return id;
    } catch (e) {
      print('Error inserting tax rate: $e');
      return null;
    }
  }

  /// Update tax rate in database
  Future<bool> update() async {
    try {
      final db = await DatabaseHelper().database;
      final count = await db.update(
        'vehicle_tax_rates',
        toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      print('Error updating tax rate: $e');
      return false;
    }
  }

  /// Delete tax rate from database
  Future<bool> delete() async {
    try {
      final db = await DatabaseHelper().database;
      final count = await db.delete(
        'vehicle_tax_rates',
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      print('Error deleting tax rate: $e');
      return false;
    }
  }

  /// Archive old tax rates (set isActive = 0)
  static Future<int> archiveOldRates(String currentMonth) async {
    try {
      final db = await DatabaseHelper().database;
      final count = await db.rawUpdate('''
        UPDATE vehicle_tax_rates
        SET isActive = 0
        WHERE databaseMonth != ?
      ''', [currentMonth]);
      return count;
    } catch (e) {
      print('Error archiving old rates: $e');
      return 0;
    }
  }

  /// Get count of active tax rates
  static Future<int> getActiveCount() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM vehicle_tax_rates
        WHERE isActive = 1
      ''');
      if (result.isNotEmpty && result.first['count'] != null) {
        return result.first['count'] as int;
      }
      return 0;
    } catch (e) {
      print('Error getting active count: $e');
      return 0;
    }
  }

  /// Get current database month
  static Future<String?> getCurrentDatabaseMonth() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.rawQuery('''
        SELECT databaseMonth FROM vehicle_tax_rates
        WHERE isActive = 1
        ORDER BY importedAt DESC
        LIMIT 1
      ''');
      
      if (result.isNotEmpty) {
        return result.first['databaseMonth'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting current database month: $e');
      return null;
    }
  }
}

