# 🚚 SHEET 4: TRUCKS & CABINS TAX CALCULATOR - COMPLETE GUIDE

## 🎯 WHAT IS THIS SHEET?

Sheet 4 "Trucks & Cabins" is a **TAX CALCULATOR** for **TRUCKS and CABIN VEHICLES** (pickups) weighing between 3-20 tonnes.

**Key Point:** Trucks have **DIFFERENT tax rules** than passenger cars!

---

## 🔑 THE CRITICAL DIFFERENCE: AGE DOESN'T MATTER FOR TRUCKS!

```
╔════════════════════════════════════════════════════════════════╗
║         ENVIRONMENTAL LEVY: TRUCKS vs PASSENGER CARS          ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  PASSENGER CARS (Age-Dependent):                              ║
║  - 2016+ (< 10 years): 0% environmental levy                  ║
║  - 2015- (10+ years): 50% environmental levy                  ║
║  → Age makes HUGE difference!                                 ║
║                                                                ║
║  TRUCKS & CABINS (Age-Independent):                           ║
║  - 2024 (new): 20% environmental levy                         ║
║  - 2015 (10 years): 20% environmental levy                    ║
║  - 2010 (15 years): 20% environmental levy                    ║
║  → Age makes NO difference! Always 20%! 🔑                    ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

💡 BUSINESS INSIGHT:
   For 10+ year old vehicles, TRUCKS are WAY cheaper than CARS!
   
   2015 Car:   50% environmental = 28.5M UGX
   2015 Truck: 20% environmental = 11.4M UGX
   SAVINGS: 17.1M UGX!
```

---

## 🚛 VEHICLE TYPES USING THIS SHEET

```
CATEGORY 1: 4 TONNE TRUCKS
  Examples: Mitsubishi Canter 4T, Isuzu Elf 4T
  Import Duty: 10%
  Environmental: 20%
  Common Use: Light delivery, small cargo

CATEGORY 2: DOUBLE CABIN PICKUPS ⭐ POPULAR!
  Examples: Toyota Hilux, Isuzu D-Max, Ford Ranger
  Import Duty: 20%
  Environmental: 20%
  Common Use: Construction, business, personal

CATEGORY 3: SINGLE CABIN PICKUPS
  Examples: Nissan Hardbody, Toyota Hilux Single Cab
  Import Duty: 20%
  Environmental: 20%
  Common Use: Cargo transport, commercial

CATEGORY 4: 3-6.9 TONNE TRUCKS
  Examples: Isuzu NPR, Mitsubishi Fuso
  Import Duty: 20%
  Environmental: 20%
  Common Use: Medium cargo, deliveries
```

---

## 📋 COMPLETE FORMULA BREAKDOWN

### **INPUT ROWS:**

```
Row 3: EXCHANGE RATE
       Formula: ='without Surcharge'!B3
       Example: 3,586.88 UGX/USD
       💡 Links to passenger car sheet for consistency

Row 5: CIF USD
       Value: Manually entered
       Example: $4,975.08
       💡 Truck purchase price + insurance + freight

Row 6: CUSTOMS VALUE
       Formula: = B5 × B3
       Example: 4,975.08 × 3,586.88 = 17,844,999 UGX
       💡 Base for all percentage taxes
```

### **TAX CALCULATION ROWS:**

