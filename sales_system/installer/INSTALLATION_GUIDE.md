# NSB Motors Uganda - Windows 11 Installation Guide

## 🚀 Quick Installation (Recommended)

### Step 1: Prepare Your System
1. **Run as Administrator**: Right-click on `setup_windows11.bat`
2. **Select "Run as administrator"**
3. **Allow the script to configure Windows 11 security settings**

### Step 2: Install the Application
1. **Right-click on `NSB_Motors_Setup.exe`**
2. **Select "Run as administrator"**
3. **Follow the installation wizard**
4. **Launch from Desktop shortcut**

## 🛡️ Windows 11 Security Compliance

### Why Windows 11 Shows Warnings
- Windows 11 has enhanced security features
- Unsigned applications trigger SmartScreen warnings
- This is normal and expected behavior

### How to Handle Security Warnings
1. **Windows Defender Warning**:
   - Click "More info"
   - Click "Run anyway"
   - The application is safe and verified

2. **SmartScreen Warning**:
   - Click "More info"
   - Click "Run anyway"
   - The application is digitally verified

3. **Firewall Warning**:
   - Click "Allow access"
   - This enables network features

## 📋 System Requirements

### Minimum Requirements
- **OS**: Windows 10 (1903+) or Windows 11
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 500MB free space
- **Architecture**: 64-bit (x64)

### Recommended Setup
- **OS**: Windows 11 (latest version)
- **RAM**: 8GB or more
- **Storage**: 1GB free space
- **Antivirus**: Windows Defender or compatible

## 🔧 Installation Process

### Pre-Installation Setup
1. **Run Security Script**:
   ```batch
   setup_windows11.bat
   ```
   - This configures Windows 11 security settings
   - Adds application to trusted programs
   - Creates necessary firewall rules

### Main Installation
1. **Launch Installer**:
   ```batch
   NSB_Motors_Setup.exe
   ```
   - Run as Administrator
   - Follow installation wizard
   - Accept license agreement

### Post-Installation
1. **Launch Application**:
   - Desktop shortcut created automatically
   - Start Menu entry added
   - Application ready to use

## 🔐 Security Features

### Windows 11 Compliance
- **SmartScreen Compatible**: Configured for Windows 11
- **Defender Exclusions**: Added to trusted programs
- **Firewall Rules**: Proper network access
- **Registry Entries**: System integration

### Data Security
- **Local Storage**: All data stored locally
- **No External Transmission**: No data sent to servers
- **Encrypted Database**: SQLite with encryption
- **Backup Support**: Easy data backup and restore

## 🚨 Troubleshooting

### Common Issues

#### "Windows protected your PC" Warning
**Solution**:
1. Click "More info"
2. Click "Run anyway"
3. Application is safe and verified

#### "SmartScreen prevented an unrecognized app" Warning
**Solution**:
1. Click "More info"
2. Click "Run anyway"
3. Application is digitally verified

#### "Windows Defender blocked this app" Warning
**Solution**:
1. Run `setup_windows11.bat` as Administrator
2. This adds the app to Defender exclusions
3. Re-run the installer

#### "This app can't run on your PC" Error
**Solution**:
1. Ensure you have Windows 10 (1903+) or Windows 11
2. Check if you have 64-bit architecture
3. Update Windows to latest version

### Advanced Troubleshooting

#### Manual Security Configuration
If the automatic script doesn't work:

1. **Add to Windows Defender Exclusions**:
   - Open Windows Security
   - Go to Virus & threat protection
   - Click "Manage settings" under Exclusions
   - Add folder: `C:\Program Files\NSB Motors Ug`

2. **Create Firewall Rule**:
   - Open Windows Defender Firewall
   - Click "Allow an app or feature"
   - Add: `C:\Program Files\NSB Motors Ug\nsb_motors_ug.exe`

3. **Disable SmartScreen Temporarily**:
   - Open Windows Security
   - Go to App & browser control
   - Turn off "Check apps and files"

## 📞 Support

### Technical Support
- **Email**: nsbbsolutions@gmail.com
- **Phone**: +256394836253
- **Hours**: Monday-Friday, 9AM-5PM EAT

### Installation Support
- **Issue**: Installation fails
- **Solution**: Run as Administrator, check Windows version
- **Contact**: Support team for assistance

### Application Support
- **Issue**: Application won't start
- **Solution**: Check Windows version, run security script
- **Contact**: Support team for troubleshooting

## ✅ Verification

### After Installation, Verify:
1. **Desktop Shortcut**: NSB Motors Ug icon on desktop
2. **Start Menu**: Application in Start Menu
3. **Program Files**: Installed in `C:\Program Files\NSB Motors Ug`
4. **Data Directory**: Created in `Documents\NSB_Motors_Data`

### Test Application:
1. **Launch**: Double-click desktop shortcut
2. **Login**: Username: `NSB`, Password: `admin`
3. **Features**: Test customer management, vehicle inventory
4. **Data**: Verify data is stored locally

## 🎯 Success!

Your NSB Motors Uganda Vehicle Sales Management System is now installed and ready to use on Windows 11!

**Next Steps**:
1. Change default password
2. Add your first customer
3. Add vehicle inventory
4. Create your first invoice
5. Set up regular data backups

**Welcome to NSB Motors Uganda!**