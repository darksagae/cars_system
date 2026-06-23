# PDF Invoice Analysis

## Overview
The PDF invoice system generates professional quotation/invoice documents for vehicle sales. The invoice is structured as a two-phase payment system with detailed breakdowns of costs in both USD and UGX (Ugandan Shillings).

## Invoice Structure

### 1. Document Header Section
**Location**: Lines 1598-1791 (`_buildDocumentTitle`)

**Components**:
- **Company Logo**: Loaded from `assets/logo/logo.png` (80x50px)
- **Company Information**:
  - Name: "NSB BUSINESS SOLUTIONS (U) LTD"
  - Tagline: "People • Product • Growth"
  - Address: P.O. Box 110833, Kampala - Uganda, Kamu Kamu Plaza, Suite No. SF-31
- **Contact Information** (with icons):
  - Phone: +256 394 836253 / +256 752 128406 (WhatsApp icon)
  - Email: nsbbsolutions@gmail.com (Gmail icon)
  - Social Media: Facebook, X (Twitter), TikTok, Instagram (@nsb motors ug)
- **Document Title**: "QUOTATION" (24pt bold)
- **Date**: Formatted as "DAYth -MONTH, YEAR" (e.g., "15th -Jan, 2024")

**Visual Elements**:
- Location icon (24x24px) above address
- Social media icons (14x14px) in footer
- Horizontal divider line separating header from content

---

### 2. Customer Information Section
**Location**: Lines 1793-1862 (`_buildCustomerInformation`)

**Fields Displayed**:
- Customer Name (bold label)
- Customer Contacts (phone number)
- Customer Email (blue color, italic)

**Data Source**:
- Primary: `invoice.customer` object
- Fallback: Extracted from `invoice.notes` field if customer not linked
- Format: Two-column table (Label | Value)

---

### 3. Vehicle Details Section
**Location**: Lines 1864-1987 (`_buildVehicleDetails`)

**Fields Displayed**:
- **Stock No.**: Vehicle stock number
- **Make**: Vehicle manufacturer (e.g., Toyota, Honda)
- **Chassis No.**: Vehicle chassis/vin number
- **Color**: Vehicle color (displayed in UPPERCASE)
- **Engine Size / Fuel type**: Format "XXXXcc / FuelType" (e.g., "2000cc / Petrol")
- **Year**: Manufacturing year

**Data Source**:
- Primary: Invoice model fields (`invoice.stockNo`, `invoice.vehicleMake`, etc.)
- Fallback: Parsed from `invoice.notes` via `_parseInvoiceNotes()` method
- Additional parsed fields (if available):
  - Serial Number (S/N)
  - Tonnage

**Format**: Two-column table (Label | Value)

---

### 4. First Installment Section
**Location**: Lines 1989-2088 (`_buildFirstInstallmentTable`)

**Purpose**: Shows costs for vehicle import and clearance (Phase 1)

**Table Structure**:
| Column | Description |
|--------|-------------|
| DESCRIPTION | Service name |
| COST IN USD | Amount in US Dollars |
| USD RATE | Exchange rate (USD to UGX) |
| COST IN UGX | Amount in Ugandan Shillings |

**Dynamic Rows** (shown only if selected):
1. **C&F Mombasa** (Cost & Freight to Mombasa)
   - USD amount from `parsed.cfMombasaUsd`
   - UGX = USD × Rate

2. **Clearance Mombasa-Kampala**
   - USD amount from `parsed.clearanceUsd`
   - UGX = USD × Rate

3. **C&F Kampala** (Cost & Freight to Kampala)
   - USD amount from `parsed.cfKampalaUsd` or `invoice.carPriceUSD`
   - UGX = USD × Rate

4. **TT Charges** (Telegraphic Transfer charges)
   - Default: $40 USD
   - From `parsed.ttUsd` or default 40.0
   - UGX = 40 × Rate

**Total Row**:
- Shows "TOTAL" with First Installment Total in UGX
- Source: `invoice.firstInstallmentUGX` or `parsed.phase1TotalUgx`

**Calculation Logic**:
```dart
First Installment Total = (Selected Path UGX) + (TT Charges UGX)
```
- Selected Path can be: C&F Mombasa, Clearance, or C&F Kampala
- Only selected options are displayed
- Rate: `parsed.phase1Rate ?? invoice.exchangeRate`

---

### 5. Second Installment Section
**Location**: Lines 2184-2294 (`_buildSecondInstallmentTable`)

**Purpose**: Shows costs for vehicle registration and taxes (Phase 2)

