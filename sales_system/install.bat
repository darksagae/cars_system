@echo off
echo Installing NSB Motors System...
echo =================================

REM Create installation directory
set INSTALL_DIR=%PROGRAMFILES%\NSB Motors\NSB Motors System
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy application files
echo Copying application files...
xcopy /E /I /Y "build\windows\x64\runner\Release" "%INSTALL_DIR%"

REM Create poppler directory and copy binaries
echo Copying poppler utilities...
if not exist "%INSTALL_DIR%\poppler" mkdir "%INSTALL_DIR%\poppler"
xcopy /E /I /Y "poppler-extracted\poppler-25.12.0\Library\bin" "%INSTALL_DIR%\poppler"

REM Add to PATH environment variable
echo Adding poppler to PATH...
setx PATH "%PATH%;%INSTALL_DIR%\poppler" /M

REM Create shortcuts
echo Creating shortcuts...
set SHORTCUT_DIR=%USERPROFILE%\Desktop
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%SHORTCUT_DIR%\NSB Motors System.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "%INSTALL_DIR%\saga.exe" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs
del CreateShortcut.vbs

echo.
echo Installation complete!
echo The application has been installed to %INSTALL_DIR%
echo A shortcut has been created on your desktop
echo.
pause