# 📄 SHEET 1: QUOTATION - COMPLETE BUSINESS LOGIC GUIDE

## 🎯 WHAT IS THIS SHEET?

Sheet 1 "Quotation" is **the final document you give to customers**. It's like an invoice that shows:
- What vehicle they're buying
- How much they need to pay (broken into 2 installments)
- Where to send the money

---

## 💰 THE TWO-INSTALLMENT PAYMENT SYSTEM

```
┌─────────────────────────────────────────────────────────────────────┐
│                      CUSTOMER PAYMENT JOURNEY                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Step 1: Customer sees quotation                                   │
│  Step 2: Pays FIRST INSTALLMENT (USD costs in UGX)                 │
│          ↓ Vehicle is shipped from Mombasa to Kampala              │
│  Step 3: Pays SECOND INSTALLMENT (Taxes + Fees)                    │
│          ↓ Vehicle is registered and released                      │
│  Step 4: Customer collects vehicle                                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📋 SECTION-BY-SECTION BREAKDOWN

### 🔖 SECTION 1: HEADER (Rows 1-4)

**Row 2:** Document Title = "QUOTATION"
**Row 3:** Date = "DATE : 6th -Jul,2025"

**Purpose:** Identifies the document and when it was created.

**Implementation Notes:**
- Date should auto-generate: `DateTime.now()`
- Format: "DATE : ${day}th-${month},${year}"

---

### 👤 SECTION 2: CUSTOMER INFORMATION (Rows 5-7)

| Row | Field | Example | Source |
|-----|-------|---------|--------|
| 5 | Customer Name | "Ms" | From Customer table |
| 6 | Customer Contacts | "+2567" | Customer phone number |
| 7 | Customer Email | "N/A" | Customer email (or N/A) |

**Purpose:** Identify who is buying the vehicle.

**Implementation:**
```dart
Row 5: ${customer.name}
Row 6: ${customer.phone}
Row 7: ${customer.email ?? 'N/A'}
```

---

### 🚗 SECTION 3: VEHICLE DETAILS (Rows 9-14)

| Row | Field | Example | Purpose |
|-----|-------|---------|---------|
| 9 | Stock No. | "SWIFT2012" | Internal tracking (optional) |
| 10 | Make | "Suzuki" | Manufacturer |
| 11 | Chassis No. | "NKE165-8016821" | VIN for registration |
| 12 | Color | "SILVER" | Vehicle color |
| 13 | Engine Size / Fuel | "1490 C.C Petrol (Hybrid)" | For tax calculation |
| 14 | Year | "2015" | **CRITICAL for tax** |

**Critical Logic:**
```dart
int vehicleAge = currentYear - vehicleYear;
bool hasSurcharge = vehicleAge >= 8;

// Example:
2025 - 2015 = 10 years old
10 >= 8 → WITH SURCHARGE (50% environmental levy!)
```

**Purpose:** Vehicle identification + tax calculation input.

---

### 💵 SECTION 4: FIRST INSTALLMENT - USD COSTS (Rows 18-25)

**Row 20: Table Headers**
- [B] "COST IN USD"
- [C] "USD RATE" 
- [D] "COST IN Ugx"

#### **Row 21: C&F Mombasa**
```
Formula: D21 = B21 × C21
Example: $5,000 × 3,570 = 17,850,000 UGX
```
**Meaning:** Cost & Freight to Mombasa port (car price + shipping)

#### **Row 22: Clearance Mombasa-Kampala**
```
Formula: D22 = B22 × C22
Example: $1,000 × 3,570 = 3,570,000 UGX
```
**Meaning:** Transport from Mombasa to Kampala + Kenya customs clearance

#### **Row 23: C&F Kampala**
```
Formula: D23 = B23 × C23
Example: $500 × 3,570 = 1,785,000 UGX
```
**Meaning:** Additional costs upon arrival in Kampala

#### **Row 24: TT Charges**
```
Formula: D24 = B24 × C24
Example: $40 × 3,570 = 142,800 UGX
```
**Meaning:** Bank wire transfer fees (usually fixed at $40)

#### **Row 25: TOTAL FIRST INSTALLMENT**
```
Formula: D25 = D21 + D22 + D23 + D24
Example: 17,850,000 + 3,570,000 + 1,785,000 + 142,800 = 23,347,800 UGX
```

**🎯 This is what customer pays BEFORE vehicle arrives!**

---

### 💰 SECTION 5: SECOND INSTALLMENT - UGX COSTS (Rows 27-36)

#### **Row 29: Taxes Payable to URA** 🔗
```
Formula: D29 = 'with surcharge'!B17
          OR
         D29 = 'without Surcharge'!B17
