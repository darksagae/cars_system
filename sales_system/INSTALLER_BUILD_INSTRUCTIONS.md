# NSB Motors Sales System - Installer Build Instructions

This guide explains how to create a professional Windows installer (.exe) that can be distributed via USB drive or any other method.

## Prerequisites

1. **Flutter SDK** - Must be installed and in your PATH
2. **Inno Setup** - Download and install from: https://jrsoftware.org/isinfo.php
   - Recommended version: Inno Setup 6 or later
   - During installation, make sure to check "Add Inno Setup directory to PATH"

## Quick Start

### Option 1: Automated Build (Recommended)

1. Open Command Prompt or PowerShell in the project root directory (`cars_system/sales_system`)
2. Run the build script:
   ```batch
   build_installer_complete.bat
   ```
3. The script will:
   - Clean previous builds
   - Build the Flutter application in Release mode
   - Download Visual C++ Redistributable (if needed)
   - Create the Windows installer using Inno Setup
4. The installer will be created in: `dist\NSB_Motors_Setup_v1.0.0.exe`

### Option 2: Manual Build

1. **Build Flutter Application:**
   ```batch
   flutter clean
   flutter pub get
   flutter build windows --release
   ```

2. **Create Installer:**
   - Open Inno Setup Compiler
   - Open the file: `installer\NSB_Motors_Complete_Installer.iss`
   - Click "Build" → "Compile" (or press F9)
   - The installer will be created in the `dist` folder

## Distributing the Installer

### Via USB Drive

1. Copy `NSB_Motors_Setup_v1.0.0.exe` to your USB drive
2. On the target computer:
   - Insert the USB drive
   - Navigate to the USB drive
   - Double-click `NSB_Motors_Setup_v1.0.0.exe`
   - Follow the installation wizard

### Via Network/Email

1. Copy the installer file to a shared network location or attach to email
2. Users can download and run the installer

## Installation Process on Target Computer

1. **Run the Installer:**
   - Double-click `NSB_Motors_Setup_v1.0.0.exe`
   - Windows may show a security warning - click "Run" or "More info" → "Run anyway"

2. **Installation Wizard:**
   - Welcome screen
   - License agreement
   - Installation location (default: `C:\Program Files\NSB Motors Sales System`)
   - Additional tasks (desktop icon, etc.)
   - Ready to install
   - Installation progress
   - Completion screen

3. **First Launch:**
   - The application will launch automatically (if selected)
   - On first launch, you'll see "Setup New Device" screen
   - Create your account:
     - Username
     - Password
     - Confirm Password
   - First user becomes administrator
   - After account creation, you can log in

## Installer Features

- ✅ Professional Windows installer interface
- ✅ Automatic Visual C++ Redistributable installation (if needed)
- ✅ Desktop shortcut option
- ✅ Start Menu integration
- ✅ Uninstaller included
- ✅ Windows 10/11 compatible
- ✅ 64-bit only (optimized for modern systems)

## Troubleshooting

### "Flutter not found" Error
- Make sure Flutter is installed and added to PATH
- Or specify the Flutter path when prompted by the script

### "Inno Setup not found" Error
- Install Inno Setup from: https://jrsoftware.org/isinfo.php
- Make sure to check "Add Inno Setup directory to PATH" during installation
- Or specify the ISCC.exe path when prompted

### Installer Creation Fails
- Check that the Flutter build completed successfully
- Verify that `build\windows\x64\runner\Release\sales_system.exe` exists
- Check Inno Setup script for syntax errors
- Make sure you have write permissions to the `dist` folder

### Installation Fails on Target Computer
- Make sure the target computer meets system requirements:
  - Windows 10 (1903+) or Windows 11
  - 64-bit processor
  - Administrator rights
- Check Windows Defender or antivirus isn't blocking the installer
- Try running as administrator

## Customizing the Installer

### Change Version Number
Edit `installer\NSB_Motors_Complete_Installer.iss`:
```iss
#define MyAppVersion "1.0.1"  // Change version here
```

### Change Application Name
Edit `installer\NSB_Motors_Complete_Installer.iss`:
```iss
#define MyAppName "Your Custom Name"
```

### Add Custom Icon
1. Place your `.ico` file in `assets\app_icon\`
2. Update the installer script:
```iss
SetupIconFile=..\assets\app_icon\your_icon.ico
```

## File Structure

```
cars_system/sales_system/
├── build_installer_complete.bat    # Main build script
├── installer/
│   ├── NSB_Motors_Complete_Installer.iss  # Inno Setup script
│   ├── README.txt                   # Pre-installation info
│   ├── POST_INSTALL.txt            # Post-installation info
│   └── LICENSE.txt                 # License file
└── dist/
    └── NSB_Motors_Setup_v1.0.0.exe # Final installer (created after build)
```

## Support

For issues or questions:
- Email: nsbbsolutions@gmail.com


