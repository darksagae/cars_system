@echo off
echo Building Sales System Windows Installer...
echo ==========================================

REM Set variables
set APP_NAME=Sales System
set VERSION=1.0.0
set BUILD_DIR=build\windows\x64\runner\Release
set INSTALLER_DIR=installer
set OUTPUT_DIR=dist

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

REM Check if NSIS is installed
where makensis >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: NSIS is not installed or not in PATH
    echo Please install NSIS from https://nsis.sourceforge.io/
    pause
    exit /b 1
)

echo.
echo Step 1: Building Flutter application for Windows...
echo ==================================================

REM Clean previous builds
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"

REM Build Flutter app for Windows
flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter build failed
    pause
    exit /b 1
)

echo.
echo Step 2: Preparing installer files...
echo ====================================

REM Create installer directory structure
if not exist "%INSTALLER_DIR%\assets" mkdir "%INSTALLER_DIR%\assets"
if not exist "%INSTALLER_DIR%\data" mkdir "%INSTALLER_DIR%\data"

REM Copy application files
if not exist "%INSTALLER_DIR%\build" mkdir "%INSTALLER_DIR%\build"
xcopy /E /I /Y "%BUILD_DIR%\*" "%INSTALLER_DIR%\build\"

REM Download Visual C++ Redistributable
echo Downloading Visual C++ Redistributable...
powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile '%INSTALLER_DIR%\vcredist_x64.exe'}"
if %ERRORLEVEL% neq 0 (
    echo WARNING: Failed to download Visual C++ Redistributable
    echo You may need to download it manually
)

REM Download SQLite
echo Downloading SQLite...
powershell -Command "& {Invoke-WebRequest -Uri 'https://www.sqlite.org/2024/sqlite-dll-win64-x64-3460000.zip' -OutFile '%INSTALLER_DIR%\sqlite.zip'}"
if %ERRORLEVEL% neq 0 (
    echo WARNING: Failed to download SQLite
    echo You may need to download it manually
)

REM Extract SQLite
if exist "%INSTALLER_DIR%\sqlite.zip" (
    powershell -Command "& {Expand-Archive -Path '%INSTALLER_DIR%\sqlite.zip' -DestinationPath '%INSTALLER_DIR%\sqlite' -Force}"
    if exist "%INSTALLER_DIR%\sqlite\sqlite-dll-win64-x64-3460000\sqlite3.exe" (
        copy "%INSTALLER_DIR%\sqlite\sqlite-dll-win64-x64-3460000\sqlite3.exe" "%INSTALLER_DIR%\sqlite3.exe"
    )
    rmdir /s /q "%INSTALLER_DIR%\sqlite"
    del "%INSTALLER_DIR%\sqlite.zip"
)

REM Create application icon
echo Creating application icon...
REM You can replace this with your actual icon file
if not exist "%INSTALLER_DIR%\assets\icon.ico" (
    echo Creating placeholder icon...
    REM This is a placeholder - you should provide a real icon file
    echo. > "%INSTALLER_DIR%\assets\icon.ico"
)

REM Create LICENSE file
echo Creating LICENSE file...
(
echo Sales System License
echo ====================
echo.
echo Copyright ^(c^) 2024 Enick Sales
echo.
echo Permission is hereby granted, free of charge, to any person obtaining a copy
echo of this software and associated documentation files ^(the "Software"^), to deal
echo in the Software without restriction, including without limitation the rights
echo to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
echo copies of the Software, and to permit persons to whom the Software is
echo furnished to do so, subject to the following conditions:
echo.
echo The above copyright notice and this permission notice shall be included in all
echo copies or substantial portions of the Software.
echo.
echo THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
echo IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
echo FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
echo AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
echo LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
echo OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
echo SOFTWARE.
) > "%INSTALLER_DIR%\LICENSE.txt"

echo.
echo Step 3: Building NSIS installer...
echo ==================================

REM Build the installer
makensis "%INSTALLER_DIR%\sales_system_installer.nsi"
if %ERRORLEVEL% neq 0 (
    echo ERROR: NSIS build failed
    pause
    exit /b 1
)

REM Move installer to output directory
if exist "%INSTALLER_DIR%\SalesSystemSetup.exe" (
    move "%INSTALLER_DIR%\SalesSystemSetup.exe" "%OUTPUT_DIR%\SalesSystemSetup_%VERSION%.exe"
    echo.
    echo SUCCESS: Installer created successfully!
    echo Installer location: %OUTPUT_DIR%\SalesSystemSetup_%VERSION%.exe
) else (
    echo ERROR: Installer file not found
    pause
    exit /b 1
)

echo.
echo Step 4: Creating portable version...
echo ===================================