```

**THIS IS THE KEY FORMULA!**

It **PULLS** the total taxes from one of the tax calculator sheets:
- If vehicle age >= 8 years → Use 'with surcharge' sheet
- If vehicle age < 8 years → Use 'without Surcharge' sheet

**Example from current sheet:**
- D29 = 1,553,000 UGX (for a 2015 car with no CIF entered, so only fixed fees)

**What's included in this number:**
1. Import Declaration Fees (1%)
2. Import Duty (25%)
3. V.A.T (18%)
4. Withholding Tax (6%)
5. Environmental Levy (0% or 50%)
6. Registration Fees (1,500,000 fixed)
7. Stamp Duty (18,000 fixed)
8. Form Fees (35,000 fixed)
9. Infrastructure Levy (1.5%)

#### **Row 30: Number Plates**
```
Value: 714,300 UGX (FIXED)
```
**Standard government price - NEVER changes**

#### **Row 31: 3rd Party Insurance**
```
Value: Manually entered
Example: 150,000 UGX (varies by vehicle)
```
**Mandatory insurance - price depends on vehicle type**

#### **Row 32: Agency Fees**
```
Value: Manually entered
Example: 400,000 UGX
```
**YOUR PROFIT! Your fee for handling everything:**
- Documentation
- URA liaison
- Registration process
- Customer service

#### **Row 36: REGISTRATION PROCESS TOTAL**
```
Formula: D36 = SUM(D29:D35)
Example: 1,553,000 + 714,300 + 0 + 400,000 = 2,667,300 UGX
```

**🎯 This is what customer pays AFTER vehicle arrives, BEFORE collection!**

---

### 🎯 SECTION 6: GRAND TOTAL (Row 38)

```
Formula: D38 = D25 + D36

Example:
= 23,347,800 (First Installment)
+ 2,667,300 (Second Installment)
= 26,015,100 UGX TOTAL PRICE

In USD: $7,287 (at 3,570 rate)
```

**This is the FINAL amount customer pays for everything!**

---

### 🏦 SECTION 7: BANK DETAILS (Rows 41-50)

| Row | Information |
|-----|-------------|
| 43 | **Payee:** NSB BUSINESS SOLUTIONS (U) LTD |
| 45 | **Bank:** EQUITY BANK |
| 47 | **Branch:** EQUITY BANK, CHURCH HOUSE |
| 48 | **SWIFT:** EQBLUGKA |
| 50 | **Account (UGX):** 1001202951908 |

**Purpose:** Where customer sends the money

**Note:** Should match your `StandardItems` constants in the system.

---

## 🔄 DATA FLOW DIAGRAM

```
┌───────────────────────────────────────────────────────────────────────┐
│                        HOW SHEET 1 WORKS                              │
└───────────────────────────────────────────────────────────────────────┘

   USER INPUTS:                  CALCULATIONS:                   OUTPUT:
                                                               
┌──────────────────┐         ┌──────────────────────┐      ┌──────────────┐
│ Customer Info    │────────▶│ Fill Rows 5-7        │      │              │
│ - Name           │         └──────────────────────┘      │              │
│ - Phone          │                                       │              │
│ - Email          │                                       │              │
└──────────────────┘                                       │              │
                                                           │              │
┌──────────────────┐         ┌──────────────────────┐      │              │
│ Vehicle Info     │────────▶│ Fill Rows 9-14       │      │              │
│ - Make/Model     │         │ Check Year (Row 14)  │      │   QUOTATION  │
│ - Year           │         │  ↓                   │      │   DOCUMENT   │
│ - Chassis        │         │ Age >= 8?            │      │              │
│ - Engine Size    │         └────────┬─────────────┘      │   (PDF)      │
└──────────────────┘                  │                    │              │
                                      ↓                    │              │
┌──────────────────┐         ┌──────────────────────┐      │              │
│ USD Costs        │────────▶│ Calculate Rows 21-25 │      │              │
│ - C&F Mombasa    │         │ Formula: USD × Rate  │      │              │
│ - Clearance      │         └──────────────────────┘      │              │
│ - Exchange Rate  │                                       │              │
└──────────────────┘                  │                    │              │
                                      ↓                    │              │
