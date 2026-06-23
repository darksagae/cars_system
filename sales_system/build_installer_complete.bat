@echo off
REM ============================================================
REM NSB Motors Sales System - Complete Installer Builder
REM This script builds the Flutter app and creates a Windows installer
REM ============================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo   NSB Motors Sales System - Installer Builder
echo ============================================================
echo.

REM Set paths
set PROJECT_ROOT=%~dp0
set BUILD_DIR=%PROJECT_ROOT%build\windows\x64\runner\Release
set INSTALLER_DIR=%PROJECT_ROOT%installer
set DIST_DIR=%PROJECT_ROOT%dist
set FLUTTER_PATH=flutter

REM Check if Flutter is available
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [INFO] Flutter not found in PATH. Checking common locations...
    REM Try common Flutter installation paths
    if exist "C:\Users\Eng.Tifie\Desktop\All files\kali linux\flutter\bin\flutter.bat" (
        set "FLUTTER_PATH=C:\Users\Eng.Tifie\Desktop\All files\kali linux\flutter\bin\flutter.bat"
        echo [OK] Flutter found at: !FLUTTER_PATH!
    ) else if exist "C:\src\flutter\bin\flutter.bat" (
        set "FLUTTER_PATH=C:\src\flutter\bin\flutter.bat"
        echo [OK] Flutter found at: !FLUTTER_PATH!
    ) else (
        echo [ERROR] Flutter is not found in PATH or common locations.
        echo Please add Flutter to your PATH or specify the full path.
        echo.
        set /p FLUTTER_PATH="Enter Flutter path (or press Enter to exit): "
        if "!FLUTTER_PATH!"=="" (
            exit /b 1
        )
    )
) else (
    set FLUTTER_PATH=flutter
    echo [OK] Flutter found in PATH
)

REM Check if Inno Setup is installed
set INNO_SETUP_PATH=
where iscc >nul 2>nul
if %ERRORLEVEL% equ 0 (
    set INNO_SETUP_PATH=iscc
    echo [OK] Inno Setup found in PATH
) else (
    REM Try common installation paths
    if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
        set INNO_SETUP_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
        echo [OK] Inno Setup found at: !INNO_SETUP_PATH!
    ) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
        set INNO_SETUP_PATH="C:\Program Files\Inno Setup 6\ISCC.exe"
        echo [OK] Inno Setup found at: !INNO_SETUP_PATH!
    ) else (
        echo [WARNING] Inno Setup not found!
        echo.
        echo Please install Inno Setup from: https://jrsoftware.org/isinfo.php
        echo Or specify the path to ISCC.exe
        echo.
        set /p INNO_SETUP_PATH="Enter Inno Setup ISCC.exe path (or press Enter to skip installer creation): "
        if "!INNO_SETUP_PATH!"=="" (
            echo [INFO] Skipping installer creation. You can build it manually later.
            set SKIP_INSTALLER=1
        )
    )
)

echo.
echo ============================================================
echo Step 1: Cleaning previous builds...
echo ============================================================

if exist "%BUILD_DIR%" (
    echo Removing old build directory...
    rmdir /s /q "%BUILD_DIR%"
)

if exist "%DIST_DIR%" (
    echo Cleaning old distribution files...
    rmdir /s /q "%DIST_DIR%"
)

echo.
echo ============================================================
echo Step 2: Building Flutter application (Release mode)...
echo ============================================================

cd /d "%PROJECT_ROOT%"
call "%FLUTTER_PATH%" clean
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter clean failed
    pause
    exit /b 1
)

call "%FLUTTER_PATH%" pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter pub get failed
    pause
    exit /b 1
)

call "%FLUTTER_PATH%" build windows --release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter build failed
    pause
    exit /b 1
)

if not exist "%BUILD_DIR%\sales_system.exe" (
    echo [ERROR] Build output not found at: %BUILD_DIR%
    echo Expected executable: sales_system.exe
    pause
    exit /b 1
)

echo [OK] Flutter build completed successfully!

echo.
echo ============================================================
echo Step 3: Preparing installer files...
echo ============================================================

REM Create dist directory
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

REM Check for VC++ Redistributable
if not exist "%PROJECT_ROOT%vc_redist.x64.exe" (
    echo [INFO] Visual C++ Redistributable not found.
    echo [INFO] Downloading VC++ Redistributable...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile '%PROJECT_ROOT%vc_redist.x64.exe' -UseBasicParsing}"
    if %ERRORLEVEL% equ 0 (
        echo [OK] VC++ Redistributable downloaded
    ) else (
        echo [WARNING] Failed to download VC++ Redistributable
        echo [INFO] Installer will still work, but users may need to install VC++ Redistributable manually
    )
)

echo.
echo ============================================================
echo Step 4: Creating Windows Installer...
echo ============================================================

if defined SKIP_INSTALLER (
    echo [INFO] Skipping installer creation as requested.
    goto :end
)

if "!INNO_SETUP_PATH!"=="" (
    echo [ERROR] Inno Setup path not specified
    goto :end
)

cd /d "%INSTALLER_DIR%"
!INNO_SETUP_PATH! "NSB_Motors_Complete_Installer.iss"
if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================
    echo [SUCCESS] Installer created successfully!
    echo ============================================================
    echo.
    echo Installer location: %DIST_DIR%\NSB_Motors_Setup_v1.0.0.exe
    echo.
    echo You can now:
    echo   1. Copy the installer to a USB drive
    echo   2. Distribute it to other computers
    echo   3. Run the installer on target computers
    echo.
) else (
    echo [ERROR] Installer creation failed
    echo Please check the Inno Setup script for errors
)

:end
echo.
echo ============================================================
echo Build process completed!
echo ============================================================
echo.
pause

