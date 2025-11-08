#!/usr/bin/env python3
"""
MV Database PDF Extractor
Extracts vehicle tax data from URA MV Database PDF files
"""

import sys
import csv
import re
from pathlib import Path

try:
    import pdfplumber
except ImportError:
    print("Installing required package: pdfplumber...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pdfplumber", "--user", "--quiet"])
    import pdfplumber

def clean_number(text):
    """Clean and convert text to number"""
    if not text or text.strip() == '':
        return 0
    # Remove commas, spaces, currency symbols
    cleaned = re.sub(r'[,\s\$UGX]', '', str(text))
    try:
        return float(cleaned)
    except:
        return 0

def clean_text(text):
    """Clean text fields"""
    if not text:
        return ''
    return str(text).strip()

def extract_engine_size(text):
    """Extract engine size in CC from various formats"""
    if not text:
        return 0
    # Look for patterns like "1800cc", "1.8L", "1800 CC"
    text = str(text).upper()
    
    # Match CC format
    match = re.search(r'(\d+)\s*C\.?C', text)
    if match:
        return int(match.group(1))
    
    # Match liter format (1.8L -> 1800)
    match = re.search(r'(\d+\.?\d*)\s*L', text)
    if match:
        return int(float(match.group(1)) * 1000)
    
    # Just numbers
    match = re.search(r'(\d+)', text)
    if match:
        return int(match.group(1))
    
    return 0

def parse_year_range(text):
    """Parse year range like '2009-2017' or '2010'"""
    if not text:
        return 2000, 2024
    
    text = str(text).strip()
    
    # Single year
    if text.isdigit():
        year = int(text)
        return year, year
    
    # Range format: 2009-2017
    match = re.search(r'(\d{4})\s*[-–]\s*(\d{4})', text)
    if match:
        return int(match.group(1)), int(match.group(2))
    
    # Fallback
    return 2000, 2024

def extract_tables_from_pdf(pdf_path):
    """Extract all tables from PDF"""
    print(f"Opening PDF: {pdf_path}")
    
    all_data = []
    
    with pdfplumber.open(pdf_path) as pdf:
        print(f"Total pages: {len(pdf.pages)}")
        
        for page_num, page in enumerate(pdf.pages, 1):
            print(f"Processing page {page_num}...")
            
            # Extract tables from page
            tables = page.extract_tables()
            
            if not tables:
                # Try extracting text and parsing manually
                text = page.extract_text()
                if text:
                    # Try to find tabular data in text
                    lines = text.split('\n')
                    for line in lines:
                        # Look for lines with vehicle data
                        # This is a fallback - adjust based on actual PDF structure
                        if any(keyword in line.upper() for keyword in ['TOYOTA', 'HONDA', 'NISSAN', 'SUZUKI', 'SUBARU', 'MAZDA']):
                            all_data.append(['text_line', line])
            else:
                for table in tables:
                    all_data.extend(table)
    
    return all_data

