# 🔢 SHEET 3: TAX CALCULATOR WITHOUT SURCHARGE - COMPLETE GUIDE

## 🎯 WHAT IS THIS SHEET?

Sheet 3 "without Surcharge" is a **TAX CALCULATOR** for **NEWER PASSENGER CARS** (less than 10 years old).

In 2025: This applies to **2016 and newer** models.

**Think of it as:** The SAME calculator as Sheet 2, but WITHOUT the devastating 50% environmental levy!

---

## 🟢 WHY "WITHOUT SURCHARGE"?

Uganda government **ENCOURAGES** importing newer, cleaner vehicles:
- Newer cars = Less pollution
- No 50% environmental penalty
- Total tax rate: ~60% instead of ~110%
- **Customers save MILLIONS!**

```
2016 Car (9 years):   0% environmental levy → Affordable ✅
2015 Car (10 years): 50% environmental levy → Expensive 🔴

The difference is MASSIVE!
```

---

## 📊 WHEN TO USE THIS SHEET

```
Decision Rule:

Current Year: 2025
Vehicle Year: 2017
Age = 2025 - 2017 = 8 years

IF age < 10 years
   THEN use Sheet 3 (without surcharge)  ← 0% environmental levy ✅
ELSE
   THEN use Sheet 2 (with surcharge)     ← 50% environmental levy 🔴
```

**This Sheet Applies To (in 2025):**
- ✅ 2016 models (9 years old)
- ✅ 2017 models (8 years old)
- ✅ 2018 models (7 years old)
- ✅ 2019-2024 models (1-6 years old)
- ✅ All passenger cars NEWER than 10 years

---

## 📋 ROW-BY-ROW BREAKDOWN

### **INPUT SECTION (Same as Sheet 2)**

| Row | Field | Example | Notes |
|-----|-------|---------|-------|
| 3 | Exchange Rate | 3,586.88 | UGX per 1 USD |
| 4 | Vehicle Year | 2017 | Must be 2016+ for this sheet |
| 5 | CIF USD | $10,000 | Manual entry |
| 6 | Customs Value | 35,868,800 | = B5 × B3 |

---

### **TAX CALCULATIONS (Rows 8-17)**

#### **Row 8: Import Declaration Fees**
```
Formula: = B6 × 1%
Rate: 1%
Same as Sheet 2: ✅ IDENTICAL
```

#### **Row 9: Import Duty**
```
Formula: = B6 × 25%
Rate: 25%
Same as Sheet 2: ✅ IDENTICAL

For passenger cars, always 25%
```

#### **Row 10: V.A.T**
```
Formula: = (B6 + B9) × 18%
Rate: 18% on duty-paid value
Same as Sheet 2: ✅ IDENTICAL

V.A.T calculated on (Customs Value + Import Duty)
```

#### **Row 11: W.H.T (Withholding Tax)**
```
Formula: = B6 × 6%
Rate: 6%
Same as Sheet 2: ✅ IDENTICAL
```

#### **Row 12: Environmental Levy (SURCHARGE)** 🟢🟢🟢
```
Formula: (blank or 0%)
Rate: 0% ← THE GAME CHANGER!

⚠️ THIS IS THE ONLY DIFFERENCE!

Sheet 2 (with surcharge):    = B6 × 50%  🔴 HUGE TAX
Sheet 3 (without surcharge): = B6 × 0%   🟢 ZERO TAX

For $12,000 car (45.6M customs value):
- Sheet 2: Environmental = 22.8M UGX
- Sheet 3: Environmental = 0 UGX

SAVINGS: 22.8M UGX!!! 💰💰💰
```

#### **Row 13: Registration Fees**
```
Value: 1,500,000 UGX (FIXED)
Same as Sheet 2: ✅ IDENTICAL
```

#### **Row 14: Stamp Duty**
```
Value: 18,000 UGX (FIXED)
Same as Sheet 2: ✅ IDENTICAL
```

#### **Row 15: Form Fees**
```
Value: 35,000 UGX (FIXED)
Same as Sheet 2: ✅ IDENTICAL
```

#### **Row 16: Infrastructural Levy**
```
Formula: = B6 × 1.5%
Rate: 1.5%
Same as Sheet 2: ✅ IDENTICAL
```

