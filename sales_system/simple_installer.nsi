; NSIS Installer Script for Flutter App with Poppler Utils
!define APPNAME "NSB Motors System"
!define COMPANYNAME "NSB Motors"
!define DESCRIPTION "Vehicle Management System"
!define VERSION "1.0"

; Main Install settings
Name "${APPNAME}"
InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
RequestExecutionLevel admin

; Modern interface settings
!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_UNABORTWARNING

; MUI Settings
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Set languages
!insertmacro MUI_LANGUAGE "English"

; The file to write
OutFile "nsb_motors_installer.exe"

Section "Install"
  ; Set output path to the installation directory
  SetOutPath "$INSTDIR"
  
  ; Copy the main application files
  File /r "build\windows\x64\runner\Release\*"
  
  ; Create the poppler directory and copy binaries
  SetOutPath "$INSTDIR\poppler"
  File /r "poppler-extracted\poppler-25.12.0\Library\bin\*"
  
  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\${COMPANYNAME}"
  CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\saga.exe"
  CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\saga.exe"
  
  ; Add to PATH environment variable
  EnVar::AddValue "PATH" "$INSTDIR\poppler"
  
  ; Write uninstall information
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
  ; Remove files and uninstaller
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
  Delete "$DESKTOP\${APPNAME}.lnk"
  RMDir "$SMPROGRAMS\${COMPANYNAME}"
  
  ; Remove from PATH
  EnVar::DeleteValue "PATH" "$INSTDIR\poppler"
SectionEnd