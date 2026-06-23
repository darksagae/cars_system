# 🚗 NSB MOTORS - COMPLETE TAX CALCULATION & QUOTATION SYSTEM LOGIC

## 📊 EXECUTIVE SUMMARY

The NSB Quotation system uses **6 interconnected Excel sheets** to:
1. Generate customer quotations with dual-currency pricing (USD & UGX)
2. Calculate Uganda Revenue Authority (URA) taxes based on vehicle type, year, and weight
3. Break down payments into two installments (First: USD-based, Second: UGX-based)

---

## 🎯 VEHICLE CATEGORIZATION & TAX RULES

### **DECISION TREE FOR TAX CALCULATION**

```
START: Vehicle Information
    ├─ Vehicle Type?
    │   ├─ Passenger Car/SUV/Sedan → Check Age
    │   │   ├─ Age >= 8 years → Sheet 2: WITH SURCHARGE (50% environmental levy)
    │   │   └─ Age < 8 years → Sheet 3: WITHOUT SURCHARGE (0% environmental levy)
    │   │
    │   ├─ Truck/Cabin → Check Weight
    │   │   ├─ 3-6.9 tonnes → Sheet 4: TRUCKS & CABINS
    │   │   ├─ 7-19.9 tonnes → Sheet 5: 7 TONNE TRUCKS
    │   │   └─ 20+ tonnes / Tractor Head → Sheet 6: TRACTOR HEADS AND 20>
    │
    └─ Calculate Taxes → Pull into Quotation (Sheet 1)
```

---

## 📋 QUOTATION STRUCTURE (Sheet 1)

### **Payment Breakdown Logic**

#### **FIRST INSTALLMENT (USD → UGX)**
```
Purpose: Cover initial costs before vehicle arrival

Components:
1. C&F Mombasa (Cost & Freight to Mombasa)
2. Clearance Mombasa-Kampala (Transport + clearance)
3. C&F Kampala (Cost & Freight to Kampala)
4. TT Charges (Bank transfer fees - typically $40)

Calculation:
Each line: UGX Amount = USD Amount × Exchange Rate
Total 1st Installment = Sum of all above in UGX
```

#### **SECOND INSTALLMENT (UGX only)**
```
Purpose: Government fees and registration costs

Components:
1. Taxes Payable to URA → PULLED FROM TAX CALCULATOR SHEETS
2. Number Plates → FIXED: 714,300 UGX
3. Third Party Insurance → Manual entry
4. Agency Fees → Manual entry (typically 400,000)

Calculation:
Total 2nd Installment = Sum of all above
```

#### **GRAND TOTAL**
```
GRAND TOTAL (UGX) = 1st Installment + 2nd Installment
```

---

## 🔢 TAX CALCULATION FORMULAS

### **CATEGORY 1: PASSENGER CARS (WITH SURCHARGE) - Sheet 2**
**Applies to:** Cars 8+ years old

| Tax Component | Formula | Rate | Notes |
|---------------|---------|------|-------|
| **Customs Value** | CIF_USD × Exchange_Rate | N/A | Base for all calculations |
| **Import Declaration Fees** | Customs_Value × 1% | 1% | |
| **Import Duty** | Customs_Value × 25% | 25% | For ordinary cars |
| **V.A.T** | (Customs_Value + Import_Duty) × 18% | 18% | On duty-paid value |
| **Withholding Tax (W.H.T)** | Customs_Value × 6% | 6% | |
| **Environmental Levy** | Customs_Value × 50% | 50% | ⚠️ **MAJOR COST for old cars** |
| **Registration Fees** | Fixed | 1,500,000 | |
| **Stamp Duty** | Fixed | 18,000 | |
| **Registration Form** | Fixed | 35,000 | |
| **Infrastructural Levy** | Customs_Value × 1.5% | 1.5% | |
| **TOTAL TAXES** | Sum of all above | | → Goes to Quotation Row 29 |

**Example:** CIF $10,000 at 3,586 rate = 35,860,000 UGX customs value
- Import Duty: 8,965,000
- V.A.T: 8,068,500
- W.H.T: 2,151,600
- Environmental: **17,930,000** ← Big one!
- Fixed fees: 1,553,000
- Infrastructure: 537,900
**Total ≈ 39,206,000 UGX**

---

