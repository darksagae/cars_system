; Sales System Installer Script
; Created for Flutter Sales System Application

;--------------------------------
; General

!define APPNAME "Sales System"
!define COMPANYNAME "Enick Sales"
!define DESCRIPTION "Professional Sales Management System"
!define VERSIONMAJOR 1
!define VERSIONMINOR 0
!define VERSIONBUILD 0
!define HELPURL "https://github.com/enick/sales-system"
!define UPDATEURL "https://github.com/enick/sales-system/releases"
!define ABOUTURL "https://github.com/enick/sales-system"
!define INSTALLSIZE 50000
!define INSTALLERNAME "SalesSystemSetup.exe"

;--------------------------------
; Modern UI

!include "MUI2.nsh"

;--------------------------------
; General

Name "${APPNAME}"
BrandingText "${APPNAME} ${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
OutFile "${INSTALLERNAME}"
InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
InstallDirRegKey HKLM "Software\${COMPANYNAME}\${APPNAME}" ""
RequestExecutionLevel admin

;--------------------------------
; Variables

Var StartMenuFolder

;--------------------------------
; Interface Settings

!define MUI_ABORTWARNING
!define MUI_ICON "assets\icon.ico"
!define MUI_UNICON "assets\icon.ico"

;--------------------------------
; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY

; Start Menu Folder Page Configuration
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\${COMPANYNAME}\${APPNAME}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"

!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!insertmacro MUI_PAGE_INSTFILES

; Finish Page Configuration
!define MUI_FINISHPAGE_RUN "$INSTDIR\sales_system.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APPNAME}"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.txt"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Show Release Notes"

!insertmacro MUI_PAGE_FINISH

; Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "Sales System (required)" SecMain
    SectionIn RO
    
    ; Set output path to the installation directory
    SetOutPath "$INSTDIR"
    
    ; Install application files
    File "build\windows\x64\runner\Release\sales_system.exe"
    File "build\windows\x64\runner\Release\flutter_windows.dll"
    File "build\windows\x64\runner\Release\data\flutter_assets\*"
    
    ; Install Visual C++ Redistributable
    File "installer\vcredist_x64.exe"
    
    ; Install SQLite
    File "installer\sqlite3.exe"
    
    ; Create data directory
    CreateDirectory "$INSTDIR\data"
    
    ; Create logs directory
    CreateDirectory "$INSTDIR\logs"
    
    ; Create backups directory
    CreateDirectory "$INSTDIR\backups"
    
    ; Install documentation
    File "README.md"
    File "LICENSE"
    File "CHANGELOG.md"
    
    ; Store installation folder
    WriteRegStr HKLM "Software\${COMPANYNAME}\${APPNAME}" "" $INSTDIR
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; Add to Add/Remove Programs
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "Publisher" "${COMPANYNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "HelpLink" "${HELPURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "URLUpdateInfo" "${UPDATEURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "URLInfoAbout" "${ABOUTURL}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "NoRepair" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
    
    ; Create Start Menu shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
        CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APPNAME}.lnk" "$INSTDIR\sales_system.exe"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\README.lnk" "$INSTDIR\README.md"
    !insertmacro MUI_STARTMENU_WRITE_END
    
    ; Create Desktop shortcut
    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\sales_system.exe"
    
    ; Install Visual C++ Redistributable silently
    ExecWait "$INSTDIR\vcredist_x64.exe /quiet /norestart"
    
    ; Clean up redistributable
    Delete "$INSTDIR\vcredist_x64.exe"
    
    ; Set file permissions
    AccessControl::GrantOnFile "$INSTDIR" "(BU)" "FullAccess"
    AccessControl::GrantOnFile "$INSTDIR\data" "(BU)" "FullAccess"
    AccessControl::GrantOnFile "$INSTDIR\logs" "(BU)" "FullAccess"
    AccessControl::GrantOnFile "$INSTDIR\backups" "(BU)" "FullAccess"
    
    ; Set application to run as administrator
    WriteRegStr HKLM "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" "$INSTDIR\sales_system.exe" "RUNASADMIN"
    
    ; Create firewall rules
    ExecWait 'netsh advfirewall firewall add rule name="${APPNAME}" dir=in action=allow program="$INSTDIR\sales_system.exe"'
    ExecWait 'netsh advfirewall firewall add rule name="${APPNAME}" dir=out action=allow program="$INSTDIR\sales_system.exe"'
    
    ; Register file associations
    WriteRegStr HKCR ".sales" "" "SalesSystemFile"
    WriteRegStr HKCR "SalesSystemFile" "" "${APPNAME} File"
    WriteRegStr HKCR "SalesSystemFile\DefaultIcon" "" "$INSTDIR\sales_system.exe,0"
    WriteRegStr HKCR "SalesSystemFile\shell\open\command" "" '"$INSTDIR\sales_system.exe" "%1"'
    
    ; Set application as default for .sales files
    WriteRegStr HKCR ".sales\OpenWithList\sales_system.exe" "" ""
    
    ; Create application data directory
    CreateDirectory "$APPDATA\${COMPANYNAME}\${APPNAME}"
    
    ; Set application data permissions
    AccessControl::GrantOnFile "$APPDATA\${COMPANYNAME}\${APPNAME}" "(BU)" "FullAccess"
    
    ; Create registry entries for application settings
    WriteRegStr HKLM "Software\${COMPANYNAME}\${APPNAME}\Settings" "InstallPath" "$INSTDIR"
    WriteRegStr HKLM "Software\${COMPANYNAME}\${APPNAME}\Settings" "DataPath" "$APPDATA\${COMPANYNAME}\${APPNAME}"
    WriteRegStr HKLM "Software\${COMPANYNAME}\${APPNAME}\Settings" "Version" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
    WriteRegDWORD HKLM "Software\${COMPANYNAME}\${APPNAME}\Settings" "FirstRun" 1
    
    ; Create backup script
    FileOpen $0 "$INSTDIR\backup.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 "echo Backing up Sales System data...$\r$\n"
    FileWrite $0 "xcopy /E /I /Y $\"$APPDATA\${COMPANYNAME}\${APPNAME}\*$\" $\"$INSTDIR\backups\%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%\*$\"$\r$\n"
    FileWrite $0 "echo Backup completed.$\r$\n"
    FileWrite $0 "pause$\r$\n"
    FileClose $0
    
    ; Create restore script
    FileOpen $0 "$INSTDIR\restore.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 "echo Restoring Sales System data...$\r$\n"
    FileWrite $0 "set /p backup_path=Enter backup folder path: $\r$\n"
    FileWrite $0 "xcopy /E /I /Y $\"%backup_path%\*$\" $\"$APPDATA\${COMPANYNAME}\${APPNAME}\*$\"$\r$\n"
    FileWrite $0 "echo Restore completed.$\r$\n"
    FileWrite $0 "pause$\r$\n"
    FileClose $0
    
    ; Create uninstall script
    FileOpen $0 "$INSTDIR\uninstall_clean.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 "echo Cleaning up Sales System...$\r$\n"
    FileWrite $0 "rmdir /S /Q $\"$APPDATA\${COMPANYNAME}\${APPNAME}$\"$\r$\n"
    FileWrite $0 "reg delete $\"HKLM\Software\${COMPANYNAME}\${APPNAME}$\" /f$\r$\n"
    FileWrite $0 "reg delete $\"HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}$\" /f$\r$\n"
    FileWrite $0 "netsh advfirewall firewall delete rule name=$\"${APPNAME}$\"$\r$\n"
    FileWrite $0 "echo Cleanup completed.$\r$\n"
    FileWrite $0 "pause$\r$\n"
    FileClose $0
    
    ; Create README for user
    FileOpen $0 "$INSTDIR\README.txt" w
    FileWrite $0 "${APPNAME} ${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}$\r$\n"
    FileWrite $0 "=====================================$\r$\n$\r$\n"
    FileWrite $0 "Thank you for installing ${APPNAME}!$\r$\n$\r$\n"
    FileWrite $0 "INSTALLATION COMPLETED SUCCESSFULLY$\r$\n$\r$\n"
    FileWrite $0 "Application Location: $INSTDIR$\r$\n"
    FileWrite $0 "Data Location: $APPDATA\${COMPANYNAME}\${APPNAME}$\r$\n$\r$\n"
    FileWrite $0 "QUICK START$\r$\n"
    FileWrite $0 "==========$\r$\n"
    FileWrite $0 "1. Double-click the desktop shortcut to launch the application$\r$\n"
    FileWrite $0 "2. Or use the Start Menu shortcut$\r$\n"
    FileWrite $0 "3. The application will create its database on first run$\r$\n$\r$\n"
    FileWrite $0 "FEATURES$\r$\n"
    FileWrite $0 "========$\r$\n"
    FileWrite $0 "- Customer Management$\r$\n"
    FileWrite $0 "- Invoice Generation$\r$\n"
    FileWrite $0 "- Payment Tracking$\r$\n"
    FileWrite $0 "- Product Management$\r$\n"
    FileWrite $0 "- Reports & Analytics$\r$\n"
    FileWrite $0 "- PDF Generation$\r$\n"
    FileWrite $0 "- Email Integration$\r$\n"
    FileWrite $0 "- WhatsApp Integration$\r$\n$\r$\n"
    FileWrite $0 "BACKUP & RESTORE$\r$\n"
    FileWrite $0 "================$\r$\n"
    FileWrite $0 "Use backup.bat to create data backups$\r$\n"
    FileWrite $0 "Use restore.bat to restore from backup$\r$\n$\r$\n"
    FileWrite $0 "UNINSTALLATION$\r$\n"
    FileWrite $0 "==============$\r$\n"
    FileWrite $0 "Use the Uninstall shortcut in Start Menu$\r$\n"
    FileWrite $0 "Or run uninstall_clean.bat for complete removal$\r$\n$\r$\n"
    FileWrite $0 "SUPPORT$\r$\n"
    FileWrite $0 "=======$\r$\n"
    FileWrite $0 "For support and updates, visit: ${HELPURL}$\r$\n$\r$\n"
    FileWrite $0 "Copyright ${COMPANYNAME} 2024$\r$\n"
    FileClose $0
    
    ; Set installation complete flag
    WriteRegDWORD HKLM "Software\${COMPANYNAME}\${APPNAME}" "Installed" 1
    
    ; Log installation
    FileOpen $0 "$INSTDIR\logs\install.log" w
    FileWrite $0 "${APPNAME} ${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD} installed on %date% %time%$\r$\n"
    FileWrite $0 "Installation path: $INSTDIR$\r$\n"
    FileWrite $0 "Data path: $APPDATA\${COMPANYNAME}\${APPNAME}$\r$\n"
    FileClose $0
