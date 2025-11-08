# 📚 URA MONTHLY TAX DATABASE - COMPLETE GUIDE

## 🎯 WHAT ARE THESE PDF FILES?

The **TAX** folder contains **MONTHLY UPDATES** from Uganda Revenue Authority (URA) with **OFFICIAL CIF VALUES** for used motor vehicles.

```
╔════════════════════════════════════════════════════════════════╗
║           MONTHLY URA DATABASE UPDATES (2025)                  ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  ✅ April 2025      - 402 pages  (~16.31 MB)                   ║
║  ✅ May 2025        - 441 pages  (~16.52 MB)                   ║
║  ❌ June 2025       - Corrupted file                           ║
║  ✅ July 2025       - 366 pages  (~18.54 MB)                   ║
║  ✅ August 2025     - 417 pages  (~2.88 MB)                    ║
║  ✅ September 2025  - 421 pages  (~2.82 MB)                    ║
║  ✅ October 2025    - 426 pages  (~2.71 MB) ← CURRENT         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

🎯 CURRENT MONTH: OCTOBER 2025
📋 Latest Database: "Used MV Database Update October 2025.pdf"
📊 Estimated Entries: ~8,000-10,000 vehicles per month
```

---

## 📋 DATABASE STRUCTURE

### **Column Format:**

```
S/N | HSC CODE | COO | Description | CC | CIF (USD)
─────────────────────────────────────────────────────────
1     8703.24.90  JP   Acura MDX, 2009  3700 cc  9,116.29
2     8703.24.90  JP   Acura MDX, 2010  3700 cc  9,847.28
3     8703.24.90  JP   Acura MDX, 2011  3700 cc  11,119.78
```

**Column Details:**

| Column | Name | Meaning | Example |
|--------|------|---------|---------|
| 1 | S/N | Serial Number | 1, 2, 3... |
| 2 | HSC CODE | Harmonized System Code | 8703.24.90 (cars), 8704.xx (trucks) |
| 3 | COO | Country of Origin | JP (Japan), DE (Germany), UK, US |
| 4 | Description | Make, Model, Year, Specs | "Acura MDX, 2009" |
| 5 | CC | Engine Capacity | 3700 cc |
| 6 | CIF (USD) | Official value | $9,116.29 |

---

## 🎯 SAMPLE ENTRIES FROM OCTOBER 2025

### **Example 1: Acura MDX (Year Progression)**

```
Year    Engine    CIF Value    Increase from Previous Year
──────────────────────────────────────────────────────────────
2009    3700 cc   $9,116.29    -
2010    3700 cc   $9,847.28    +$731 (+8%)
2011    3700 cc   $11,119.78   +$1,273 (+13%)
2012    3700 cc   $12,231.76   +$1,112 (+10%)

💡 INSIGHT: Newer models have higher CIF values
           Each year newer = ~$700-1,300 more in CIF
           This affects customs value and ALL taxes!
```

### **Example 2: Audi A1 (Engine Size Variation)**

```
Year    Engine    CIF Value    Note
──────────────────────────────────────────────────────────────
2016    1000 cc   $4,311.19    Smallest engine
2016    1100 cc   $4,311.19    Same as 1000cc
2016    1400 cc   $5,477.17    +$1,166 for bigger engine

💡 INSIGHT: Larger engines = Higher CIF
           Engine size matters for valuation!
```

### **Example 3: AM General Tractor Head (Year Progression)**

```
Year          HP       CIF Value
──────────────────────────────────────────────────────────
1990-         240 Hp   $6,978.35
1991          240 Hp   $7,021.36    +$43
1992          240 Hp   $7,215.62    +$194
1993          240 Hp   $7,451.85    +$236
...
1998          240 Hp   $8,517.75
1999          240 Hp   $8,561.33
2000          240 Hp   $8,604.91

💡 INSIGHT: Even for trucks, year matters!
           Each year newer = $40-200 increase
```

---

## 🔄 HOW MONTHLY UPDATES WORK

```
╔════════════════════════════════════════════════════════════════╗
║              MONTHLY URA UPDATE CYCLE                          ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Month 1 (e.g., April):                                        ║
║  → URA releases "Used MV Database Update April 2025.pdf"       ║
║  → Contains CIF values valid for April imports                 ║
║                                                                ║
║  Month 2 (e.g., May):                                          ║
║  → URA releases "Used MV Database Update May 2025.pdf"         ║
║  → CIF values updated (market changes!)                        ║
║  → Some vehicles added, some removed                           ║
║  → Prices may increase or decrease                             ║
║                                                                ║
║  Current (October):                                            ║
║  → Latest database: October 2025                               ║
║  → Use THIS for current month calculations                     ║
║  → Previous months archived for reference                      ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

---

## 💡 WHY VALUES CHANGE MONTHLY

### **Factors Affecting CIF:**

```
1. MARKET DEMAND:
   - High demand vehicles = Price increases
   - Low demand = Price decreases
   