```
Row 8:  IMPORT DUTY
        Formula: = B6 × 25%
        ⚠️ Formula shows 25%, but actual varies:
           - 4 tonne: 10%
           - Cabins/3-20T: 20%
        Example: 17,844,999 × 25% = 4,461,250 UGX

Row 9:  V.A.T
        Formula: = (B6 + B8) × 18%
        Example: (17,844,999 + 4,461,250) × 18%
               = 4,015,125 UGX
        💡 V.A.T on duty-paid value (same as cars)

Row 10: W.H.T (Withholding Tax)
        Formula: = B6 × 6%
        Example: 17,844,999 × 6% = 1,070,700 UGX

Row 11: ENVIRONMENTAL LEVY (SURCHARGE)
        Formula: = B6 × 20%
        Example: 17,844,999 × 20% = 3,569,000 UGX
        🔑 ALWAYS 20% - Age doesn't matter!
        🟡 Lower than old cars (20% vs 50%)

Row 12: MOTOR VEHICLE REGISTRATION FEES
        Value: 1,500,000 UGX (FIXED)
        💡 Same as light passenger cars

Row 13: STAMP DUTY
        Value: 18,000 UGX (FIXED)

Row 14: FORM FEES
        Value: 35,000 UGX (FIXED)

Row 15: INFRASTRUCTURE LEVY
        Formula: = B6 × 1.5%
        Example: 17,844,999 × 1.5% = 267,675 UGX

Row 16: TOTAL TAXES ⭐
        Formula: = SUM(B8:B15)
        Example: 14,936,749 UGX
        🔗 Linked to Quotation Row 29 for truck sales
```

---

## 💰 REAL EXAMPLE: 2015 Toyota Hilux Double Cab

```
╔═══════════════════════════════════════════════════════════════╗
║      2015 TOYOTA HILUX DOUBLE CABIN (10 YEARS OLD)           ║
╚═══════════════════════════════════════════════════════════════╝

Vehicle Details:
  Year: 2015 (10 years old)
  Type: Double Cabin Pickup
  Tonnage: ~2.5 tonnes
  CIF: $15,000
  Exchange Rate: 3,800 UGX/USD

INPUTS:
─────────────────────────────────────────────────────────────────
Row 3: Exchange Rate = 3,800 UGX/USD
Row 5: CIF USD = $15,000
Row 6: Customs Value = $15,000 × 3,800 = 57,000,000 UGX

TAX BREAKDOWN:
─────────────────────────────────────────────────────────────────
Row 8:  Import Duty         = 57,000,000 × 20%
                             = 11,400,000 UGX
        (20% for double cabins)

Row 9:  V.A.T               = (57,000,000 + 11,400,000) × 18%
                             = 68,400,000 × 18%
                             = 12,312,000 UGX

Row 10: W.H.T               = 57,000,000 × 6%
                             = 3,420,000 UGX

Row 11: Environmental Levy  = 57,000,000 × 20%
                             = 11,400,000 UGX
        🟡 ONLY 20% (not 50% like old cars!)

Row 12: Registration Fees   = 1,500,000 UGX

Row 13: Stamp Duty         = 18,000 UGX

Row 14: Form Fees          = 35,000 UGX

Row 15: Infrastructure Levy = 57,000,000 × 1.5%
                             = 855,000 UGX

─────────────────────────────────────────────────────────────────
Row 16: ⭐ TOTAL TAXES      = 41,940,000 UGX
                             ($11,037 USD)
─────────────────────────────────────────────────────────────────

CUSTOMER TOTAL COST:
  CIF:                  57,000,000 UGX
  Taxes:                41,940,000 UGX (73.6% of CIF)
  Number Plates:           714,300 UGX
  Insurance:               300,000 UGX
  Agency Fees:             800,000 UGX
  ───────────────────────────────────
  GRAND TOTAL:         100,754,300 UGX ($26,514 USD)
```

---

## 🔍 COMPARISON: 2015 CAR vs 2015 TRUCK

### **Same Year, Same CIF - Different Vehicle Type:**