SectionEnd

;--------------------------------
; Component Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} "Core application files and dependencies"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Uninstaller Section

Section "Uninstall"
    ; Remove application files
    Delete "$INSTDIR\sales_system.exe"
    Delete "$INSTDIR\flutter_windows.dll"
    Delete "$INSTDIR\README.txt"
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\CHANGELOG.md"
    Delete "$INSTDIR\backup.bat"
    Delete "$INSTDIR\restore.bat"
    Delete "$INSTDIR\uninstall_clean.bat"
    Delete "$INSTDIR\Uninstall.exe"
    
    ; Remove data directory (with user confirmation)
    MessageBox MB_YESNO "Do you want to remove all application data? This will delete all your sales data, invoices, and customer information." IDNO skip_data_removal
    RMDir /r "$APPDATA\${COMPANYNAME}\${APPNAME}"
    RMDir /r "$INSTDIR\data"
    RMDir /r "$INSTDIR\logs"
    RMDir /r "$INSTDIR\backups"
    skip_data_removal:
    
    ; Remove Start Menu shortcuts
    !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
    Delete "$SMPROGRAMS\$StartMenuFolder\${APPNAME}.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\README.lnk"
    RMDir "$SMPROGRAMS\$StartMenuFolder"
    
    ; Remove Desktop shortcut
    Delete "$DESKTOP\${APPNAME}.lnk"
    
    ; Remove registry entries
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}"
    DeleteRegKey HKLM "Software\${COMPANYNAME}\${APPNAME}"
    DeleteRegKey HKCR ".sales"
    DeleteRegKey HKCR "SalesSystemFile"
    
    ; Remove firewall rules
    ExecWait 'netsh advfirewall firewall delete rule name="${APPNAME}"'
    
    ; Remove application directory
    RMDir /r "$INSTDIR"
    
    ; Remove company directory if empty
    RMDir "$PROGRAMFILES\${COMPANYNAME}"
    
    ; Log uninstallation
    FileOpen $0 "$TEMP\${APPNAME}_uninstall.log" w
    FileWrite $0 "${APPNAME} ${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD} uninstalled on %date% %time%$\r$\n"
    FileClose $0