REM Create portable version
if not exist "%OUTPUT_DIR%\SalesSystem_Portable" mkdir "%OUTPUT_DIR%\SalesSystem_Portable"
xcopy /E /I /Y "%BUILD_DIR%\*" "%OUTPUT_DIR%\SalesSystem_Portable\"

REM Create portable launcher
(
echo @echo off
echo echo Starting Sales System...
echo start "" "sales_system.exe"
) > "%OUTPUT_DIR%\SalesSystem_Portable\SalesSystem.bat"

REM Create portable README
(
echo Sales System Portable Version
echo =============================
echo.
echo This is a portable version of Sales System that can run without installation.
echo.
echo To use:
echo 1. Double-click SalesSystem.bat to start the application
echo 2. Or double-click sales_system.exe directly
echo.
echo Data will be stored in the same directory as the application.
echo.
echo For the full installer version, use SalesSystemSetup_%VERSION%.exe
) > "%OUTPUT_DIR%\SalesSystem_Portable\README.txt"

echo.
echo Step 5: Creating distribution package...
echo =======================================

REM Create distribution ZIP
if exist "%OUTPUT_DIR%\SalesSystem_%VERSION%.zip" del "%OUTPUT_DIR%\SalesSystem_%VERSION%.zip"
powershell -Command "& {Compress-Archive -Path '%OUTPUT_DIR%\*' -DestinationPath '%OUTPUT_DIR%\SalesSystem_%VERSION%.zip' -Force}"

echo.
echo Build completed successfully!
echo =============================
echo.
echo Files created:
echo - Installer: %OUTPUT_DIR%\SalesSystemSetup_%VERSION%.exe
echo - Portable: %OUTPUT_DIR%\SalesSystem_Portable\
echo - Package: %OUTPUT_DIR%\SalesSystem_%VERSION%.zip
echo.
echo You can now distribute the installer to users.
echo.

REM Clean up temporary files
if exist "%INSTALLER_DIR%\vcredist_x64.exe" del "%INSTALLER_DIR%\vcredist_x64.exe"
if exist "%INSTALLER_DIR%\sqlite3.exe" del "%INSTALLER_DIR%\sqlite3.exe"
if exist "%INSTALLER_DIR%\build" rmdir /s /q "%INSTALLER_DIR%\build"

echo Press any key to exit...
pause >nul
echo Building Sales System Windows Installer...
echo ==========================================

REM Set variables
set APP_NAME=Sales System
set VERSION=1.0.0
set BUILD_DIR=build\windows\x64\runner\Release
set INSTALLER_DIR=installer
set OUTPUT_DIR=dist

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

REM Check if NSIS is installed
where makensis >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: NSIS is not installed or not in PATH
    echo Please install NSIS from https://nsis.sourceforge.io/
    pause
    exit /b 1
)

echo.
echo Step 1: Building Flutter application for Windows...
echo ==================================================

REM Clean previous builds
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"

REM Build Flutter app for Windows
flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter build failed
    pause
    exit /b 1
)

echo.
echo Step 2: Preparing installer files...
echo ====================================

REM Create installer directory structure
if not exist "%INSTALLER_DIR%\assets" mkdir "%INSTALLER_DIR%\assets"
if not exist "%INSTALLER_DIR%\data" mkdir "%INSTALLER_DIR%\data"

REM Copy application files
if not exist "%INSTALLER_DIR%\build" mkdir "%INSTALLER_DIR%\build"
xcopy /E /I /Y "%BUILD_DIR%\*" "%INSTALLER_DIR%\build\"

REM Download Visual C++ Redistributable
echo Downloading Visual C++ Redistributable...
powershell -Command "& {Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile '%INSTALLER_DIR%\vcredist_x64.exe'}"
if %ERRORLEVEL% neq 0 (
    echo WARNING: Failed to download Visual C++ Redistributable
    echo You may need to download it manually
)

REM Download SQLite
echo Downloading SQLite...
powershell -Command "& {Invoke-WebRequest -Uri 'https://www.sqlite.org/2024/sqlite-dll-win64-x64-3460000.zip' -OutFile '%INSTALLER_DIR%\sqlite.zip'}"
if %ERRORLEVEL% neq 0 (
    echo WARNING: Failed to download SQLite
    echo You may need to download it manually
)