#### **Row 17: TOTAL TAXES** ⭐
```
Formula: = SUM(B8:B16)
Same as Sheet 2: ✅ IDENTICAL FORMULA

BUT the RESULT is MUCH LOWER because Row 12 = 0!

🔗 Linked to Quotation Sheet Row 29
Formula in Quotation: ='without Surcharge'!B17
```

---

## 🔍 SHEET 2 vs SHEET 3 - SIDE BY SIDE

```
╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║                         SHEET 2 vs SHEET 3 COMPARISON                                          ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝

┌──────────────────────┬───────────────────────┬───────────────────────┬──────────────────┐
│ TAX COMPONENT        │ SHEET 2 (Old Cars)    │ SHEET 3 (New Cars)    │ DIFFERENCE       │
│                      │ 10+ years             │ < 10 years            │                  │
├──────────────────────┼───────────────────────┼───────────────────────┼──────────────────┤
│ Exchange Rate        │ B3 (Manual)           │ B3 (Manual)           │ SAME ✅          │
│ Vehicle Year         │ B4 (2015 or older)    │ B4 (2016+)            │ DIFFERENT        │
│ CIF USD              │ B5 (Manual)           │ B5 (Manual)           │ SAME ✅          │
│ Customs Value        │ =B5*B3                │ =B5*B3                │ SAME ✅          │
├──────────────────────┼───────────────────────┼───────────────────────┼──────────────────┤
│ Import Declaration   │ =B6*1%                │ =B6*1%                │ SAME ✅          │
│ Import Duty          │ =B6*25%               │ =B6*25%               │ SAME ✅          │
│ V.A.T                │ =(B6+B9)*18%          │ =(B6+B9)*18%          │ SAME ✅          │
│ W.H.T                │ =B6*6%                │ =B6*6%                │ SAME ✅          │
│ 🔥 Environmental     │ =B6*50% (22.8M)       │ =B6*0% (0)            │ DIFFERENT! 🔥    │
│ Registration Fees    │ 1,500,000             │ 1,500,000             │ SAME ✅          │
│ Stamp Duty           │ 18,000                │ 18,000                │ SAME ✅          │
│ Form Fees            │ 35,000                │ 35,000                │ SAME ✅          │
│ Infrastructure       │ =B6*1.5%              │ =B6*1.5%              │ SAME ✅          │
├──────────────────────┼───────────────────────┼───────────────────────┼──────────────────┤
│ TOTAL TAXES          │ 49.9M UGX (~110%)     │ 27.1M UGX (~60%)      │ 22.8M SAVINGS! 💰│
└──────────────────────┴───────────────────────┴───────────────────────┴──────────────────┘

💡 ONLY ONE LINE IS DIFFERENT: Row 12 (Environmental Levy)
   But this ONE line creates a 22.8M UGX difference!
```

---

## 💰 WORKED EXAMPLE: 2016 vs 2015 Comparison

### **Example: 2016 Toyota Harrier (Sheet 3)** ✅

```
╔═══════════════════════════════════════════════════════════════╗
║          2016 TOYOTA HARRIER - WITHOUT SURCHARGE             ║
╚═══════════════════════════════════════════════════════════════╝

INPUTS:
  Row 3: Exchange Rate = 3,800 UGX/USD
  Row 4: Year = 2016 (9 years old in 2025)
  Row 5: CIF USD = $12,000
  
CALCULATIONS:
─────────────────────────────────────────────────────────────────
Row 6:  Customs Value         = $12,000 × 3,800
                               = 45,600,000 UGX

TAX BREAKDOWN:
─────────────────────────────────────────────────────────────────
Row 8:  Import Declaration    = 45,600,000 × 1%
                               = 456,000 UGX

Row 9:  Import Duty          = 45,600,000 × 25%
                               = 11,400,000 UGX

Row 10: V.A.T                = (45,600,000 + 11,400,000) × 18%
                               = 57,000,000 × 18%
                               = 10,260,000 UGX

Row 11: W.H.T                = 45,600,000 × 6%
                               = 2,736,000 UGX

Row 12: Environmental Levy   = 45,600,000 × 0%
                               = 0 UGX ✅ ZERO!

Row 13: Registration Fees    = 1,500,000 UGX (fixed)

Row 14: Stamp Duty          = 18,000 UGX (fixed)

Row 15: Form Fees           = 35,000 UGX (fixed)

Row 16: Infrastructure Levy  = 45,600,000 × 1.5%
                               = 684,000 UGX

─────────────────────────────────────────────────────────────────
Row 17: ⭐ TOTAL TAXES       = 27,089,000 UGX
                               ($7,129 USD)
─────────────────────────────────────────────────────────────────

CUSTOMER TOTAL COST:
  CIF:                  45,600,000 UGX
  Taxes:                27,089,000 UGX
  Number Plates:           714,300 UGX
  Insurance:               200,000 UGX
  Agency Fees:             500,000 UGX
  ───────────────────────────────────
  GRAND TOTAL:          74,103,300 UGX ($19,500 USD)

Tax Rate: 59.4% of CIF ✅ REASONABLE
```