2. EXCHANGE RATES:
   - JPY/USD rate changes
   - USD/EUR rate changes
   - Affects international purchase prices

3. VEHICLE AVAILABILITY:
   - Scarce models = Higher CIF
   - Common models = Lower CIF
   
4. AGE DEPRECIATION:
   - Vehicles get older each month
   - Older = Lower CIF (usually)
   
5. GLOBAL MARKET:
   - Japan auction prices
   - European used car prices
   - Shipping costs

EXAMPLE:
April: 2015 Harrier = $11,000
May: 2015 Harrier = $10,850 (↓ aged one month)
June: 2015 Harrier = $11,200 (↑ high demand)
```

---

## 🎯 HOW THIS INTEGRATES WITH YOUR EXCEL SYSTEM

### **Complete Workflow:**

```
┌─────────────────────────────────────────────────────────────┐
│              CUSTOMER WANTS VEHICLE                         │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Look up in URA Database (Current Month)            │
│  ────────────────────────────────────────────────────────── │
│  Search: "Toyota Harrier 2015 2400cc"                       │
│  Find: CIF USD = $11,500 (October 2025 official value)      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Open Excel Tax Calculator                          │
│  ────────────────────────────────────────────────────────── │
│  Vehicle: 2015 Harrier                                       │
│  Age: 2025 - 2015 = 10 years                                 │
│  Decision: Use Sheet 2 (WITH SURCHARGE)                      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Enter Values in Sheet 2                            │
│  ────────────────────────────────────────────────────────── │
│  Row 3: Exchange Rate = 3,800 UGX/USD (current)              │
│  Row 4: Year = 2015                                          │
│  Row 5: CIF USD = $11,500 (from URA database!)               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Sheet 2 Calculates Taxes                           │
│  ────────────────────────────────────────────────────────── │
│  Customs Value: $11,500 × 3,800 = 43,700,000 UGX            │
│  Environmental (50%): 21,850,000 UGX                         │
│  Other Taxes: 25,565,000 UGX                                 │
│  TOTAL TAXES (Row 17): 47,415,000 UGX                        │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Quotation Sheet Pulls Taxes                        │
│  ────────────────────────────────────────────────────────── │
│  Sheet 1, Row 29: ='with surcharge'!B17                      │
│  Result: 47,415,000 UGX appears in quotation                 │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: Complete Quotation & Send to Customer              │
│  ────────────────────────────────────────────────────────── │
│  First Installment: (shipping costs in UGX)                  │
│  Second Installment: 47.4M + 714K + fees = 49.3M UGX        │
│  GRAND TOTAL: Customer sees final price                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 💻 IMPLEMENTATION IN YOUR FLUTTER SYSTEM

### **Database Import Strategy:**

```dart
class URADatabaseImporter {
  
  // Step 1: Import monthly PDF
  Future<void> importMonthlyDatabase(String pdfPath, String month) async {
    // Extract data from PDF
    List<VehicleCIFEntry> entries = await extractPDFData(pdfPath);
    
    // Archive old data
    await archiveOldCIF Month(month);
    
    // Import new data
    for (var entry in entries) {
      await db.insert('vehicle_cif_values', {
        'hsc_code': entry.hscCode,
        'country_origin': entry.coo,
        'make': entry.make,
        'model': entry.model,
        'year': entry.year,
        'engine_cc': entry.engineCC,
        'cif_usd': entry.cifUSD,
        'database_month': month,  // 'October 2025'
        'imported_at': DateTime.now().toIso8601String(),
      });
    }
    
    // Mark as active
    await setActiveDatabase(month);
  }
  
  // Step 2: Lookup vehicle
  Future<double?> lookupCIF(String make, String model, int year, int engineCC) async {
    var result = await db.query(
      'vehicle_cif_values',
      where: 'make = ? AND model = ? AND year = ? AND engine_cc = ? AND is_active = 1',
      whereArgs: [make, model, year, engineCC],
    );
    
    if (result.isNotEmpty) {
      return result.first['cif_usd'] as double;
    }
    
    return null;  // Not found in database
  }
}
```

### **Usage in Invoice Form:**