SectionEnd

;--------------------------------
; Functions

Function .onInit
    ; Check if already installed
    ReadRegStr $R0 HKLM "Software\${COMPANYNAME}\${APPNAME}" ""
    StrCmp $R0 "" not_installed
    MessageBox MB_YESNO "${APPNAME} is already installed. Do you want to reinstall?" IDYES not_installed
    Abort
    not_installed:
    
    ; Check system requirements
    Call CheckSystemRequirements
    
    ; Set installation directory
    StrCpy $INSTDIR "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
FunctionEnd

Function CheckSystemRequirements
    ; Check Windows version
    Call GetWindowsVersion
    Pop $R0
    IntCmp $R0 6 0 win_version_ok win_version_ok
    MessageBox MB_OK "This application requires Windows 7 or later. Your system is not supported."
    Abort
    win_version_ok:
    
    ; Check available disk space
    Call GetDiskSpace
    Pop $R0
    IntCmp $R0 ${INSTALLSIZE} disk_space_ok disk_space_ok
    MessageBox MB_OK "Insufficient disk space. Please free up at least ${INSTALLSIZE} KB of space."
    Abort
    disk_space_ok:
    
    ; Check if running as administrator
    Call IsUserAdmin
    Pop $R0
    StrCmp $R0 "true" admin_ok
    MessageBox MB_OK "This installer requires administrator privileges. Please run as administrator."
    Abort
    admin_ok:
FunctionEnd

Function GetWindowsVersion
    Push $R0
    Push $R1
    
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentVersion"
    StrCpy $R1 $R0 1
    IntOp $R0 $R1 - 0
    
    Pop $R1
    Exch $R0
FunctionEnd

Function GetDiskSpace
    Push $R0
    Push $R1
    
    StrCpy $R0 $INSTDIR 3
    System::Call 'kernel32::GetDiskFreeSpaceExA(t, *l, *l, *l) i(r0, .r1, ., .)'
    IntOp $R0 $R1 / 1024
    
    Pop $R1
    Exch $R0
FunctionEnd

Function IsUserAdmin
    Push $R0
    Push $R1
    
    System::Call 'advapi32::OpenSCManagerA(i 0, i 0, i 0x1) i .r0'
    IntCmp $R0 0 admin_false admin_true admin_false
    
    admin_true:
        System::Call 'advapi32::CloseServiceHandle(i r0)'
        StrCpy $R0 "true"
        Goto admin_end
    
    admin_false:
        StrCpy $R0 "false"
    
    admin_end:
        Pop $R1
        Exch $R0
FunctionEnd

Function .onInstSuccess
    ; Create desktop shortcut
    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\sales_system.exe"
    
    ; Show completion message
    MessageBox MB_YESNO "${APPNAME} has been successfully installed. Would you like to launch it now?" IDNO launch_skip
    Exec "$INSTDIR\sales_system.exe"
    launch_skip:
FunctionEnd

Function .onInstFailed
    ; Clean up on failure
    RMDir /r "$INSTDIR"
    DeleteRegKey HKLM "Software\${COMPANYNAME}\${APPNAME}"
    MessageBox MB_OK "Installation failed. Please try again."
FunctionEnd

;--------------------------------
; Installer Attributes

RequestExecutionLevel admin
ShowInstDetails show
ShowUninstDetails show
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize on
SetOverwrite on
SetDateSave on
; Created for Flutter Sales System Application