def process_mv_database(pdf_path, output_csv):
    """Main processing function"""
    print("\n" + "="*60)
    print("MV DATABASE PDF EXTRACTOR")
    print("="*60 + "\n")
    
    # Extract raw data
    raw_data = extract_tables_from_pdf(pdf_path)
    
    if not raw_data:
        print("ERROR: No data extracted from PDF!")
        return False
    
    print(f"\nExtracted {len(raw_data)} rows of raw data")
    
    # Analyze first few rows to understand structure
    print("\n" + "-"*60)
    print("SAMPLE DATA (first 10 rows):")
    print("-"*60)
    for i, row in enumerate(raw_data[:10], 1):
        print(f"Row {i}: {row}")
    
    print("\n" + "-"*60)
    print("ANALYSIS:")
    print("-"*60)
    
    # Try to identify header row
    header_row = None
    data_start = 0
    
    for i, row in enumerate(raw_data[:20]):  # Check first 20 rows
        row_text = ' '.join([str(cell).upper() for cell in row if cell])
        if any(keyword in row_text for keyword in ['MAKE', 'MODEL', 'YEAR', 'ENGINE', 'TAX', 'DUTY']):
            header_row = i
            data_start = i + 1
            print(f"Found potential header at row {i}: {row}")
            break
    
    if header_row is None:
        print("WARNING: Could not identify header row automatically")
        print("Attempting to parse data without header...")
        data_start = 0
    
    # Process data rows
    processed_data = []
    skipped = 0
    
    for row_num, row in enumerate(raw_data[data_start:], data_start):
        try:
            # Skip empty rows
            if not row or all(not cell or str(cell).strip() == '' for cell in row):
                continue
            
            # Skip rows that look like headers
            row_text = ' '.join([str(cell).upper() for cell in row if cell])
            if 'MAKE' in row_text and 'MODEL' in row_text:
                continue
            
            # Try to extract vehicle data
            # This is a generic parser - you may need to adjust based on actual PDF structure
            
            # Attempt to identify columns
            make = None
            model = None
            year_from = 2000
            year_to = 2024
            engine_cc = 0
            fuel_type = 'Petrol'
            total_tax = 0
            
            # Process each cell
            for cell in row:
                if not cell:
                    continue
                
                cell_str = str(cell).strip()
                cell_upper = cell_str.upper()
                
                # Identify make (common car brands)
                if any(brand in cell_upper for brand in ['TOYOTA', 'HONDA', 'NISSAN', 'SUZUKI', 'SUBARU', 'MAZDA', 'MITSUBISHI', 'ISUZU', 'MERCEDES', 'BMW', 'AUDI', 'VOLKSWAGEN', 'LAND ROVER', 'RANGE ROVER']):
                    if not make:
                        make = cell_str.title()
                
                # Identify model (usually follows make)
                elif make and not model and len(cell_str) > 2 and cell_str[0].isupper():
                    # Skip if it looks like a year or number
                    if not cell_str.isdigit() and not re.match(r'\d{4}', cell_str):
                        model = cell_str
                
                # Identify years
                elif re.match(r'\d{4}', cell_str):
                    year_from, year_to = parse_year_range(cell_str)
                
                # Identify engine size
                elif 'CC' in cell_upper or 'L' in cell_upper:
                    engine_cc = extract_engine_size(cell_str)
                
                # Identify fuel type
                elif cell_upper in ['PETROL', 'DIESEL', 'HYBRID', 'ELECTRIC']:
                    fuel_type = cell_str.title()
                
                # Identify tax amounts (large numbers)
                else:
                    num = clean_number(cell_str)
                    if num > 100000:  # Likely a tax amount
                        if num > total_tax:
                            total_tax = num
            
            # Only add if we have minimum required data
            if make and model and total_tax > 0:
                processed_data.append({
                    'make': make,
                    'model': model,
                    'modelcode': '',
                    'bodytype': '',
                    'yearfrom': year_from,
                    'yearto': year_to,
                    'enginesizecc': engine_cc if engine_cc > 0 else 1500,  # Default to 1500 if missing
                    'fueltype': fuel_type,
                    'fobvalue': 0,
                    'customsvalue': 0,
                    'importduty': 0,
                    'exciseduty': 0,
                    'vat': 0,
                    'infrastructurelevy': 0,
                    'environmentallevy': 0,
                    'withholdingtax': 0,
                    'registrationfee': 0,
                    'totaltaxugx': total_tax
                })
            else:
                skipped += 1
        
        except Exception as e:
            print(f"Error processing row {row_num}: {e}")
            skipped += 1
            continue
    
    print(f"\nProcessed {len(processed_data)} valid records")
    print(f"Skipped {skipped} rows")
    
    if not processed_data:
        print("\nERROR: No valid data could be extracted!")
        print("\nThe PDF structure might be different than expected.")
        print("Please share a screenshot or description of the PDF layout.")
        return False
    
    # Show sample of processed data
    print("\n" + "-"*60)
    print("PROCESSED DATA SAMPLE (first 5 records):")
    print("-"*60)
    for i, record in enumerate(processed_data[:5], 1):
        print(f"{i}. {record['make']} {record['model']} ({record['yearfrom']}-{record['yearto']}) "
              f"{record['enginesizecc']}cc - Tax: {record['totaltaxugx']:,.0f} UGX")
    
    # Write to CSV
    print(f"\nWriting to CSV: {output_csv}")
    
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        fieldnames = [
            'make', 'model', 'modelcode', 'bodytype', 'yearfrom', 'yearto',
            'enginesizecc', 'fueltype', 'fobvalue', 'customsvalue', 'importduty',
            'exciseduty', 'vat', 'infrastructurelevy', 'environmentallevy',
            'withholdingtax', 'registrationfee', 'totaltaxugx'
        ]
        
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(processed_data)
    
    print(f"\n{'='*60}")
    print(f"SUCCESS! Extracted {len(processed_data)} vehicles")
    print(f"Output: {output_csv}")
    print(f"{'='*60}\n")
    
    return True

if __name__ == '__main__':
    pdf_path = '/home/darksagae/Desktop/Enick_Sales/Used MV Database Update October 2025.pdf'
    output_csv = '/home/darksagae/Desktop/Enick_Sales/mv_database_october_2025.csv'
    
    if not Path(pdf_path).exists():
        print(f"ERROR: PDF file not found: {pdf_path}")
        sys.exit(1)
    
    success = process_mv_database(pdf_path, output_csv)
    
    if success:
        print("\nYou can now import this CSV file using:")
        print("  Settings → Tax Database Import → Upload CSV")
    else:
        print("\nExtraction failed. Manual analysis needed.")
        print("\nPlease provide:")
        print("  1. A screenshot of a sample page from the PDF")
        print("  2. Or describe the table structure (columns)")