```dart
// When user enters vehicle details
Future<void> autoLookupCIF() async {
  // Get from URA database
  double? cifUSD = await URADatabaseImporter().lookupCIF(
    make: _makeController.text,
    model: _modelController.text,
    year: int.parse(_yearController.text),
    engineCC: int.parse(_engineSizeController.text),
  );
  
  if (cifUSD != null) {
    setState(() {
      _cifUSDController.text = cifUSD.toString();
      _showSuccessDialog("✅ CIF value found in URA database!");
    });
  } else {
    _showWarningDialog(
      "⚠️ Vehicle not found in URA database.\n"
      "Please enter CIF manually or check vehicle details."
    );
  }
}
```

---

## 📊 DATABASE SCHEMA FOR SYSTEM

```sql
CREATE TABLE vehicle_cif_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  s_n INTEGER,
  hsc_code TEXT NOT NULL,
  country_origin TEXT,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  engine_cc INTEGER,
  engine_hp INTEGER,
  fuel_type TEXT,
  cif_usd REAL NOT NULL,
  database_month TEXT NOT NULL,  -- 'October 2025'
  imported_at TEXT NOT NULL,
  imported_by TEXT,
  is_active INTEGER DEFAULT 1,  -- Current month = 1
  notes TEXT
);

CREATE INDEX idx_cif_lookup ON vehicle_cif_values(
  make, model, year, engine_cc, is_active
);

CREATE INDEX idx_database_month ON vehicle_cif_values(
  database_month, is_active
);
```

---

## 🔄 MONTHLY UPDATE WORKFLOW

### **When URA Releases New Database (e.g., November 2025):**

```
STEP 1: DOWNLOAD NEW PDF
  - URA releases "Used MV Database Update November 2025.pdf"
  - Save to TAX folder
  
STEP 2: IMPORT INTO SYSTEM
  - Admin clicks "Import Tax Database" in settings
  - Select November PDF
  - System extracts all entries
  
STEP 3: ARCHIVE OLD DATA
  - Mark October data as is_active = 0
  - Keep for historical reference
  - Mark November data as is_active = 1
  
STEP 4: VERIFY CHANGES
  - Show summary: "Imported 8,453 vehicles"
  - Show changes: "235 price increases, 189 decreases"
  - Alert on major changes (>10% difference)
  
STEP 5: ALL NEW QUOTATIONS USE NOVEMBER DATA
  - Auto-lookup now uses November CIF values
  - Old quotations keep their original CIF
  - System tracks which month's database was used
```

---

## 💡 KEY INSIGHTS FROM DATABASE ANALYSIS

### **Insight 1: CIF Values Are NOT Arbitrary**

```
⚠️ IMPORTANT: You CANNOT just make up CIF values!

URA has official values for each:
- Make
- Model  
- Year
- Engine size

Example:
Acura MDX 2010 3700cc = $9,847.28 (official)

If you try to declare:
- Too low ($5,000) → URA rejects, penalties
- Too high ($15,000) → You overpay taxes

MUST use URA database values!
```

### **Insight 2: Engine Size Matters**

```
Audi A1 2016:
- 1000cc: $4,311.19
- 1400cc: $5,477.17
- Difference: $1,166 (27% more!)

This affects:
- Customs value
- ALL percentage-based taxes
- Final customer price

Your system MUST capture engine size accurately!
```

### **Insight 3: Year-Over-Year Changes**

```
Acura MDX 3700cc:
2009: $9,116
2010: $9,847  (+8%)
2011: $11,120 (+13%)
2012: $12,232 (+10%)

Pattern: Newer = More expensive
Average increase: ~10% per year

Use for estimates when exact model not listed.
```

### **Insight 4: Alphabetical Sorting**

```
Database is sorted A-Z by make:

A: Acura, Alfa Romeo, AM General, Ashok, Audi...
B: BMW, Bentley, Benz...
C: Cadillac, Caterpillar, Chevrolet...
...
T: Toyota, Tractor heads...

Makes lookup systematic but requires full scan
or database import for fast searching.
```

---

## 🚀 SYSTEM FEATURES TO IMPLEMENT

### **Feature 1: Auto-Lookup from Database**

```
UI Flow:
┌─────────────────────────────────────────┐
│ Invoice Form                            │
├─────────────────────────────────────────┤
│ Make: [Toyota           ]               │
│ Model: [Harrier         ]               │
│ Year: [2015             ]               │
│ Engine: [2400           ] cc            │
│ CIF USD: [              ]               │
│          [🔍 Auto-Lookup from URA DB]   │
└─────────────────────────────────────────┘
                 │
                 ↓ (User clicks button)
┌─────────────────────────────────────────┐
│ ✅ Found in October 2025 Database       │
├─────────────────────────────────────────┤
│ Toyota Harrier 2015 2400cc              │
│ CIF USD: $11,450.00                     │
│                                         │
│ [Use This Value] [Edit Manually]       │
└─────────────────────────────────────────┘
```