;--------------------------------
; General

!define APPNAME "Sales System"
!define COMPANYNAME "Enick Sales"
!define DESCRIPTION "Professional Sales Management System"
!define VERSIONMAJOR 1
!define VERSIONMINOR 0
!define VERSIONBUILD 0
!define HELPURL "https://github.com/enick/sales-system"
!define UPDATEURL "https://github.com/enick/sales-system/releases"
!define ABOUTURL "https://github.com/enick/sales-system"
!define INSTALLSIZE 50000
!define INSTALLERNAME "SalesSystemSetup.exe"

;--------------------------------
; Modern UI

!include "MUI2.nsh"

;--------------------------------
; General

Name "${APPNAME}"
BrandingText "${APPNAME} ${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
OutFile "${INSTALLERNAME}"
InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
InstallDirRegKey HKLM "Software\${COMPANYNAME}\${APPNAME}" ""
RequestExecutionLevel admin

;--------------------------------
; Variables

Var StartMenuFolder

;--------------------------------
; Interface Settings

!define MUI_ABORTWARNING
!define MUI_ICON "assets\icon.ico"
!define MUI_UNICON "assets\icon.ico"

;--------------------------------
; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY

; Start Menu Folder Page Configuration
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\${COMPANYNAME}\${APPNAME}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"

!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!insertmacro MUI_PAGE_INSTFILES

; Finish Page Configuration
!define MUI_FINISHPAGE_RUN "$INSTDIR\sales_system.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APPNAME}"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.txt"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Show Release Notes"

!insertmacro MUI_PAGE_FINISH

; Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "Sales System (required)" SecMain
    SectionIn RO
    
    ; Set output path to the installation directory
    SetOutPath "$INSTDIR"
    
    ; Install application files
    File "build\windows\x64\runner\Release\sales_system.exe"
    File "build\windows\x64\runner\Release\flutter_windows.dll"
    File "build\windows\x64\runner\Release\data\flutter_assets\*"
    
    ; Install Visual C++ Redistributable
    File "installer\vcredist_x64.exe"
    
    ; Install SQLite
    File "installer\sqlite3.exe"
    
    ; Create data directory
    CreateDirectory "$INSTDIR\data"
    
    ; Create logs directory
    CreateDirectory "$INSTDIR\logs"
    
    ; Create backups directory
    CreateDirectory "$INSTDIR\backups"
    
    ; Install documentation
    File "README.md"
    File "LICENSE"
    File "CHANGELOG.md"
    
    ; Store installation folder
    WriteRegStr HKLM "Software\${COMPANYNAME}\${APPNAME}" "" $INSTDIR
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; Add to Add/Remove Programs
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "Publisher" "${COMPANYNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "HelpLink" "${HELPURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "URLUpdateInfo" "${UPDATEURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "URLInfoAbout" "${ABOUTURL}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "NoRepair" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
    
    ; Create Start Menu shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
        CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APPNAME}.lnk" "$INSTDIR\sales_system.exe"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
        CreateShortCut "$SMPROGRAMS\$StartMenuFolder\README.lnk" "$INSTDIR\README.md"
    !insertmacro MUI_STARTMENU_WRITE_END
    
    ; Create Desktop shortcut
    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\sales_system.exe"
    
    ; Install Visual C++ Redistributable silently
    ExecWait "$INSTDIR\vcredist_x64.exe /quiet /norestart"
    
    ; Clean up redistributable
    Delete "$INSTDIR\vcredist_x64.exe"
    
    ; Set file permissions
    AccessControl::GrantOnFile "$INSTDIR" "(BU)" "FullAccess"
    AccessControl::GrantOnFile "$INSTDIR\data" "(BU)" "FullAccess"
    AccessControl::GrantOnFile "$INSTDIR\logs" "(BU)" "FullAccess"
    AccessControl::GrantOnFile "$INSTDIR\backups" "(BU)" "FullAccess"
    
    ; Set application to run as administrator
    WriteRegStr HKLM "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" "$INSTDIR\sales_system.exe" "RUNASADMIN"
    
    ; Create firewall rules
    ExecWait 'netsh advfirewall firewall add rule name="${APPNAME}" dir=in action=allow program="$INSTDIR\sales_system.exe"'
    ExecWait 'netsh advfirewall firewall add rule name="${APPNAME}" dir=out action=allow program="$INSTDIR\sales_system.exe"'
    
    ; Register file associations
    WriteRegStr HKCR ".sales" "" "SalesSystemFile"
    WriteRegStr HKCR "SalesSystemFile" "" "${APPNAME} File"
    WriteRegStr HKCR "SalesSystemFile\DefaultIcon" "" "$INSTDIR\sales_system.exe,0"
    WriteRegStr HKCR "SalesSystemFile\shell\open\command" "" '"$INSTDIR\sales_system.exe" "%1"'
    
    ; Set application as default for .sales files
    WriteRegStr HKCR ".sales\OpenWithList\sales_system.exe" "" ""
    
    ; Create application data directory
    CreateDirectory "$APPDATA\${COMPANYNAME}\${APPNAME}"
    
    ; Set application data permissions
    AccessControl::GrantOnFile "$APPDATA\${COMPANYNAME}\${APPNAME}" "(BU)" "FullAccess"
    
    ; Create registry entries for application settings
    WriteRegStr HKLM "Software\${COMPANYNAME}\${APPNAME}\Settings" "InstallPath" "$INSTDIR"
    WriteRegStr HKLM "Software\${COMPANYNAME}\${APPNAME}\Settings" "DataPath" "$APPDATA\${COMPANYNAME}\${APPNAME}"
    WriteRegStr HKLM "Software\${COMPANYNAME}\${APPNAME}\Settings" "Version" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
    WriteRegDWORD HKLM "Software\${COMPANYNAME}\${APPNAME}\Settings" "FirstRun" 1
    
    ; Create backup script
    FileOpen $0 "$INSTDIR\backup.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 "echo Backing up Sales System data...$\r$\n"
    FileWrite $0 "xcopy /E /I /Y $\"$APPDATA\${COMPANYNAME}\${APPNAME}\*$\" $\"$INSTDIR\backups\%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%\*$\"$\r$\n"
    FileWrite $0 "echo Backup completed.$\r$\n"
    FileWrite $0 "pause$\r$\n"
    FileClose $0
    
    ; Create restore script
    FileOpen $0 "$INSTDIR\restore.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 "echo Restoring Sales System data...$\r$\n"
    FileWrite $0 "set /p backup_path=Enter backup folder path: $\r$\n"
    FileWrite $0 "xcopy /E /I /Y $\"%backup_path%\*$\" $\"$APPDATA\${COMPANYNAME}\${APPNAME}\*$\"$\r$\n"
    FileWrite $0 "echo Restore completed.$\r$\n"
    FileWrite $0 "pause$\r$\n"
    FileClose $0
    
    ; Create uninstall script
    FileOpen $0 "$INSTDIR\uninstall_clean.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 "echo Cleaning up Sales System...$\r$\n"
    FileWrite $0 "rmdir /S /Q $\"$APPDATA\${COMPANYNAME}\${APPNAME}$\"$\r$\n"
    FileWrite $0 "reg delete $\"HKLM\Software\${COMPANYNAME}\${APPNAME}$\" /f$\r$\n"
    FileWrite $0 "reg delete $\"HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}$\" /f$\r$\n"
    FileWrite $0 "netsh advfirewall firewall delete rule name=$\"${APPNAME}$\"$\r$\n"
    FileWrite $0 "echo Cleanup completed.$\r$\n"
    FileWrite $0 "pause$\r$\n"
    FileClose $0
    
    ; Create README for user
    FileOpen $0 "$INSTDIR\README.txt" w
    FileWrite $0 "${APPNAME} ${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}$\r$\n"
    FileWrite $0 "=====================================$\r$\n$\r$\n"
    FileWrite $0 "Thank you for installing ${APPNAME}!$\r$\n$\r$\n"
    FileWrite $0 "INSTALLATION COMPLETED SUCCESSFULLY$\r$\n$\r$\n"
    FileWrite $0 "Application Location: $INSTDIR$\r$\n"
    FileWrite $0 "Data Location: $APPDATA\${COMPANYNAME}\${APPNAME}$\r$\n$\r$\n"
    FileWrite $0 "QUICK START$\r$\n"
    FileWrite $0 "==========$\r$\n"
    FileWrite $0 "1. Double-click the desktop shortcut to launch the application$\r$\n"
    FileWrite $0 "2. Or use the Start Menu shortcut$\r$\n"
    FileWrite $0 "3. The application will create its database on first run$\r$\n$\r$\n"
    FileWrite $0 "FEATURES$\r$\n"
    FileWrite $0 "========$\r$\n"
    FileWrite $0 "- Customer Management$\r$\n"
    FileWrite $0 "- Invoice Generation$\r$\n"
    FileWrite $0 "- Payment Tracking$\r$\n"
    FileWrite $0 "- Product Management$\r$\n"
    FileWrite $0 "- Reports & Analytics$\r$\n"
    FileWrite $0 "- PDF Generation$\r$\n"
    FileWrite $0 "- Email Integration$\r$\n"
    FileWrite $0 "- WhatsApp Integration$\r$\n$\r$\n"
    FileWrite $0 "BACKUP & RESTORE$\r$\n"
    FileWrite $0 "================$\r$\n"
    FileWrite $0 "Use backup.bat to create data backups$\r$\n"
    FileWrite $0 "Use restore.bat to restore from backup$\r$\n$\r$\n"
    FileWrite $0 "UNINSTALLATION$\r$\n"
    FileWrite $0 "==============$\r$\n"
    FileWrite $0 "Use the Uninstall shortcut in Start Menu$\r$\n"
    FileWrite $0 "Or run uninstall_clean.bat for complete removal$\r$\n$\r$\n"
    FileWrite $0 "SUPPORT$\r$\n"
    FileWrite $0 "=======$\r$\n"
    FileWrite $0 "For support and updates, visit: ${HELPURL}$\r$\n$\r$\n"
    FileWrite $0 "Copyright ${COMPANYNAME} 2024$\r$\n"
    FileClose $0
    
    ; Set installation complete flag
    WriteRegDWORD HKLM "Software\${COMPANYNAME}\${APPNAME}" "Installed" 1
    
    ; Log installation
    FileOpen $0 "$INSTDIR\logs\install.log" w
    FileWrite $0 "${APPNAME} ${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD} installed on %date% %time%$\r$\n"
    FileWrite $0 "Installation path: $INSTDIR$\r$\n"
    FileWrite $0 "Data path: $APPDATA\${COMPANYNAME}\${APPNAME}$\r$\n"
    FileClose $0
