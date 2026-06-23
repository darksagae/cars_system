#!/bin/bash

# Sales System Deployment Script
# This script prepares the application for distribution

set -e

echo "Sales System Deployment Script"
echo "=============================="

# Set variables
APP_NAME="Sales System"
VERSION="1.0.0"
BUILD_DIR="build"
DIST_DIR="dist"
RELEASE_DIR="releases"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "This script must be run from the Flutter project root directory"
    exit 1
fi

print_status "Starting deployment process..."

# Create directories
mkdir -p "$DIST_DIR"
mkdir -p "$RELEASE_DIR"

# Clean previous builds
print_status "Cleaning previous builds..."
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# Build for different platforms
print_status "Building for different platforms..."

# Build for Linux
print_status "Building for Linux..."
flutter build linux --release
if [ $? -eq 0 ]; then
    print_success "Linux build completed"
    
    # Create Linux package
    mkdir -p "$DIST_DIR/linux"
    cp -r "$BUILD_DIR/linux/x64/release/bundle" "$DIST_DIR/linux/SalesSystem"
    
    # Create Linux launcher script
    cat > "$DIST_DIR/linux/SalesSystem/sales_system.sh" << 'EOF'
#!/bin/bash
# Sales System Launcher Script

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Change to the application directory
cd "$DIR"

# Set executable permissions
chmod +x sales_system

# Launch the application
./sales_system
EOF
    
    chmod +x "$DIST_DIR/linux/SalesSystem/sales_system.sh"
    
    # Create Linux README
    cat > "$DIST_DIR/linux/SalesSystem/README.txt" << EOF
Sales System for Linux
=====================

To run the application:
1. Make sure you have the required dependencies installed
2. Run: ./sales_system.sh
3. Or run: ./sales_system

Dependencies:
- GTK3 development libraries
- libc6
- libstdc++6

For Ubuntu/Debian:
sudo apt-get install libgtk-3-0 libc6 libstdc++6

For CentOS/RHEL:
sudo yum install gtk3 glibc libstdc++

For Arch Linux:
sudo pacman -S gtk3 glibc libstdc++5
EOF
    
    # Create Linux package
    cd "$DIST_DIR/linux"
    tar -czf "../SalesSystem_Linux_$VERSION.tar.gz" SalesSystem
    cd - > /dev/null
    
    print_success "Linux package created: $DIST_DIR/SalesSystem_Linux_$VERSION.tar.gz"
else
    print_error "Linux build failed"
fi

# Build for Windows
print_status "Building for Windows..."
flutter build windows --release
if [ $? -eq 0 ]; then
    print_success "Windows build completed"
    
    # Create Windows package
    mkdir -p "$DIST_DIR/windows"
    cp -r "$BUILD_DIR/windows/x64/runner/Release" "$DIST_DIR/windows/SalesSystem"
    
    # Create Windows launcher batch file
    cat > "$DIST_DIR/windows/SalesSystem/SalesSystem.bat" << 'EOF'
@echo off
echo Starting Sales System...
start "" "sales_system.exe"
EOF
    
    # Create Windows README
    cat > "$DIST_DIR/windows/SalesSystem/README.txt" << EOF
Sales System for Windows
========================

To run the application:
1. Double-click SalesSystem.bat
2. Or double-click sales_system.exe directly

Requirements:
- Windows 7 SP1 or later
- Visual C++ Redistributable 2015-2022

If you get missing DLL errors, install:
https://aka.ms/vs/17/release/vc_redist.x64.exe
EOF
    
    # Create Windows package
    cd "$DIST_DIR/windows"
    if command -v zip &> /dev/null; then
        zip -r "../SalesSystem_Windows_$VERSION.zip" SalesSystem
    else
        tar -czf "../SalesSystem_Windows_$VERSION.tar.gz" SalesSystem
    fi
    cd - > /dev/null
    
    print_success "Windows package created: $DIST_DIR/SalesSystem_Windows_$VERSION.zip"
else
    print_error "Windows build failed"
fi

