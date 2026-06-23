@echo off
TITLE NSB Motors Sales System Installer

echo ==================================================
echo NSB Motors Sales System - Automated Setup
echo ==================================================
echo.
echo This will install the required Visual C++ Redistributables
echo and then launch the application.
echo.
echo Press any key to continue...
pause >nul

echo.
echo Installing Visual C++ Redistributables...
echo Please wait, this may take a few minutes...
vc_redist.x64.exe /install /quiet /norestart

if %ERRORLEVEL% EQU 0 (
    echo Visual C++ Redistributables installed successfully.
) else (
    echo Warning: Visual C++ Redistributables installation may have failed.
    echo Continuing with application launch...
)

echo.
echo Launching NSB Motors Sales System...
echo If the application doesn't start, please check the troubleshooting guide.
echo.
start "" "sales_system.exe"

echo.
echo Setup complete! The application should now be running.
echo You can close this window.
echo.
echo For future use, you can directly run sales_system.exe
pause