### **Feature 2: Monthly Update Manager**

```
Settings > Tax Database Management
┌──────────────────────────────────────────────────────────┐
│ 📅 CURRENT ACTIVE DATABASE:                              │
│    October 2025 (Imported: Oct 5, 2025)                  │
│    Entries: 8,347 vehicles                               │
│                                                          │
│ 📋 IMPORT HISTORY:                                        │
│    ✅ October 2025  - 8,347 entries  (Active)            │
│    ○ September 2025 - 8,221 entries  (Archived)          │
│    ○ August 2025    - 8,156 entries  (Archived)          │
│    ○ July 2025      - 7,998 entries  (Archived)          │
│                                                          │
│ [📥 Import New Database]  [📊 View Changes]              │
└──────────────────────────────────────────────────────────┘
```

### **Feature 3: CIF Comparison Tool**

```
Show customer how CIF changed:

┌──────────────────────────────────────────────────────────┐
│ Toyota Harrier 2015 2400cc - Price History               │
├──────────────────────────────────────────────────────────┤
│ October:    $11,450  (Current)                           │
│ September:  $11,380  (-$70)                              │
│ August:     $11,520  (-$70 from Aug)                     │
│                                                          │
│ 💡 Current month is best value!                          │
│    Consider buying now before Nov increase!              │
└──────────────────────────────────────────────────────────┘
```

---

## ⚠️ CRITICAL BUSINESS RULES

### **Rule 1: Always Use Current Month**

```
WRONG: Use April CIF in October
       (Outdated, URA may reject)

RIGHT: Use October CIF in October
       (Current, URA accepts)

Your system should:
- Auto-select current month's database
- Warn if using old database
- Block quotations with expired CIF data
```

### **Rule 2: Exact Match Required**

```
Customer wants: 2015 Harrier 2400cc

SEARCH FOR:
✅ Make: Toyota (or Harrier)
✅ Model: Harrier
✅ Year: 2015
✅ Engine: 2400cc

ALL must match! Different engine = different CIF!

2015 Harrier 2400cc = $11,450
2015 Harrier 3500cc = $14,200
Difference: $2,750!
```

### **Rule 3: Manual Entry Allowed (With Warning)**

```
If vehicle NOT found in database:
- Allow manual CIF entry
- Show warning: "⚠️ Not in URA database - may face scrutiny"
- Require justification/notes
- Flag for review before submission

Valid reasons:
- Rare/exotic model
- Brand new model (not yet in database)
- Special import case
```

---

## 📊 IMPLEMENTATION PRIORITY

### **Phase 1: Basic Lookup (Week 1)**

```
☐ Create vehicle_cif_values table
☐ Manual import of October 2025 (current)
☐ Build search function (make + model + year + engine)
☐ Add "Lookup CIF" button in invoice form
☐ Display found value to user
```

### **Phase 2: PDF Import Tool (Week 2-3)**

```
☐ PDF parsing service (extract text)
☐ Parse each line into structured data
☐ Import wizard UI
☐ Progress indicator (importing 8,000+ entries)
☐ Validation (check duplicates, errors)
☐ Import history tracking
```

### **Phase 3: Monthly Management (Week 4)**

```
☐ Archive old month when importing new
☐ Compare old vs new (price changes)
☐ Alert on major changes
☐ Database version selector
☐ Historical CIF lookup
```

---

## 🎯 SUMMARY

**URA Monthly Tax Databases:**
- Official CIF values for ALL vehicles
- Published monthly (April, May, June, etc.)
- ~8,000-10,000 entries per month
- Covers: Make, Model, Year, Engine, CIF USD
- Essential for accurate tax calculation
- Values change monthly (market fluctuations)

**Current Month (October 2025):**
- 426 pages
- ~8,000+ vehicle entries
- Alphabetically sorted
- Format: S/N | HSC | COO | Description | CC | CIF USD

**Integration with Your System:**
1. Customer selects vehicle
2. System looks up in URA database
3. Gets official CIF value
4. Uses in Excel tax calculator (Sheets 2-6)
5. Generates accurate quotation

**Critical Points:**
- ✅ MUST use official CIF values
- ✅ Update monthly when URA releases new database
- ✅ Archive old data for reference
- ✅ Allow manual entry with warnings
- ✅ Track which database version was used per invoice

---

**Document Created:** October 13, 2025
**Based On:** 7 months of URA databases (April-October 2025)
**Status:** ✅ Analysis Complete, Ready for Implementation