### **CATEGORY 2: PASSENGER CARS (WITHOUT SURCHARGE) - Sheet 3**
**Applies to:** Cars < 8 years old

**SAME AS CATEGORY 1 EXCEPT:**
- **Environmental Levy = 0%** (instead of 50%)

**Decision Rule:**
```dart
int currentYear = DateTime.now().year;
int vehicleAge = currentYear - vehicleYear;

if (vehicleAge >= 8) {
    useWithSurcharge(); // 50% environmental levy
} else {
    useWithoutSurcharge(); // 0% environmental levy
}
```

---

### **CATEGORY 3: TRUCKS & CABINS (3-20 tonnes) - Sheet 4**
**Applies to:** Small-medium trucks, double/single cabins

| Tax Component | Formula | Rate | Notes |
|---------------|---------|------|-------|
| **Customs Value** | CIF_USD × Exchange_Rate | N/A | |
| **Import Duty** | Customs_Value × 25% | 10-25% | Varies by tonnage |
| **V.A.T** | (Customs_Value + Import_Duty) × 18% | 18% | |
| **W.H.T** | Customs_Value × 6% | 6% | |
| **Environmental Levy** | Customs_Value × 20% | 20% | Lower than cars |
| **Registration Fees** | Fixed | 1,500,000 | Same as cars |
| **Stamp Duty** | Fixed | 18,000 | |
| **Form Fees** | Fixed | 35,000 | |
| **Infrastructural Levy** | Customs_Value × 1.5% | 1.5% | |
| **TOTAL TAXES** | Sum of all above | | |

**Tonnage Rules:**
- 4 tonne trucks: 10% import duty
- 3-20 tonne trucks: 20% import duty
- All pay 20% environmental levy

---

### **CATEGORY 4: MEDIUM-HEAVY TRUCKS (7-19.9 tonnes) - Sheet 5**
**Applies to:** Trucks between 7 and 19.9 tonnes

| Tax Component | Formula | Rate | Notes |
|---------------|---------|------|-------|
| **Customs Value** | CIF_USD × Exchange_Rate | N/A | |
| **Import Duty** | Customs_Value × 10% | 10% | Lower than light trucks |
| **V.A.T** | (Customs_Value + Import_Duty) × 18% | 18% | |
| **W.H.T** | Customs_Value × 6% | 6% | |
| **Environmental Levy** | Customs_Value × 20% | 20% | |
| **Registration Fees** | Fixed | 1,250,000 | ⬇️ Lower than cars |
| **Stamp Duty** | Fixed | 18,000 | |
| **Form Fees** | Fixed | 35,000 | |
| **Infrastructural Levy** | Customs_Value × 1.5% | 1.5% | |
| **TOTAL TAXES** | Sum of all above | | |

**When CIF = 0:** Total = 1,303,000 (just fixed fees)

---

### **CATEGORY 5: SUPER HEAVY TRUCKS (20+ tonnes) & TRACTOR HEADS - Sheet 6**
**Applies to:** Trucks above 20 tonnes gross weight, tractor heads

| Tax Component | Formula | Rate | Notes |
|---------------|---------|------|-------|
| **Customs Value** | CIF_USD × Exchange_Rate | N/A | |
| **Import Duty** | Customs_Value × 0% | 0% | ✅ **ZERO** for heavy trucks |
| **V.A.T** | Customs_Value × 18% | 18% | No duty to add |
| **W.H.T** | Customs_Value × 6% | 6% | |
| **Environmental Levy** | Customs_Value × 20% | 20% | |
| **Registration Fees** | Fixed | 1,250,000 | |
| **Stamp Duty** | Fixed | 18,000 | |
| **Form Fees** | Fixed | 35,000 | |
| **Infrastructural Levy** | Customs_Value × 0% | 0% | ✅ **Also ZERO** |
| **TOTAL TAXES** | Sum of all above | | |

**Benefits for heavy trucks:**
- NO import duty (saves 25%)
- NO infrastructural levy (saves 1.5%)
- Lower registration fees (1,250,000 vs 1,500,000)

---

## 🔄 DATA FLOW IN CURRENT SYSTEM