SectionEnd

;--------------------------------
; Component Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} "Core application files and dependencies"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Uninstaller Section

Section "Uninstall"
    ; Remove application files
    Delete "$INSTDIR\sales_system.exe"
    Delete "$INSTDIR\flutter_windows.dll"
    Delete "$INSTDIR\README.txt"
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\CHANGELOG.md"
    Delete "$INSTDIR\backup.bat"
    Delete "$INSTDIR\restore.bat"
    Delete "$INSTDIR\uninstall_clean.bat"
    Delete "$INSTDIR\Uninstall.exe"
    
    ; Remove data directory (with user confirmation)
    MessageBox MB_YESNO "Do you want to remove all application data? This will delete all your sales data, invoices, and customer information." IDNO skip_data_removal
    RMDir /r "$APPDATA\${COMPANYNAME}\${APPNAME}"
    RMDir /r "$INSTDIR\data"
    RMDir /r "$INSTDIR\logs"
    RMDir /r "$INSTDIR\backups"
    skip_data_removal:
    
    ; Remove Start Menu shortcuts
    !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
    Delete "$SMPROGRAMS\$StartMenuFolder\${APPNAME}.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
    Delete "$SMPROGRAMS\$StartMenuFolder\README.lnk"
    RMDir "$SMPROGRAMS\$StartMenuFolder"
    
    ; Remove Desktop shortcut
    Delete "$DESKTOP\${APPNAME}.lnk"
    
    ; Remove registry entries
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME}${APPNAME}"
    DeleteRegKey HKLM "Software\${COMPANYNAME}\${APPNAME}"
    DeleteRegKey HKCR ".sales"
    DeleteRegKey HKCR "SalesSystemFile"
    
    ; Remove firewall rules
    ExecWait 'netsh advfirewall firewall delete rule name="${APPNAME}"'
    
    ; Remove application directory
    RMDir /r "$INSTDIR"
    
    ; Remove company directory if empty
    RMDir "$PROGRAMFILES\${COMPANYNAME}"
    
    ; Log uninstallation
    FileOpen $0 "$TEMP\${APPNAME}_uninstall.log" w
    FileWrite $0 "${APPNAME} ${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD} uninstalled on %date% %time%$\r$\n"
    FileClose $0