┌──────────────────┐         ┌──────────────────────┐      │              │
│ Tax Calculator   │◀────────│ Link to Sheet 2 or 3 │      │              │
│ (Sheet 2 or 3)   │         │ Pull taxes (Row 29)  │      │              │
│ Returns:         │────────▶│ Formula:             │      │              │
│ Total Taxes      │         │ ='with surcharge'!B17│      │              │
└──────────────────┘         └──────────────────────┘      │              │
                                      │                    │              │
┌──────────────────┐                  ↓                    │              │
│ Fixed Costs      │         ┌──────────────────────┐      │              │
│ - Number Plates  │────────▶│ Add Rows 30-32       │      │              │
│ - Insurance      │         │ Calculate Row 36     │      │              │
│ - Agency Fees    │         └──────────────────────┘      │              │
└──────────────────┘                  │                    └──────────────┘
                                      ↓                            │
                             ┌──────────────────────┐             │
                             │ Grand Total (Row 38) │             │
                             │ = Row 25 + Row 36    │             │
                             └──────────────────────┘             │
                                      │                           │
                                      └───────────────────────────┘
```

---

## 🔗 KEY FORMULA CONNECTIONS

### **The Most Important Formula in Sheet 1:**

**Row 29:** `='with surcharge'!B17`

This **LINKS** to the tax calculator sheet and pulls the total taxes.

**How it works:**

1. **In Sheet 2 (with surcharge):**
   - User enters: CIF USD, Exchange Rate, Year
   - Sheet calculates all taxes
   - **Row 17** contains the TOTAL TAXES
   
2. **Sheet 1 (Quotation):**
   - Formula in D29 references Sheet 2, Row 17
   - Value automatically updates when Sheet 2 changes
   
3. **This is an Excel cell reference formula**
   - `=` means formula
   - `'with surcharge'!` means "from the sheet named 'with surcharge'"
   - `B17` means cell B17 in that sheet

**In Your System:**
You need to replicate this by:
```dart
// Calculate taxes using TaxCalculator
double taxes = TaxCalculator(
  cifUSD: cifUSD,
  exchangeRate: exchangeRate,
  vehicleYear: vehicleYear,
  vehicleType: VehicleType.passengerCar,
).calculateTotalTax();

// Then use in invoice
invoice.taxesURA = taxes; // This is your "Row 29"
```

---

## 🎨 VISUAL EXAMPLE WITH REAL NUMBERS

Let's say customer wants a **2015 Toyota Harrier** for **$8,000 CIF**:

```
╔═══════════════════════════════════════════════════════════════╗
║                  QUOTATION FOR MR. JOHN DOE                   ║
║                     DATE: 13th-Oct, 2025                      ║
╚═══════════════════════════════════════════════════════════════╝

CUSTOMER INFORMATION:
  Name: John Doe
  Phone: +256 704 624217
  Email: john@example.com

VEHICLE DETAILS:
  Make: Toyota
  Model: Harrier
  Year: 2015 (10 years old → WITH SURCHARGE!)
  Chassis: ABC123XYZ456
  Engine: 2400 C.C Petrol
  Color: Black

═══════════════════════════════════════════════════════════════

FIRST INSTALLMENT (USD converted to UGX)
                        USD    |  Rate  |      UGX
────────────────────────────────────────────────────
C&F Mombasa:          $8,000   | 3,570  | 28,560,000
Clearance Mombasa-KLA: $1,200  | 3,570  |  4,284,000
C&F Kampala:             $500  | 3,570  |  1,785,000
TT Charges:               $40  | 3,570  |    142,800
                        ─────            ──────────
TOTAL FIRST:          $9,740             34,771,800 UGX

═══════════════════════════════════════════════════════════════

SECOND INSTALLMENT (All in UGX)
────────────────────────────────────────────────────
Taxes to URA:                            39,206,000
  (Breakdown: 25% duty + 18% VAT + 6% WHT
   + 50% environmental + 1.5% infrastructure
   + fixed fees)
   
Number Plates:                              714,300
3rd Party Insurance:                        200,000
Agency Fees:                                500,000
                                        ──────────
TOTAL SECOND:                            40,620,300 UGX

═══════════════════════════════════════════════════════════════

GRAND TOTAL:                             75,392,100 UGX
(Approximately $21,120 USD at rate 3,570)

═══════════════════════════════════════════════════════════════

PAYMENT DETAILS:
  Bank: EQUITY BANK
  Account (UGX): 1001202951908
  Payee: NSB BUSINESS SOLUTIONS (U) LTD
  SWIFT: EQBLUGKA