## 🎯 WHAT ARE THESE PDF FILES?

The **TAX** folder contains **MONTHLY UPDATES** from Uganda Revenue Authority (URA) with **OFFICIAL CIF VALUES** for used motor vehicles.

```
╔════════════════════════════════════════════════════════════════╗
║           MONTHLY URA DATABASE UPDATES (2025)                  ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  ✅ April 2025      - 402 pages  (~16.31 MB)                   ║
║  ✅ May 2025        - 441 pages  (~16.52 MB)                   ║
║  ❌ June 2025       - Corrupted file                           ║
║  ✅ July 2025       - 366 pages  (~18.54 MB)                   ║
║  ✅ August 2025     - 417 pages  (~2.88 MB)                    ║
║  ✅ September 2025  - 421 pages  (~2.82 MB)                    ║
║  ✅ October 2025    - 426 pages  (~2.71 MB) ← CURRENT         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

🎯 CURRENT MONTH: OCTOBER 2025
📋 Latest Database: "Used MV Database Update October 2025.pdf"
📊 Estimated Entries: ~8,000-10,000 vehicles per month
```

---

## 📋 DATABASE STRUCTURE

### **Column Format:**

```
S/N | HSC CODE | COO | Description | CC | CIF (USD)
─────────────────────────────────────────────────────────
1     8703.24.90  JP   Acura MDX, 2009  3700 cc  9,116.29
2     8703.24.90  JP   Acura MDX, 2010  3700 cc  9,847.28
3     8703.24.90  JP   Acura MDX, 2011  3700 cc  11,119.78
```

**Column Details:**

| Column | Name | Meaning | Example |
|--------|------|---------|---------|
| 1 | S/N | Serial Number | 1, 2, 3... |
| 2 | HSC CODE | Harmonized System Code | 8703.24.90 (cars), 8704.xx (trucks) |
| 3 | COO | Country of Origin | JP (Japan), DE (Germany), UK, US |
| 4 | Description | Make, Model, Year, Specs | "Acura MDX, 2009" |
| 5 | CC | Engine Capacity | 3700 cc |
| 6 | CIF (USD) | Official value | $9,116.29 |

---

## 🎯 SAMPLE ENTRIES FROM OCTOBER 2025

### **Example 1: Acura MDX (Year Progression)**

```
Year    Engine    CIF Value    Increase from Previous Year
──────────────────────────────────────────────────────────────
2009    3700 cc   $9,116.29    -
2010    3700 cc   $9,847.28    +$731 (+8%)
2011    3700 cc   $11,119.78   +$1,273 (+13%)
2012    3700 cc   $12,231.76   +$1,112 (+10%)

💡 INSIGHT: Newer models have higher CIF values
           Each year newer = ~$700-1,300 more in CIF
           This affects customs value and ALL taxes!
```

### **Example 2: Audi A1 (Engine Size Variation)**

```
Year    Engine    CIF Value    Note
──────────────────────────────────────────────────────────────
2016    1000 cc   $4,311.19    Smallest engine
2016    1100 cc   $4,311.19    Same as 1000cc
2016    1400 cc   $5,477.17    +$1,166 for bigger engine

💡 INSIGHT: Larger engines = Higher CIF
           Engine size matters for valuation!
```

### **Example 3: AM General Tractor Head (Year Progression)**

```
Year          HP       CIF Value
──────────────────────────────────────────────────────────
1990-         240 Hp   $6,978.35
1991          240 Hp   $7,021.36    +$43
1992          240 Hp   $7,215.62    +$194
1993          240 Hp   $7,451.85    +$236
...
1998          240 Hp   $8,517.75
1999          240 Hp   $8,561.33
2000          240 Hp   $8,604.91

💡 INSIGHT: Even for trucks, year matters!
           Each year newer = $40-200 increase
```

---

## 🔄 HOW MONTHLY UPDATES WORK

```
╔════════════════════════════════════════════════════════════════╗
║              MONTHLY URA UPDATE CYCLE                          ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Month 1 (e.g., April):                                        ║
║  → URA releases "Used MV Database Update April 2025.pdf"       ║
║  → Contains CIF values valid for April imports                 ║
║                                                                ║
║  Month 2 (e.g., May):                                          ║
║  → URA releases "Used MV Database Update May 2025.pdf"         ║
║  → CIF values updated (market changes!)                        ║
║  → Some vehicles added, some removed                           ║
║  → Prices may increase or decrease                             ║
║                                                                ║
║  Current (October):                                            ║
║  → Latest database: October 2025                               ║
║  → Use THIS for current month calculations                     ║
║  → Previous months archived for reference                      ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

---

## 💡 WHY VALUES CHANGE MONTHLY

### **Factors Affecting CIF:**

```
1. MARKET DEMAND:
   - High demand vehicles = Price increases
   - Low demand = Price decreases
   
