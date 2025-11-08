#!/bin/bash

# Sales System Windows Installer Build Script for Linux
# This script builds the Windows installer from a Linux environment

set -e

echo "Building Sales System Windows Installer from Linux..."
echo "====================================================="

# Set variables
APP_NAME="Sales System"
VERSION="1.0.0"
BUILD_DIR="build/windows/x64/runner/Release"
INSTALLER_DIR="installer"
OUTPUT_DIR="dist"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    echo "Please install Flutter and add it to your PATH"
    exit 1
fi

# Check if Wine is installed (for Windows compatibility)
if ! command -v wine &> /dev/null; then
    echo "WARNING: Wine is not installed. Some Windows-specific features may not work."
    echo "Consider installing Wine for better Windows compatibility."
fi

echo ""
echo "Step 1: Building Flutter application for Windows..."
echo "=================================================="

# Clean previous builds
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# Build Flutter app for Windows
flutter build windows --release
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter build failed"
    exit 1
fi

echo ""
echo "Step 2: Preparing installer files..."
echo "===================================="

# Create installer directory structure
mkdir -p "$INSTALLER_DIR/assets"
mkdir -p "$INSTALLER_DIR/data"

# Copy application files
mkdir -p "$INSTALLER_DIR/build"
cp -r "$BUILD_DIR"/* "$INSTALLER_DIR/build/"

# Download Visual C++ Redistributable
echo "Downloading Visual C++ Redistributable..."
if command -v wget &> /dev/null; then
    wget -O "$INSTALLER_DIR/vcredist_x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe" || echo "WARNING: Failed to download Visual C++ Redistributable"
elif command -v curl &> /dev/null; then
    curl -L -o "$INSTALLER_DIR/vcredist_x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe" || echo "WARNING: Failed to download Visual C++ Redistributable"
else
    echo "WARNING: Neither wget nor curl found. Please download Visual C++ Redistributable manually."
fi

# Download SQLite
echo "Downloading SQLite..."
if command -v wget &> /dev/null; then
    wget -O "$INSTALLER_DIR/sqlite.zip" "https://www.sqlite.org/2024/sqlite-dll-win64-x64-3460000.zip" || echo "WARNING: Failed to download SQLite"
elif command -v curl &> /dev/null; then
    curl -L -o "$INSTALLER_DIR/sqlite.zip" "https://www.sqlite.org/2024/sqlite-dll-win64-x64-3460000.zip" || echo "WARNING: Failed to download SQLite"
else
    echo "WARNING: Neither wget nor curl found. Please download SQLite manually."
fi

# Extract SQLite
if [ -f "$INSTALLER_DIR/sqlite.zip" ]; then
    if command -v unzip &> /dev/null; then
        unzip -o "$INSTALLER_DIR/sqlite.zip" -d "$INSTALLER_DIR/sqlite"
        if [ -f "$INSTALLER_DIR/sqlite/sqlite-dll-win64-x64-3460000/sqlite3.exe" ]; then
            cp "$INSTALLER_DIR/sqlite/sqlite-dll-win64-x64-3460000/sqlite3.exe" "$INSTALLER_DIR/sqlite3.exe"
        fi
        rm -rf "$INSTALLER_DIR/sqlite"
        rm "$INSTALLER_DIR/sqlite.zip"
    else
        echo "WARNING: unzip not found. Please extract SQLite manually."
    fi
fi

# Create application icon
echo "Creating application icon..."
if [ ! -f "$INSTALLER_DIR/assets/icon.ico" ]; then
    echo "Creating placeholder icon..."
    # This is a placeholder - you should provide a real icon file
    touch "$INSTALLER_DIR/assets/icon.ico"
fi

# Create LICENSE file
echo "Creating LICENSE file..."
cat > "$INSTALLER_DIR/LICENSE.txt" << 'EOF'
Sales System License
====================

Copyright (c) 2024 Enick Sales

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

echo ""
echo "Step 3: Building NSIS installer..."
echo "=================================="

# Check if NSIS is available
if command -v makensis &> /dev/null; then
    # Build the installer
    makensis "$INSTALLER_DIR/sales_system_installer.nsi"
    if [ $? -ne 0 ]; then
        echo "ERROR: NSIS build failed"
        exit 1
    fi
    
    # Move installer to output directory
    if [ -f "$INSTALLER_DIR/SalesSystemSetup.exe" ]; then
        mv "$INSTALLER_DIR/SalesSystemSetup.exe" "$OUTPUT_DIR/SalesSystemSetup_$VERSION.exe"
        echo ""
        echo "SUCCESS: Installer created successfully!"
        echo "Installer location: $OUTPUT_DIR/SalesSystemSetup_$VERSION.exe"
    else
        echo "ERROR: Installer file not found"
        exit 1
    fi
else
    echo "WARNING: NSIS not found. Skipping installer creation."
    echo "Please install NSIS or run this script on a Windows system."
fi

echo ""
echo "Step 4: Creating portable version..."
echo "===================================="

# Create portable version
mkdir -p "$OUTPUT_DIR/SalesSystem_Portable"
cp -r "$BUILD_DIR"/* "$OUTPUT_DIR/SalesSystem_Portable/"

# Create portable launcher
cat > "$OUTPUT_DIR/SalesSystem_Portable/SalesSystem.bat" << 'EOF'
@echo off
echo Starting Sales System...
start "" "sales_system.exe"
EOF

# Create portable README
cat > "$OUTPUT_DIR/SalesSystem_Portable/README.txt" << EOF
Sales System Portable Version
=============================

This is a portable version of Sales System that can run without installation.

To use:
1. Double-click SalesSystem.bat to start the application
2. Or double-click sales_system.exe directly

Data will be stored in the same directory as the application.

For the full installer version, use SalesSystemSetup_$VERSION.exe
EOF

echo ""
echo "Step 5: Creating distribution package..."
echo "======================================="

# Create distribution ZIP
if [ -f "$OUTPUT_DIR/SalesSystem_$VERSION.zip" ]; then
    rm "$OUTPUT_DIR/SalesSystem_$VERSION.zip"
fi

if command -v zip &> /dev/null; then
    cd "$OUTPUT_DIR"
    zip -r "SalesSystem_$VERSION.zip" *
    cd ..
elif command -v tar &> /dev/null; then
    cd "$OUTPUT_DIR"
    tar -czf "SalesSystem_$VERSION.tar.gz" *
    cd ..
else
    echo "WARNING: Neither zip nor tar found. Skipping package creation."
fi

echo ""
echo "Build completed successfully!"
echo "============================="
echo ""
echo "Files created:"
echo "- Installer: $OUTPUT_DIR/SalesSystemSetup_$VERSION.exe"
echo "- Portable: $OUTPUT_DIR/SalesSystem_Portable/"
if [ -f "$OUTPUT_DIR/SalesSystem_$VERSION.zip" ]; then
    echo "- Package: $OUTPUT_DIR/SalesSystem_$VERSION.zip"
elif [ -f "$OUTPUT_DIR/SalesSystem_$VERSION.tar.gz" ]; then
    echo "- Package: $OUTPUT_DIR/SalesSystem_$VERSION.tar.gz"
fi
echo ""
echo "You can now distribute the installer to users."
echo ""

# Clean up temporary files
if [ -f "$INSTALLER_DIR/vcredist_x64.exe" ]; then
    rm "$INSTALLER_DIR/vcredist_x64.exe"
fi
if [ -f "$INSTALLER_DIR/sqlite3.exe" ]; then
    rm "$INSTALLER_DIR/sqlite3.exe"
fi
if [ -d "$INSTALLER_DIR/build" ]; then
    rm -rf "$INSTALLER_DIR/build"
fi

echo "Press Enter to exit..."
read

# Sales System Windows Installer Build Script for Linux
# This script builds the Windows installer from a Linux environment

set -e

echo "Building Sales System Windows Installer from Linux..."
echo "====================================================="

# Set variables
APP_NAME="Sales System"
VERSION="1.0.0"
BUILD_DIR="build/windows/x64/runner/Release"
INSTALLER_DIR="installer"
OUTPUT_DIR="dist"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    echo "Please install Flutter and add it to your PATH"
    exit 1
fi

# Check if Wine is installed (for Windows compatibility)
if ! command -v wine &> /dev/null; then
    echo "WARNING: Wine is not installed. Some Windows-specific features may not work."
    echo "Consider installing Wine for better Windows compatibility."
fi

echo ""
echo "Step 1: Building Flutter application for Windows..."
echo "=================================================="

# Clean previous builds
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# Build Flutter app for Windows
flutter build windows --release
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter build failed"
    exit 1
fi

echo ""
echo "Step 2: Preparing installer files..."
echo "===================================="

# Create installer directory structure
mkdir -p "$INSTALLER_DIR/assets"
mkdir -p "$INSTALLER_DIR/data"

# Copy application files
mkdir -p "$INSTALLER_DIR/build"
cp -r "$BUILD_DIR"/* "$INSTALLER_DIR/build/"

# Download Visual C++ Redistributable
echo "Downloading Visual C++ Redistributable..."
if command -v wget &> /dev/null; then
    wget -O "$INSTALLER_DIR/vcredist_x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe" || echo "WARNING: Failed to download Visual C++ Redistributable"
elif command -v curl &> /dev/null; then
    curl -L -o "$INSTALLER_DIR/vcredist_x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe" || echo "WARNING: Failed to download Visual C++ Redistributable"
else
    echo "WARNING: Neither wget nor curl found. Please download Visual C++ Redistributable manually."
fi

# Download SQLite
echo "Downloading SQLite..."
if command -v wget &> /dev/null; then
    wget -O "$INSTALLER_DIR/sqlite.zip" "https://www.sqlite.org/2024/sqlite-dll-win64-x64-3460000.zip" || echo "WARNING: Failed to download SQLite"
elif command -v curl &> /dev/null; then
    curl -L -o "$INSTALLER_DIR/sqlite.zip" "https://www.sqlite.org/2024/sqlite-dll-win64-x64-3460000.zip" || echo "WARNING: Failed to download SQLite"
else
    echo "WARNING: Neither wget nor curl found. Please download SQLite manually."
fi

# Extract SQLite
if [ -f "$INSTALLER_DIR/sqlite.zip" ]; then
    if command -v unzip &> /dev/null; then
        unzip -o "$INSTALLER_DIR/sqlite.zip" -d "$INSTALLER_DIR/sqlite"
        if [ -f "$INSTALLER_DIR/sqlite/sqlite-dll-win64-x64-3460000/sqlite3.exe" ]; then
            cp "$INSTALLER_DIR/sqlite/sqlite-dll-win64-x64-3460000/sqlite3.exe" "$INSTALLER_DIR/sqlite3.exe"
        fi
        rm -rf "$INSTALLER_DIR/sqlite"
        rm "$INSTALLER_DIR/sqlite.zip"
    else
        echo "WARNING: unzip not found. Please extract SQLite manually."
    fi
fi

# Create application icon
echo "Creating application icon..."
if [ ! -f "$INSTALLER_DIR/assets/icon.ico" ]; then
    echo "Creating placeholder icon..."
    # This is a placeholder - you should provide a real icon file
    touch "$INSTALLER_DIR/assets/icon.ico"
fi

# Create LICENSE file
echo "Creating LICENSE file..."
cat > "$INSTALLER_DIR/LICENSE.txt" << 'EOF'
Sales System License
====================

Copyright (c) 2024 Enick Sales

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

echo ""
echo "Step 3: Building NSIS installer..."
echo "=================================="

# Check if NSIS is available
if command -v makensis &> /dev/null; then
    # Build the installer
    makensis "$INSTALLER_DIR/sales_system_installer.nsi"
    if [ $? -ne 0 ]; then
        echo "ERROR: NSIS build failed"
        exit 1
    fi
    
    # Move installer to output directory
    if [ -f "$INSTALLER_DIR/SalesSystemSetup.exe" ]; then
        mv "$INSTALLER_DIR/SalesSystemSetup.exe" "$OUTPUT_DIR/SalesSystemSetup_$VERSION.exe"
        echo ""
        echo "SUCCESS: Installer created successfully!"
        echo "Installer location: $OUTPUT_DIR/SalesSystemSetup_$VERSION.exe"
    else
        echo "ERROR: Installer file not found"
        exit 1
    fi
else
    echo "WARNING: NSIS not found. Skipping installer creation."
    echo "Please install NSIS or run this script on a Windows system."
fi

echo ""
echo "Step 4: Creating portable version..."
echo "===================================="

# Create portable version
mkdir -p "$OUTPUT_DIR/SalesSystem_Portable"
cp -r "$BUILD_DIR"/* "$OUTPUT_DIR/SalesSystem_Portable/"

# Create portable launcher
cat > "$OUTPUT_DIR/SalesSystem_Portable/SalesSystem.bat" << 'EOF'
@echo off
echo Starting Sales System...
start "" "sales_system.exe"
EOF

# Create portable README
cat > "$OUTPUT_DIR/SalesSystem_Portable/README.txt" << EOF
Sales System Portable Version
=============================

This is a portable version of Sales System that can run without installation.

To use:
1. Double-click SalesSystem.bat to start the application
2. Or double-click sales_system.exe directly

Data will be stored in the same directory as the application.

For the full installer version, use SalesSystemSetup_$VERSION.exe
EOF

echo ""
echo "Step 5: Creating distribution package..."
echo "======================================="

# Create distribution ZIP
if [ -f "$OUTPUT_DIR/SalesSystem_$VERSION.zip" ]; then
    rm "$OUTPUT_DIR/SalesSystem_$VERSION.zip"
fi

if command -v zip &> /dev/null; then
    cd "$OUTPUT_DIR"
    zip -r "SalesSystem_$VERSION.zip" *
    cd ..
elif command -v tar &> /dev/null; then
    cd "$OUTPUT_DIR"
    tar -czf "SalesSystem_$VERSION.tar.gz" *
    cd ..
else
    echo "WARNING: Neither zip nor tar found. Skipping package creation."
fi

echo ""
echo "Build completed successfully!"
echo "============================="
echo ""
echo "Files created:"
echo "- Installer: $OUTPUT_DIR/SalesSystemSetup_$VERSION.exe"
echo "- Portable: $OUTPUT_DIR/SalesSystem_Portable/"
if [ -f "$OUTPUT_DIR/SalesSystem_$VERSION.zip" ]; then
    echo "- Package: $OUTPUT_DIR/SalesSystem_$VERSION.zip"
elif [ -f "$OUTPUT_DIR/SalesSystem_$VERSION.tar.gz" ]; then
    echo "- Package: $OUTPUT_DIR/SalesSystem_$VERSION.tar.gz"
fi
echo ""
echo "You can now distribute the installer to users."
echo ""

# Clean up temporary files
if [ -f "$INSTALLER_DIR/vcredist_x64.exe" ]; then
    rm "$INSTALLER_DIR/vcredist_x64.exe"
fi
if [ -f "$INSTALLER_DIR/sqlite3.exe" ]; then
    rm "$INSTALLER_DIR/sqlite3.exe"
fi
if [ -d "$INSTALLER_DIR/build" ]; then
    rm -rf "$INSTALLER_DIR/build"
fi

echo "Press Enter to exit..."
read
