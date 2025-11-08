# 🔢 SHEET 2: TAX CALCULATOR WITH SURCHARGE - COMPLETE GUIDE

## 🎯 WHAT IS THIS SHEET?

Sheet 2 "with surcharge" is a **TAX CALCULATOR** for **OLD PASSENGER CARS** (8+ years old).

**Think of it as:** A calculator that takes 3 inputs (CIF, Exchange Rate, Year) and outputs the TOTAL TAXES the customer must pay to URA.

---

## 🔴 WHY "WITH SURCHARGE"?

Uganda government discourages importing old, polluting vehicles by imposing a **50% ENVIRONMENTAL LEVY** on cars that are 8 or more years old.

```
New Car (< 8 years):  No environmental levy → Cheaper
Old Car (>= 8 years): 50% environmental levy → EXPENSIVE!

Example:
$10,000 car customs value = 35,860,000 UGX
Environmental levy = 17,930,000 UGX (50% of customs value!)
```

---

## 📊 WHEN TO USE THIS SHEET

```
Decision Rule:

Current Year: 2025
Vehicle Year: 2015
Age = 2025 - 2015 = 10 years

IF age >= 8 years
   THEN use Sheet 2 (with surcharge)  ← 50% environmental levy
ELSE
   THEN use Sheet 3 (without surcharge) ← 0% environmental levy
```

**This Sheet Applies To:**
- ✅ Passenger cars (sedans, SUVs, hatchbacks)
- ✅ Manufactured 8+ years ago
- ✅ NOT trucks (trucks have separate sheets)

---

## 🔄 DATA FLOW

```
┌─────────────────────────────────────────────────────────────┐
│              HOW SHEET 2 WORKS                              │
└─────────────────────────────────────────────────────────────┘

USER INPUTS:                    CALCULATIONS:
                               
┌──────────────┐               ┌──────────────────────┐
│ Row 3:       │              │ Row 6:               │
│ Exchange Rate│──────────┐   │ CUSTOMS VALUE        │
│ 3,586.88 UGX │          │   │ = B5 × B3            │
└──────────────┘          │   └──────────────────────┘
                          │              │
┌──────────────┐          │              ↓
│ Row 4:       │          │   ┌──────────────────────┐
│ Vehicle Year │          │   │ Row 8:               │
│ 2010         │          │   │ Import Declaration   │
└──────────────┘          │   │ = B6 × 1%            │
                          │   └──────────────────────┘
┌──────────────┐          │              ↓
│ Row 5:       │──────────┤   ┌──────────────────────┐
│ CIF USD      │          │   │ Row 9:               │
│ $10,000      │          │   │ Import Duty          │
└──────────────┘          │   │ = B6 × 25%           │
                          │   └──────────────────────┘
                          │              ↓
                          │   ┌──────────────────────┐
                          │   │ Row 10:              │
                          │   │ V.A.T                │
                          │   │ = (B6+B9) × 18%      │
                          │   └──────────────────────┘
                          │              ↓
                          │   ┌──────────────────────┐
                          │   │ Row 11:              │
                          │   │ W.H.T                │
                          │   │ = B6 × 6%            │
                          │   └──────────────────────┘
                          │              ↓
                          │   ┌──────────────────────┐
                          │   │ Row 12: 🔴           │
                          │   │ ENVIRONMENTAL LEVY   │
                          │   │ = B6 × 50%           │
                          │   └──────────────────────┘
                          │              ↓
                          │   ┌──────────────────────┐
                          │   │ Row 13-15:           │
                          │   │ Fixed Fees           │
                          │   │ 1,553,000 UGX        │
                          │   └──────────────────────┘
                          │              ↓
                          │   ┌──────────────────────┐
                          │   │ Row 16:              │
                          │   │ Infrastructure Levy  │
                          │   │ = B6 × 1.5%          │
                          │   └──────────────────────┘
                          │              ↓
                          │   ┌──────────────────────┐
                          │   │ Row 17: ⭐           │
                          │   │ TOTAL TAXES          │
                          │   │ = SUM(B8:B16)        │
                          │   └──────────────────────┘
                          │              │
                          │              ↓
                          │   ┌──────────────────────┐
                          └──▶│ Sent to Quotation    │
                              │ Sheet Row 29         │
                              └──────────────────────┘
```