---

### **Comparison: Same Car, One Year Older (Sheet 2)** 🔴

```
╔═══════════════════════════════════════════════════════════════╗
║          2015 TOYOTA HARRIER - WITH SURCHARGE                ║
╚═══════════════════════════════════════════════════════════════╝

INPUTS:
  Row 3: Exchange Rate = 3,800 UGX/USD
  Row 4: Year = 2015 (10 years old in 2025)
  Row 5: CIF USD = $12,000 (SAME PRICE!)

Row 12: Environmental Levy   = 45,600,000 × 50%
                               = 22,800,000 UGX 🔴🔴🔴

─────────────────────────────────────────────────────────────────
Row 17: TOTAL TAXES          = 49,889,000 UGX
                               ($13,129 USD)
─────────────────────────────────────────────────────────────────

CUSTOMER TOTAL COST:
  CIF:                  45,600,000 UGX
  Taxes:                49,889,000 UGX 🔴
  Number Plates:           714,300 UGX
  Insurance:               200,000 UGX
  Agency Fees:             500,000 UGX
  ───────────────────────────────────
  GRAND TOTAL:          96,903,300 UGX ($25,500 USD)

Tax Rate: 109.4% of CIF 🔴 BRUTAL!
```

---

## 💡 THE ONE-LINE DIFFERENCE

```
╔════════════════════════════════════════════════════════════╗
║             ROW 12: ENVIRONMENTAL LEVY                     ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Sheet 2 (2015 car): = B6 × 50% = 22,800,000 UGX 🔴       ║
║  Sheet 3 (2016 car): = B6 × 0%  =         0 UGX ✅        ║
║                                                            ║
║  DIFFERENCE: 22,800,000 UGX ($6,000 USD)                  ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

THIS ONE LINE is why:
- Newer cars are more attractive to customers
- 2016 is the magic cutoff year in 2025
- Customers should ALWAYS choose 2016+ if possible
```

---

## 🎯 COMPLETE FORMULA REFERENCE

### **All Formulas in Sheet 3:**

```
Row 6:  Customs Value        = B5 × B3
Row 8:  Import Declaration   = B6 × 1%
Row 9:  Import Duty          = B6 × 25%
Row 10: V.A.T                = (B6 + B9) × 18%
Row 11: W.H.T                = B6 × 6%
Row 12: Environmental Levy   = B6 × 0%  🟢 ZERO!
Row 13: Registration Fees    = 1,500,000 (fixed)
Row 14: Stamp Duty          = 18,000 (fixed)
Row 15: Form Fees           = 35,000 (fixed)
Row 16: Infrastructure Levy  = B6 × 1.5%
Row 17: TOTAL TAXES         = SUM(B8:B16)
```

**99% identical to Sheet 2, except Row 12!**

---

## 🔄 HOW SHEET 3 CONNECTS TO QUOTATION

```
QUOTATION SHEET LOGIC:

Step 1: Check vehicle year
        IF (2025 - vehicleYear) < 10
           THEN use Sheet 3

Step 2: Pull taxes from Sheet 3
        Formula in Quotation Row 29:
        ='without Surcharge'!B17

Step 3: Display to customer
        Customer sees lower taxes!
        Higher chance of sale!

FLOW DIAGRAM:
┌─────────────────┐
│ Vehicle Year:   │
│ 2017 (8 years)  │───────┐
└─────────────────┘       │
                          │
                          ↓
                    ┌───────────────────┐
                    │ Age Check:        │
                    │ 8 < 10? YES!      │
                    └───────────────────┘
                          │
                          ↓
                    ┌───────────────────┐
                    │ Use Sheet 3       │
                    │ (without surcharge)│
                    └───────────────────┘
                          │
                          ↓
                    ┌───────────────────┐
                    │ Environmental = 0 │
                    │ Total Tax = 27M   │
                    └───────────────────┘
                          │
                          ↓
                    ┌───────────────────┐
                    │ Quotation Row 29  │
                    │ = 27M UGX         │
                    └───────────────────┘
                          │
                          ↓
                    ┌───────────────────┐
                    │ Happy Customer!   │
                    │ Lower price!      │
                    └───────────────────┘
```

