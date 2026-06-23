@echo off
echo Creating NSB Motors System Installer...

rem Create installation directory
mkdir "C:\NSB Motors System"

rem Copy all files
xcopy "dist\app" "C:\NSB Motors System" /E /I /Y

echo Installation files copied to C:\NSB Motors System
echo.
echo Creating desktop shortcut...

rem Create desktop shortcut
set SCRIPT="%TEMP%\shortcut.vbs"
echo Set oWS = WScript.CreateObject("WScript.Shell") > %SCRIPT%
echo sLinkFile = "%USERPROFILE%\Desktop\NSB Motors System.lnk" >> %SCRIPT%
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%
echo oLink.TargetPath = "C:\NSB Motors System\sales_system.exe" >> %SCRIPT%
echo oLink.WorkingDirectory = "C:\NSB Motors System" >> %SCRIPT%
echo oLink.Save >> %SCRIPT%
cscript %SCRIPT%
del %SCRIPT%

echo Desktop shortcut created.
echo.
echo Installation complete!
echo You can now launch NSB Motors System from your desktop.
echo.
echo Press any key to exit...
pause >nul