---

## 📋 ROW-BY-ROW BREAKDOWN

### **INPUT SECTION**

#### **Row 3: Exchange Rate** 💱
```
Field: EXCHANGE RATE
Value: 3,586.88 UGX/USD (example)
Type: MANUAL INPUT

Purpose: Conversion rate from USD to UGX
Updates: Daily/Weekly based on Bank of Uganda rate

Example:
If rate = 3,586.88
Then $1 = 3,586.88 UGX
```

#### **Row 4: Vehicle Year** 📅
```
Field: YEAR
Value: 2010 (example)
Type: MANUAL INPUT

Purpose: Determine if surcharge applies
Logic: 2025 - 2010 = 15 years old
       15 >= 8 → Use THIS sheet (with surcharge)

Critical: This determines which tax calculator to use!
```

#### **Row 5: CIF USD** 💵
```
Field: CIF USD
Value: Manually entered
Type: MANUAL INPUT

Purpose: Base value for ALL tax calculations
Includes:
  - Vehicle purchase price
  - Insurance to Mombasa
  - Freight to Mombasa

Example: $10,000

🎯 THIS IS THE STARTING POINT FOR EVERYTHING!
```

---

### **CALCULATED SECTION**

#### **Row 6: Customs Value** 🔢
```
Field: CUSTOMS VALUE
Formula: = B5 × B3
Example: = $10,000 × 3,586.88 = 35,868,800 UGX

Purpose: Convert CIF to UGX
This value is the BASE for all percentage taxes!

All taxes below use THIS number as the base.
```

---

### **TAX CALCULATIONS**

#### **Row 8: Import Declaration Fees** 📋
```
Field: IMPORT DECLARATION FEES
Formula: = B6 × 1%
Rate: 1%

Example:
35,868,800 × 1% = 358,688 UGX

Purpose: URA processing fee for import paperwork
```

#### **Row 9: Import Duty** 💰
```
Field: IMPORT DUTY
Formula: = B6 × 25%
Rate: 25% for passenger cars

Example:
35,868,800 × 25% = 8,967,200 UGX

Purpose: Primary import tax on foreign goods
🔴 MAJOR TAX #1 (25% of car value!)
```

#### **Row 10: V.A.T (Value Added Tax)** 📈
```
Field: V.A.T
Formula: = (B6 + B9) × 18%
Rate: 18%

⚠️ CRITICAL: V.A.T is calculated on DUTY-PAID VALUE
Not just customs value, but customs + duty!

Example:
(35,868,800 + 8,967,200) × 18%
= 44,836,000 × 18%
= 8,070,480 UGX

Purpose: Standard sales tax
🔴 MAJOR TAX #2 (18% on duty-paid value)
```

#### **Row 11: Withholding Tax (W.H.T)** 💼
```
Field: W.H.T
Formula: = B6 × 6%
Rate: 6%

Example:
35,868,800 × 6% = 2,152,128 UGX

Purpose: Advance income tax collection
```

#### **Row 12: Environmental Levy (SURCHARGE)** 🔴🔴🔴
```
Field: SURCHARGE (ENVIRONMENTAL)
Formula: = B6 × 50%
Rate: 50% ← THE KILLER!

Example:
35,868,800 × 50% = 17,934,400 UGX

🔴🔴🔴 THIS IS THE BIG ONE!
50% of customs value as environmental penalty!
This ALONE equals HALF the car's value!

Purpose: Discourage old, polluting vehicles
This is why old cars cost SO much in Uganda!

Comparison:
- New car (< 8 years): 0% environmental = 0 UGX
- Old car (>= 8 years): 50% environmental = 17,934,400 UGX
- DIFFERENCE: 17.9 MILLION UGX just for being old!
```

#### **Row 13: Registration Fees** 🚗
```
Field: REG FEES
Value: 1,500,000 UGX (FIXED)
Type: CONSTANT

Purpose: Motor vehicle registration with URA
Covers: License plates, vehicle registration database

Same for ALL light vehicles (cars, SUVs)
Heavier trucks pay less: 1,250,000 UGX
```