2. EXCHANGE RATES:
   - JPY/USD rate changes
   - USD/EUR rate changes
   - Affects international purchase prices

3. VEHICLE AVAILABILITY:
   - Scarce models = Higher CIF
   - Common models = Lower CIF
   
4. AGE DEPRECIATION:
   - Vehicles get older each month
   - Older = Lower CIF (usually)
   
5. GLOBAL MARKET:
   - Japan auction prices
   - European used car prices
   - Shipping costs

EXAMPLE:
April: 2015 Harrier = $11,000
May: 2015 Harrier = $10,850 (↓ aged one month)
June: 2015 Harrier = $11,200 (↑ high demand)
```

---

## 🎯 HOW THIS INTEGRATES WITH YOUR EXCEL SYSTEM

### **Complete Workflow:**

```
┌─────────────────────────────────────────────────────────────┐
│              CUSTOMER WANTS VEHICLE                         │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Look up in URA Database (Current Month)            │
│  ────────────────────────────────────────────────────────── │
│  Search: "Toyota Harrier 2015 2400cc"                       │
│  Find: CIF USD = $11,500 (October 2025 official value)      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Open Excel Tax Calculator                          │
│  ────────────────────────────────────────────────────────── │
│  Vehicle: 2015 Harrier                                       │
│  Age: 2025 - 2015 = 10 years                                 │
│  Decision: Use Sheet 2 (WITH SURCHARGE)                      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Enter Values in Sheet 2                            │
│  ────────────────────────────────────────────────────────── │
│  Row 3: Exchange Rate = 3,800 UGX/USD (current)              │
│  Row 4: Year = 2015                                          │
│  Row 5: CIF USD = $11,500 (from URA database!)               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Sheet 2 Calculates Taxes                           │
│  ────────────────────────────────────────────────────────── │
│  Customs Value: $11,500 × 3,800 = 43,700,000 UGX            │
│  Environmental (50%): 21,850,000 UGX                         │
│  Other Taxes: 25,565,000 UGX                                 │
│  TOTAL TAXES (Row 17): 47,415,000 UGX                        │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Quotation Sheet Pulls Taxes                        │
│  ────────────────────────────────────────────────────────── │
│  Sheet 1, Row 29: ='with surcharge'!B17                      │
│  Result: 47,415,000 UGX appears in quotation                 │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: Complete Quotation & Send to Customer              │
│  ────────────────────────────────────────────────────────── │
│  First Installment: (shipping costs in UGX)                  │
│  Second Installment: 47.4M + 714K + fees = 49.3M UGX        │
│  GRAND TOTAL: Customer sees final price                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 💻 IMPLEMENTATION IN YOUR FLUTTER SYSTEM

### **Database Import Strategy:**

```dart
class URADatabaseImporter {
  
  // Step 1: Import monthly PDF
  Future<void> importMonthlyDatabase(String pdfPath, String month) async {
    // Extract data from PDF
    List<VehicleCIFEntry> entries = await extractPDFData(pdfPath);
    
    // Archive old data
    await archiveOldCIF Month(month);
    
    // Import new data
    for (var entry in entries) {
      await db.insert('vehicle_cif_values', {
        'hsc_code': entry.hscCode,
        'country_origin': entry.coo,
        'make': entry.make,
        'model': entry.model,
        'year': entry.year,
        'engine_cc': entry.engineCC,
        'cif_usd': entry.cifUSD,
        'database_month': month,  // 'October 2025'
        'imported_at': DateTime.now().toIso8601String(),
      });
    }
    
    // Mark as active
    await setActiveDatabase(month);
  }
  
  // Step 2: Lookup vehicle
  Future<double?> lookupCIF(String make, String model, int year, int engineCC) async {
    var result = await db.query(
      'vehicle_cif_values',
      where: 'make = ? AND model = ? AND year = ? AND engine_cc = ? AND is_active = 1',
      whereArgs: [make, model, year, engineCC],
    );
    
    if (result.isNotEmpty) {
      return result.first['cif_usd'] as double;
    }
    
    return null;  // Not found in database
  }
}
```

### **Usage in Invoice Form:**