```
User Input (Vehicle Details)
    ↓
Auto-select Tax Calculator Sheet
    ↓
Enter: CIF USD, Exchange Rate, Vehicle Year
    ↓
Tax Calculator Sheet computes all taxes
    ↓
Total Taxes (Row 17) pulled via formula
    ↓
Quotation Sheet Row 29: =Sheet!B17
    ↓
Add: Number Plates + Insurance + Agency Fees
    ↓
Calculate 2nd Installment Total
    ↓
Add 1st Installment (USD costs in UGX)
    ↓
GRAND TOTAL
    ↓
Generate PDF/Print Quotation
```

---

## 💡 SYSTEM IMPLEMENTATION RECOMMENDATIONS

### **1. VEHICLE TYPE ENUM**
```dart
enum VehicleType {
  passengerCar,      // Ordinary cars, SUVs, sedans
  lightTruck,        // 3-6.9 tonnes
  mediumTruck,       // 7-19.9 tonnes
  heavyTruck,        // 20+ tonnes
  tractorHead,       // Tractor heads
  doubleCabin,       // Pickup trucks
  singleCabin,       // Pickup trucks
}
```

### **2. TAX CALCULATOR CLASS**
```dart
class TaxCalculator {
  final double cifUSD;
  final double exchangeRate;
  final int vehicleYear;
  final VehicleType vehicleType;
  final double? tonnage; // For trucks
  
  double get customsValue => cifUSD * exchangeRate;
  
  double calculateTotalTax() {
    switch (vehicleType) {
      case VehicleType.passengerCar:
        return _calculateCarTax();
      case VehicleType.lightTruck:
        return _calculateLightTruckTax();
      case VehicleType.mediumTruck:
        return _calculateMediumTruckTax();
      case VehicleType.heavyTruck:
        return _calculateHeavyTruckTax();
      // ... etc
    }
  }
  
  double _calculateCarTax() {
    bool hasSurcharge = (DateTime.now().year - vehicleYear) >= 8;
    
    double importDeclaration = customsValue * 0.01;
    double importDuty = customsValue * 0.25;
    double vat = (customsValue + importDuty) * 0.18;
    double wht = customsValue * 0.06;
    double environmental = hasSurcharge ? customsValue * 0.50 : 0.0;
    double regFees = 1500000;
    double stampDuty = 18000;
    double formFees = 35000;
    double infrastructure = customsValue * 0.015;
    
    return importDeclaration + importDuty + vat + wht + 
           environmental + regFees + stampDuty + formFees + infrastructure;
  }
  
  // Similar methods for other vehicle types...
}
```

### **3. INVOICE CALCULATION LOGIC**
```dart
class InvoiceCalculation {
  // First Installment (USD-based)
  double cfMombasa;
  double clearanceMombasaKampala;
  double cfKampala;
  double ttCharges;
  double exchangeRate;
  
  double get firstInstallmentUGX {
    return (cfMombasa + clearanceMombasaKampala + cfKampala + ttCharges) 
           * exchangeRate;
  }
  
  // Second Installment (UGX-based)
  double taxesURA; // From TaxCalculator
  double numberPlates = 714300; // Fixed
  double thirdPartyInsurance;
  double agencyFees;
  
  double get secondInstallmentUGX {
    return taxesURA + numberPlates + thirdPartyInsurance + agencyFees;
  }
  
  double get grandTotal {
    return firstInstallmentUGX + secondInstallmentUGX;
  }
}
```

### **4. DATABASE SCHEMA FOR TAX RATES**
```sql
CREATE TABLE tax_rate_rules (
  id INTEGER PRIMARY KEY,
  vehicle_type TEXT NOT NULL, -- 'car', 'light_truck', etc.
  weight_min REAL, -- For trucks (in tonnes)
  weight_max REAL,
  age_threshold INTEGER, -- 8 for cars
  import_duty_rate REAL,
  vat_rate REAL,
  wht_rate REAL,
  environmental_levy_rate REAL,
  infrastructure_levy_rate REAL,
  reg_fees REAL,
  stamp_duty REAL,
  form_fees REAL,
  effective_from TEXT, -- Date when this rate became effective
  effective_to TEXT, -- NULL if current
  notes TEXT
);
```

