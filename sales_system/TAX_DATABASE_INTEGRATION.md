# 🚗 MV DATABASE TAX INTEGRATION - COMPLETE SPECIFICATION

## 📋 OVERVIEW

This document outlines the integration of the monthly-updated "MV Database" (Motor Vehicle Tax Database) into the NSB Motors sales system.

### Purpose
- Import monthly tax rates from URA/MV Database PDF/Excel
- Auto-lookup taxes when creating invoices
- Keep historical tax data for auditing
- Update tax rates monthly without code changes

---

## 🗄️ DATABASE SCHEMA

### 1. Vehicle Tax Rates Table
```sql
CREATE TABLE vehicle_tax_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  -- Vehicle Identification
  make TEXT NOT NULL,              -- "Toyota", "Suzuki", "Honda"
  model TEXT NOT NULL,             -- "Wish", "Swift", "CR-V"
  modelCode TEXT,                  -- "ACU 30", "ACU 35", "ZGE 20"
  bodyType TEXT,                   -- "Sedan", "SUV", "Hatchback"
  yearFrom INTEGER NOT NULL,       -- 2010
  yearTo INTEGER NOT NULL,         -- 2015
  engineSizeCC INTEGER NOT NULL,   -- 1500, 2000, 3500
  fuelType TEXT NOT NULL,          -- "Petrol", "Diesel", "Hybrid"
  
  -- Tax Components (all in UGX)
  fobValue REAL NOT NULL,          -- Free On Board value (base price)
  customsValue REAL NOT NULL,      -- Assessed customs value
  importDuty REAL NOT NULL,        -- Import duty amount
  exciseDuty REAL NOT NULL,        -- Excise duty amount
  vat REAL NOT NULL,               -- VAT (18%)
  infrastructureLevy REAL,         -- Infrastructure levy
  environmentalLevy REAL,          -- Environmental levy
  withholdingTax REAL,             -- Withholding tax (if applicable)
  registrationFee REAL,            -- Registration fee
  
  -- Total Tax (this goes to invoice)
  totalTaxUGX REAL NOT NULL,       -- SUM of all tax components
  
  -- Metadata
  databaseMonth TEXT NOT NULL,     -- "October 2025", "November 2025"
  importedAt TEXT NOT NULL,        -- ISO8601 timestamp
  importedBy TEXT,                 -- Admin username
  sourceFile TEXT,                 -- "MV Database October 2025.pdf"
  isActive INTEGER DEFAULT 1,      -- 1=current month, 0=archived
  notes TEXT,                      -- Additional notes
  
  -- Constraints
  UNIQUE(make, model, modelCode, yearFrom, yearTo, engineSizeCC, databaseMonth),
  CHECK(yearFrom <= yearTo),
  CHECK(totalTaxUGX >= 0)
);

-- Performance Indexes
CREATE INDEX idx_tax_make_model ON vehicle_tax_rates(make, model);
CREATE INDEX idx_tax_year_range ON vehicle_tax_rates(yearFrom, yearTo);
CREATE INDEX idx_tax_engine_size ON vehicle_tax_rates(engineSizeCC);
CREATE INDEX idx_tax_active ON vehicle_tax_rates(isActive);
CREATE INDEX idx_tax_month ON vehicle_tax_rates(databaseMonth, isActive);
CREATE INDEX idx_tax_lookup ON vehicle_tax_rates(make, model, yearFrom, yearTo, engineSizeCC, isActive);
```

### 2. Tax Import History Table
```sql
CREATE TABLE tax_import_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fileName TEXT NOT NULL,          -- "MV Database October 2025.pdf"
  importMonth TEXT NOT NULL,       -- "October 2025"
  importedAt TEXT NOT NULL,        -- ISO8601 timestamp
  importedBy TEXT,                 -- Admin username
  recordsImported INTEGER NOT NULL, -- Number of tax rates imported
  recordsUpdated INTEGER,          -- Number of existing records updated
  recordsFailed INTEGER,           -- Number that failed to import
  status TEXT NOT NULL,            -- "success", "partial", "failed"
  errorLog TEXT,                   -- Error messages if any
  notes TEXT,
  
  CHECK(status IN ('success', 'partial', 'failed'))
);
```

---

## 🔧 IMPLEMENTATION COMPONENTS