```dart
// When user enters vehicle details
Future<void> autoLookupCIF() async {
  // Get from URA database
  double? cifUSD = await URADatabaseImporter().lookupCIF(
    make: _makeController.text,
    model: _modelController.text,
    year: int.parse(_yearController.text),
    engineCC: int.parse(_engineSizeController.text),
  );
  
  if (cifUSD != null) {
    setState(() {
      _cifUSDController.text = cifUSD.toString();
      _showSuccessDialog("✅ CIF value found in URA database!");
    });
  } else {
    _showWarningDialog(
      "⚠️ Vehicle not found in URA database.\n"
      "Please enter CIF manually or check vehicle details."
    );
  }
}
```

---

## 📊 DATABASE SCHEMA FOR SYSTEM

```sql
CREATE TABLE vehicle_cif_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  s_n INTEGER,
  hsc_code TEXT NOT NULL,
  country_origin TEXT,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  engine_cc INTEGER,
  engine_hp INTEGER,
  fuel_type TEXT,
  cif_usd REAL NOT NULL,
  database_month TEXT NOT NULL,  -- 'October 2025'
  imported_at TEXT NOT NULL,
  imported_by TEXT,
  is_active INTEGER DEFAULT 1,  -- Current month = 1
  notes TEXT
);

CREATE INDEX idx_cif_lookup ON vehicle_cif_values(
  make, model, year, engine_cc, is_active
);

CREATE INDEX idx_database_month ON vehicle_cif_values(
  database_month, is_active
);
```

---

## 🔄 MONTHLY UPDATE WORKFLOW

### **When URA Releases New Database (e.g., November 2025):**

```
STEP 1: DOWNLOAD NEW PDF
  - URA releases "Used MV Database Update November 2025.pdf"
  - Save to TAX folder
  
STEP 2: IMPORT INTO SYSTEM
  - Admin clicks "Import Tax Database" in settings
  - Select November PDF
  - System extracts all entries
  
STEP 3: ARCHIVE OLD DATA
  - Mark October data as is_active = 0
  - Keep for historical reference
  - Mark November data as is_active = 1
  
STEP 4: VERIFY CHANGES
  - Show summary: "Imported 8,453 vehicles"
  - Show changes: "235 price increases, 189 decreases"
  - Alert on major changes (>10% difference)
  
STEP 5: ALL NEW QUOTATIONS USE NOVEMBER DATA
  - Auto-lookup now uses November CIF values
  - Old quotations keep their original CIF
  - System tracks which month's database was used
```

---

## 💡 KEY INSIGHTS FROM DATABASE ANALYSIS

### **Insight 1: CIF Values Are NOT Arbitrary**

```
⚠️ IMPORTANT: You CANNOT just make up CIF values!

URA has official values for each:
- Make
- Model  
- Year
- Engine size

Example:
Acura MDX 2010 3700cc = $9,847.28 (official)

If you try to declare:
- Too low ($5,000) → URA rejects, penalties
- Too high ($15,000) → You overpay taxes

MUST use URA database values!
```

### **Insight 2: Engine Size Matters**

```
Audi A1 2016:
- 1000cc: $4,311.19
- 1400cc: $5,477.17
- Difference: $1,166 (27% more!)

This affects:
- Customs value
- ALL percentage-based taxes
- Final customer price

Your system MUST capture engine size accurately!
```

### **Insight 3: Year-Over-Year Changes**

```
Acura MDX 3700cc:
2009: $9,116
2010: $9,847  (+8%)
2011: $11,120 (+13%)
2012: $12,232 (+10%)

Pattern: Newer = More expensive
Average increase: ~10% per year

Use for estimates when exact model not listed.
```

### **Insight 4: Alphabetical Sorting**

```
Database is sorted A-Z by make:

A: Acura, Alfa Romeo, AM General, Ashok, Audi...
B: BMW, Bentley, Benz...
C: Cadillac, Caterpillar, Chevrolet...
...
T: Toyota, Tractor heads...

Makes lookup systematic but requires full scan
or database import for fast searching.
```

---

## 🚀 SYSTEM FEATURES TO IMPLEMENT

### **Feature 1: Auto-Lookup from Database**

```
UI Flow:
┌─────────────────────────────────────────┐
│ Invoice Form                            │
├─────────────────────────────────────────┤
│ Make: [Toyota           ]               │
│ Model: [Harrier         ]               │
│ Year: [2015             ]               │
│ Engine: [2400           ] cc            │
│ CIF USD: [              ]               │
│          [🔍 Auto-Lookup from URA DB]   │
└─────────────────────────────────────────┘
                 │
                 ↓ (User clicks button)
┌─────────────────────────────────────────┐
│ ✅ Found in October 2025 Database       │
├─────────────────────────────────────────┤
│ Toyota Harrier 2015 2400cc              │
│ CIF USD: $11,450.00                     │
│                                         │
│ [Use This Value] [Edit Manually]       │
└─────────────────────────────────────────┘
```