#### **Row 14: Stamp Duty** 📄
```
Field: STAMP DUTY
Value: 18,000 UGX (FIXED)
Type: CONSTANT

Purpose: Government stamp duty on vehicle imports
```

#### **Row 15: Form Fees** 📝
```
Field: REG FORM
Value: 35,000 UGX (FIXED)
Type: CONSTANT

Purpose: Cost of official registration forms
```

#### **Row 16: Infrastructural Levy** 🏗️
```
Field: INFRASTRUCTURAL LEVY
Formula: = B6 × 1.5%
Rate: 1.5%

Example:
35,868,800 × 1.5% = 538,032 UGX

Purpose: Infrastructure development fund
```

---

### **OUTPUT SECTION**

#### **Row 17: TOTAL TAXES** ⭐⭐⭐
```
Field: TOTAL TAXES
Formula: = SUM(B8:B16)
Type: CALCULATED OUTPUT

This is THE FINAL NUMBER!
Adds all taxes together:
= Import Declaration
+ Import Duty
+ V.A.T
+ W.H.T
+ Environmental Levy
+ Registration Fees
+ Stamp Duty
+ Form Fees
+ Infrastructural Levy

🔗 LINKED TO QUOTATION SHEET!
Quotation Row 29 = 'with surcharge'!B17

This value automatically appears in customer quotation!
```

---

## 💰 WORKED EXAMPLE: $10,000 CAR (2010 MODEL)

Let's calculate taxes for a **2010 Toyota Harrier** with **CIF USD = $10,000**:

```
╔═══════════════════════════════════════════════════════════════╗
║            TAX CALCULATION: 2010 TOYOTA HARRIER              ║
╚═══════════════════════════════════════════════════════════════╝

INPUT VALUES:
─────────────────────────────────────────────────────────────────
Row 3: Exchange Rate    = 3,586.88 UGX/USD
Row 4: Vehicle Year     = 2010 (15 years old → WITH SURCHARGE ✓)
Row 5: CIF USD          = $10,000

CALCULATED CUSTOMS VALUE:
─────────────────────────────────────────────────────────────────
Row 6: Customs Value    = $10,000 × 3,586.88
                        = 35,868,800 UGX

TAX BREAKDOWN:
─────────────────────────────────────────────────────────────────
Row 8:  Import Declaration    = 35,868,800 × 1%
                               =    358,688 UGX

Row 9:  Import Duty          = 35,868,800 × 25%
                               =  8,967,200 UGX   🔴

Row 10: V.A.T                = (35,868,800 + 8,967,200) × 18%
                               =  8,070,480 UGX   🔴

Row 11: W.H.T                = 35,868,800 × 6%
                               =  2,152,128 UGX

Row 12: Environmental Levy   = 35,868,800 × 50%
                               = 17,934,400 UGX   🔴🔴🔴 OUCH!

Row 13: Registration Fees    = 1,500,000 UGX  (fixed)

Row 14: Stamp Duty          =    18,000 UGX  (fixed)

Row 15: Form Fees           =    35,000 UGX  (fixed)

Row 16: Infrastructure Levy  = 35,868,800 × 1.5%
                               =    538,032 UGX

─────────────────────────────────────────────────────────────────
Row 17: ⭐ TOTAL TAXES      = 39,573,928 UGX
─────────────────────────────────────────────────────────────────

TAX ANALYSIS:
═════════════════════════════════════════════════════════════════
Total Taxes:          39,573,928 UGX ($11,033 USD)
Customs Value:        35,868,800 UGX ($10,000 USD)

Effective Tax Rate:   110.3% of CIF value! 🔴

You pay MORE in taxes than the car cost!

TOP 3 TAXES:
1. Environmental Levy: 17,934,400 UGX (45.3%)
2. Import Duty:         8,967,200 UGX (22.7%)
3. V.A.T:              8,070,480 UGX (20.4%)

Environmental levy ALONE = 50% of car value!
```

---

## 📊 COMPARISON: NEW vs OLD CAR

Same $10,000 car, different ages:

```
┌─────────────────────────────────────────────────────────────┐
│              2020 MODEL (5 years old)                       │
│              Uses Sheet 3 (WITHOUT surcharge)               │
├─────────────────────────────────────────────────────────────┤
│ Import Duty:             8,967,200 UGX                      │
│ V.A.T:                   8,070,480 UGX                      │
│ W.H.T:                   2,152,128 UGX                      │
│ Environmental Levy:              0 UGX  ✅ ZERO!            │
│ Fixed Fees:              1,553,000 UGX                      │
│ Infrastructure Levy:       538,032 UGX                      │
├─────────────────────────────────────────────────────────────┤
│ TOTAL TAXES:            21,639,528 UGX                      │
│ Effective Rate:         60.3% of CIF                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              2010 MODEL (15 years old)                      │
│              Uses Sheet 2 (WITH surcharge)                  │
├─────────────────────────────────────────────────────────────┤
│ Import Duty:             8,967,200 UGX                      │
│ V.A.T:                   8,070,480 UGX                      │
│ W.H.T:                   2,152,128 UGX                      │
│ Environmental Levy:     17,934,400 UGX  🔴 MASSIVE!         │
│ Fixed Fees:              1,553,000 UGX                      │
│ Infrastructure Levy:       538,032 UGX                      │
├─────────────────────────────────────────────────────────────┤
│ TOTAL TAXES:            39,573,928 UGX                      │
│ Effective Rate:         110.3% of CIF                       │
└─────────────────────────────────────────────────────────────┘

💰 COST DIFFERENCE: 17,934,400 UGX ($5,000 USD)

Just for being 10 years older!
That's a BRAND NEW SMALL CAR in tax difference!
```

---

## 🔗 CONNECTION TO OTHER SHEETS

### **Link to Quotation (Sheet 1)**

```dart
// In Quotation Sheet, Row 29:
Formula: ='with surcharge'!B17

// This means:
Quotation.taxesPayableToURA = WithSurchargeSheet.totalTaxes;

// Automatically updates when Sheet 2 changes!
```

### **Relationship with Sheet 3 (without Surcharge)**

```dart
// Decision logic:
if (vehicleAge >= 8) {
    useSheet2(); // with surcharge (50% environmental)
} else {
    useSheet3(); // without surcharge (0% environmental)
}

// Only ONE difference between Sheet 2 and Sheet 3:
Sheet2.Row12 = customsValue × 50%;  // Environmental levy
Sheet3.Row12 = customsValue × 0%;   // No environmental levy

// Everything else is IDENTICAL!
```

---

## 🚀 IMPLEMENTATION IN FLUTTER

### **Tax Calculator Class**

```dart
class TaxCalculatorWithSurcharge {
  final double cifUSD;
  final double exchangeRate;
  final int vehicleYear;
  
  // Calculated value
  double get customsValue => cifUSD * exchangeRate;
  
  // Row 8: Import Declaration Fees
  double get importDeclarationFees => customsValue * 0.01;
  
  // Row 9: Import Duty
  double get importDuty => customsValue * 0.25;
  
  // Row 10: V.A.T
  double get vat => (customsValue + importDuty) * 0.18;
  
  // Row 11: W.H.T
  double get wht => customsValue * 0.06;
  
  // Row 12: Environmental Levy (THE BIG ONE!)
  double get environmentalLevy => customsValue * 0.50;  // 50%!
  
  // Row 13: Registration Fees (Fixed)
  double get registrationFees => 1500000.0;
  
  // Row 14: Stamp Duty (Fixed)
  double get stampDuty => 18000.0;
  
  // Row 15: Form Fees (Fixed)
  double get formFees => 35000.0;
  
  // Row 16: Infrastructure Levy
  double get infrastructureLevy => customsValue * 0.015;
  
  // Row 17: TOTAL TAXES
  double get totalTaxes {
    return importDeclarationFees
         + importDuty
         + vat
         + wht
         + environmentalLevy
         + registrationFees
         + stampDuty
         + formFees
         + infrastructureLevy;
  }
  
  // Breakdown for display
  Map<String, double> getTaxBreakdown() {
    return {
      'Import Declaration': importDeclarationFees,
      'Import Duty': importDuty,
      'V.A.T': vat,
      'W.H.T': wht,
      'Environmental Levy': environmentalLevy,
      'Registration Fees': registrationFees,
      'Stamp Duty': stampDuty,
      'Form Fees': formFees,
      'Infrastructure Levy': infrastructureLevy,
      'TOTAL': totalTaxes,
    };
  }
}
```