### A. Tax Rate Model (`lib/models/vehicle_tax_rate.dart`)
```dart
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
  
  // Tax components
  final double fobValue;
  final double customsValue;
  final double importDuty;
  final double exciseDuty;
  final double vat;
  final double? infrastructureLevy;
  final double? environmentalLevy;
  final double? withholdingTax;
  final double? registrationFee;
  
  // Total
  final double totalTaxUGX;
  
  // Metadata
  final String databaseMonth;
  final DateTime importedAt;
  final String? importedBy;
  final String? sourceFile;
  final bool isActive;
  final String? notes;

  VehicleTaxRate({...});
  
  // Lookup method
  static Future<VehicleTaxRate?> findTaxRate({
    required String make,
    required String model,
    required int year,
    required int engineSizeCC,
  }) async {
    // Query database for matching tax rate
    // Return most recent active rate
  }
  
  // Display formatted tax breakdown
  String get taxBreakdown {
    return '''
FOB Value: ${UgandaFormatters.formatCurrency(fobValue)}
Import Duty: ${UgandaFormatters.formatCurrency(importDuty)}
Excise Duty: ${UgandaFormatters.formatCurrency(exciseDuty)}
VAT: ${UgandaFormatters.formatCurrency(vat)}
Infrastructure Levy: ${UgandaFormatters.formatCurrency(infrastructureLevy ?? 0)}
Total Tax: ${UgandaFormatters.formatCurrency(totalTaxUGX)}
    ''';
  }
}
```

### B. Tax Import Service (`lib/services/tax_import_service.dart`)
```dart
class TaxImportService {
  // Import from PDF (using pdf parser)
  Future<TaxImportResult> importFromPDF(String filePath) async {
    // 1. Parse PDF
    // 2. Extract vehicle data & tax rates
    // 3. Validate data
    // 4. Mark old data as inactive (isActive = 0)
    // 5. Insert new data (isActive = 1)
    // 6. Log import history
  }
  
  // Import from Excel (using excel package)
  Future<TaxImportResult> importFromExcel(String filePath) async {
    // Similar to PDF import
  }
  
  // Import from CSV
  Future<TaxImportResult> importFromCSV(String filePath) async {
    // Simplest format for testing
  }
  
  // Archive old month's data
  Future<void> archiveOldData(String currentMonth) async {
    // Set isActive = 0 for all records where databaseMonth != currentMonth
  }
  
  // Get import history
  Future<List<TaxImportHistory>> getImportHistory() async {}
}
```

### C. Tax Lookup Helper (`lib/helpers/tax_lookup_helper.dart`)
```dart
class TaxLookupHelper {
  // Smart lookup with fuzzy matching
  static Future<VehicleTaxRate?> lookup({
    required String make,
    required String model,
    required int year,
    required int engineSizeCC,
    String? modelCode,
  }) async {
    // 1. Try exact match first
    // 2. Try with year range (yearFrom <= year <= yearTo)
    // 3. Try with closest engine size (±100 CC)
    // 4. Return null if no match
  }
  
  // Get all tax rates for a vehicle (different years/engine sizes)
  static Future<List<VehicleTaxRate>> getAllRatesForVehicle({
    required String make,
    required String model,
  }) async {}
  
  // Get suggested tax based on similar vehicles
  static Future<VehicleTaxRate?> getSuggestedRate({
    required String make,
    required String model,
    required int year,
    required int engineSizeCC,
  }) async {
    // Use ML or weighted average from similar vehicles
  }
}
```

---

## 🎨 USER INTERFACE CHANGES

### 1. Tax Import Screen (`lib/screens/tax_import_screen.dart`)

```
┌─────────────────────────────────────────────┐
│  📊 Tax Database Import                     │
├─────────────────────────────────────────────┤
│                                              │
│  Current Database: October 2025              │
│  Last Updated: 2025-10-15 10:30 AM          │
│  Total Tax Rates: 1,247                     │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  📁 Select File to Import              │ │
│  │  [Choose File] MV Database Nov 2025.pdf│ │
│  └────────────────────────────────────────┘ │
│                                              │
│  Database Month: [November 2025 ▼]          │
│                                              │
│  [ ] Mark as active (archive October data)  │
│  [ ] Keep old data for reference            │
│                                              │
│  [📥 Import Tax Database]                   │
│                                              │
│  ── Import History ──────────────────────   │
│  📅 October 2025 - 1,247 records ✓          │
│  📅 September 2025 - 1,198 records ✓        │
│  📅 August 2025 - 1,156 records ✓           │
│                                              │
└─────────────────────────────────────────────┘
```

### 2. Enhanced Invoice Form - Tax Lookup