**Table Structure**:
| Column | Description |
|--------|-------------|
| DESCRIPTION | Fee/tax name |
| AMOUNT (UGX) | Amount in Ugandan Shillings |

**Rows**:
1. **Taxes Payable to URA** (Uganda Revenue Authority)
   - Source: `invoice.taxesURA` or `parsed.taxesUra`

2. **Number Plates**
   - Source: `invoice.numberPlatesFee` or `parsed.plates`
   - Default: 714,300 UGX

3. **3rd Party Insurance**
   - Source: `invoice.thirdPartyInsurance` or `parsed.insurance`
   - Only shown if amount > 0

4. **Agent Fees**
   - Source: `invoice.agencyFees` or `parsed.agent`

**Note**: No total row here - total is shown in Grand Total Summary

---

### 6. Grand Total Summary Section
**Location**: Lines 2319-2403 (`_buildRegistrationProcessSection`)

**Purpose**: Final summary of all costs

**Table Structure**:
| Column | Description |
|--------|-------------|
| COMPONENT | Cost category |
| AMOUNT (UGX) | Amount in Ugandan Shillings |

**Rows**:
1. **First Installment**
   - Total from First Installment section

2. **Registration Process**
   - Sum of: URA Taxes + Number Plates + Insurance + Agent Fees
   - Formula: `taxesURA + numberPlatesFee + thirdPartyInsurance + agencyFees`

3. **GRAND TOTAL (UGX)** (bold, larger font)
   - Formula: `First Installment + Registration Process`

**Calculation**:
```dart
Grand Total = First Installment UGX + Second Installment UGX
Second Installment = Registration Process = URA + Plates + Insurance + Agent
```

---

### 7. Bank Information Footer
**Location**: Lines 2413-2503 (`_buildBankFooterSection`)

**Components**:

**Bank Details**:
- Payee: NSB BUSINESS SOLUTIONS (U) LTD
- Bank Name: EQUITY BANK
- Bank Address: EQUITY BANK, CHURCH HOUSE
- SWIFT CODE: EQBLUGKA
- Account Numbers (bold, red):
  - UGX: 1001202951908
  - USD: 1001203004471

**Business Footer**:
- Black background with white text
- Text: ".... Business & Logistics Partner"
- Centered alignment

---

## Data Flow & Calculations

### Invoice Data Sources (Priority Order)

1. **Primary Source**: Invoice model fields
   - `invoice.firstInstallmentUGX`
   - `invoice.taxesURA`
   - `invoice.numberPlatesFee`
   - `invoice.thirdPartyInsurance`
   - `invoice.agencyFees`
   - `invoice.exchangeRate`

2. **Secondary Source**: Parsed from `invoice.notes`
   - Extracted via `_parseInvoiceNotes()` method
   - Supports legacy invoices with data in notes field
   - Parses structured text like "Phase 1 Total: 5000000"

3. **Fallback Values**:
   - TT Charges: 40.0 USD (if not specified)
   - Exchange Rate: `invoice.exchangeRate` (default: 3834.56)
   - Number Plates: 714,300 UGX

### Notes Parsing Logic
**Location**: Lines 1384-1480 (`_parseInvoiceNotes`)

**Supported Patterns**:
- `Phase 1 Total: 5000000` → `phase1TotalUgx`
- `C&F Mombasa: 2000` → `cfMombasaUsd`
- `Clearance Msa→Kla: 1500` → `clearanceUsd`
- `C&F Kampala: 3000` → `cfKampalaUsd`
- `TT Charges: 40` → `ttUsd`
- `Phase 1 Rate: 3834.56` → `phase1Rate`
- `URA Taxes: 2000000` → `taxesUra`
- `Number Plates: 714300` → `plates`
- `3rd Party Insurance: 500000` → `insurance`
- `Agency Fees: 300000` → `agent`
- `Registration Process: 2667300` → `registrationProcess`

**Legacy Support**:
- `Phase 1 Mode: C&F Mombasa` → Used if individual values not available
- Supports old format where mode was stored as string

---

## Key Features

### 1. Dynamic Option Display
- Only shows selected Phase 1 options (C&F Mombasa, Clearance, C&F Kampala)
- Supports 1 or 2 selected options
- Handles legacy invoices with mode-based selection

### 2. Currency Conversion
- All USD amounts converted to UGX using exchange rate
- Rate can vary per invoice (stored in `invoice.exchangeRate`)
- Format: `USD Amount × Exchange Rate = UGX Amount`

### 3. Fallback Data Handling
- Extracts customer info from notes if not linked
- Parses vehicle details from notes if fields empty
- Graceful degradation when data missing

