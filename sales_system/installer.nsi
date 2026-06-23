; NSIS Installer Script for Flutter App with Poppler Utils
; Define your application name
!define APPNAME "NSB Motors System"
!define COMPANYNAME "NSB Motors"
!define DESCRIPTION "Vehicle Management System"

; Main Install settings
Name "${APPNAME}"
InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
InstallDirRegKey HKCU "Software\${COMPANYNAME}\${APPNAME}" ""
RequestExecutionLevel admin

; Modern interface settings
!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_UNABORTWARNING

; MUI Settings
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Set languages
!insertmacro MUI_LANGUAGE "English"

; The file to write
OutFile "nsb_motors_installer.exe"

; The stuff to install
Section "${APPNAME}" SEC001
  SectionIn RO
  
  ; Set output path to the installation directory
  SetOutPath "$INSTDIR"
  
  ; Add files
  File /r "..\build\windows\x64\runner\Release\*"
  
  ; Create the poppler directory and copy binaries
  SetOutPath "$INSTDIR\poppler"
  File /r "bundled_deps\*"
  
  ; Add registry entries
  WriteRegStr HKCU "Software\${COMPANYNAME}\${APPNAME}" "" "$INSTDIR"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Add to PATH environment variable
  EnVar::SetHKCU
  EnVar::AddValue "PATH" "$INSTDIR\poppler"
  
SectionEnd

; Create Shortcuts
Section -AdditionalIcons
  CreateDirectory "$SMPROGRAMS\${COMPANYNAME}"
  CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\saga.exe"
  CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\saga.exe"
SectionEnd

; Registry information for add/remove programs
Section -RegistryEntries
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$INSTDIR\saga.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "${COMPANYNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "1.0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "AboutURL" "https://nsbmotors.com/"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Description" "${DESCRIPTION}"
SectionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove files and uninstaller
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
  Delete "$DESKTOP\${APPNAME}.lnk"
  RMDir "$SMPROGRAMS\${COMPANYNAME}"
  
  ; Remove from PATH
  EnVar::SetHKCU
  EnVar::DeleteValue "PATH" "$INSTDIR\poppler"
  
  ; Remove registry keys
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
  DeleteRegKey HKCU "Software\${COMPANYNAME}\${APPNAME}"
SectionEnd

; Functions
Function .onInit
  ; Check if already installed
  ReadRegStr $R0 HKCU "Software\${COMPANYNAME}\${APPNAME}" ""
  StrCmp $R0 "" done
  
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
  "${APPNAME} is already installed. $\n$\nClick `OK` to remove the \
  previous version or `Cancel` to cancel this upgrade." \
  IDOK uninst
  Abort
  
  ; Run the uninstaller
  uninst:
  ClearErrors
  ExecWait '$R0\uninstall.exe _?=$R0'
  
  IfErrors no_remove_uninstaller done
  no_remove_uninstaller:
  Delete $R0\uninstall.exe
  RMDir $R0
  
  done:
FunctionEnd