# Build for macOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building for macOS..."
    flutter build macos --release
    if [ $? -eq 0 ]; then
        print_success "macOS build completed"
        
        # Create macOS package
        mkdir -p "$DIST_DIR/macos"
        cp -r "$BUILD_DIR/macos/Build/Products/Release/sales_system.app" "$DIST_DIR/macos/SalesSystem.app"
        
        # Create macOS README
        cat > "$DIST_DIR/macos/README.txt" << EOF
Sales System for macOS
=====================

To run the application:
1. Double-click SalesSystem.app
2. Or run from Terminal: open SalesSystem.app

Requirements:
- macOS 10.14 or later
- Intel or Apple Silicon Mac

Note: You may need to allow the application in Security & Privacy settings.
EOF
        
        # Create macOS package
        cd "$DIST_DIR/macos"
        tar -czf "../SalesSystem_macOS_$VERSION.tar.gz" SalesSystem.app
        cd - > /dev/null
        
        print_success "macOS package created: $DIST_DIR/SalesSystem_macOS_$VERSION.tar.gz"
    else
        print_error "macOS build failed"
    fi
else
    print_warning "Skipping macOS build (not on macOS)"
fi

# Create installer packages
print_status "Creating installer packages..."

# Windows Installer
if [ -f "installer/build_installer.bat" ]; then
    print_status "Creating Windows installer..."
    if command -v wine &> /dev/null; then
        wine cmd /c installer/build_installer.bat
        if [ $? -eq 0 ]; then
            print_success "Windows installer created"
        else
            print_warning "Windows installer creation failed (Wine may not be properly configured)"
        fi
    else
        print_warning "Wine not available, skipping Windows installer creation"
    fi
fi

# Create release notes
print_status "Creating release notes..."
cat > "$DIST_DIR/RELEASE_NOTES.md" << EOF
# Sales System $VERSION Release Notes

## What's New

### Core Features
- ✅ Customer Management System
- ✅ Product Management System
- ✅ Invoice Generation with PDF Export
- ✅ Payment Tracking System
- ✅ Reports & Analytics Dashboard
- ✅ Email Integration
- ✅ WhatsApp Integration

### User Interface
- ✅ Modern Glass Morphism Design
- ✅ Responsive Layout
- ✅ Beautiful Animations
- ✅ Professional Color Scheme

### Technical Features
- ✅ SQLite Database
- ✅ Cross-Platform Support
- ✅ Local Data Storage
- ✅ Automatic Backups
- ✅ Error Handling
- ✅ Performance Optimization

## Installation