---

## 💰 REAL-WORLD EXAMPLE WITH ACTUAL NUMBERS

### **Customer Scenario: Mark Wants a Family Car (2025)**

```
╔═══════════════════════════════════════════════════════════════╗
║                  MARK'S CAR SHOPPING IN 2025                 ║
╚═══════════════════════════════════════════════════════════════╝

CUSTOMER: Mark, 40M UGX budget, needs reliable family car

OPTION 1: 2015 Honda Fit @ $7,000 (10 years old - Sheet 2)
─────────────────────────────────────────────────────────────────
Customs Value:        $7,000 × 3,800 = 26,600,000 UGX
Environmental Levy:   26,600,000 × 50% = 13,300,000 UGX 🔴
Other Taxes:          12,800,000 UGX
Total Taxes:          26,100,000 UGX
───────────────────────────────────────────────────────────────
TOTAL COST TO MARK:   54,414,300 UGX ❌ OVER BUDGET!

OPTION 2: 2017 Suzuki Swift @ $6,500 (8 years old - Sheet 3)
─────────────────────────────────────────────────────────────────
Customs Value:        $6,500 × 3,800 = 24,700,000 UGX
Environmental Levy:   24,700,000 × 0% = 0 UGX ✅
Other Taxes:          11,950,000 UGX
Total Taxes:          11,950,000 UGX
───────────────────────────────────────────────────────────────
TOTAL COST TO MARK:   38,364,300 UGX ✅ UNDER BUDGET!

WHAT MARK GETS WITH OPTION 2:
✅ Saves 16M UGX
✅ Gets 2-year newer car (2017 vs 2015)
✅ Lower future maintenance
✅ Better resale value
✅ Still 1.6M under budget!

MARK'S DECISION: 2017 Swift! Easy choice!
```

---

## 🚀 IMPLEMENTATION IN FLUTTER

### **Tax Calculator Class (Without Surcharge)**

```dart
class TaxCalculatorWithoutSurcharge {
  final double cifUSD;
  final double exchangeRate;
  final int vehicleYear;
  
  // Row 6: Customs Value
  double get customsValue => cifUSD * exchangeRate;
  
  // Row 8: Import Declaration Fees
  double get importDeclarationFees => customsValue * 0.01;
  
  // Row 9: Import Duty
  double get importDuty => customsValue * 0.25;
  
  // Row 10: V.A.T (on duty-paid value!)
  double get vat => (customsValue + importDuty) * 0.18;
  
  // Row 11: W.H.T
  double get wht => customsValue * 0.06;
  
  // Row 12: Environmental Levy
  double get environmentalLevy => 0.0;  // 🟢 ZERO for newer cars!
  
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
         + environmentalLevy  // This is 0!
         + registrationFees
         + stampDuty
         + formFees
         + infrastructureLevy;
  }
  
  // Get breakdown
  Map<String, double> getTaxBreakdown() {
    return {
      'Import Declaration': importDeclarationFees,
      'Import Duty': importDuty,
      'V.A.T': vat,
      'W.H.T': wht,
      'Environmental Levy': environmentalLevy,  // Will be 0
      'Registration Fees': registrationFees,
      'Stamp Duty': stampDuty,
      'Form Fees': formFees,
      'Infrastructure Levy': infrastructureLevy,
      'TOTAL': totalTaxes,
    };
  }
}
```

### **Smart Tax Calculator (Auto-Select Sheet)**

