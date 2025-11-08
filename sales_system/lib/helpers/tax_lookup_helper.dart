import '../models/vehicle_tax_rate.dart';

/// Helper class for smart tax rate lookups
class TaxLookupHelper {
  /// Lookup tax rate with exact matching
  static Future<VehicleTaxRate?> lookup({
    required String make,
    required String model,
    required int year,
    required int engineSizeCC,
    String? modelCode,
  }) async {
    try {
      // Try exact match first
      var taxRate = await VehicleTaxRate.findTaxRate(
        make: make,
        model: model,
        year: year,
        engineSizeCC: engineSizeCC,
        modelCode: modelCode,
      );
      
      if (taxRate != null) {
        return taxRate;
      }
      
      // If no exact match, try fuzzy search
      return await VehicleTaxRate.findClosestTaxRate(
        make: make,
        model: model,
        year: year,
        engineSizeCC: engineSizeCC,
      );
    } catch (e) {
      print('Error in tax lookup: $e');
      return null;
    }
  }

  /// Get all available tax rates for a vehicle
  static Future<List<VehicleTaxRate>> getAllRatesForVehicle({
    required String make,
    required String model,
  }) async {
    return await VehicleTaxRate.getAllRatesForVehicle(
      make: make,
      model: model,
    );
  }

  /// Parse engine size string to CC integer
  /// Examples: "3,500 C.C" → 3500, "2.0L" → 2000, "1500cc" → 1500
  static int parseEngineSize(String engineSizeStr) {
    try {
      // Remove common suffixes and separators
      String cleaned = engineSizeStr
          .toUpperCase()
          .replaceAll('C.C', '')
          .replaceAll('CC', '')
          .replaceAll('L', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();
      
      // If it's a decimal (like 2.0), multiply by 1000
      if (cleaned.contains('.')) {
        double liters = double.parse(cleaned);
        return (liters * 1000).round();
      }
      
      // Otherwise, parse as integer
      return int.parse(cleaned);
    } catch (e) {
      print('Error parsing engine size "$engineSizeStr": $e');
      return 0;
    }
  }

  /// Format engine size for display
  /// Examples: 3500 → "3,500 C.C", 2000 → "2,000 C.C"
  static String formatEngineSize(int engineSizeCC) {
    if (engineSizeCC == 0) return 'Unknown';
    return '${_formatNumber(engineSizeCC)} C.C';
  }

  /// Format number with thousands separator
  static String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    
    return buffer.toString();
  }

  /// Normalize make/model names for better matching
  /// Examples: "toyota " → "Toyota", "HONDA" → "Honda"
  static String normalizeName(String name) {
    if (name.isEmpty) return name;
    
    return name.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Get suggested tax rate based on similar vehicles
  static Future<VehicleTaxRate?> getSuggestedRate({
    required String make,
    required String model,
    required int year,
    required int engineSizeCC,
  }) async {
    try {
      // Get all rates for this make/model
      final rates = await getAllRatesForVehicle(make: make, model: model);
      
      if (rates.isEmpty) return null;
      
      // Find the closest match based on year and engine size
      VehicleTaxRate? closest;
      int minDifference = 999999;
      
      for (final rate in rates) {
        // Check if year is in range
        if (year >= rate.yearFrom && year <= rate.yearTo) {
          // Calculate engine size difference
          final engineDiff = (rate.engineSizeCC - engineSizeCC).abs();
          
          if (engineDiff < minDifference) {
            minDifference = engineDiff;
            closest = rate;
          }
        }
      }
      
      // If no match in year range, find closest year range
      if (closest == null && rates.isNotEmpty) {
        for (final rate in rates) {
          final yearDiff = (rate.yearFrom - year).abs();
          final engineDiff = (rate.engineSizeCC - engineSizeCC).abs();
          final totalDiff = yearDiff * 100 + engineDiff; // Weight year more
          
          if (totalDiff < minDifference) {
            minDifference = totalDiff;
            closest = rate;
          }
        }
      }
      
      return closest;
    } catch (e) {
      print('Error getting suggested rate: $e');
      return null;
    }
  }

  /// Validate vehicle details before lookup
  static String? validateVehicleDetails({
    required String make,
    required String model,
    required String year,
    required String engineSize,
  }) {
    if (make.trim().isEmpty) {
      return 'Please enter vehicle make';
    }
    
    if (model.trim().isEmpty) {
      return 'Please enter vehicle model';
    }
    
    if (year.trim().isEmpty) {
      return 'Please enter vehicle year';
    }
    
    final yearInt = int.tryParse(year);
    if (yearInt == null || yearInt < 1900 || yearInt > DateTime.now().year + 1) {
      return 'Please enter a valid year';
    }
    
    if (engineSize.trim().isEmpty) {
      return 'Please enter engine size';
    }
    
    final engineCC = parseEngineSize(engineSize);
    if (engineCC == 0) {
      return 'Please enter a valid engine size';
    }
    
    return null; // No errors
  }

  /// Get current database month info
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final currentMonth = await VehicleTaxRate.getCurrentDatabaseMonth();
      final activeCount = await VehicleTaxRate.getActiveCount();
      
      return {
        'currentMonth': currentMonth ?? 'No database loaded',
        'activeCount': activeCount,
        'hasData': activeCount > 0,
      };
    } catch (e) {
      print('Error getting database info: $e');
      return {
        'currentMonth': 'Error',
        'activeCount': 0,
        'hasData': false,
      };
    }
  }
}