```dart
// In invoice_form_screen.dart

// Add tax lookup button
Row(
  children: [
    Expanded(
      child: TextField(
        controller: _taxesURAController,
        label: 'Taxes Payable to URA (UGX)',
        onChanged: (value) => _calculateSecondInstallment(),
      ),
    ),
    SizedBox(width: 12),
    ElevatedButton.icon(
      icon: Icon(Icons.search),
      label: Text('Auto-Lookup'),
      onPressed: _autoLookupTax,
    ),
  ],
)

// Auto-lookup function
Future<void> _autoLookupTax() async {
  if (_makeController.text.isEmpty || 
      _yearController.text.isEmpty) {
    showError('Please enter vehicle make and year first');
    return;
  }
  
  // Extract engine size (e.g., "3,500 C.C" → 3500)
  final engineCC = _parseEngineSize(_engineSizeController.text);
  
  // Lookup tax
  final taxRate = await TaxLookupHelper.lookup(
    make: _makeController.text,
    model: _modelController.text,
    year: int.parse(_yearController.text),
    engineSizeCC: engineCC,
  );
  
  if (taxRate != null) {
    setState(() {
      _taxesURAController.text = taxRate.totalTaxUGX.toString();
      _calculateSecondInstallment();
    });
    
    // Show breakdown
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tax Breakdown'),
        content: Text(taxRate.taxBreakdown),
        actions: [
          TextButton(
            child: Text('Use This Amount'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tax Not Found'),
        content: Text('No tax rate found for this vehicle. Please enter manually.'),
      ),
    );
  }
}
```

---

## 📊 DATA FLOW

### Monthly Update Flow
```
1. Admin receives "MV Database November 2025.pdf"
   ↓
2. Opens Tax Import Screen
   ↓
3. Selects file and imports
   ↓
4. System:
   - Parses PDF/Excel
   - Validates data
   - Archives October data (isActive = 0)
   - Imports November data (isActive = 1)
   - Logs import history
   ↓
5. All new invoices use November rates
6. Old invoices keep their original tax amounts
```

### Invoice Creation Flow
```
1. User enters vehicle details
   ↓
2. User clicks "Auto-Lookup Tax"
   ↓
3. System queries vehicle_tax_rates WHERE:
   - make = 'Suzuki'
   - model = 'Swift'
   - yearFrom <= 2012 <= yearTo
   - engineSizeCC ≈ 3500
   - isActive = 1
   ↓
4. Returns matching tax rate
   ↓
5. Auto-fills tax amount
6. User can override if needed
   ↓
7. Invoice saved with tax amount
```

---

## 🔄 MIGRATION PLAN

### Step 1: Add Database Tables
Update `database_helper.dart` version to 4:
```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 4) {
    // Create vehicle_tax_rates table
    // Create tax_import_history table
  }
}
```

### Step 2: Create Models & Services
- `VehicleTaxRate` model
- `TaxImportHistory` model
- `TaxImportService`
- `TaxLookupHelper`

### Step 3: Build Import UI
- Tax Import Screen
- Import history viewer
- Tax rate browser

### Step 4: Enhance Invoice Form
- Add "Auto-Lookup" button
- Show tax breakdown dialog
- Save tax reference with invoice

---

## ✅ BENEFITS

1. **Accuracy**: Always use latest URA tax rates
2. **Speed**: Auto-fill tax instead of manual lookup
3. **Audit Trail**: Keep history of all tax rates used
4. **Flexibility**: User can still override if needed
5. **Compliance**: Reference exact tax database used
6. **Efficiency**: No more manual Excel lookups

---

## 🎯 PRIORITY IMPLEMENTATION

### PHASE 1 (Essential)
1. ✅ Database tables (vehicle_tax_rates, tax_import_history)
2. ✅ VehicleTaxRate model
3. ✅ CSV import (simplest format for testing)
4. ✅ Tax lookup in invoice form
5. ✅ Basic import UI

### PHASE 2 (Enhancement)
6. Excel import (using `excel` package)
7. PDF import (using `pdf` package)
8. Tax breakdown display
9. Import history viewer

### PHASE 3 (Advanced)
10. Fuzzy matching for similar vehicles
11. Tax suggestions based on history
12. Bulk import validation
13. Export tax reports

---

## 📝 NEXT STEPS

Should I proceed with implementing **PHASE 1**?

This will give you:
- Tax database storage
- Monthly import capability
- Auto-lookup in invoices
- Foundation for future enhancements