REM Extract SQLite
if exist "%INSTALLER_DIR%\sqlite.zip" (
    powershell -Command "& {Expand-Archive -Path '%INSTALLER_DIR%\sqlite.zip' -DestinationPath '%INSTALLER_DIR%\sqlite' -Force}"
    if exist "%INSTALLER_DIR%\sqlite\sqlite-dll-win64-x64-3460000\sqlite3.exe" (
        copy "%INSTALLER_DIR%\sqlite\sqlite-dll-win64-x64-3460000\sqlite3.exe" "%INSTALLER_DIR%\sqlite3.exe"
    )
    rmdir /s /q "%INSTALLER_DIR%\sqlite"
    del "%INSTALLER_DIR%\sqlite.zip"
)

REM Create application icon
echo Creating application icon...
REM You can replace this with your actual icon file
if not exist "%INSTALLER_DIR%\assets\icon.ico" (
    echo Creating placeholder icon...
    REM This is a placeholder - you should provide a real icon file
    echo. > "%INSTALLER_DIR%\assets\icon.ico"
)

REM Create LICENSE file
echo Creating LICENSE file...
(
echo Sales System License
echo ====================
echo.
echo Copyright ^(c^) 2024 Enick Sales
echo.
echo Permission is hereby granted, free of charge, to any person obtaining a copy
echo of this software and associated documentation files ^(the "Software"^), to deal
echo in the Software without restriction, including without limitation the rights
echo to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
echo copies of the Software, and to permit persons to whom the Software is
echo furnished to do so, subject to the following conditions:
echo.
echo The above copyright notice and this permission notice shall be included in all
echo copies or substantial portions of the Software.
echo.
echo THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
echo IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
echo FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
echo AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
echo LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
echo OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
echo SOFTWARE.
) > "%INSTALLER_DIR%\LICENSE.txt"

echo.
echo Step 3: Building NSIS installer...
echo ==================================

REM Build the installer
makensis "%INSTALLER_DIR%\sales_system_installer.nsi"
if %ERRORLEVEL% neq 0 (
    echo ERROR: NSIS build failed
    pause
    exit /b 1
)

REM Move installer to output directory
if exist "%INSTALLER_DIR%\SalesSystemSetup.exe" (
    move "%INSTALLER_DIR%\SalesSystemSetup.exe" "%OUTPUT_DIR%\SalesSystemSetup_%VERSION%.exe"
    echo.
    echo SUCCESS: Installer created successfully!
    echo Installer location: %OUTPUT_DIR%\SalesSystemSetup_%VERSION%.exe
) else (
    echo ERROR: Installer file not found
    pause
    exit /b 1
)

echo.
echo Step 4: Creating portable version...
echo ===================================

REM Create portable version
if not exist "%OUTPUT_DIR%\SalesSystem_Portable" mkdir "%OUTPUT_DIR%\SalesSystem_Portable"
xcopy /E /I /Y "%BUILD_DIR%\*" "%OUTPUT_DIR%\SalesSystem_Portable\"

REM Create portable launcher
(
echo @echo off
echo echo Starting Sales System...
echo start "" "sales_system.exe"
) > "%OUTPUT_DIR%\SalesSystem_Portable\SalesSystem.bat"

REM Create portable README
(
echo Sales System Portable Version
echo =============================
echo.
echo This is a portable version of Sales System that can run without installation.
echo.
echo To use:
echo 1. Double-click SalesSystem.bat to start the application
echo 2. Or double-click sales_system.exe directly
echo.
echo Data will be stored in the same directory as the application.
echo.
echo For the full installer version, use SalesSystemSetup_%VERSION%.exe
) > "%OUTPUT_DIR%\SalesSystem_Portable\README.txt"

echo.
echo Step 5: Creating distribution package...
echo =======================================

REM Create distribution ZIP
if exist "%OUTPUT_DIR%\SalesSystem_%VERSION%.zip" del "%OUTPUT_DIR%\SalesSystem_%VERSION%.zip"
powershell -Command "& {Compress-Archive -Path '%OUTPUT_DIR%\*' -DestinationPath '%OUTPUT_DIR%\SalesSystem_%VERSION%.zip' -Force}"

echo.
echo Build completed successfully!
echo =============================
echo.
echo Files created:
echo - Installer: %OUTPUT_DIR%\SalesSystemSetup_%VERSION%.exe
echo - Portable: %OUTPUT_DIR%\SalesSystem_Portable\
echo - Package: %OUTPUT_DIR%\SalesSystem_%VERSION%.zip
echo.
echo You can now distribute the installer to users.
echo.

REM Clean up temporary files
if exist "%INSTALLER_DIR%\vcredist_x64.exe" del "%INSTALLER_DIR%\vcredist_x64.exe"
if exist "%INSTALLER_DIR%\sqlite3.exe" del "%INSTALLER_DIR%\sqlite3.exe"
if exist "%INSTALLER_DIR%\build" rmdir /s /q "%INSTALLER_DIR%\build"

echo Press any key to exit...
pause >nul
