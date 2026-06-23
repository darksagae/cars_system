@echo off
echo Uninstalling NSB Motors System...
echo ==================================

REM Remove installation directory
set INSTALL_DIR=%PROGRAMFILES%\NSB Motors\NSB Motors System
if exist "%INSTALL_DIR%" (
    echo Removing application files...
    rmdir /S /Q "%INSTALL_DIR%"
    echo Application files removed.
) else (
    echo Application not found.
)

REM Remove shortcut
set SHORTCUT_FILE=%USERPROFILE%\Desktop\NSB Motors System.lnk
if exist "%SHORTCUT_FILE%" (
    echo Removing desktop shortcut...
    del "%SHORTCUT_FILE%"
    echo Desktop shortcut removed.
)

echo.
echo Uninstallation complete!
echo.
pause