### **Feature 2: Monthly Update Manager**

```
Settings > Tax Database Management
┌──────────────────────────────────────────────────────────┐
│ 📅 CURRENT ACTIVE DATABASE:                              │
│    October 2025 (Imported: Oct 5, 2025)                  │
│    Entries: 8,347 vehicles                               │
│                                                          │
│ 📋 IMPORT HISTORY:                                        │
│    ✅ October 2025  - 8,347 entries  (Active)            │
│    ○ September 2025 - 8,221 entries  (Archived)          │
│    ○ August 2025    - 8,156 entries  (Archived)          │
│    ○ July 2025      - 7,998 entries  (Archived)          │
│                                                          │
│ [📥 Import New Database]  [📊 View Changes]              │
└──────────────────────────────────────────────────────────┘
```

### **Feature 3: CIF Comparison Tool**

```
Show customer how CIF changed:

┌──────────────────────────────────────────────────────────┐
│ Toyota Harrier 2015 2400cc - Price History               │
├──────────────────────────────────────────────────────────┤
│ October:    $11,450  (Current)                           │
│ September:  $11,380  (-$70)                              │
│ August:     $11,520  (-$70 from Aug)                     │
│                                                          │
│ 💡 Current month is best value!                          │
│    Consider buying now before Nov increase!              │
└──────────────────────────────────────────────────────────┘
```

---

## ⚠️ CRITICAL BUSINESS RULES

### **Rule 1: Always Use Current Month**

```
WRONG: Use April CIF in October
       (Outdated, URA may reject)

RIGHT: Use October CIF in October
       (Current, URA accepts)

Your system should:
- Auto-select current month's database
- Warn if using old database
- Block quotations with expired CIF data
```

### **Rule 2: Exact Match Required**

```
Customer wants: 2015 Harrier 2400cc

SEARCH FOR:
✅ Make: Toyota (or Harrier)
✅ Model: Harrier
✅ Year: 2015
✅ Engine: 2400cc

ALL must match! Different engine = different CIF!

2015 Harrier 2400cc = $11,450
2015 Harrier 3500cc = $14,200
Difference: $2,750!
```

### **Rule 3: Manual Entry Allowed (With Warning)**

```
If vehicle NOT found in database:
- Allow manual CIF entry
- Show warning: "⚠️ Not in URA database - may face scrutiny"
- Require justification/notes
- Flag for review before submission

Valid reasons:
- Rare/exotic model
- Brand new model (not yet in database)
- Special import case
```

---

## 📊 IMPLEMENTATION PRIORITY

### **Phase 1: Basic Lookup (Week 1)**

```
☐ Create vehicle_cif_values table
☐ Manual import of October 2025 (current)
☐ Build search function (make + model + year + engine)
☐ Add "Lookup CIF" button in invoice form
☐ Display found value to user
```

### **Phase 2: PDF Import Tool (Week 2-3)**

```
☐ PDF parsing service (extract text)
☐ Parse each line into structured data
☐ Import wizard UI
☐ Progress indicator (importing 8,000+ entries)
☐ Validation (check duplicates, errors)
☐ Import history tracking
```

### **Phase 3: Monthly Management (Week 4)**

```
☐ Archive old month when importing new
☐ Compare old vs new (price changes)
☐ Alert on major changes
☐ Database version selector
☐ Historical CIF lookup
```

---

## 🎯 SUMMARY

**URA Monthly Tax Databases:**
- Official CIF values for ALL vehicles
- Published monthly (April, May, June, etc.)
- ~8,000-10,000 entries per month
- Covers: Make, Model, Year, Engine, CIF USD
- Essential for accurate tax calculation
- Values change monthly (market fluctuations)

**Current Month (October 2025):**
- 426 pages
- ~8,000+ vehicle entries
- Alphabetically sorted
- Format: S/N | HSC | COO | Description | CC | CIF USD

**Integration with Your System:**
1. Customer selects vehicle
2. System looks up in URA database
3. Gets official CIF value
4. Uses in Excel tax calculator (Sheets 2-6)
5. Generates accurate quotation

**Critical Points:**
- ✅ MUST use official CIF values
- ✅ Update monthly when URA releases new database
- ✅ Archive old data for reference
- ✅ Allow manual entry with warnings
- ✅ Track which database version was used per invoice

---

**Document Created:** October 13, 2025
**Based On:** 7 months of URA databases (April-October 2025)
**Status:** ✅ Analysis Complete, Ready for Implementation










