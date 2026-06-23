#!/usr/bin/env python3
import pdfplumber
import csv
import re
import sys
import os

def clean_num(txt):
    if not txt: return 0
    # Remove commas and spaces
    txt = str(txt).replace(',', '').replace(' ', '').strip()
    # If there are multiple dots, it's likely thousands separators or OCR error
    if txt.count('.') > 1:
        # Keep only the last dot if it looks like a decimal, otherwise remove all
        parts = txt.split('.')
        if len(parts[-1]) <= 2: # Likely decimal
            txt = "".join(parts[:-1]) + "." + parts[-1]
        else:
            txt = "".join(parts)
    try:
        return float(txt)
    except:
        return 0

MAKES = ['TOYOTA', 'HONDA', 'NISSAN', 'SUZUKI', 'SUBARU', 'MAZDA', 'MITSUBISHI', 'ISUZU', 'MERCEDES', 'BMW', 'AUDI', 'VOLKSWAGEN', 'LAND ROVER', 'RANGE ROVER', 'LEXUS', 'INFINITI', 'ACURA', 'HYUNDAI', 'KIA', 'HINO', 'SCANIA', 'MAN', 'VOLVO', 'DAF', 'IVECO', 'RENAULT', 'PEUGEOT', 'FORD', 'CHEVROLET', 'JEEP']

def extract_data(pdf_path):
    print(f"Opening {pdf_path}...")
    vehicles = []
    
    with pdfplumber.open(pdf_path) as pdf:
        total = len(pdf.pages)
        for i, page in enumerate(pdf.pages):
            if i % 10 == 0: print(f"Processing page {i}/{total}...")
            text = page.extract_text()
            if not text: continue
            
            lines = text.split('\n')
            for line in lines:
                # Pattern: Serial (1-5 digits) + HS Code (87xx.xx.xx) + Country (2-3 letters)
                # Then description... then CIF at the end
                match = re.search(r'^(\d+)\s+(87\d{2}(?:\.\d{2}){2})\s+([A-Z]{2,3})\s+(.+?)\s+([0-9,.]+)\s*$', line)
                if match:
                    serial, hs, country, desc, cif_str = match.groups()
                    
                    # Clean cif
                    cif = clean_num(cif_str)
                    if cif < 100: continue # Skip small numbers (might be something else)
                    
                    # Extract year
                    year_match = re.search(r'\b(19|20)\d{2}\b', desc)
                    year = int(year_match.group(0)) if year_match else 0
                    
                    # Extract CC
                    cc_match = re.search(r'(\d+)\s*(?:cc|CC|Litre)', desc, re.I)
                    cc = int(cc_match.group(1)) if cc_match else 0
                    
                    # Identify make
                    make = "Unknown"
                    desc_upper = desc.upper()
                    for m in MAKES:
                        if m in desc_upper:
                            make = m.title()
                            break
                    
                    # Model (everything between make and year/cc)
                    words = desc.split()
                    model = "Unknown"
                    if make != "Unknown":
                        try:
                            start_idx = desc_upper.find(make.upper()) + len(make)
                            model_text = desc[start_idx:].strip()
                            # Strip year and CC from model
                            model_text = re.sub(r'\b(19|20)\d{2}\b', '', model_text)
                            model_text = re.sub(r'\b\d+\s*(?:cc|CC|Litre)\b', '', model_text, flags=re.I)
                            model = model_text.split(',')[0].strip()
                        except: pass
                    else:
                        model = words[0] if words else "Unknown"
                    
                    vehicles.append({
                        'serial_number': serial,
                        'hsc_code': hs,
                        'country_origin': country,
                        'make': make,
                        'model': model,
                        'year': year,
                        'engine_cc': cc,
                        'description': desc,
                        'cif_usd': cif,
                        'database_month': 'October 2025'
                    })
                else:
                    if len(line) > 20 and any(c.isdigit() for c in line[:5]):
                        # print(f"Skipped: {line}") # Debug
                        pass

    return vehicles

if __name__ == "__main__":
    pdf = '/home/darksagae/Desktop/NSB/cars_system/TAX/Used MV Database Update October 2025.pdf'
    out = 'mv_data_full.csv'
    
    data = extract_data(pdf)
    print(f"Extracted {len(data)} vehicles.")
    
    if data:
        with open(out, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)
        print(f"Saved to {out}")
