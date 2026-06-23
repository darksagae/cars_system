# NSB Motors System Simple Installer
# This script copies all necessary files to the installation directory

Write-Host "Creating NSB Motors System Installer..."

# Create installation directory
 = "C:\NSB Motors System"
if (!(Test-Path )) {
    New-Item -ItemType Directory -Path  | Out-Null
}

# Copy all files
Copy-Item -Path "dist\app\*" -Destination  -Recurse -Force

Write-Host "Installation files copied to "

# Create desktop shortcut
 = New-Object -comObject WScript.Shell
 = .CreateShortcut("C:\Users\Eng.Tifie\Desktop\NSB Motors System.lnk")
.TargetPath = "\sales_system.exe"
.WorkingDirectory = 
.Save()

Write-Host "Desktop shortcut created."
Write-Host "Installation complete!"
Write-Host "You can now launch NSB Motors System from your desktop."
