@echo off
echo NSB Motors Uganda - Windows 11 Setup
echo ====================================
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with Administrator privileges...
) else (
    echo This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo.
echo Setting up NSB Motors Uganda for Windows 11...
echo.

REM Run PowerShell script for security compliance
echo Configuring Windows 11 security settings...
powershell -ExecutionPolicy Bypass -File "%~dp0windows11_security.ps1"

echo.
echo Setup completed successfully!
echo.
echo The application is now configured for Windows 11.
echo You can now run NSB_Motors_Setup.exe without security warnings.
echo.
pause