```
┌─────────────────────────────────────────────────────────────────────┐
│ OPTION A: 2015 TOYOTA PRADO (PASSENGER CAR - 10 years old)         │
├─────────────────────────────────────────────────────────────────────┤
│ CIF: $15,000                                                        │
│ Customs Value: 57,000,000 UGX                                       │
│                                                                     │
│ Import Duty:           14,250,000 UGX (25%)                         │
│ V.A.T:                 12,825,000 UGX (18%)                         │
│ W.H.T:                  3,420,000 UGX (6%)                          │
│ Environmental Levy:    28,500,000 UGX (50%) 🔴 MASSIVE!             │
│ Other Taxes:            3,420,000 UGX                               │
│ ─────────────────────────────────────────────────────────────────  │
│ TOTAL TAXES:           62,415,000 UGX                               │
│ Tax Rate: 109.5% of CIF                                             │
│                                                                     │
│ GRAND TOTAL TO CUSTOMER: 120,829,300 UGX ($31,797 USD)             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ OPTION B: 2015 TOYOTA HILUX (TRUCK - 10 years old)                 │
├─────────────────────────────────────────────────────────────────────┤
│ CIF: $15,000                                                        │
│ Customs Value: 57,000,000 UGX                                       │
│                                                                     │
│ Import Duty:           11,400,000 UGX (20%)                         │
│ V.A.T:                 12,312,000 UGX (18%)                         │
│ W.H.T:                  3,420,000 UGX (6%)                          │
│ Environmental Levy:    11,400,000 UGX (20%) 🟡 BETTER!              │
│ Other Taxes:            2,855,000 UGX                               │
│ ─────────────────────────────────────────────────────────────────  │
│ TOTAL TAXES:           41,940,000 UGX                               │
│ Tax Rate: 73.6% of CIF                                              │
│                                                                     │
│ GRAND TOTAL TO CUSTOMER: 100,754,300 UGX ($26,514 USD)             │
└─────────────────────────────────────────────────────────────────────┘

💰 CUSTOMER SAVES: 20,075,000 UGX ($5,283 USD)

💡 LESSON: Old trucks are MORE tax-efficient than old cars!
```

---

## 🚀 FLUTTER IMPLEMENTATION

```dart
class TaxCalculatorTrucksCabins {
  final double cifUSD;
  final double exchangeRate;
  final int vehicleYear;  // Age doesn't affect environmental levy
  final TruckType truckType;
  
  double get customsValue => cifUSD * exchangeRate;
  
  // Row 8: Import Duty (tonnage-dependent)
  double get importDuty {
    double rate;
    switch (truckType) {
      case TruckType.fourTonne:
        rate = 0.10;  // 10% for 4T trucks
        break;
      case TruckType.doubleCabin:
      case TruckType.singleCabin:
      case TruckType.threeTo6Tonne:
        rate = 0.20;  // 20% for cabins and 3-6.9T
        break;
      default:
        rate = 0.20;  // Default 20%
    }
    return customsValue * rate;
  }
  
  // Row 9: V.A.T
  double get vat => (customsValue + importDuty) * 0.18;
  
  // Row 10: W.H.T
  double get wht => customsValue * 0.06;
  
  // Row 11: Environmental Levy
  // 🔑 ALWAYS 20% for trucks, regardless of age!
  double get environmentalLevy => customsValue * 0.20;
  
  // Row 12-14: Fixed Fees
  double get registrationFees => 1500000.0;
  double get stampDuty => 18000.0;
  double get formFees => 35000.0;
  
  // Row 15: Infrastructure Levy
  double get infrastructureLevy => customsValue * 0.015;
  
  // Row 16: TOTAL TAXES
  double get totalTaxes {
    return importDuty
         + vat
         + wht
         + environmentalLevy  // Always 20%!
         + registrationFees
         + stampDuty
         + formFees
         + infrastructureLevy;
  }
  
  Map<String, double> getTaxBreakdown() {
    return {
      'Import Duty': importDuty,
      'V.A.T': vat,
      'W.H.T': wht,
      'Environmental Levy (20%)': environmentalLevy,
      'Registration Fees': registrationFees,
      'Stamp Duty': stampDuty,
      'Form Fees': formFees,
      'Infrastructure Levy': infrastructureLevy,
      'TOTAL': totalTaxes,
    };
  }
}

enum TruckType {
  fourTonne,        // 10% import duty
  doubleCabin,      // 20% import duty
  singleCabin,      // 20% import duty
  threeTo6Tonne,    // 20% import duty
}
```

---

## 🎯 KEY INSIGHTS

1. **Age Independence** - 2010 truck = 2020 truck (20% environmental)
2. **Lower Than Old Cars** - 20% vs 50% environmental
3. **Predictable** - No year-based surprises
4. **Business Friendly** - Affordable for old commercial vehicles

**Document Created:** October 13, 2025
**Status:** ✅ Complete