```

---

## 💡 KEY IMPLEMENTATION INSIGHTS

### **1. The Quotation is Reactive**
- When you change CIF in tax calculator → Row 29 updates
- When Row 29 updates → Row 36 updates
- When Row 36 updates → Row 38 (Grand Total) updates

### **2. Two Types of Fields**
**Auto-Calculated:**
- All USD × Exchange Rate conversions (Rows 21-24)
- First Installment Total (Row 25)
- Taxes from URA (Row 29) - pulled from other sheet
- Second Installment Total (Row 36)
- Grand Total (Row 38)

**Manually Entered:**
- Customer info
- Vehicle details
- USD amounts for shipping
- Exchange rate
- Insurance amount
- Agency fees

### **3. Critical Decision Point**
**Row 14 (Year) determines EVERYTHING:**
```
IF Year >= (Current Year - 8)
   THEN use 'without Surcharge' sheet → Lower taxes
ELSE
   THEN use 'with surcharge' sheet → Higher taxes (50% penalty!)
```

For 2015 car in 2025:
- 2025 - 2015 = 10 years
- 10 >= 8 → Use "with surcharge"
- Environmental Levy = 50% of customs value!

### **4. The Tax Link is Dynamic**
The formula `='with surcharge'!B17` means:
- Excel automatically fetches the value from that cell
- If tax calculation changes, quotation updates instantly
- **In your system:** You need to recalculate taxes whenever:
  - CIF changes
  - Exchange rate changes
  - Vehicle year changes
  - Vehicle type changes

---

## 🚀 HOW TO IMPLEMENT IN YOUR FLUTTER SYSTEM

### **Step 1: Create Invoice Model (Already Done! ✅)**
Your current `Invoice` model has most fields needed.

### **Step 2: Add Tax Calculator Integration**
```dart
// When creating invoice
final taxCalculator = TaxCalculator(
  cifUSD: invoice.clearanceFeeUSD, // Use as CIF
  exchangeRate: invoice.exchangeRate,
  vehicleYear: invoice.vehicleYear,
  vehicleType: determineVehicleType(invoice),
);

invoice.taxesURA = taxCalculator.calculateTotalTax();
```

### **Step 3: Real-time Calculation in UI**
```dart
// In invoice_form_screen.dart
void _calculateTotals() {
  // First Installment (USD → UGX)
  double firstInstallment = (carPriceUSD + clearanceFeeUSD + ttCharges) 
                          * exchangeRate;
  
  // Second Installment (UGX)
  double secondInstallment = taxesURA 
                           + numberPlatesFee 
                           + thirdPartyInsurance 
                           + agencyFees;
  
  // Grand Total
  double grandTotal = firstInstallment + secondInstallment;
  
  setState(() {
    _firstInstallmentUGX = firstInstallment;
    _secondInstallmentUGX = secondInstallment;
    _grandTotalUGX = grandTotal;
  });
}
```

### **Step 4: Auto-update on Changes**
```dart
// Attach listeners to all input controllers
_carPriceUSDController.addListener(_calculateTotals);
_exchangeRateController.addListener(_calculateTotals);
_taxesURAController.addListener(_calculateTotals);
// ... etc
```

### **Step 5: Generate PDF Quotation**
Use your existing PDF generation but match this exact layout!

---

## ✅ VALIDATION RULES

Before generating quotation, validate:

1. ✅ Customer selected (Rows 5-7 filled)
2. ✅ Vehicle details entered (Rows 9-14 filled)
3. ✅ At least one USD cost entered (Rows 21-24)
4. ✅ Exchange rate > 0 (Column C)
5. ✅ Taxes calculated (Row 29 > 0)
6. ✅ Agency fees entered (Row 32)
7. ✅ Grand Total > 0 (Row 38)

---

## 🎯 SUMMARY

**Sheet 1 (Quotation) is:**
- Customer-facing final document
- Shows 2-installment payment breakdown
- **Dynamically linked to tax calculator sheets**
- Grand Total = USD costs (converted) + UGX costs

**Most Critical Elements:**
1. **Row 14 (Year)** → Determines tax surcharge
2. **Row 29 (Taxes)** → Linked to tax calculator sheet
3. **Row 38 (Grand Total)** → Final price to customer

**In Your System:**
- Replicate all formulas in Dart
- Make calculations real-time
- Generate PDF matching this exact format
- Use TaxCalculator service for Row 29 value

---

**Document Created:** $(date)
**Source:** NSB QUOTATION & TAX ASSESSMENTS - Sheet 1 Analysis
**Status:** ✅ Complete and Ready for Implementation