### **Usage Example**

```dart
// Create calculator
final calculator = TaxCalculatorWithSurcharge(
  cifUSD: 10000,
  exchangeRate: 3586.88,
  vehicleYear: 2010,
);

// Get total taxes
double totalTaxes = calculator.totalTaxes;
// Result: 39,573,928 UGX

// Use in invoice
invoice.taxesURA = totalTaxes;

// Show breakdown to user
Map<String, double> breakdown = calculator.getTaxBreakdown();
```

---

## ⚠️ CRITICAL BUSINESS RULES

### **1. The 8-Year Cutoff**
```
Age Calculation: CurrentYear - VehicleYear

IF age >= 8 → WITH surcharge (Sheet 2)
IF age < 8  → WITHOUT surcharge (Sheet 3)

Examples:
2025 - 2018 = 7 years  → WITHOUT (0% environmental)
2025 - 2017 = 8 years  → WITH (50% environmental)
2025 - 2010 = 15 years → WITH (50% environmental)

🔴 One year difference = 17.9M UGX in taxes!
```

### **2. V.A.T is on Duty-Paid Value**
```
WRONG: vat = customsValue × 18%
RIGHT: vat = (customsValue + importDuty) × 18%

The government charges V.A.T on the value
AFTER import duty has been added!
```

### **3. Fixed Fees Never Change**
```
Registration: 1,500,000 UGX (light vehicles)
Stamp Duty:      18,000 UGX
Form Fees:       35,000 UGX
───────────────────────────
TOTAL FIXED:  1,553,000 UGX

Even if CIF = $0, minimum tax = 1,553,000 UGX
```

### **4. All Percentage Taxes Use Customs Value**
```
Base = Customs Value (Row 6)

Calculated from this base:
- Import Declaration (1%)
- Import Duty (25%)
- W.H.T (6%)
- Environmental Levy (50%)
- Infrastructure Levy (1.5%)

Exception: V.A.T uses (Customs Value + Import Duty)
```

---

## 🎯 VALIDATION RULES

Before calculating taxes, validate:

```dart
// 1. Exchange rate must be positive
if (exchangeRate <= 0) throw ValidationError();

// 2. CIF must be positive
if (cifUSD <= 0) throw ValidationError();

// 3. Vehicle year must be reasonable
int currentYear = DateTime.now().year;
if (vehicleYear > currentYear || vehicleYear < 1900) {
  throw ValidationError();
}

// 4. Check if surcharge applies
int age = currentYear - vehicleYear;
if (age < 8) {
  // Should use Sheet 3 instead!
  throw WrongSheetError('Use WITHOUT surcharge');
}
```

---

## 📈 TAX RATE SUMMARY

| Component | Rate | Base | Type |
|-----------|------|------|------|
| Import Declaration | 1% | Customs Value | Percentage |
| Import Duty | 25% | Customs Value | Percentage |
| V.A.T | 18% | Customs + Duty | Percentage |
| W.H.T | 6% | Customs Value | Percentage |
| Environmental Levy | **50%** | Customs Value | Percentage |
| Registration Fees | 1,500,000 | - | Fixed |
| Stamp Duty | 18,000 | - | Fixed |
| Form Fees | 35,000 | - | Fixed |
| Infrastructure Levy | 1.5% | Customs Value | Percentage |

**Total Percentage-Based:** ~101.5% of customs value
**Total Fixed:** 1,553,000 UGX
**Effective Rate:** ~110% for old cars!

---

## 💡 KEY TAKEAWAYS

1. **50% Environmental Levy is the killer** - Makes old cars 110%+ of CIF in taxes
2. **Row 17 is linked to Quotation** - This is how taxes appear in customer quote
3. **V.A.T is on duty-paid value** - Not just customs value
4. **Fixed fees = 1.55M UGX** - Minimum tax even if car is free
5. **One year difference (7 vs 8) = $5,000 in taxes** - Buy newer!

---

**Document Created:** $(date)
**Source:** Sheet 2 "with surcharge" Analysis
**Status:** ✅ Complete and Ready for Implementation
