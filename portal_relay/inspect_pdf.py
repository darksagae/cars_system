import pdfplumber
import sys

pdf_path = '/home/darksagae/Desktop/NSB/cars_system/TAX/Used MV Database Update October 2025.pdf'

with pdfplumber.open(pdf_path) as pdf:
    for i in range(min(5, len(pdf.pages))):
        print(f"--- PAGE {i+1} ---")
        print(pdf.pages[i].extract_text())
        print("\n")