### 4. Professional Styling
- Company branding (logo, colors)
- Social media integration
- Clean table layouts with borders
- Consistent typography (Roboto font)
- Color-coded sections

### 5. Multi-Phase Payment Structure
- **Phase 1**: Import/Clearance costs (USD-based)
- **Phase 2**: Registration/Tax costs (UGX-based)
- Clear separation and summary

---

## Technical Implementation

### PDF Generation Library
- **Package**: `pdf` (Dart PDF package)
- **Widgets**: `pdf/widgets.dart` (pw namespace)
- **Printing**: `printing` package for print functionality

### Image Loading
- Logo: `assets/logo/logo.png`
- Icons: `assets/fonts/*.png` (address, whatsapp, facebook, instagram, x, tiktok, gmail)
- Fallback: Text placeholder if images not found

### Fonts
- Base: Roboto Regular (Google Fonts)
- Bold: Roboto Bold (Google Fonts)
- Loaded via `PdfGoogleFonts.robotoRegular()`

### Page Format
- **Size**: A4 (PdfPageFormat.a4)
- **Margin**: 8pt all around
- **Orientation**: Portrait

### Number Formatting
- **Money (no decimals)**: `#,##0` (e.g., 1,234,567)
- **Money (with decimals)**: `#,##0.00` (e.g., 1,234,567.89)
- **Date**: "DAYth -MONTH, YEAR" (e.g., "15th -Jan, 2024")

---

## Potential Issues & Improvements

### Current Issues

1. **Date Formatting**
   - Format: "15th -Jan, 2024" has unusual spacing
   - Could be improved to "15th Jan, 2024" or "January 15, 2024"

2. **Missing Invoice Number Display**
   - Invoice number not prominently displayed in header
   - Should be visible near "QUOTATION" title

3. **No Page Numbers**
   - Multi-page invoices would benefit from page numbers

4. **Hardcoded Values**
   - Bank account numbers hardcoded
   - Company address hardcoded
   - Could be moved to configuration

5. **Error Handling**
   - Logo loading failures are caught but could show better fallback
   - Missing customer data shows "N/A" but could be more informative

### Suggested Improvements

1. **Add Invoice Number to Header**
   ```dart
   pw.Text('QUOTATION #${invoice.invoiceNumber}', ...)
   ```

2. **Add Terms & Conditions Section**
   - Payment terms
   - Delivery timeline
   - Warranty information

3. **Add QR Code**
   - Payment QR code for mobile money
   - Invoice verification QR code

4. **Multi-language Support**
   - Support for local languages (Luganda, Swahili)

5. **Digital Signature**
   - Company signature/image
   - Date and authorized by field

6. **Tax Breakdown**
   - Detailed URA tax breakdown (if available in parsed notes)
   - Shows: Customs Value, Import Duty, VAT, WHT, etc.

7. **Payment Status Indicator**
   - Visual indicator if invoice is paid/partially paid
   - Payment history table

8. **Due Date Display**
   - Show payment due date prominently
   - Highlight if overdue

---

## Data Validation

### Required Fields for Complete Invoice
- Customer information (name, contacts)
- Vehicle details (make, model, year)
- At least one Phase 1 option selected
- Exchange rate
- URA taxes amount
- Number plates fee

### Optional Fields
- Customer email
- Vehicle color
- Chassis number
- Engine size
- 3rd Party Insurance
- Agent fees

---

## Testing Scenarios

### Test Case 1: Complete Invoice
- All fields populated
- Both Phase 1 options selected
- All Phase 2 fees present
- Expected: Full invoice with all sections

### Test Case 2: Minimal Invoice
- Only required fields
- Single Phase 1 option
- Missing optional fields
- Expected: Invoice generated with "N/A" for missing fields

### Test Case 3: Legacy Invoice
- Data stored in notes field
- Old format parsing
- Expected: Correctly parsed and displayed

### Test Case 4: Missing Logo
- Logo file not found
- Expected: Fallback "NSB" text box

### Test Case 5: Zero Values
- Insurance = 0
- Expected: Insurance row not shown or shown as empty

---

## Summary

The PDF invoice system is well-structured with:
- ✅ Clear two-phase payment breakdown
- ✅ Professional branding and layout
- ✅ Flexible data sources (model fields + notes parsing)
- ✅ Currency conversion support
- ✅ Dynamic option display
- ✅ Comprehensive vehicle and customer information

**Areas for Enhancement**:
- Add invoice number to header
- Improve date formatting
- Add terms & conditions
- Support for payment status indicators
- Configuration file for hardcoded values

The system is production-ready and handles edge cases gracefully with fallback mechanisms.




