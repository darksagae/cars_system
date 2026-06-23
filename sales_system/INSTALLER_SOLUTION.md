# NSB Motors System - Installer Solution

## Overview
This document describes the solution for bundling poppler-utils with the NSB Motors System Flutter application for Windows. The solution ensures that the PDF search functionality works without requiring users to separately install Python or poppler-utils on each machine.

## Problem
The Flutter application uses `pdftotext` from poppler-utils for PDF search functionality. Previously, each machine required manual installation of Python and poppler-utils, which was time-consuming and error-prone.

## Solution
We've created a self-contained installer that bundles all necessary dependencies with the application:

1. **Main Application**: The Flutter Windows application
2. **Poppler Utilities**: All required poppler binaries including `pdftotext.exe`
3. **Automatic PATH Configuration**: The installer adds poppler to the system PATH
4. **Desktop Shortcut**: Creates a convenient shortcut for launching the application

## Technical Details

### Installer Features
- **Self-contained**: No external dependencies required after installation
- **Automatic PATH setup**: Poppler utilities are automatically added to system PATH
- **Easy deployment**: Single installer file for all machines
- **Clean uninstallation**: Removes all files and PATH entries when uninstalled

### File Structure
```
NSB Motors System/
├── Application files (saga.exe, DLLs, assets, etc.)
└── poppler/
    └── poppler-25.12.0/
        ├── Library/
        │   └── bin/
        │       ├── pdftotext.exe (primary requirement)
        │       ├── poppler.dll (core library)
        │       ├── cairo.dll (graphics library)
        │       └── other dependencies...
        └── share/
            └── poppler/
                ├── cMap/ (character mapping files)
                └── unicodeMap/ (unicode mapping files)
```

### Installation Process
1. Run `nsb_motors_system_setup.exe`
2. Follow the installation wizard
3. The installer will:
   - Copy application files to Program Files
   - Extract poppler utilities to the application directory
   - Add poppler directory to system PATH
   - Create desktop and start menu shortcuts
4. Launch the application from desktop shortcut

## Benefits

1. **No Manual Setup**: Users no longer need to manually install Python or poppler-utils
2. **Consistent Environment**: All machines have identical setup
3. **Reduced Support**: Fewer installation-related issues
4. **Offline Capability**: Works without internet connection after initial installation
5. **Easy Deployment**: Single installer for all machines

## Verification

The bundled poppler utilities have been tested and verified:
- `pdftotext.exe` is included in the correct location
- All required DLL dependencies are present
- Installer successfully compiles with Inno Setup
- PATH configuration works correctly

## Files Created

1. `nsb_motors_system_setup.exe` - Main installer (46.8 MB)
2. `nsb_motors_setup.iss` - Inno Setup script
3. `LICENSE` - License agreement
4. `test_pdf_functionality.bat` - Verification script

## Deployment Instructions

1. Distribute `nsb_motors_system_setup.exe` to all machines
2. Run the installer on each machine as administrator
3. No additional setup required
4. The PDF search functionality will work immediately

## Maintenance

To update the application in the future:
1. Rebuild the Flutter application
2. Update the `dist\app` directory with new files
3. Recompile the installer using the same `.iss` script
4. Distribute the new installer

This solution eliminates the need for individual machine setup while ensuring reliable PDF search functionality across all installations.