### **5. FIXED CONSTANTS**
```dart
class TaxConstants {
  // Fixed Fees
  static const double numberPlatesPrice = 714300.0;
  static const double stampDuty = 18000.0;
  static const double formFees = 35000.0;
  static const double regFeesLightVehicle = 1500000.0;
  static const double regFeesHeavyVehicle = 1250000.0;
  
  // Tax Rates (can be overridden from database)
  static const double vatRate = 0.18;
  static const double whtRate = 0.06;
  static const double infrastructureLevy = 0.015;
  
  // Environmental Levy (varies by category)
  static const double envLevyOldCars = 0.50;
  static const double envLevyTrucks = 0.20;
  
  // Import Duty (varies by category)
  static const double importDutyCars = 0.25;
  static const double importDutyLightTrucks = 0.25;
  static const double importDutyMediumTrucks = 0.10;
  static const double importDutyHeavyTrucks = 0.00;
}
```

---

## 🎯 KEY BUSINESS RULES TO IMPLEMENT

### **Rule 1: Age-Based Surcharge**
- IF car age >= 8 years → Apply 50% environmental levy
- ELSE → No environmental levy

### **Rule 2: Weight-Based Truck Categories**
- 3-6.9 tonnes → 25% import duty, 20% environmental levy
- 7-19.9 tonnes → 10% import duty, 20% environmental levy, reduced reg fees
- 20+ tonnes → 0% import duty, 20% environmental levy, no infrastructure levy

### **Rule 3: Fixed Fees**
- Number plates: ALWAYS 714,300 UGX
- Stamp duty: ALWAYS 18,000 UGX
- Form fees: ALWAYS 35,000 UGX
- Reg fees: 1,500,000 (light) or 1,250,000 (heavy)

### **Rule 4: Customs Value Calculation**
- Customs Value = CIF_USD × Exchange_Rate
- ALL percentage-based taxes use this as the base

### **Rule 5: V.A.T Calculation**
- V.A.T = (Customs_Value + Import_Duty) × 18%
- V.A.T is on the DUTY-PAID value, not just customs value

---

## 📝 EXCEL FORMULA REFERENCE

### **Key Formulas from Sheets:**

**Quotation Sheet:**
- D21: `=B21*C21` (USD × Rate for C&F Mombasa)
- D25: `=D21+D22+D23+D24` (Total 1st Installment)
- D29: `='with surcharge'!B17` (Pull taxes from calculator)
- D36: `=SUM(D29:D35)` (Total 2nd Installment)
- D38: `=D25+D36` (Grand Total)

**Tax Calculator Sheets:**
- B6: `=B5*B3` (Customs Value = CIF × Rate)
- B9: `=B6*25%` (Import Duty)
- B10: `=(B6+B9)*18%` (V.A.T)
- B11: `=B6*6%` (W.H.T)
- B12: `=B6*50%` (Environmental - with surcharge) or `=B6*20%` (trucks)
- B16: `=B6*1.5%` (Infrastructure Levy)
- B17: `=SUM(B8:B16)` (Total Taxes)

---

## 🚀 NEXT STEPS FOR IMPLEMENTATION

1. **Create VehicleType enum and tax rate constants**
2. **Build TaxCalculator service class with all formulas**
3. **Update Invoice model to store tax breakdown**
4. **Add vehicle type selector in invoice form**
5. **Implement auto-calculation when vehicle details change**
6. **Add tax breakdown display (like Excel sheet structure)**
7. **Create database table for tax rate rules (future URA updates)**
8. **Build tax rate import tool for monthly updates**
9. **Add validation: Age vs Surcharge logic**
10. **Generate PDF quotation matching Excel format**

---

## ❓ QUESTIONS TO CLARIFY

1. **CIF Value Source**: Where does CIF USD come from?
   - Manual entry?
   - From vehicle stock database?
   - Import from supplier invoice?

2. **Exchange Rate**: 
   - Fixed or variable?
   - Updated daily/weekly/monthly?
   - Source (Bank of Uganda)?

3. **Tonnage for Trucks**:
   - How is tonnage determined?
   - User selects or auto-detected from make/model?

4. **Agency Fees & Insurance**:
   - Standard amounts per vehicle type?
   - Or always manually entered?

5. **Tax Rate Updates**:
   - How often does URA change rates?
   - Who updates the system?
   - Need approval workflow?

---

**Document Created:** $(date)
**Analysis Source:** NSB QUOTATION & TAX ASSESSMENTS(1) (Autosaved) (Autosaved) - Copy(3).xlsx
**Total Sheets Analyzed:** 6
**Status:** ✅ Complete Analysis Ready for Implementation
