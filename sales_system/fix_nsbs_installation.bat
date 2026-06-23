@echo off
echo NSB Motors System - Installation Fix
echo ====================================
echo.
echo Fixing NSB Motors System installation...
echo.
echo 1. Creating desktop shortcut...

REM Create desktop shortcut with correct executable name
powershell $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\NSB Motors System.lnk"); $Shortcut.TargetPath = "C:\NSBMotors\sales_system.exe"; $Shortcut.WorkingDirectory = "C:\NSBMotors"; $Shortcut.Save()
echo.
echo 2. Verifying installation...

REM Check if the executable exists
if exist "C:\NSBMotors\sales_system.exe" (
echo    Installation verified successfully!
) else (
echo    Warning: Main executable not found. Please reinstall the application.
)
echo.
echo Installation fix complete!
echo.
echo You can now launch NSB Motors System from the desktop shortcut.
echo.
pause
