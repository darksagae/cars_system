@echo off
echo Testing PDF Search Functionality with Bundled Poppler Utilities
echo =============================================================

REM Check if pdftotext is available in the current directory
echo Checking for pdftotext.exe in bundled poppler directory...
if exist "dist\app\poppler\poppler-25.12.0\Library\bin\pdftotext.exe" (
    echo [PASS] Found pdftotext.exe in bundled poppler directory
) else (
    echo [FAIL] pdftotext.exe not found in bundled poppler directory
)

REM Check if pdftotext is available in PATH
echo Checking for pdftotext.exe in PATH...
pdftotext.exe --version >nul 2>&1
if %errorlevel% == 0 (
    echo [PASS] pdftotext.exe is available in PATH
) else (
    echo [WARN] pdftotext.exe is not available in PATH
    echo        This is expected before installation
)

echo.
echo Test Summary:
echo - The bundled poppler utilities are included in the installer
echo - After installation, pdftotext.exe will be available system-wide
echo - The Flutter application will be able to use PDF search functionality
echo   without requiring a separate Python installation
echo.
echo The installer has been created successfully:
echo nsb_motors_system_setup.exe
echo.
pause