```dart
class SmartTaxCalculator {
  final double cifUSD;
  final double exchangeRate;
  final int vehicleYear;
  
  double calculateTotalTaxes() {
    int currentYear = DateTime.now().year;  // 2025
    int age = currentYear - vehicleYear;
    
    if (age >= 10) {
      // Use Sheet 2: WITH surcharge
      return TaxCalculatorWithSurcharge(
        cifUSD: cifUSD,
        exchangeRate: exchangeRate,
        vehicleYear: vehicleYear,
      ).totalTaxes;
    } else {
      // Use Sheet 3: WITHOUT surcharge
      return TaxCalculatorWithoutSurcharge(
        cifUSD: cifUSD,
        exchangeRate: exchangeRate,
        vehicleYear: vehicleYear,
      ).totalTaxes;
    }
  }
  
  String getSheetUsed() {
    int age = DateTime.now().year - vehicleYear;
    return age >= 10 ? "with surcharge" : "without Surcharge";
  }
  
  bool hasEnvironmentalLevy() {
    int age = DateTime.now().year - vehicleYear;
    return age >= 10;
  }
}

// Usage:
final calculator = SmartTaxCalculator(
  cifUSD: 12000,
  exchangeRate: 3800,
  vehicleYear: 2016,
);

double taxes = calculator.calculateTotalTaxes();  // 27.1M UGX
String sheet = calculator.getSheetUsed();  // "without Surcharge"
bool hasLevy = calculator.hasEnvironmentalLevy();  // false
```

---

## 📊 TAX BREAKDOWN VISUALIZATION

### **For 2016 Car ($12,000 CIF):**

```
Tax Component               Amount (UGX)    % of Customs    % of Total Tax
──────────────────────────────────────────────────────────────────────────
Import Declaration            456,000          1.0%            1.7%
Import Duty                11,400,000         25.0%           42.1%
V.A.T                      10,260,000         22.5%*          37.9%
W.H.T                       2,736,000          6.0%           10.1%
Environmental Levy                  0          0.0% ✅         0.0% ✅
Registration Fees           1,500,000          3.3%            5.5%
Stamp Duty                     18,000          0.04%           0.1%
Form Fees                      35,000          0.08%           0.1%
Infrastructure Levy            684,000          1.5%            2.5%
──────────────────────────────────────────────────────────────────────────
TOTAL TAXES                27,089,000         59.4%          100%

* V.A.T is 18% of (Customs + Duty), so it's 22.5% of Customs Value alone
```

---

## 🎯 CUSTOMER SALES PITCH FOR SHEET 3 CARS

### **The Winning Script:**

```
CUSTOMER: "I'm looking at a 2015 Mark X for $12,000"

YOU: "Great choice of model! But let me help you save money.
      
      I have a 2016 Mark X for $12,000 - same price!
      
      Let me show you the difference:
      
      ┌──────────────────────────────────────────┐
      │ 2015 Model (10 years old):               │
      │ - Taxes: 49.9M UGX                       │
      │ - Total: 96.9M UGX                       │
      │ - You pay 50% environmental levy         │
      └──────────────────────────────────────────┘
      
      ┌──────────────────────────────────────────┐
      │ 2016 Model (9 years old):                │
      │ - Taxes: 27.1M UGX                       │
      │ - Total: 74.1M UGX                       │
      │ - NO environmental levy! ✅              │
      └──────────────────────────────────────────┘
      
      SAVINGS: 22.8M UGX!
      
      Same car model, same price, but 2016 saves you
      enough money to buy ANOTHER small car!
      
      Which one makes sense?"

CUSTOMER: "Obviously the 2016! Why would anyone buy 2015?"

YOU: "Exactly! That's why we focus on 2016 and newer.
      We want to save you money!"
```

---

## 📊 2025 RECOMMENDED INVENTORY MIX

Based on Sheet 3 logic, focus on:

```
PRIORITY VEHICLES (2025):
┌──────────┬─────────┬──────────────┬─────────────┬──────────────┐
│ Year     │ Age     │ Sheet Used   │ Env. Levy   │ Marketability│
├──────────┼─────────┼──────────────┼─────────────┼──────────────┤
│ 2023-24  │ 1-2 yr  │ Sheet 3      │ 0%          │ ⭐⭐⭐⭐⭐     │
│ 2020-22  │ 3-5 yr  │ Sheet 3      │ 0%          │ ⭐⭐⭐⭐       │
│ 2017-19  │ 6-8 yr  │ Sheet 3      │ 0%          │ ⭐⭐⭐         │
│ 2016     │ 9 yr    │ Sheet 3      │ 0%          │ ⭐⭐ (2026!)  │
├──────────┼─────────┼──────────────┼─────────────┼──────────────┤
│ 2015     │ 10 yr   │ Sheet 2      │ 50% 🔴      │ ⭐ Difficult  │
│ 2014-    │ 11+ yr  │ Sheet 2      │ 50% 🔴      │ ❌ Avoid      │
└──────────┴─────────┴──────────────┴─────────────┴──────────────┘

INVENTORY STRATEGY:
- 70%: 2017-2023 models (Sheet 3 - easy to sell)
- 20%: 2016 models (Sheet 3 - urgent sale before 2026)
- 10%: 2015 and older (Sheet 2 - only if great deal)
```

