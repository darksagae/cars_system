#!/bin/bash

# URA PDF Extractor Setup Script
# Installs Python dependencies and sets up the PDF extraction environment

echo "🚀 Setting up URA PDF Extractor..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first:"
    echo "   Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip"
    echo "   Windows: Download from python.org"
    echo "   macOS: brew install python3"
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip3 first:"
    echo "   Ubuntu/Debian: sudo apt install python3-pip"
    exit 1
fi

echo "✅ pip3 found: $(pip3 --version)"

# Create python_pdf_extractor directory
EXTRACTOR_DIR="python_pdf_extractor"
if [ ! -d "$EXTRACTOR_DIR" ]; then
    mkdir -p "$EXTRACTOR_DIR"
    echo "✅ Created $EXTRACTOR_DIR directory"
fi

# Copy the Python script
if [ -f "python_pdf_extractor/ura_pdf_extractor.py" ]; then
    echo "✅ Python extraction script found"
else
    echo "❌ Python extraction script not found. Please ensure ura_pdf_extractor.py is in the $EXTRACTOR_DIR directory"
    exit 1
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
cd "$EXTRACTOR_DIR"

if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt --user
    if [ $? -eq 0 ]; then
        echo "✅ Python dependencies installed successfully"
    else
        echo "❌ Failed to install Python dependencies"
        exit 1
    fi
else
    echo "❌ requirements.txt not found"
    exit 1
fi

# Make the script executable
chmod +x ura_pdf_extractor.py
echo "✅ Made extraction script executable"

# Test the installation
echo "🧪 Testing Python extraction script..."
python3 ura_pdf_extractor.py --help
if [ $? -eq 0 ]; then
    echo "✅ Python extraction script is working correctly"
else
    echo "❌ Python extraction script test failed"
    exit 1
fi

cd ..

echo ""
echo "🎉 URA PDF Extractor setup completed successfully!"
echo ""
echo "📋 What was installed:"
echo "   • Python 3 and pip3"
echo "   • pdfplumber library for PDF extraction"
echo "   • pandas for data processing"
echo "   • numpy for numerical operations"
echo "   • openpyxl for Excel file handling"
echo ""
echo "🚀 You can now use the Python PDF extraction in the Flutter app!"
echo ""
echo "📖 Usage:"
echo "   1. Open the Flutter app"
echo "   2. Go to PDF Import tab in the Hybrid Import Wizard"
echo "   3. Select a URA PDF file"
echo "   4. Click 'Extract with Python'"
echo ""
echo "💡 The extracted CSV will be automatically generated and ready for import."