SectionEnd

;--------------------------------
; Functions

Function .onInit
    ; Check if already installed
    ReadRegStr $R0 HKLM "Software\${COMPANYNAME}\${APPNAME}" ""
    StrCmp $R0 "" not_installed
    MessageBox MB_YESNO "${APPNAME} is already installed. Do you want to reinstall?" IDYES not_installed
    Abort
    not_installed:
    
    ; Check system requirements
    Call CheckSystemRequirements
    
    ; Set installation directory
    StrCpy $INSTDIR "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
FunctionEnd

Function CheckSystemRequirements
    ; Check Windows version
    Call GetWindowsVersion
    Pop $R0
    IntCmp $R0 6 0 win_version_ok win_version_ok
    MessageBox MB_OK "This application requires Windows 7 or later. Your system is not supported."
    Abort
    win_version_ok:
    
    ; Check available disk space
    Call GetDiskSpace
    Pop $R0
    IntCmp $R0 ${INSTALLSIZE} disk_space_ok disk_space_ok
    MessageBox MB_OK "Insufficient disk space. Please free up at least ${INSTALLSIZE} KB of space."
    Abort
    disk_space_ok:
    
    ; Check if running as administrator
    Call IsUserAdmin
    Pop $R0
    StrCmp $R0 "true" admin_ok
    MessageBox MB_OK "This installer requires administrator privileges. Please run as administrator."
    Abort
    admin_ok:
FunctionEnd

Function GetWindowsVersion
    Push $R0
    Push $R1
    
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentVersion"
    StrCpy $R1 $R0 1
    IntOp $R0 $R1 - 0
    
    Pop $R1
    Exch $R0
FunctionEnd

Function GetDiskSpace
    Push $R0
    Push $R1
    
    StrCpy $R0 $INSTDIR 3
    System::Call 'kernel32::GetDiskFreeSpaceExA(t, *l, *l, *l) i(r0, .r1, ., .)'
    IntOp $R0 $R1 / 1024
    
    Pop $R1
    Exch $R0
FunctionEnd

Function IsUserAdmin
    Push $R0
    Push $R1
    
    System::Call 'advapi32::OpenSCManagerA(i 0, i 0, i 0x1) i .r0'
    IntCmp $R0 0 admin_false admin_true admin_false
    
    admin_true:
        System::Call 'advapi32::CloseServiceHandle(i r0)'
        StrCpy $R0 "true"
        Goto admin_end
    
    admin_false:
        StrCpy $R0 "false"
    
    admin_end:
        Pop $R1
        Exch $R0
FunctionEnd

Function .onInstSuccess
    ; Create desktop shortcut
    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\sales_system.exe"
    
    ; Show completion message
    MessageBox MB_YESNO "${APPNAME} has been successfully installed. Would you like to launch it now?" IDNO launch_skip
    Exec "$INSTDIR\sales_system.exe"
    launch_skip:
FunctionEnd

Function .onInstFailed
    ; Clean up on failure
    RMDir /r "$INSTDIR"
    DeleteRegKey HKLM "Software\${COMPANYNAME}\${APPNAME}"
    MessageBox MB_OK "Installation failed. Please try again."
FunctionEnd

;--------------------------------
; Installer Attributes

RequestExecutionLevel admin
ShowInstDetails show
ShowUninstDetails show
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize on
SetOverwrite on
SetDateSave on