### Windows
1. Download \`SalesSystemSetup_$VERSION.exe\`
2. Run the installer as administrator
3. Follow the installation wizard
4. Launch from desktop or Start Menu

### Linux
1. Download \`SalesSystem_Linux_$VERSION.tar.gz\`
2. Extract the archive
3. Install dependencies (see README.txt)
4. Run \`./sales_system.sh\`

### macOS
1. Download \`SalesSystem_macOS_$VERSION.tar.gz\`
2. Extract the archive
3. Double-click \`SalesSystem.app\`

## System Requirements

### Windows
- Windows 7 SP1 or later
- 2 GB RAM minimum
- 100 MB disk space
- Visual C++ Redistributable 2015-2022

### Linux
- GTK3 development libraries
- libc6
- libstdc++6
- 2 GB RAM minimum
- 100 MB disk space

### macOS
- macOS 10.14 or later
- 2 GB RAM minimum
- 100 MB disk space

## Support

For support and questions:
- GitHub Issues: https://github.com/enick/sales-system/issues
- Email: support@enicksales.com
- Documentation: See INSTALLATION_GUIDE.md

## License

This software is licensed under the MIT License.
See LICENSE file for details.

---

**Thank you for using Sales System!**
EOF

# Create distribution summary
print_status "Creating distribution summary..."
cat > "$DIST_DIR/DISTRIBUTION_SUMMARY.md" << EOF
# Sales System Distribution Summary

## Version: $VERSION
## Build Date: $(date)

## Available Packages

### Windows
- **Installer**: \`SalesSystemSetup_$VERSION.exe\` (Recommended)
- **Portable**: \`SalesSystem_Windows_$VERSION.zip\`

### Linux
- **Package**: \`SalesSystem_Linux_$VERSION.tar.gz\`

### macOS
- **Package**: \`SalesSystem_macOS_$VERSION.tar.gz\`

## File Sizes
$(du -h "$DIST_DIR"/*.tar.gz "$DIST_DIR"/*.zip 2>/dev/null | sort -hr || echo "No packages found")

## Distribution Checklist
- [ ] All platforms built successfully
- [ ] Installer packages created
- [ ] Documentation included
- [ ] Release notes created
- [ ] File sizes reasonable
- [ ] Packages tested

## Next Steps
1. Test all packages on target platforms
2. Upload to release repository
3. Update download links
4. Notify users of new release
5. Monitor for issues and feedback

## Notes
- Windows installer includes Visual C++ Redistributable
- Linux package requires GTK3 dependencies
- macOS package may require security permissions
- All packages include comprehensive documentation
EOF

# Create final distribution package
print_status "Creating final distribution package..."
cd "$DIST_DIR"
if command -v zip &> /dev/null; then
    zip -r "SalesSystem_Complete_$VERSION.zip" *
    print_success "Complete distribution package created: SalesSystem_Complete_$VERSION.zip"
elif command -v tar &> /dev/null; then
    tar -czf "SalesSystem_Complete_$VERSION.tar.gz" *
    print_success "Complete distribution package created: SalesSystem_Complete_$VERSION.tar.gz"
else
    print_warning "No compression tool available, skipping final package creation"
fi
cd - > /dev/null

# Display summary
print_success "Deployment completed successfully!"
echo ""
echo "Distribution Summary:"
echo "===================="
echo "Version: $VERSION"
echo "Build Date: $(date)"
echo ""
echo "Created Packages:"
ls -la "$DIST_DIR"/*.tar.gz "$DIST_DIR"/*.zip 2>/dev/null || echo "No packages found"
echo ""
echo "Files created in: $DIST_DIR/"
echo ""
echo "Next Steps:"
echo "1. Test all packages on target platforms"
echo "2. Upload to release repository"
echo "3. Update documentation"
echo "4. Notify users of new release"
echo ""

print_success "Deployment process completed!"

# Sales System Deployment Script
# This script prepares the application for distribution

set -e

echo "Sales System Deployment Script"
echo "=============================="

# Set variables
APP_NAME="Sales System"
VERSION="1.0.0"
BUILD_DIR="build"
DIST_DIR="dist"
RELEASE_DIR="releases"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "This script must be run from the Flutter project root directory"
    exit 1
fi

print_status "Starting deployment process..."

# Create directories
mkdir -p "$DIST_DIR"
mkdir -p "$RELEASE_DIR"

# Clean previous builds
print_status "Cleaning previous builds..."
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# Build for different platforms
print_status "Building for different platforms..."

# Build for Linux
print_status "Building for Linux..."
flutter build linux --release
if [ $? -eq 0 ]; then
    print_success "Linux build completed"
    
    # Create Linux package
    mkdir -p "$DIST_DIR/linux"
    cp -r "$BUILD_DIR/linux/x64/release/bundle" "$DIST_DIR/linux/SalesSystem"
    
    # Create Linux launcher script
    cat > "$DIST_DIR/linux/SalesSystem/sales_system.sh" << 'EOF'
#!/bin/bash
# Sales System Launcher Script

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Change to the application directory
cd "$DIR"

# Set executable permissions
chmod +x sales_system

# Launch the application
./sales_system
EOF
    
    chmod +x "$DIST_DIR/linux/SalesSystem/sales_system.sh"
    
    # Create Linux README
    cat > "$DIST_DIR/linux/SalesSystem/README.txt" << EOF
Sales System for Linux
=====================

To run the application:
1. Make sure you have the required dependencies installed
2. Run: ./sales_system.sh
3. Or run: ./sales_system

Dependencies:
- GTK3 development libraries
- libc6
- libstdc++6

For Ubuntu/Debian:
sudo apt-get install libgtk-3-0 libc6 libstdc++6

For CentOS/RHEL:
sudo yum install gtk3 glibc libstdc++

For Arch Linux:
sudo pacman -S gtk3 glibc libstdc++5
EOF
    
    # Create Linux package
    cd "$DIST_DIR/linux"
    tar -czf "../SalesSystem_Linux_$VERSION.tar.gz" SalesSystem
    cd - > /dev/null
    
    print_success "Linux package created: $DIST_DIR/SalesSystem_Linux_$VERSION.tar.gz"
else
    print_error "Linux build failed"
fi

# Build for Windows
print_status "Building for Windows..."
flutter build windows --release
if [ $? -eq 0 ]; then
    print_success "Windows build completed"
    
    # Create Windows package
    mkdir -p "$DIST_DIR/windows"
    cp -r "$BUILD_DIR/windows/x64/runner/Release" "$DIST_DIR/windows/SalesSystem"
    
    # Create Windows launcher batch file
    cat > "$DIST_DIR/windows/SalesSystem/SalesSystem.bat" << 'EOF'
@echo off
echo Starting Sales System...
start "" "sales_system.exe"
EOF
    
    # Create Windows README
    cat > "$DIST_DIR/windows/SalesSystem/README.txt" << EOF
Sales System for Windows
========================

To run the application:
1. Double-click SalesSystem.bat
2. Or double-click sales_system.exe directly

Requirements:
- Windows 7 SP1 or later
- Visual C++ Redistributable 2015-2022

If you get missing DLL errors, install:
https://aka.ms/vs/17/release/vc_redist.x64.exe
EOF
    
    # Create Windows package
    cd "$DIST_DIR/windows"
    if command -v zip &> /dev/null; then
        zip -r "../SalesSystem_Windows_$VERSION.zip" SalesSystem
    else
        tar -czf "../SalesSystem_Windows_$VERSION.tar.gz" SalesSystem
    fi
    cd - > /dev/null
    
    print_success "Windows package created: $DIST_DIR/SalesSystem_Windows_$VERSION.zip"
else
    print_error "Windows build failed"
fi

# Build for macOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building for macOS..."
    flutter build macos --release
    if [ $? -eq 0 ]; then
        print_success "macOS build completed"
        
        # Create macOS package
        mkdir -p "$DIST_DIR/macos"
        cp -r "$BUILD_DIR/macos/Build/Products/Release/sales_system.app" "$DIST_DIR/macos/SalesSystem.app"
        
        # Create macOS README
        cat > "$DIST_DIR/macos/README.txt" << EOF
Sales System for macOS
=====================

To run the application:
1. Double-click SalesSystem.app
2. Or run from Terminal: open SalesSystem.app

Requirements:
- macOS 10.14 or later
- Intel or Apple Silicon Mac

Note: You may need to allow the application in Security & Privacy settings.
EOF
        
        # Create macOS package
        cd "$DIST_DIR/macos"
        tar -czf "../SalesSystem_macOS_$VERSION.tar.gz" SalesSystem.app
        cd - > /dev/null
        
        print_success "macOS package created: $DIST_DIR/SalesSystem_macOS_$VERSION.tar.gz"
    else
        print_error "macOS build failed"
    fi
else
    print_warning "Skipping macOS build (not on macOS)"
fi

# Create installer packages
print_status "Creating installer packages..."

# Windows Installer
if [ -f "installer/build_installer.bat" ]; then
    print_status "Creating Windows installer..."
    if command -v wine &> /dev/null; then
        wine cmd /c installer/build_installer.bat
        if [ $? -eq 0 ]; then
            print_success "Windows installer created"
        else
            print_warning "Windows installer creation failed (Wine may not be properly configured)"
        fi
    else
        print_warning "Wine not available, skipping Windows installer creation"
    fi
fi

# Create release notes
print_status "Creating release notes..."
cat > "$DIST_DIR/RELEASE_NOTES.md" << EOF
# Sales System $VERSION Release Notes

## What's New

### Core Features
- ✅ Customer Management System
- ✅ Product Management System
- ✅ Invoice Generation with PDF Export
- ✅ Payment Tracking System
- ✅ Reports & Analytics Dashboard
- ✅ Email Integration
- ✅ WhatsApp Integration

### User Interface
- ✅ Modern Glass Morphism Design
- ✅ Responsive Layout
- ✅ Beautiful Animations
- ✅ Professional Color Scheme

### Technical Features
- ✅ SQLite Database
- ✅ Cross-Platform Support
- ✅ Local Data Storage
- ✅ Automatic Backups
- ✅ Error Handling
- ✅ Performance Optimization

## Installation

### Windows
1. Download \`SalesSystemSetup_$VERSION.exe\`
2. Run the installer as administrator
3. Follow the installation wizard
4. Launch from desktop or Start Menu

### Linux
1. Download \`SalesSystem_Linux_$VERSION.tar.gz\`
2. Extract the archive
3. Install dependencies (see README.txt)
4. Run \`./sales_system.sh\`

### macOS
1. Download \`SalesSystem_macOS_$VERSION.tar.gz\`
2. Extract the archive
3. Double-click \`SalesSystem.app\`

## System Requirements

### Windows
- Windows 7 SP1 or later
- 2 GB RAM minimum
- 100 MB disk space
- Visual C++ Redistributable 2015-2022

### Linux
- GTK3 development libraries
- libc6
- libstdc++6
- 2 GB RAM minimum
- 100 MB disk space

### macOS
- macOS 10.14 or later
- 2 GB RAM minimum
- 100 MB disk space

## Support

For support and questions:
- GitHub Issues: https://github.com/enick/sales-system/issues
- Email: support@enicksales.com
- Documentation: See INSTALLATION_GUIDE.md

## License

This software is licensed under the MIT License.
See LICENSE file for details.

---

**Thank you for using Sales System!**
EOF

# Create distribution summary
print_status "Creating distribution summary..."
cat > "$DIST_DIR/DISTRIBUTION_SUMMARY.md" << EOF
# Sales System Distribution Summary

## Version: $VERSION
## Build Date: $(date)

## Available Packages

### Windows
- **Installer**: \`SalesSystemSetup_$VERSION.exe\` (Recommended)
- **Portable**: \`SalesSystem_Windows_$VERSION.zip\`

### Linux
- **Package**: \`SalesSystem_Linux_$VERSION.tar.gz\`

### macOS
- **Package**: \`SalesSystem_macOS_$VERSION.tar.gz\`

## File Sizes
$(du -h "$DIST_DIR"/*.tar.gz "$DIST_DIR"/*.zip 2>/dev/null | sort -hr || echo "No packages found")

## Distribution Checklist
- [ ] All platforms built successfully
- [ ] Installer packages created
- [ ] Documentation included
- [ ] Release notes created
- [ ] File sizes reasonable
- [ ] Packages tested

## Next Steps
1. Test all packages on target platforms
2. Upload to release repository
3. Update download links
4. Notify users of new release
5. Monitor for issues and feedback

## Notes
- Windows installer includes Visual C++ Redistributable
- Linux package requires GTK3 dependencies
- macOS package may require security permissions
- All packages include comprehensive documentation
EOF

# Create final distribution package
print_status "Creating final distribution package..."
cd "$DIST_DIR"
if command -v zip &> /dev/null; then
    zip -r "SalesSystem_Complete_$VERSION.zip" *
    print_success "Complete distribution package created: SalesSystem_Complete_$VERSION.zip"
elif command -v tar &> /dev/null; then
    tar -czf "SalesSystem_Complete_$VERSION.tar.gz" *
    print_success "Complete distribution package created: SalesSystem_Complete_$VERSION.tar.gz"
else
    print_warning "No compression tool available, skipping final package creation"
fi
cd - > /dev/null

# Display summary
print_success "Deployment completed successfully!"
echo ""
echo "Distribution Summary:"
echo "===================="
echo "Version: $VERSION"
echo "Build Date: $(date)"
echo ""
echo "Created Packages:"
ls -la "$DIST_DIR"/*.tar.gz "$DIST_DIR"/*.zip 2>/dev/null || echo "No packages found"
echo ""
echo "Files created in: $DIST_DIR/"
echo ""
echo "Next Steps:"
echo "1. Test all packages on target platforms"
echo "2. Upload to release repository"
echo "3. Update documentation"
echo "4. Notify users of new release"
echo ""

print_success "Deployment process completed!"