---

## 💡 KEY BUSINESS INSIGHTS

### **1. Sheet 3 Cars are Your Best Sellers**

```
WHY?
✅ Lower taxes = Lower customer cost
✅ Easier to fit customer budgets
✅ Faster sales turnover
✅ Higher customer satisfaction
✅ More referrals

PROFIT MARGIN:
2016 Car: Buy $10K, Sell 45M → Profit 12M UGX (fast sale)
2015 Car: Buy $10K, Sell 55M → Profit 12M UGX (slow sale)

Same profit, but 2016 sells 3× faster!
```

### **2. Use Tax Savings as Competitive Advantage**

```
COMPETITOR: "We have 2015 Harrier for 85M"

YOU: "We have 2016 Harrier for 79M
     AND it saves customer 22M in taxes!
     Total: 79M vs competitor's 85M + higher taxes
     
     We win on price AND tax efficiency!"
```

### **3. The 2026 Warning**

```
FOR 2016 VEHICLES:

SELL NOW: "This 2016 is 9 years old today.
          No environmental levy!
          
          But in 2026, it becomes 10 years old.
          Environmental levy kicks in.
          Resale value drops significantly.
          
          Buy it NOW while it's still tax-friendly!"

Creates urgency + legitimate value!
```

---

## ✅ VALIDATION & WARNING SYSTEM

### **When to Use Sheet 3:**

```dart
bool shouldUseSheetThree(int vehicleYear) {
  int currentYear = 2025;
  int age = currentYear - vehicleYear;
  
  // Sheet 3 for cars YOUNGER than 10 years
  return age < 10;
}

// In your system:
if (shouldUseSheetThree(vehicleYear)) {
  calculator = TaxCalculatorWithoutSurcharge(...);
  message = "✅ This vehicle qualifies for lower taxes!";
} else {
  calculator = TaxCalculatorWithSurcharge(...);
  message = "⚠️ 50% environmental levy applies!";
}
```

### **UI Warning Messages:**

```dart
// For 2016 vehicles (9 years old)
if (vehicleYear == 2016) {
  showInfo(
    "ℹ️ Note: This vehicle is 9 years old.\n"
    "No environmental levy today, but will have\n"
    "50% levy starting January 2026.\n"
    "Consider 2017+ for longer tax benefits."
  );
}

// For 2017+ vehicles
if (vehicleYear >= 2017) {
  showSuccess(
    "✅ This vehicle is ${age} years old.\n"
    "NO environmental levy!\n"
    "Customer saves ~22M UGX in taxes!"
  );
}
```

---

## 🎯 SUMMARY

**Sheet 3 (without Surcharge) is:**
- Tax calculator for cars LESS than 10 years old
- In 2025: Applies to 2016 and newer models
- **99% identical to Sheet 2, except NO environmental levy**
- Total tax: ~60% of CIF (vs 110% for old cars)
- Customer savings: ~22M UGX compared to 2015 cars

**The Single Critical Difference:**
```
Row 12: Environmental Levy

Sheet 2 (2015): = 22,800,000 UGX (50% of customs)
Sheet 3 (2016): = 0 UGX (0%)

This ONE row saves customers MILLIONS!
```

**Business Impact:**
- Focus inventory on Sheet 3 vehicles (2016+)
- Use tax savings as main selling point
- Educate customers on 10-year cutoff
- Build trust through transparency

**System Implementation:**
- Auto-detect which sheet to use based on vehicle year
- Show tax comparison (2015 vs 2016) to customers
- Warn about 2026 cutoff for 2016 vehicles
- Generate quotations with correct tax calculator

---

**Document Created:** October 13, 2025
**Applies To:** 2016 and newer vehicles in 2025
**Cutoff:** 2025 - 10 = 2015
**Status:** ✅ Complete and Ready for Implementation

---

**NSB MOTORS UGANDA**
"Buy 2016+ and Save Millions in Taxes!"
📞 +256 704 624217 | +256 752 128406
📧 nsbmotorsug@gmail.com
